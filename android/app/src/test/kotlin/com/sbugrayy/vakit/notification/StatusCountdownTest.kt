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
        assertEquals(0, display.minutesPart)
        assertNull(display.minutesLeft)
        assertEquals(next - 540 * 60_000L + 1_000L, display.nextTickAtMillis)
    }

    @Test
    fun displayAtEightHoursFiftyNineMinutesSixSecondsRemaining() {
        val now = next - (8 * 3_600_000L + 59 * 60_000L + 6_000L)
        val display = StatusCountdown.displayAt(next, now)

        assertEquals(8, display.hoursLeft)
        assertEquals(59, display.minutesPart)
        assertNull(display.minutesLeft)
        assertEquals(next - 539 * 60_000L + 1_000L, display.nextTickAtMillis)
    }

    @Test
    fun displayAtOneHourFiftyTwoMinutesThirtySecondsRemaining() {
        val now = next - (1 * 3_600_000L + 52 * 60_000L + 30_000L)
        val display = StatusCountdown.displayAt(next, now)

        assertEquals(1, display.hoursLeft)
        assertEquals(52, display.minutesPart)
        assertNull(display.minutesLeft)
        assertEquals(next - 112 * 60_000L + 1_000L, display.nextTickAtMillis)
    }

    @Test
    fun displayAtOneHourThirtyMinutesRemaining() {
        val now = next - (1 * 3_600_000L + 30 * 60_000L)
        val display = StatusCountdown.displayAt(next, now)

        assertEquals(1, display.hoursLeft)
        assertEquals(30, display.minutesPart)
        assertNull(display.minutesLeft)
        assertEquals(next - 90 * 60_000L + 1_000L, display.nextTickAtMillis)
    }

    @Test
    fun displayAtExactSixtyOneMinutesRemaining() {
        val now = next - 61 * 60_000L
        val display = StatusCountdown.displayAt(next, now)

        assertEquals(1, display.hoursLeft)
        assertEquals(1, display.minutesPart)
        assertNull(display.minutesLeft)
        assertEquals(next - 61 * 60_000L + 1_000L, display.nextTickAtMillis)
    }

    @Test
    fun displayAtJustUnderSixtyOneMinutesRemaining() {
        val now = next - (61 * 60_000L - 1L)
        val display = StatusCountdown.displayAt(next, now)

        assertNull(display.hoursLeft)
        assertNull(display.minutesPart)
        assertEquals(60, display.minutesLeft)
        assertEquals(next - 60 * 60_000L + 1_000L, display.nextTickAtMillis)
    }

    @Test
    fun displayAtExactSixtyMinutesRemaining() {
        val now = next - 60 * 60_000L
        val display = StatusCountdown.displayAt(next, now)

        assertNull(display.hoursLeft)
        assertNull(display.minutesPart)
        assertEquals(60, display.minutesLeft)
        assertEquals(next - 60 * 60_000L + 1_000L, display.nextTickAtMillis)
    }

    @Test
    fun displayAtFiftyNineMinutesFiftyNineSecondsRemaining() {
        val now = next - (59 * 60_000L + 59_000L)
        val display = StatusCountdown.displayAt(next, now)

        assertNull(display.hoursLeft)
        assertNull(display.minutesPart)
        assertEquals(59, display.minutesLeft)
        assertEquals(next - 59 * 60_000L + 1_000L, display.nextTickAtMillis)
    }

    @Test
    fun displayAtFortyFourMinutesFiftyTwoSecondsRemaining() {
        val now = next - (44 * 60_000L + 52_000L)
        val display = StatusCountdown.displayAt(next, now)

        assertNull(display.hoursLeft)
        assertNull(display.minutesPart)
        assertEquals(44, display.minutesLeft)
        assertEquals(next - 44 * 60_000L + 1_000L, display.nextTickAtMillis)
    }

    @Test
    fun displayAtOneMinuteOneSecondRemaining() {
        val now = next - (60_000L + 1_000L)
        val display = StatusCountdown.displayAt(next, now)

        assertNull(display.hoursLeft)
        assertNull(display.minutesPart)
        assertEquals(1, display.minutesLeft)
        assertEquals(next - 60_000L + 1_000L, display.nextTickAtMillis)
    }

    @Test
    fun displayAtFiftyNineSecondsRemaining() {
        val now = next - 59_000L
        val display = StatusCountdown.displayAt(next, now)

        assertNull(display.hoursLeft)
        assertNull(display.minutesPart)
        assertEquals(0, display.minutesLeft)
        assertNull(display.nextTickAtMillis)
    }

    @Test
    fun displayAtOneMillisecondRemaining() {
        val now = next - 1L
        val display = StatusCountdown.displayAt(next, now)

        assertNull(display.hoursLeft)
        assertNull(display.minutesPart)
        assertEquals(0, display.minutesLeft)
        assertNull(display.nextTickAtMillis)
    }

    @Test
    fun displayAtExactNextMomentReturnsAllNull() {
        val now = next
        val display = StatusCountdown.displayAt(next, now)

        assertNull(display.hoursLeft)
        assertNull(display.minutesPart)
        assertNull(display.minutesLeft)
        assertNull(display.nextTickAtMillis)
    }

    @Test
    fun displayAfterNextMomentPassedReturnsAllNull() {
        val now = next + 5_000L
        val display = StatusCountdown.displayAt(next, now)

        assertNull(display.hoursLeft)
        assertNull(display.minutesPart)
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

        assertEquals(181, displays.size)

        val expectedHourPairs = (180 downTo 61).map { total ->
            Pair(total / 60, total % 60)
        }
        val actualHourPairs = displays.take(120).map {
            Pair(it.hoursLeft, it.minutesPart)
        }
        assertEquals(expectedHourPairs, actualHourPairs)
        assertTrue(displays.take(120).all { it.minutesLeft == null })

        val expectedMinutes = (60 downTo 0).toList()
        val actualMinutes = displays.drop(120).map { it.minutesLeft }
        assertEquals(expectedMinutes, actualMinutes)
        assertTrue(
            displays.drop(120).all {
                it.hoursLeft == null && it.minutesPart == null
            }
        )

        assertNull(displays.last().nextTickAtMillis)
    }
}
