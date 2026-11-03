package com.productivemuslim.app

import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.view.WindowManager
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

// FragmentActivity: local_auth's biometric prompt requires it.
class MainActivity : FlutterFragmentActivity() {

    private val channelName = "com.productivemuslim.app/widget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Jamaat focus: undo a session a force-stop left running (DND on).
        JamaatFocus.resume(this)
        BootClock.register(flutterEngine.dartExecutor.binaryMessenger)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateWidget" -> {
                    // Persist the Dart-formatted snapshot, then repaint.
                    val prefs = getSharedPreferences(
                        ProductiveMuslimWidgetProvider.PREFS,
                        Context.MODE_PRIVATE
                    )
                    prefs.edit().apply {
                        @Suppress("UNCHECKED_CAST")
                        val payload = call.arguments as? Map<String, Any?>
                        payload?.forEach { (key, value) -> putString(key, value?.toString() ?: "") }
                        apply()
                    }
                    ProductiveMuslimWidgetProvider.updateAll(this)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        // Jamaat focus: plan in, status/permissions out (JamaatFocus.kt).
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.productivemuslim.app/focus"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "schedule" -> {
                    JamaatFocus.schedule(this, call.arguments as? Map<*, *> ?: emptyMap<String, Any>())
                    result.success(null)
                }
                "status" -> result.success(JamaatFocus.status(this))
                "end" -> {
                    JamaatFocus.end(this)
                    result.success(null)
                }
                "hasDndAccess" -> result.success(JamaatFocus.hasDndAccess(this))
                "hasBlockAccess" -> result.success(JamaatFocus.hasBlockAccess(this))
                "isBlockingAvailable" -> result.success(JamaatFocus.blockingAvailable(this))
                "requestDndAccess" -> {
                    openSettings(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
                    result.success(null)
                }
                "requestBlockAccess" -> {
                    openSettings(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        // App lock on → blank recents thumbnail (and no screenshots).
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.productivemuslim.app/secure"
        ).setMethodCallHandler { call, result ->
            if (call.method == "setSecure") {
                if (call.arguments == true) {
                    window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                } else {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                }
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
        // Quran reader / tasbih open → the display stays on.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.productivemuslim.app/screen"
        ).setMethodCallHandler { call, result ->
            if (call.method == "keepOn") {
                if (call.arguments == true) {
                    window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                } else {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                }
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
        // Per-ayah share → the system share chooser, plain text.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.productivemuslim.app/share"
        ).setMethodCallHandler { call, result ->
            val text = call.arguments as? String
            if (call.method == "shareText" && text != null) {
                val send = Intent(Intent.ACTION_SEND)
                    .setType("text/plain")
                    .putExtra(Intent.EXTRA_TEXT, text)
                try {
                    startActivity(Intent.createChooser(send, null))
                    result.success(null)
                } catch (e: ActivityNotFoundException) {
                    result.error("NO_TARGET", e.message, null)
                }
            } else if (call.method == "shareImage") {
                shareImage(call.argument<String>("path"), call.argument<String>("text"), result)
            } else {
                result.notImplemented()
            }
        }
    }

    /**
     * Ramadan share card → the chooser with a PNG. The file must sit in
     * cache/share/ (res/xml/share_file_paths.xml); anything else is refused.
     */
    private fun shareImage(path: String?, text: String?, result: MethodChannel.Result) {
        val uri = try {
            FileProvider.getUriForFile(this, "$packageName.shareprovider", File(path ?: ""))
        } catch (e: IllegalArgumentException) {
            result.error("BAD_PATH", e.message, null)
            return
        }
        val send = Intent(Intent.ACTION_SEND)
            .setType("image/png")
            .putExtra(Intent.EXTRA_STREAM, uri)
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        if (text != null) send.putExtra(Intent.EXTRA_TEXT, text)
        // ClipData carries the read grant to the chooser's own preview too.
        send.clipData = ClipData.newRawUri(null, uri)
        try {
            startActivity(Intent.createChooser(send, null))
            result.success(null)
        } catch (e: ActivityNotFoundException) {
            result.error("NO_TARGET", e.message, null)
        }
    }

    /** Some settings pages are missing on low-RAM / Go devices: fall back to Settings. */
    private fun openSettings(action: String) {
        try {
            startActivity(Intent(action))
        } catch (e: ActivityNotFoundException) {
            startActivity(Intent(Settings.ACTION_SETTINGS))
        }
    }
}
