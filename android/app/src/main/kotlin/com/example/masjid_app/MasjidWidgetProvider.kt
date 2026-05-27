package com.example.masjid_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class MasjidWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, widgetId)
        }
    }

    companion object {
        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            widgetId: Int
        ) {
            val prefs = context.getSharedPreferences(
                "${context.packageName}.home_widget",
                Context.MODE_PRIVATE
            )

            val fajr    = prefs.getString("fajr", "--:--") ?: "--:--"
            val dhuhr   = prefs.getString("dhuhr", "--:--") ?: "--:--"
            val asr     = prefs.getString("asr", "--:--") ?: "--:--"
            val maghrib = prefs.getString("maghrib", "--:--") ?: "--:--"
            val isha    = prefs.getString("isha", "--:--") ?: "--:--"
            val next    = prefs.getString("next_prayer", "") ?: ""
            val nextTime = prefs.getString("next_prayer_time", "") ?: ""

            val views = RemoteViews(context.packageName, R.layout.masjid_widget)

            views.setTextViewText(R.id.tv_fajr, fajr)
            views.setTextViewText(R.id.tv_dhuhr, dhuhr)
            views.setTextViewText(R.id.tv_asr, asr)
            views.setTextViewText(R.id.tv_maghrib, maghrib)
            views.setTextViewText(R.id.tv_isha, isha)

            if (next.isNotEmpty()) {
                views.setTextViewText(R.id.tv_next_prayer, "➤ $next $nextTime")
            }

            // Tap opens the app
            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
