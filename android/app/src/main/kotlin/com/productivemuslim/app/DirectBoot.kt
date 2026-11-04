package com.productivemuslim.app

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.UserManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Notifications between a reboot and the first unlock. The plugin's cache
 * (and so [NotificationBootReceiver]) lives in credential-encrypted storage,
 * readable only after unlock: a night reboot (OS update, Samsung auto
 * restart) lost Fajr azan / sahri until then. Dart mirrors every scheduled
 * notification (final localized strings) into device-protected storage;
 * LOCKED_BOOT_COMPLETED arms them here and [post] shows them itself. At
 * BOOT_COMPLETED [handOver] cancels these alarms and tells the boot
 * receiver which ids were already shown, so the plugin doesn't repeat them.
 * Jamaat focus is not covered: its session starts after unlock.
 */
object DirectBoot {
    const val ACTION_FIRE = "com.productivemuslim.app.DIRECT_BOOT_FIRE"
    const val EXTRA_ID = "id"
    private const val PREFS = "direct_boot_plan"
    private const val ENTRIES = "entries"
    private const val POSTED = "posted"

    // flutter_local_notifications' tap contract, so a tap after unlock
    // routes like a plugin notification (getNotificationAppLaunchDetails).
    private const val SELECT_NOTIFICATION = "SELECT_NOTIFICATION"

    fun register(c: Context, messenger: BinaryMessenger) {
        MethodChannel(messenger, "com.productivemuslim.app/direct_boot")
            .setMethodCallHandler { call, result ->
                if (call.method == "save") {
                    val entries = (call.arguments as? List<*>).orEmpty().mapNotNull {
                        val m = it as? Map<*, *> ?: return@mapNotNull null
                        DirectBootPlan.Entry(
                            id = (m["id"] as? Number)?.toInt() ?: return@mapNotNull null,
                            at = (m["at"] as? Number)?.toLong() ?: return@mapNotNull null,
                            channel = m["channel"] as? String ?: return@mapNotNull null,
                            title = m["title"] as? String ?: "",
                            body = m["body"] as? String ?: "",
                            payload = m["payload"] as? String ?: "",
                        )
                    }
                    prefs(c).edit()
                        .putStringSet(ENTRIES, entries.map(DirectBootPlan::encode).toSet())
                        .apply()
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }

    // minSdk 24: device-protected storage always exists.
    private fun prefs(c: Context): SharedPreferences =
        c.createDeviceProtectedStorageContext()
            .getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun entries(p: SharedPreferences) =
        p.getStringSet(ENTRIES, null).orEmpty().mapNotNull(DirectBootPlan::decode)

    private fun alarm(c: Context, id: Int, flags: Int): PendingIntent? =
        PendingIntent.getBroadcast(
            c, id,
            Intent(c, DirectBootReceiver::class.java)
                .setAction(ACTION_FIRE)
                .putExtra(EXTRA_ID, id),
            flags or PendingIntent.FLAG_IMMUTABLE
        )

    /** LOCKED_BOOT_COMPLETED: arm the stored plan until unlock. */
    fun arm(c: Context) {
        val p = prefs(c)
        // Not locked (no FBE, or already unlocked): the normal path runs.
        if (c.getSystemService(UserManager::class.java).isUserUnlocked) return
        val am = c.getSystemService(AlarmManager::class.java)
        val exact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S || am.canScheduleExactAlarms()
        for (e in DirectBootPlan.toArm(entries(p), System.currentTimeMillis())) {
            val pi = alarm(c, e.id, PendingIntent.FLAG_UPDATE_CURRENT) ?: continue
            try {
                if (exact) {
                    am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, e.at, pi)
                } else {
                    am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, e.at, pi)
                }
            } catch (ex: SecurityException) {
                am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, e.at, pi)
            }
        }
    }

    /** An armed entry came due: show it on its channel, as the plugin would. */
    fun post(c: Context, id: Int) {
        val p = prefs(c)
        val e = entries(p).firstOrNull { it.id == id } ?: return
        val launch = c.packageManager.getLaunchIntentForPackage(c.packageName)
            ?.setAction(SELECT_NOTIFICATION)
            ?.putExtra("notificationId", e.id)
            ?.putExtra("payload", e.payload)
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(c, e.channel)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(c)
        }
        builder
            .setSmallIcon(R.drawable.ic_stat_notify)
            .setContentTitle(e.title)
            .setContentText(e.body)
            .setAutoCancel(true)
            .setCategory(Notification.CATEGORY_REMINDER)
        if (launch != null) {
            builder.setContentIntent(
                PendingIntent.getActivity(
                    c, e.id, launch,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            )
        }
        try {
            c.getSystemService(NotificationManager::class.java).notify(e.id, builder.build())
        } catch (ex: SecurityException) {
            return // Notifications denied.
        }
        // commit: the unlock hand-over may run right after this receiver.
        p.edit().putStringSet(POSTED, p.getStringSet(POSTED, null).orEmpty() + e.id.toString())
            .commit()
    }

    /** BOOT_COMPLETED: stop the locked-boot alarms; returns the ids shown. */
    fun handOver(c: Context): Set<Int> {
        val p = prefs(c)
        val am = c.getSystemService(AlarmManager::class.java)
        for (e in entries(p)) {
            alarm(c, e.id, PendingIntent.FLAG_NO_CREATE)?.let(am::cancel)
        }
        val posted = p.getStringSet(POSTED, null).orEmpty().mapNotNull(String::toIntOrNull).toSet()
        p.edit().remove(POSTED).commit()
        return posted
    }
}

/** The pure plan logic behind [DirectBoot] (DirectBootPlanTest). */
object DirectBootPlan {
    data class Entry(
        val id: Int,
        val at: Long,
        val channel: String,
        val title: String,
        val body: String,
        val payload: String,
    )

    // NUL never occurs in a notification text; org.json isn't available
    // in JVM unit tests.
    private const val SEP = "\u0000"

    fun encode(e: Entry): String =
        listOf(e.id, e.at, e.channel, e.title, e.body, e.payload).joinToString(SEP)

    fun decode(s: String): Entry? {
        val f = s.split(SEP)
        if (f.size != 6) return null
        return Entry(
            id = f[0].toIntOrNull() ?: return null,
            at = f[1].toLongOrNull() ?: return null,
            channel = f[2],
            title = f[3],
            body = f[4],
            payload = f[5],
        )
    }

    /**
     * What a locked boot arms: everything not yet missed by more than
     * [BootPrune.GRACE_MS] (the same rule the unlock path prunes by; a
     * just-missed one fires at once), earliest first.
     */
    fun toArm(entries: List<Entry>, now: Long): List<Entry> =
        entries.filter { it.at >= now - BootPrune.GRACE_MS }.sortedBy { it.at }
}

/** LOCKED_BOOT_COMPLETED and the alarms [DirectBoot.arm] sets. */
class DirectBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_LOCKED_BOOT_COMPLETED -> DirectBoot.arm(context)
            DirectBoot.ACTION_FIRE -> DirectBoot.post(context, intent.getIntExtra(DirectBoot.EXTRA_ID, 0))
        }
    }
}
