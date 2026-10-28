package com.productivemuslim.app

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FragmentActivity: local_auth's biometric prompt requires it.
class MainActivity : FlutterFragmentActivity() {

    private val channelName = "com.productivemuslim.app/widget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
