package com.productivemuslim.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews

/**
 * Home-screen widget showing the next prayer. Plugin-free: all display
 * strings are pre-formatted in Dart ([PrayerWidgetService]) and handed over
 * a MethodChannel ([MainActivity]) which stores them in [PREFS]; this
 * provider only renders. Tapping the widget opens the app.
 *
 * The next prayer and the day's strip are picked by [WidgetSchedule] on
 * every update, and an alarm re-renders at the next prayer start or day
 * boundary, so the widget stays correct for the pushed 7 days while the app
 * isn't running; after that it asks the user to open the app.
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

    /** The last widget was removed: stop the re-render alarm chain. */
    override fun onDisabled(context: Context) {
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarms.cancel(updateIntent(context, IntArray(0)))
    }

    companion object {
        const val PREFS = "productive_muslim_widget"

        /** Repaints every placed instance of the widget. */
        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, ProductiveMuslimWidgetProvider::class.java)
            )
            if (ids.isEmpty()) return // no widget placed: no alarm chain
            ids.forEach { renderWidget(context, manager, it) }
            scheduleNext(context)
        }

        /** The re-render broadcast; extras don't affect PendingIntent identity. */
        private fun updateIntent(context: Context, ids: IntArray): PendingIntent =
            PendingIntent.getBroadcast(
                context,
                0,
                Intent(context, ProductiveMuslimWidgetProvider::class.java)
                    .setAction(AppWidgetManager.ACTION_APPWIDGET_UPDATE)
                    .putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

        /** Every pushed `widget_*` string (for [WidgetSchedule]). */
        private fun data(context: Context): Map<String, String> =
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).all
                .mapNotNull { (key, value) -> (value as? String)?.let { key to it } }
                .toMap()

        /**
         * Re-renders at the next change (see [WidgetSchedule.nextChange]). Non-waking; exact when the
         * app holds exact-alarm access, else inexact, which Android may defer by up to an hour —
         * updatePeriodMillis (30 min) is the backstop.
         */
        private fun scheduleNext(context: Context) {
            // Next prayer start or day boundary; nothing once stale (only the
            // app can push new times).
            val at = WidgetSchedule.nextChange(data(context), System.currentTimeMillis())
                ?: return
            val ids = AppWidgetManager.getInstance(context).getAppWidgetIds(
                ComponentName(context, ProductiveMuslimWidgetProvider::class.java)
            )
            val pending = updateIntent(context, ids)
            val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val exact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarms.canScheduleExactAlarms()
            try {
                if (exact) {
                    alarms.setExact(AlarmManager.RTC, at + 1000, pending)
                } else {
                    alarms.set(AlarmManager.RTC, at + 1000, pending)
                }
            } catch (e: SecurityException) {
                alarms.set(AlarmManager.RTC, at + 1000, pending)
            }
        }

        private fun renderWidget(
            context: Context,
            manager: AppWidgetManager,
            widgetId: Int
        ) {
            val data = data(context)
            // Pushed (in-app language) texts win; resources cover the time
            // before the app has ever pushed them.
            fun text(key: String, fallback: Int) =
                data[key]?.takeIf { it.isNotEmpty() } ?: context.getString(fallback)
            val configured = data["widget_configured"] == "1"
            val view = if (configured) {
                WidgetSchedule.view(data, System.currentTimeMillis())
            } else null

            val views = RemoteViews(context.packageName, R.layout.productive_muslim_widget).apply {
                when (view) {
                    is WidgetSchedule.View.Next -> {
                        setTextViewText(R.id.widget_label, text("widget_label", R.string.widget_next_prayer))
                        setTextViewText(R.id.widget_prayer, view.prayer)
                        setTextViewText(R.id.widget_time, view.time)
                        setTextViewText(R.id.widget_location, data["widget_location"].orEmpty())
                        setTextViewText(R.id.widget_times, view.strip)
                    }
                    // Past the pushed schedule: never show times that have passed.
                    WidgetSchedule.View.Stale -> {
                        setTextViewText(R.id.widget_label, context.getString(R.string.widget_setup_title))
                        setTextViewText(R.id.widget_prayer, text("widget_stale_title", R.string.widget_stale_title))
                        setTextViewText(R.id.widget_time, "")
                        setTextViewText(R.id.widget_location, data["widget_location"].orEmpty())
                        setTextViewText(R.id.widget_times, text("widget_stale_hint", R.string.widget_stale_hint))
                    }
                    null -> {
                        setTextViewText(R.id.widget_label, context.getString(R.string.widget_setup_title))
                        setTextViewText(R.id.widget_prayer, text("widget_setup_action", R.string.widget_setup_action))
                        setTextViewText(R.id.widget_time, "")
                        setTextViewText(R.id.widget_location, "")
                        setTextViewText(R.id.widget_times, text("widget_setup_hint", R.string.widget_setup_hint))
                    }
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
