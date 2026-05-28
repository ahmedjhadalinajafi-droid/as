package com.example.masjid_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
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

        private fun toDisplay(time24: String): String {
            if (time24 == "--:--" || time24.isEmpty()) return "--:--"
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
            val sdf = SimpleDateFormat("d MMM yyyy", Locale.ENGLISH)
            return sdf.format(Date())
        }

        private fun findNextPrayer(
            fajr: String, dhuhr: String, asr: String, maghrib: String, isha: String
        ): Pair<String, String> {
            val now = Calendar.getInstance()
            val nowMinutes = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)

            val prayers = listOf(
                Pair("الفجر", fajr),
                Pair("الظهر", dhuhr),
                Pair("العصر", asr),
                Pair("المغرب", maghrib),
                Pair("العشاء", isha)
            )

            for ((name, time) in prayers) {
                if (time == "--:--" || time.isEmpty()) continue
                val parts = time.split(":")
                if (parts.size < 2) continue
                val h = parts[0].trim().toIntOrNull() ?: continue
                val m = parts[1].trim().toIntOrNull() ?: continue
                if ((h * 60 + m) > nowMinutes) return Pair(name, time)
            }
            return Pair("الفجر", fajr)
        }

        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            widgetId: Int
        ) {
            val prefs = context.getSharedPreferences(
                "${context.packageName}.home_widget",
                Context.MODE_PRIVATE
            )

            val fajr    = prefs.getString("fajr",    "--:--") ?: "--:--"
            val dhuhr   = prefs.getString("dhuhr",   "--:--") ?: "--:--"
            val asr     = prefs.getString("asr",     "--:--") ?: "--:--"
            val maghrib = prefs.getString("maghrib", "--:--") ?: "--:--"
            val isha    = prefs.getString("isha",    "--:--") ?: "--:--"

            val storedNext     = prefs.getString("next_prayer",      "") ?: ""
            val storedNextTime = prefs.getString("next_prayer_time", "") ?: ""

            val (nextName, nextTime) = if (storedNext.isNotEmpty() && storedNextTime.isNotEmpty()) {
                Pair(storedNext, storedNextTime)
            } else {
                findNextPrayer(fajr, dhuhr, asr, maghrib, isha)
            }

            val views = RemoteViews(context.packageName, R.layout.masjid_widget)

            views.setTextViewText(R.id.tv_date,      todayDateStr())
            views.setTextViewText(R.id.tv_next_name, nextName)
            views.setTextViewText(R.id.tv_next_time, toDisplay(nextTime))
            views.setTextViewText(R.id.tv_fajr,    toDisplay(fajr))
            views.setTextViewText(R.id.tv_dhuhr,   toDisplay(dhuhr))
            views.setTextViewText(R.id.tv_asr,     toDisplay(asr))
            views.setTextViewText(R.id.tv_maghrib, toDisplay(maghrib))
            views.setTextViewText(R.id.tv_isha,    toDisplay(isha))

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
