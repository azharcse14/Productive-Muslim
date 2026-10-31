package com.productivemuslim.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver
import java.time.LocalDateTime
import java.time.ZoneId
import org.json.JSONArray

/**
 * Stands in for flutter_local_notifications' boot receiver. The plugin
 * re-arms every cached notification after a reboot or app update, including
 * those whose time passed while the phone was off, and AlarmManager fires
 * all of those at once (Fajr azan, sahri warning, ... in one burst). Drop
 * the stale ones from its cache first, then let the plugin re-arm the rest.
 * The app refills the schedule on its next open anyway.
 */
class NotificationBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        try {
            pruneStale(context)
        } catch (e: Exception) {
            // Unreadable cache: re-arming everything beats re-arming nothing.
            Log.e("NotificationBoot", "prune failed", e)
        }
        ScheduledNotificationBootReceiver().onReceive(context, intent)
    }

    private fun pruneStale(context: Context) {
        // The plugin's cache: SharedPreferences "scheduled_notifications",
        // key "scheduled_notifications", a JSON array of NotificationDetails.
        val prefs = context.getSharedPreferences(CACHE, Context.MODE_PRIVATE)
        val json = prefs.getString(CACHE, null) ?: return
        val all = JSONArray(json)
        val keep = JSONArray()
        val now = System.currentTimeMillis()
        for (i in 0 until all.length()) {
            val n = all.getJSONObject(i)
            val stale = BootPrune.isStale(
                n.optString("scheduledDateTime").ifEmpty { null },
                n.optString("timeZoneName").ifEmpty { null },
                now,
            )
            if (!stale) keep.put(n)
        }
        if (keep.length() != all.length()) {
            prefs.edit().putString(CACHE, keep.toString()).commit()
        }
    }

    private companion object {
        const val CACHE = "scheduled_notifications"
    }
}

/** The pure decision behind [NotificationBootReceiver] (BootPruneTest). */
object BootPrune {
    /** A notification this late still fires after boot; older ones are dropped. */
    const val GRACE_MS = 5 * 60 * 1000L

    /**
     * True when a one-off zoned notification ([dateTime] local to [zone])
     * was due more than [GRACE_MS] before [now]. Anything unparseable or
     * not zoned (repeating) is kept: the plugin knows best.
     */
    fun isStale(dateTime: String?, zone: String?, now: Long): Boolean {
        if (dateTime == null || zone == null) return false
        val at = try {
            LocalDateTime.parse(dateTime).atZone(ZoneId.of(zone)).toInstant().toEpochMilli()
        } catch (e: Exception) {
            return false
        }
        return at < now - GRACE_MS
    }
}
