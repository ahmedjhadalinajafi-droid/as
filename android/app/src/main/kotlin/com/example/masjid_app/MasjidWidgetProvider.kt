package com.example.masjid_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home-screen prayer times widget.
 *
 * Reads values written by the Flutter app (PrayerWidgetService) and renders
 * them. Every read uses a safe default and the whole update is wrapped in a
 * try/catch so a missing value can never crash the launcher (this was the
 * cause of the earlier crash on fresh install).
 */
class MasjidWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            try {
                val views = RemoteViews(context.packageName, R.layout.masjid_widget)

                val nextPrayer = widgetData.getString("next_prayer", "الفجر") ?: "الفجر"
                val nextTime = widgetData.getString("next_prayer_time", "--:--") ?: "--:--"
                val fajr = widgetData.getString("fajr", "--:--") ?: "--:--"
                val dhuhr = widgetData.getString("dhuhr", "--:--") ?: "--:--"
                val maghrib = widgetData.getString("maghrib", "--:--") ?: "--:--"
                val dayName = widgetData.getString("day_name", "") ?: ""
                val date = widgetData.getString("date", "") ?: ""

                views.setTextViewText(R.id.w_next_prayer, nextPrayer)
                views.setTextViewText(R.id.w_next_time, nextTime)
                views.setTextViewText(R.id.w_fajr, fajr)
                views.setTextViewText(R.id.w_dhuhr, dhuhr)
                views.setTextViewText(R.id.w_maghrib, maghrib)
                views.setTextViewText(R.id.w_day_name, dayName)
                views.setTextViewText(R.id.w_date, date)

                appWidgetManager.updateAppWidget(widgetId, views)
            } catch (e: Exception) {
                // Never crash the home screen — leave the widget as-is.
            }
        }
    }
}
