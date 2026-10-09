package com.sbugrayy.vakit.notification

import java.time.Instant
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter

data class NotificationState(
    val locationLabel: String,
    val next: ScheduleMoment,
    val day: ScheduleDay,
    val nextIndex: Int,
    val utcOffsetMinutes: Int
)

object NextPrayerCalculator {
    private val TIME_FORMATTER = DateTimeFormatter.ofPattern("HH:mm")

    fun stateAt(
        payload: SchedulePayload,
        nowMillis: Long
    ): NotificationState? {
        for (day in payload.days) {
            for (index in day.times.indices) {
                val moment = day.times[index]
                if (moment.epochMillis > nowMillis) {
                    return NotificationState(
                        locationLabel = payload.locationLabel,
                        next = moment,
                        day = day,
                        nextIndex = index,
                        utcOffsetMinutes = payload.utcOffsetMinutes
                    )
                }
            }
        }
        return null
    }

    fun formatTime(epochMillis: Long, utcOffsetMinutes: Int): String {
        val offset = ZoneOffset.ofTotalSeconds(utcOffsetMinutes * 60)
        val offsetDateTime = Instant.ofEpochMilli(epochMillis).atOffset(offset)
        return offsetDateTime.format(TIME_FORMATTER)
    }
}
