package com.sbugrayy.vakit.notification

import android.content.Context

object NotificationEngine {
    fun sync(context: Context, payloadJson: String, enabled: Boolean) {
        // Doğrulama: Geçersiz yükte IllegalArgumentException yukarı fırlar
        SchedulePayload.parse(payloadJson)
        val store = PrayerScheduleStore(context)
        store.savePayload(payloadJson)
        store.enabled = enabled
        refresh(context)
        // KEEP politikası mükerrer iş kurmayı engeller, her sync'te güvenle çağrılır.
        DailyRefreshWorker.schedule(context)
    }

    fun setEnabled(context: Context, enabled: Boolean) {
        val store = PrayerScheduleStore(context)
        store.enabled = enabled
        refresh(context)
    }

    fun refresh(context: Context) {
        val store = PrayerScheduleStore(context)
        val scheduler = PrayerAlarmScheduler(context)

        if (!store.enabled) {
            PersistentNotification.cancel(context)
            scheduler.cancel()
            return
        }

        val payload = store.loadPayload()
        if (payload == null) {
            PersistentNotification.cancel(context)
            scheduler.cancel()
            return
        }

        val now = System.currentTimeMillis()
        val state = NextPrayerCalculator.stateAt(payload, now)

        if (state == null) {
            PersistentNotification.showExpired(context, payload.locationLabel)
            scheduler.cancel()
        } else {
            val display = if (scheduler.canScheduleExact()) {
                StatusCountdown.displayAt(state.next.epochMillis, now)
            } else {
                // Kesin alarm izni yokken görünüm tiki kurulamayacağından
                // özet gösterilmez.
                null
            }
            PersistentNotification.show(context, state, display)
            scheduler.scheduleAt(state.next.epochMillis + 1_000L)
            val tickAt = display?.nextTickAtMillis
            if (tickAt != null) {
                scheduler.scheduleTickAt(tickAt)
            } else {
                scheduler.cancelTick()
            }
        }
    }
}
