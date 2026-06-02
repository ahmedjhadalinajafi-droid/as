package com.example.masjid_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import java.text.SimpleDateFormat
import java.util.*

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
        private const val TAG = "MasjidWidget"

        private fun safeGetPrefs(context: Context): SharedPreferences {
            return try {
                HomeWidgetPlugin.getData(context)
            } catch (e: Throwable) {
                Log.w(TAG, "HomeWidgetPlugin.getData failed, using fallback prefs", e)
                context.getSharedPreferences("HomeWidgetPlugin", Context.MODE_PRIVATE)
            }
        }

        private fun toDisplay(time24: String?): String {
            if (time24.isNullOrEmpty() || time24 == "--:--") return "--:--"
            return try {
                val sdf24 = SimpleDateFormat("HH:mm", Locale.getDefault())
                val sdf12 = SimpleDateFormat("h:mm a", Locale.ENGLISH)
                val date = sdf24.parse(time24) ?: return time24
                sdf12.format(date)
            } catch (e: Exception) {
                time24
            }
        }

        private fun todayDateStr(): String {
            return try {
                val sdf = SimpleDateFormat("d MMM yyyy", Locale.ENGLISH)
                sdf.format(Date())
            } catch (e: Exception) {
                ""
            }
        }

        private fun findNextPrayer(
            fajr: String, dhuhr: String, maghrib: String
        ): Pair<String, String> {
            return try {
                val now = Calendar.getInstance()
                val nowMinutes = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)

                val prayers = listOf(
                    Pair("الفجر", fajr),
                    Pair("الظهر", dhuhr),
                    Pair("المغرب", maghrib)
                )

                for ((name, time) in prayers) {
                    if (time == "--:--" || time.isEmpty()) continue
                    val parts = time.split(":")
                    if (parts.size < 2) continue
                    val h = parts[0].trim().toIntOrNull() ?: continue
                    val m = parts[1].trim().toIntOrNull() ?: continue
                    if ((h * 60 + m) > nowMinutes) return Pair(name, time)
                }
                Pair("الفجر", fajr)
            } catch (e: Exception) {
                Pair("الفجر", "--:--")
            }
        }

        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            widgetId: Int
        ) {
            try {
                val prefs = safeGetPrefs(context)

                val fajr     = prefs.getString("fajr",     "--:--") ?: "--:--"
                val sunrise  = prefs.getString("sunrise",  "--:--") ?: "--:--"
                val dhuhr    = prefs.getString("dhuhr",    "--:--") ?: "--:--"
                val sunset   = prefs.getString("sunset",   "--:--") ?: "--:--"
                val maghrib  = prefs.getString("maghrib",  "--:--") ?: "--:--"
                val midnight = prefs.getString("midnight", "--:--") ?: "--:--"

                val storedNext     = prefs.getString("next_prayer",      "") ?: ""
                val storedNextTime = prefs.getString("next_prayer_time", "") ?: ""

                // Check if app has ever been opened (no data written yet)
                val hasData = fajr != "--:--" || dhuhr != "--:--" || maghrib != "--:--"

                val (nextName, nextTime) = when {
                    storedNext.isNotEmpty() && storedNextTime.isNotEmpty() ->
                        Pair(storedNext, storedNextTime)
                    hasData ->
                        findNextPrayer(fajr, dhuhr, maghrib)
                    else ->
                        Pair("افتح التطبيق أولاً", "--:--")
                }

                val views = RemoteViews(context.packageName, R.layout.masjid_widget)

                views.setTextViewText(R.id.tv_date,      todayDateStr())
                views.setTextViewText(R.id.tv_next_name, nextName)
                views.setTextViewText(R.id.tv_next_time, toDisplay(nextTime))
                views.setTextViewText(R.id.tv_fajr,     toDisplay(fajr))
                views.setTextViewText(R.id.tv_sunrise,  toDisplay(sunrise))
                views.setTextViewText(R.id.tv_dhuhr,    toDisplay(dhuhr))
                views.setTextViewText(R.id.tv_sunset,   toDisplay(sunset))
                views.setTextViewText(R.id.tv_maghrib,  toDisplay(maghrib))
                views.setTextViewText(R.id.tv_midnight, toDisplay(midnight))

                val intent = Intent(context, MainActivity::class.java)
                val pendingIntent = PendingIntent.getActivity(
                    context, 0, intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

                appWidgetManager.updateAppWidget(widgetId, views)
            } catch (e: Throwable) {
                Log.e(TAG, "Widget update failed for widgetId=$widgetId", e)
                // Last-resort fallback: render widget with safe empty state
                try {
                    val views = RemoteViews(context.packageName, R.layout.masjid_widget)
                    views.setTextViewText(R.id.tv_date,      todayDateStr())
                    views.setTextViewText(R.id.tv_next_name, "افتح التطبيق أولاً")
                    views.setTextViewText(R.id.tv_next_time, "--:--")
                    views.setTextViewText(R.id.tv_fajr,     "--:--")
                    views.setTextViewText(R.id.tv_sunrise,  "--:--")
                    views.setTextViewText(R.id.tv_dhuhr,    "--:--")
                    views.setTextViewText(R.id.tv_sunset,   "--:--")
                    views.setTextViewText(R.id.tv_maghrib,  "--:--")
                    views.setTextViewText(R.id.tv_midnight, "--:--")
                    val intent = Intent(context, MainActivity::class.java)
                    val pendingIntent = PendingIntent.getActivity(
                        context, 0, intent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
                    appWidgetManager.updateAppWidget(widgetId, views)
                } catch (fallbackEx: Throwable) {
                    Log.e(TAG, "Fallback widget render also failed", fallbackEx)
                }
            }
        }
    }
}
