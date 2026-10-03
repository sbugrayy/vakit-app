package com.sbugrayy.vakit.notification

import java.time.LocalDateTime
import java.time.ZoneOffset
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test

class NextPrayerCalculatorTest {
    private val zoneOffset = ZoneOffset.ofHours(3)

    private fun toEpoch(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int
    ): Long {
        return LocalDateTime.of(year, month, day, hour, minute)
            .toInstant(zoneOffset)
            .toEpochMilli()
    }

    private fun createSamplePayload(): SchedulePayload {
        val day1Times = listOf(
            ScheduleMoment("imsak", "İmsak", toEpoch(2026, 9, 30, 5, 28)),
            ScheduleMoment("gunes", "Güneş", toEpoch(2026, 9, 30, 6, 52)),
            ScheduleMoment("ogle", "Öğle", toEpoch(2026, 9, 30, 12, 59)),
            ScheduleMoment("ikindi", "İkindi", toEpoch(2026, 9, 30, 16, 18)),
            ScheduleMoment("aksam", "Akşam", toEpoch(2026, 9, 30, 18, 56)),
            ScheduleMoment("yatsi", "Yatsı", toEpoch(2026, 9, 30, 20, 15))
        )

        val day2Times = listOf(
            ScheduleMoment("imsak", "İmsak", toEpoch(2026, 10, 1, 5, 29)),
            ScheduleMoment("gunes", "Güneş", toEpoch(2026, 10, 1, 6, 53)),
            ScheduleMoment("ogle", "Öğle", toEpoch(2026, 10, 1, 12, 59)),
            ScheduleMoment("ikindi", "İkindi", toEpoch(2026, 10, 1, 16, 16)),
            ScheduleMoment("aksam", "Akşam", toEpoch(2026, 10, 1, 18, 55)),
            ScheduleMoment("yatsi", "Yatsı", toEpoch(2026, 10, 1, 20, 14))
        )

        return SchedulePayload(
            locationLabel = "İstanbul",
            utcOffsetMinutes = 180,
            days = listOf(
                ScheduleDay("2026-09-30", day1Times),
                ScheduleDay("2026-10-01", day2Times)
            )
        )
    }

    @Test
    fun nextPrayerAt10AmIsOgle() {
        val payload = createSamplePayload()
        val now = toEpoch(2026, 9, 30, 10, 0)
        val state = NextPrayerCalculator.stateAt(payload, now)

        assertNotNull(state)
        assertEquals("ogle", state!!.next.key)
        assertEquals("Öğle", state.next.label)
        assertEquals("2026-09-30", state.day.date)
        assertEquals(2, state.nextIndex)
    }

    @Test
    fun nextPrayerAtExactOgleIsIkindi() {
        val payload = createSamplePayload()
        val now = toEpoch(2026, 9, 30, 12, 59)
        val state = NextPrayerCalculator.stateAt(payload, now)

        assertNotNull(state)
        assertEquals("ikindi", state!!.next.key)
        assertEquals("İkindi", state.next.label)
        assertEquals("2026-09-30", state.day.date)
        assertEquals(3, state.nextIndex)
    }

    @Test
    fun nextPrayerAtNightTransitionsToNextDayImsak() {
        val payload = createSamplePayload()
        val now = toEpoch(2026, 9, 30, 23, 0)
        val state = NextPrayerCalculator.stateAt(payload, now)

        assertNotNull(state)
        assertEquals("imsak", state!!.next.key)
        assertEquals("İmsak", state.next.label)
        assertEquals("2026-10-01", state.day.date)
        assertEquals(0, state.nextIndex)
    }

    @Test
    fun returnsNullWhenAllTimesPassed() {
        val payload = createSamplePayload()
        val now = toEpoch(2026, 10, 1, 20, 15)
        val state = NextPrayerCalculator.stateAt(payload, now)

        assertNull(state)
    }

    @Test
    fun formatsTimeUsingPayloadOffsetNotSystemDefault() {
        val aksamEpoch = toEpoch(2026, 9, 30, 18, 56)

        val formattedWith180 = NextPrayerCalculator.formatTime(aksamEpoch, 180)
        assertEquals("18:56", formattedWith180)

        val formattedWithZero = NextPrayerCalculator.formatTime(aksamEpoch, 0)
        assertEquals("15:56", formattedWithZero)
    }
}
