package com.productivemuslim.app

import android.os.SystemClock
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * App lock's PIN cooldown clock: time since boot, counting deep sleep and
 * immune to wall-clock changes (Dart `PlatformBootClock`).
 */
object BootClock {
    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, "com.productivemuslim.app/boot_clock")
            .setMethodCallHandler { call, result ->
                if (call.method == "sinceBootMs") {
                    result.success(SystemClock.elapsedRealtime())
                } else {
                    result.notImplemented()
                }
            }
    }
}
