package com.productivemuslim.app

import android.content.Context
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
    }
}
