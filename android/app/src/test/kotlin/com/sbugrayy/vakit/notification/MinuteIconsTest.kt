package com.sbugrayy.vakit.notification

import com.sbugrayy.vakit.R
import org.junit.Assert.assertEquals
import org.junit.Test

class MinuteIconsTest {

    @Test
    fun resForReturnsExpectedResourceForSpecificMinutes() {
        assertEquals(R.drawable.ic_stat_minute_00, MinuteIcons.resFor(0))
        assertEquals(R.drawable.ic_stat_minute_07, MinuteIcons.resFor(7))
        assertEquals(R.drawable.ic_stat_minute_45, MinuteIcons.resFor(45))
        assertEquals(R.drawable.ic_stat_minute_60, MinuteIcons.resFor(60))
    }

    @Test
    fun resForClampsValuesOutsideZeroToSixtyRange() {
        assertEquals(R.drawable.ic_stat_minute_00, MinuteIcons.resFor(-5))
        assertEquals(R.drawable.ic_stat_minute_60, MinuteIcons.resFor(61))
    }

    @Test
    fun allMinutesProduceUniqueResourcesWithoutDuplicatesOrShifts() {
        val uniqueIcons = (0..60).map { MinuteIcons.resFor(it) }.toSet()
        assertEquals(61, uniqueIcons.size)
    }
}
