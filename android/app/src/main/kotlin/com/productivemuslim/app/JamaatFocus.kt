package com.productivemuslim.app

import android.accessibilityservice.AccessibilityService
import android.app.Activity
import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.graphics.Color
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.AlarmClock
import android.provider.Settings
import android.telecom.TelecomManager
import android.text.format.DateFormat
import android.view.Gravity
import android.view.accessibility.AccessibilityEvent
import android.window.OnBackInvokedCallback
import android.window.OnBackInvokedDispatcher
import android.widget.Button
import android.widget.ImageButton
import android.widget.LinearLayout
import android.widget.TextView
import java.lang.ref.WeakReference
import java.util.Date
import kotlin.math.sqrt

/**
 * Jamaat focus engine: silences the phone (Do Not Disturb) and, with the
 * accessibility service on, covers every other app with [JamaatFocusActivity]
 * for each planned session. Dart plans the sessions (buildFocusWindows) and
 * hands them over through the com.productivemuslim.app/focus channel; alarms
 * start and end them with the app closed.
 *
 * Nafs lock rides the same engine: with it on, the accessibility service
 * counts hard shakes, and [NAFS_SHAKES] of them start a strict session of
 * the set length right away ([lockNafs]).
 *
 * State lives in SharedPreferences so the alarm receiver, the accessibility
 * service and the lock screen agree without a running engine.
 */
object JamaatFocus {
    private const val PREFS = "jamaat_focus"
    const val ACTION_TICK = "com.productivemuslim.app.focus.TICK"
    const val ACTION_END = "com.productivemuslim.app.focus.END"
    private const val CHANNEL = "productive_muslim_focus"
    private const val NOTIFICATION_ID = 7301

    /** The user's own DND exceptions (starred callers, alarms) still apply. */
    private const val SILENT = NotificationManager.INTERRUPTION_FILTER_PRIORITY

    // activeUntil: 0 = no session, -1 = until the user ends it, else epoch ms.
    private const val ACTIVE_UNTIL = "activeUntil"

    const val NAFS_SHAKES = 5

    // kind of the running session: "jamaat" or "nafs" (own texts, always blocks).
    private const val KIND = "kind"

    private fun prefs(c: Context): SharedPreferences =
        c.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun nm(c: Context) =
        c.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    fun isActive(c: Context): Boolean {
        val until = prefs(c).getLong(ACTIVE_UNTIL, 0L)
        if (until > 0 && System.currentTimeMillis() >= until) {
            // Past its end but the (inexact) end alarm hasn't run yet: end it now.
            tick(c)
            return prefs(c).getLong(ACTIVE_UNTIL, 0L) != 0L
        }
        return until != 0L
    }

    private fun isStrict(c: Context) = prefs(c).getBoolean("sessionStrict", false)

    fun hasDndAccess(c: Context) = nm(c).isNotificationPolicyAccessGranted

    fun hasBlockAccess(c: Context): Boolean {
        val me = ComponentName(c, JamaatFocusService::class.java)
        return Settings.Secure.getString(
            c.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        )?.split(':')?.any { ComponentName.unflattenFromString(it) == me } == true
    }

    private fun isNafs(c: Context) = prefs(c).getString(KIND, "") == "nafs"

    fun nafsEnabled(c: Context) = prefs(c).getBoolean("nafs", false)

    // The manifest can't change at runtime: look it up once.
    private var serviceDeclared: Boolean? = null

    /** False when the build stripped [JamaatFocusService] (`focusBlocking=false`). */
    fun blockingAvailable(c: Context): Boolean = serviceDeclared ?: try {
        val me = ComponentName(c, JamaatFocusService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            c.packageManager.getServiceInfo(me, PackageManager.ComponentInfoFlags.of(0))
        } else {
            @Suppress("DEPRECATION")
            c.packageManager.getServiceInfo(me, 0)
        }
        true
    } catch (e: PackageManager.NameNotFoundException) {
        false
    }.also { serviceDeclared = it }

    fun blocking(c: Context) =
        (isNafs(c) || prefs(c).getBoolean("block", false)) && hasBlockAccess(c) &&
            blockingAvailable(c)

    /** Replaces the plan (from Dart) and re-evaluates now. */
    fun schedule(c: Context, args: Map<*, *>) {
        val windows = FocusPlan.fromArgs(args["windows"])
        val enabled = args["enabled"] == true
        prefs(c).edit().apply {
            putString("windows", if (enabled) FocusPlan.encode(windows) else "")
            putBoolean("block", args["block"] == true)
            putBoolean("strict", args["strict"] == true)
            putBoolean("nafs", args["nafs"] == true)
            putInt("nafsMinutes", (args["nafsMinutes"] as? Number)?.toInt() ?: 5)
            for (key in listOf(
                "title", "body", "bodyUntil", "endAction", "channelName",
                "nafs.title", "nafs.bodyUntil",
            )) {
                putString(key, args[key] as? String ?: "")
            }
        }.apply()
        JamaatFocusService.current?.get()?.syncShake()
        // Switching the feature off ends a running session — unless strict.
        if (!enabled && isActive(c) && !isStrict(c)) {
            stop(c)
        }
        tick(c)
    }

    private fun windows(c: Context) = FocusPlan.parse(prefs(c).getString("windows", ""))

    /** Ends a session past its time, starts a due one, arms the next alarm. */
    fun tick(c: Context) {
        val now = System.currentTimeMillis()
        val p = prefs(c)
        var until = p.getLong(ACTIVE_UNTIL, 0L)
        if (until > 0 && now >= until) {
            stop(c)
            until = 0L
        }
        if (until == 0L) {
            FocusPlan.due(windows(c), now, p.getLong("lastStart", 0L))
                ?.let { start(c, it.first, it.second) }
            until = p.getLong(ACTIVE_UNTIL, 0L)
        }
        arm(c, FocusPlan.nextAlarm(windows(c), until, now))
    }

    private fun start(c: Context, start: Long, end: Long) {
        val nm = nm(c)
        // DND already on (Bedtime, the user's own) is left alone: we neither
        // loosen it nor take it over, so stop() never restores the wrong state.
        val silence = nm.isNotificationPolicyAccessGranted &&
            nm.currentInterruptionFilter == NotificationManager.INTERRUPTION_FILTER_ALL
        prefs(c).edit()
            .putLong(ACTIVE_UNTIL, if (end > 0) end else -1L)
            .putLong("lastStart", start)
            .putString(KIND, "jamaat")
            .putBoolean("sessionStrict", prefs(c).getBoolean("strict", false))
            .putBoolean("silenced", silence)
            .putInt("prevFilter", nm.currentInterruptionFilter)
            .apply()
        if (silence) {
            nm.setInterruptionFilter(SILENT)
        }
        showOngoing(c)
        if (blocking(c)) {
            showLock(c)
        }
        JamaatFocusService.current?.get()?.syncShake()
    }

    private fun stop(c: Context) {
        val p = prefs(c)
        val nm = nm(c)
        // Restore only what we changed: a filter the user picked meanwhile stays.
        if (p.getBoolean("silenced", false) &&
            nm.isNotificationPolicyAccessGranted &&
            nm.currentInterruptionFilter == SILENT
        ) {
            nm.setInterruptionFilter(
                p.getInt("prevFilter", NotificationManager.INTERRUPTION_FILTER_ALL)
            )
        }
        p.edit().putLong(ACTIVE_UNTIL, 0L).putBoolean("silenced", false).remove(KIND).apply()
        nm.cancel(NOTIFICATION_ID)
        JamaatFocusActivity.current?.get()?.finish()
        JamaatFocusService.current?.get()?.syncShake()
    }

    /** Shakes counted: a strict, app-blocking session from now. No-op mid-session. */
    fun lockNafs(c: Context) {
        if (isActive(c) || !nafsEnabled(c) || !blockingAvailable(c)) return
        val minutes = prefs(c).getInt("nafsMinutes", 5).coerceAtLeast(1)
        prefs(c).edit()
            .putLong(ACTIVE_UNTIL, System.currentTimeMillis() + minutes * 60_000L)
            .putString(KIND, "nafs")
            .putBoolean("sessionStrict", true)
            .putBoolean("silenced", false)
            .apply()
        showOngoing(c)
        showLock(c)
        tick(c) // arms the end alarm
    }

    /** User "End" — refused in strict mode. */
    fun end(c: Context) {
        if (isActive(c) && !isStrict(c)) {
            stop(c)
            tick(c)
        }
    }

    /** Strict: DND switched off from quick settings goes straight back on. */
    fun enforce(c: Context) {
        val nm = nm(c)
        if (isActive(c) && isStrict(c) && prefs(c).getBoolean("silenced", false) &&
            nm.isNotificationPolicyAccessGranted && nm.currentInterruptionFilter != SILENT
        ) {
            nm.setInterruptionFilter(SILENT)
        }
    }

    fun status(c: Context): Map<String, Any> = mapOf(
        "active" to isActive(c),
        "strict" to isStrict(c),
        "until" to prefs(c).getLong(ACTIVE_UNTIL, 0L),
        "nafs" to isNafs(c),
    )

    private fun arm(c: Context, at: Long?) {
        val am = c.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pi = PendingIntent.getBroadcast(
            c, 0,
            Intent(c, JamaatFocusReceiver::class.java).setAction(ACTION_TICK),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        am.cancel(pi)
        if (at == null) return
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !am.canScheduleExactAlarms()) {
                am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pi)
            } else {
                am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pi)
            }
        } catch (e: SecurityException) {
            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pi)
        }
    }

    /** Session text; a nafs session reads its own "nafs.<key>" where set. */
    fun text(c: Context, key: String): String {
        val p = prefs(c)
        val own = if (isNafs(c)) p.getString("nafs.$key", "").orEmpty() else ""
        return own.ifEmpty { p.getString(key, "").orEmpty() }
    }

    fun body(c: Context): String {
        val until = prefs(c).getLong(ACTIVE_UNTIL, 0L)
        return if (until > 0) {
            text(c, "bodyUntil").replace("{time}", DateFormat.getTimeFormat(c).format(Date(until)))
        } else {
            text(c, "body")
        }
    }

    private fun showOngoing(c: Context) {
        val nm = nm(c)
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            nm.createNotificationChannel(
                NotificationChannel(
                    CHANNEL,
                    text(c, "channelName").ifEmpty { "Jamaat focus" },
                    NotificationManager.IMPORTANCE_LOW
                )
            )
            Notification.Builder(c, CHANNEL)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(c)
        }
        builder
            .setSmallIcon(R.drawable.ic_stat_notify)
            .setContentTitle(text(c, "title"))
            .setContentText(body(c))
            .setOngoing(true)
            .setContentIntent(
                PendingIntent.getActivity(
                    c, 0, Intent(c, MainActivity::class.java),
                    PendingIntent.FLAG_IMMUTABLE
                )
            )
        if (!isStrict(c)) {
            builder.addAction(
                Notification.Action.Builder(
                    null,
                    text(c, "endAction"),
                    PendingIntent.getBroadcast(
                        c, 1,
                        Intent(c, JamaatFocusReceiver::class.java).setAction(ACTION_END),
                        PendingIntent.FLAG_IMMUTABLE
                    )
                ).build()
            )
        }
        try {
            nm.notify(NOTIFICATION_ID, builder.build())
        } catch (e: SecurityException) {
            // Notifications denied: the session still runs.
        }
    }

    fun showLock(c: Context) {
        try {
            c.startActivity(
                Intent(c, JamaatFocusActivity::class.java)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            )
        } catch (e: Exception) {
            // Background start refused: the next app switch shows it.
        }
    }

    // Installed apps rarely change mid-process: resolve once.
    private var clocks: Set<String>? = null

    /**
     * Every app that shows alarms. A chooser (no default set) would resolve to
     * "android", so take all handlers, not resolveActivity's pick.
     */
    private fun clocks(c: Context): Set<String> = clocks ?: run {
        val intent = Intent(AlarmClock.ACTION_SHOW_ALARMS)
        val found = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            c.packageManager.queryIntentActivities(intent, PackageManager.ResolveInfoFlags.of(0))
        } else {
            @Suppress("DEPRECATION")
            c.packageManager.queryIntentActivities(intent, 0)
        }
        found.map { it.activityInfo.packageName }.toSet()
    }.also { clocks = it }

    /** See [FocusPlan.allowed]; this side only looks up the device's apps. */
    fun allowed(c: Context, pkg: String): Boolean = FocusPlan.allowed(
        pkg,
        own = c.packageName,
        dialer = (c.getSystemService(Context.TELECOM_SERVICE) as? TelecomManager)
            ?.defaultDialerPackage,
        ime = Settings.Secure.getString(c.contentResolver, Settings.Secure.DEFAULT_INPUT_METHOD),
        clocks = clocks(c),
    )
}

/** Alarm (start/end), notification "End", and boot/update re-arm. */
class JamaatFocusReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == JamaatFocus.ACTION_END) {
            JamaatFocus.end(context)
        } else {
            JamaatFocus.tick(context)
        }
    }
}

/**
 * Watches which app comes to the front during a session and covers it.
 * Reads nothing but the package name of the new window.
 */
class JamaatFocusService : AccessibilityService() {
    companion object {
        var current: WeakReference<JamaatFocusService>? = null
    }

    private val filterChanged = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) = JamaatFocus.enforce(context)
    }

    // Screen on/off: shakes only count while the screen is on (not in a pocket).
    private val screenChanged = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) = syncShake()
    }

    private val shakes = ShakeCounter(JamaatFocus.NAFS_SHAKES) {
        JamaatFocus.lockNafs(this)
        if (JamaatFocus.isActive(this) && Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            performGlobalAction(GLOBAL_ACTION_LOCK_SCREEN)
        }
        syncShake()
    }
    private var listening = false
    private var registered = false

    override fun onServiceConnected() {
        current = WeakReference(this)
        val filter = IntentFilter(NotificationManager.ACTION_INTERRUPTION_FILTER_CHANGED)
        val screen = IntentFilter(Intent.ACTION_SCREEN_ON).apply {
            addAction(Intent.ACTION_SCREEN_OFF)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(filterChanged, filter, Context.RECEIVER_NOT_EXPORTED)
            registerReceiver(screenChanged, screen, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(filterChanged, filter)
            registerReceiver(screenChanged, screen)
        }
        registered = true
        syncShake()
    }

    // ponytail: sensors in the accessibility service's process, no foreground
    // service; if an OEM throttles background sensors, move this into one.
    /** Accelerometer on only while nafs lock is on, the screen is on, and no session runs. */
    fun syncShake() {
        val sm = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        val want = JamaatFocus.nafsEnabled(this) && !JamaatFocus.isActive(this) &&
            (getSystemService(Context.POWER_SERVICE) as PowerManager).isInteractive
        if (want && !listening) {
            val accel = sm.getDefaultSensor(Sensor.TYPE_ACCELEROMETER) ?: return
            listening = sm.registerListener(shakes, accel, SensorManager.SENSOR_DELAY_GAME)
        } else if (!want && listening) {
            sm.unregisterListener(shakes)
            shakes.reset()
            listening = false
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED ||
            !JamaatFocus.isActive(this)
        ) return
        JamaatFocus.enforce(this)
        val pkg = event.packageName?.toString() ?: return
        if (JamaatFocus.blocking(this) && !JamaatFocus.allowed(this, pkg)) {
            JamaatFocus.showLock(this)
        }
    }

    override fun onInterrupt() {}

    override fun onDestroy() {
        // Receivers only exist once onServiceConnected ran.
        if (registered) {
            unregisterReceiver(filterChanged)
            unregisterReceiver(screenChanged)
            registered = false
        }
        (getSystemService(Context.SENSOR_SERVICE) as SensorManager).unregisterListener(shakes)
        if (current?.get() === this) current = null
        super.onDestroy()
    }
}

/**
 * Calls [onShakes] after [needed] hard shakes (over ~2.7 g, at least 250 ms
 * apart) inside 3 s. A walk or a bump never gets there; a deliberate shake does.
 */
class ShakeCounter(private val needed: Int, private val onShakes: () -> Unit) :
    SensorEventListener {
    private val times = ArrayDeque<Long>()

    fun reset() = times.clear()

    /** [gForce] in g (1.0 = still); [atMs] any monotonic clock. */
    fun sample(gForce: Float, atMs: Long) {
        if (gForce < 2.7f) return
        if (times.isNotEmpty() && atMs - times.last() < 250) return
        times.addLast(atMs)
        while (atMs - times.first() > 3000) times.removeFirst()
        if (times.size >= needed) {
            times.clear()
            onShakes()
        }
    }

    override fun onSensorChanged(event: SensorEvent) {
        val (x, y, z) = event.values
        sample(sqrt(x * x + y * y + z * z) / SensorManager.GRAVITY_EARTH, event.timestamp / 1_000_000)
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
}

/** Full-screen jamaat cover. "End" only outside strict mode; calls stay open. */
class JamaatFocusActivity : Activity() {
    companion object {
        var current: WeakReference<Activity>? = null
    }

    // API 33+: apps targeting 36 get no onBackPressed on Android 16, so the
    // gesture would dismiss the cover. Typed Any: the class is API 33+ only.
    private var swallowBack: Any? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        current = WeakReference(this)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val cb = OnBackInvokedCallback { }
            onBackInvokedDispatcher.registerOnBackInvokedCallback(
                OnBackInvokedDispatcher.PRIORITY_DEFAULT, cb
            )
            swallowBack = cb
        }
        val density = resources.displayMetrics.density
        val pad = (32 * density).toInt()
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(pad, pad, pad, pad)
            setBackgroundColor(Color.parseColor("#15564D"))
        }
        root.addView(TextView(this).apply {
            text = JamaatFocus.text(this@JamaatFocusActivity, "title")
            textSize = 28f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
        })
        root.addView(TextView(this).apply {
            tag = "body"
            textSize = 16f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setPadding(0, pad / 2, 0, pad)
        })
        root.addView(ImageButton(this).apply {
            setImageResource(android.R.drawable.sym_action_call)
            contentDescription = getString(R.string.jamaat_focus_phone)
            setOnClickListener {
                startActivity(Intent(Intent.ACTION_DIAL, Uri.parse("tel:")))
            }
        })
        root.addView(Button(this).apply {
            tag = "end"
            text = JamaatFocus.text(this@JamaatFocusActivity, "endAction")
            setOnClickListener {
                JamaatFocus.end(this@JamaatFocusActivity)
                finish()
            }
        })
        setContentView(root)
    }

    override fun onResume() {
        super.onResume()
        if (!JamaatFocus.isActive(this)) {
            finish()
            return
        }
        val root = window.decorView
        root.findViewWithTag<TextView>("body").text = JamaatFocus.body(this)
        root.findViewWithTag<Button>("end").visibility =
            if (JamaatFocus.status(this)["strict"] == true) Button.GONE else Button.VISIBLE
    }

    @Deprecated("Back would just reveal the covered app.")
    override fun onBackPressed() {
        // Swallowed (pre-33, or 33+ without the callback path): leaving is via
        // "End" (non-strict) or the session ending.
    }

    override fun onDestroy() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            (swallowBack as? OnBackInvokedCallback)?.let {
                onBackInvokedDispatcher.unregisterOnBackInvokedCallback(it)
            }
        }
        if (current?.get() === this) current = null
        super.onDestroy()
    }
}
