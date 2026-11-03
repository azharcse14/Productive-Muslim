package com.productivemuslim.app

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Battery-optimization guidance (notification settings): whether the app is
 * exempt, and the system list where the user exempts it. Never the
 * REQUEST_IGNORE_BATTERY_OPTIMIZATIONS prompt (Play policy).
 */
object BatteryOptimization {
    fun register(activity: Activity, messenger: BinaryMessenger) {
        MethodChannel(messenger, "com.productivemuslim.app/battery")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isIgnoring" -> result.success(isIgnoring(activity))
                    "openSettings" -> {
                        openSettings(activity)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    fun isIgnoring(c: Context): Boolean =
        (c.getSystemService(Context.POWER_SERVICE) as PowerManager)
            .isIgnoringBatteryOptimizations(c.packageName)

    /** The optimization list; app info where a device has no such screen. */
    private fun openSettings(activity: Activity) {
        try {
            activity.startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
        } catch (e: ActivityNotFoundException) {
            activity.startActivity(
                Intent(
                    Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                    Uri.fromParts("package", activity.packageName, null)
                )
            )
        }
    }
}
