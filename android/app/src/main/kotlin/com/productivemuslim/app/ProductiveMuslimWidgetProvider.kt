package com.productivemuslim.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/**
 * Home-screen widget showing the next prayer. Plugin-free: all display
 * strings are pre-formatted in Dart ([PrayerWidgetService]) and handed over
 * a MethodChannel ([MainActivity]) which stores them in [PREFS]; this
 * provider only renders. Tapping the widget opens the app.
 *
 * The next prayer is picked here from `widget_schedule` on every update,
 * and an alarm re-renders at the next prayer start, so the widget stays
 * correct while the app isn't running.
 */
class ProductiveMuslimWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        appWidgetIds.forEach { renderWidget(context, appWidgetManager, it) }
        scheduleNext(context)
    }

    companion object {
        const val PREFS = "productive_muslim_widget"

        /** Repaints every placed instance of the widget. */
        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, ProductiveMuslimWidgetProvider::class.java)
            )
            ids.forEach { renderWidget(context, manager, it) }
            scheduleNext(context)
        }

        /** `widget_schedule` lines as (epochMillis, prayer, time). */
        private fun schedule(context: Context): List<Triple<Long, String, String>> {
            val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getString("widget_schedule", "") ?: ""
            return raw.lines().mapNotNull { line ->
                val parts = line.split('\t')
                val millis = parts.getOrNull(0)?.toLongOrNull()
                if (millis == null || parts.size < 3) null
                else Triple(millis, parts[1], parts[2])
            }
        }

        /** First scheduled prayer still ahead, or null past the schedule. */
        private fun upcoming(context: Context) =
            schedule(context).firstOrNull { it.first > System.currentTimeMillis() }

        /**
         * Re-renders at the next prayer start. Inexact and non-waking (no
         * exact-alarm permission): it may land late or on the next screen-on;
         * updatePeriodMillis (30 min) is the backstop.
         */
        private fun scheduleNext(context: Context) {
            val next = upcoming(context) ?: return
            val ids = AppWidgetManager.getInstance(context).getAppWidgetIds(
                ComponentName(context, ProductiveMuslimWidgetProvider::class.java)
            )
            val intent = Intent(context, ProductiveMuslimWidgetProvider::class.java)
                .setAction(AppWidgetManager.ACTION_APPWIDGET_UPDATE)
                .putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            val pending = PendingIntent.getBroadcast(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            alarms.set(AlarmManager.RTC, next.first + 1000, pending)
        }

        private fun renderWidget(
            context: Context,
            manager: AppWidgetManager,
            widgetId: Int
        ) {
            val data = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val configured = data.getString("widget_configured", "0") == "1"

            val views = RemoteViews(context.packageName, R.layout.productive_muslim_widget).apply {
                if (configured) {
                    // Past the schedule: fall back to the last pushed snapshot.
                    val next = upcoming(context)
                    setTextViewText(R.id.widget_label, data.getString("widget_label", "") ?: "")
                    setTextViewText(R.id.widget_prayer, next?.second ?: data.getString("widget_prayer", "—") ?: "—")
                    setTextViewText(R.id.widget_time, next?.third ?: data.getString("widget_time", "") ?: "")
                    setTextViewText(R.id.widget_location, data.getString("widget_location", "") ?: "")
                    setTextViewText(R.id.widget_times, data.getString("widget_times", "") ?: "")
                } else {
                    setTextViewText(R.id.widget_label, "Productive Muslim")
                    setTextViewText(R.id.widget_prayer, "Set up")
                    setTextViewText(R.id.widget_time, "")
                    setTextViewText(R.id.widget_location, "")
                    setTextViewText(R.id.widget_times, "Open the app to set your location")
                }

                val launch = context.packageManager
                    .getLaunchIntentForPackage(context.packageName)
                    ?.apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP }
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    launch,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }
            manager.updateAppWidget(widgetId, views)
        }
    }
}
