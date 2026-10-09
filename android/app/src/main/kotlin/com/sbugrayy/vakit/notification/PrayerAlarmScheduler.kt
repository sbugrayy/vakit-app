package com.sbugrayy.vakit.notification

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build

class PrayerAlarmScheduler(private val context: Context) {
    private val alarmManager: AlarmManager? =
        context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager

    fun canScheduleExact(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            alarmManager?.canScheduleExactAlarms() == true
        } else {
            true
        }
    }

    fun scheduleAt(triggerAtMillis: Long) {
        val am = alarmManager ?: return
        val pendingIntent = createPendingIntent()

        if (canScheduleExact()) {
            try {
                am.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    pendingIntent
                )
            } catch (e: SecurityException) {
                am.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    pendingIntent
                )
            }
        } else {
            am.setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                triggerAtMillis,
                pendingIntent
            )
        }
    }

    fun scheduleTickAt(triggerAtMillis: Long) {
        val am = alarmManager ?: return
        if (!canScheduleExact()) {
            // Inexact alarm en az 10 dk gecikebileceğinden yedek yok;
            // yanlış dakika göstermektense hiç göstermemek seçildi.
            cancelTick()
            return
        }

        val pendingIntent = createTickPendingIntent()
        try {
            // RTC: Ekran kapalıyken uyandırmaz, pil tüketimini engeller.
            // AllowWhileIdle: Standby kovası kotasından muaf tutarak dakikalık
            // tiklerin gecikmesini önler.
            am.setExactAndAllowWhileIdle(
                AlarmManager.RTC,
                triggerAtMillis,
                pendingIntent
            )
        } catch (e: SecurityException) {
            cancelTick()
        }
    }

    fun cancelTick() {
        val am = alarmManager ?: return
        val pendingIntent = createTickPendingIntent()
        am.cancel(pendingIntent)
        pendingIntent.cancel()
    }

    fun cancel() {
        val am = alarmManager ?: return
        val pendingIntent = createPendingIntent()
        am.cancel(pendingIntent)
        pendingIntent.cancel()
        cancelTick()
    }

    private fun createPendingIntent(): PendingIntent {
        val intent = Intent(context, PrayerAlarmReceiver::class.java)
        return PendingIntent.getBroadcast(
            context,
            ALARM_REQUEST_CODE,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
    }

    private fun createTickPendingIntent(): PendingIntent {
        val intent = Intent(context, PrayerAlarmReceiver::class.java)
        return PendingIntent.getBroadcast(
            context,
            TICK_REQUEST_CODE,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
    }

    companion object {
        const val ALARM_REQUEST_CODE = 1002
        const val TICK_REQUEST_CODE = 1006
    }
}
