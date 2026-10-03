package com.sbugrayy.vakit.notification

import java.time.LocalDateTime
import java.time.ZoneOffset
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class StatusCountdownTest {
    private val zoneOffset = ZoneOffset.ofHours(3)
    private val next = LocalDateTime.of(2026, 10, 4, 5, 37)
        .toInstant(zoneOffset)
        .toEpochMilli()

    @Test
    fun displayAtNineHoursAndSixSecondsRemaining() {
        val now = next - (9 * 3_600_000L + 6_000L)
        val display = StatusCountdown.displayAt(next, now)

        assertEquals(9, display.hoursLeft)
        assertNull(display.minutesLeft)
        assertEquals(next - 9 * 3_600_000L + 1_000L, display.nextTickAtMillis)
    }

    @Test
    fun displayAtEightHoursFiftyNineMinutesSixSecondsRemaining() {
        val now = next - (8 * 3_600_000L + 59 * 60_000L + 6_000L)
        val display = StatusCountdown.displayAt(next, now)

        assertEquals(8, display.hoursLeft)
        assertNull(display.minutesLeft)
        assertEquals(next - 8 * 3_600_000L + 1_000L, display.nextTickAtMillis)
    }

    @Test
    fun displayAtOneHourThirtyMinutesRemaining() {
        val now = next - (1 * 3_600_000L + 30 * 60_000L)
        val display = StatusCountdown.displayAt(next, now)

        assertEquals(1, display.hoursLeft)
        assertNull(display.minutesLeft)
        assertEquals(next - 60 * 60_000L + 1_000L, display.nextTickAtMillis)
    }

    @Test
    fun displayAtJustOverSixtyMinutesRemaining() {
        val now = next - (60 * 60_000L + 1L)
        val display = StatusCountdown.displayAt(next, now)

        assertEquals(1, display.hoursLeft)
        assertNull(display.minutesLeft)
        assertEquals(next - 60 * 60_000L + 1_000L, display.nextTickAtMillis)
    }

    @Test
    fun displayAtExactSixtyMinutesRemaining() {
        val now = next - 60 * 60_000L
        val display = StatusCountdown.displayAt(next, now)

        assertNull(display.hoursLeft)
        assertEquals(60, display.minutesLeft)
        assertEquals(next - 59 * 60_000L + 1_000L, display.nextTickAtMillis)
    }

    @Test
    fun displayAtTwelveMinutesThirtySecondsRemaining() {
        val now = next - (12 * 60_000L + 30_000L)
        val display = StatusCountdown.displayAt(next, now)

        assertNull(display.hoursLeft)
        assertEquals(13, display.minutesLeft)
        assertEquals(next - 12 * 60_000L + 1_000L, display.nextTickAtMillis)
    }

    @Test
    fun displayAtElevenMinutesFiftyNineSecondsRemaining() {
        val now = next - (11 * 60_000L + 59_000L)
        val display = StatusCountdown.displayAt(next, now)

        assertNull(display.hoursLeft)
        assertEquals(12, display.minutesLeft)
        assertEquals(next - 11 * 60_000L + 1_000L, display.nextTickAtMillis)
    }

    @Test
    fun displayAtSixtyOneSecondsRemaining() {
        val now = next - 61_000L
        val display = StatusCountdown.displayAt(next, now)

        assertNull(display.hoursLeft)
        assertEquals(2, display.minutesLeft)
        assertEquals(next - 60_000L + 1_000L, display.nextTickAtMillis)
    }

    @Test
    fun displayAtFiftyNineSecondsRemaining() {
        val now = next - 59_000L
        val display = StatusCountdown.displayAt(next, now)

        assertNull(display.hoursLeft)
        assertEquals(1, display.minutesLeft)
        assertNull(display.nextTickAtMillis)
    }

    @Test
    fun displayAtOneMillisecondRemaining() {
        val now = next - 1L
        val display = StatusCountdown.displayAt(next, now)

        assertNull(display.hoursLeft)
        assertEquals(1, display.minutesLeft)
        assertNull(display.nextTickAtMillis)
    }

    @Test
    fun displayAtExactNextMomentReturnsAllNull() {
        val now = next
        val display = StatusCountdown.displayAt(next, now)

        assertNull(display.hoursLeft)
        assertNull(display.minutesLeft)
        assertNull(display.nextTickAtMillis)
    }

    @Test
    fun displayAfterNextMomentPassedReturnsAllNull() {
        val now = next + 5_000L
        val display = StatusCountdown.displayAt(next, now)

        assertNull(display.hoursLeft)
        assertNull(display.minutesLeft)
        assertNull(display.nextTickAtMillis)
    }

    @Test
    fun walkTestFromThreeHoursRemaining() {
        var now = next - 3 * 3_600_000L
        val displays = mutableListOf<CountdownDisplay>()

        var steps = 0
        while (steps < 1000) {
            steps++
            val d = StatusCountdown.displayAt(next, now)
            displays.add(d)
            val tick = d.nextTickAtMillis ?: break
            assertTrue("Tik şimdiki andan büyük olmalı", tick > now)
            now = tick
        }

        assertEquals(63, displays.size)

        val expectedHours = listOf(3, 2, 1)
        val actualHours = displays.take(3).map { it.hoursLeft }
        assertEquals(expectedHours, actualHours)
        assertTrue(displays.take(3).all { it.minutesLeft == null })

        val expectedMinutes = (60 downTo 1).toList()
        val actualMinutes = displays.drop(3).map { it.minutesLeft }
        assertEquals(expectedMinutes, actualMinutes)
        assertTrue(displays.drop(3).all { it.hoursLeft == null })

        assertNull(displays.last().nextTickAtMillis)
    }
}
