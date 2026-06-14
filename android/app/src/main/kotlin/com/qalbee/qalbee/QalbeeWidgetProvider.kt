package com.qalbee.qalbee

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
 */
class QalbeeWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        appWidgetIds.forEach { renderWidget(context, appWidgetManager, it) }
    }

    companion object {
        const val PREFS = "qalbee_widget"

        /** Repaints every placed instance of the widget. */
        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, QalbeeWidgetProvider::class.java)
            )
            ids.forEach { renderWidget(context, manager, it) }
        }

        private fun renderWidget(
            context: Context,
            manager: AppWidgetManager,
            widgetId: Int
        ) {
            val data = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val configured = data.getString("widget_configured", "0") == "1"

            val views = RemoteViews(context.packageName, R.layout.qalbee_widget).apply {
                if (configured) {
                    setTextViewText(R.id.widget_label, data.getString("widget_label", "") ?: "")
                    setTextViewText(R.id.widget_prayer, data.getString("widget_prayer", "—") ?: "—")
                    setTextViewText(R.id.widget_time, data.getString("widget_time", "") ?: "")
                    setTextViewText(R.id.widget_location, data.getString("widget_location", "") ?: "")
                    setTextViewText(R.id.widget_times, data.getString("widget_times", "") ?: "")
                } else {
                    setTextViewText(R.id.widget_label, "Qalbee")
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
