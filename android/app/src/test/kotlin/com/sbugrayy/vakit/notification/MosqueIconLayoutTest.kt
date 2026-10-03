package com.sbugrayy.vakit.notification

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class MosqueIconLayoutTest {

    @Test
    fun labelFormatsMinutesWithinAndClampedOutsideRange() {
        assertEquals("12", MosqueIconLayout.label(12))
        assertEquals("60", MosqueIconLayout.label(60))
        assertEquals("1", MosqueIconLayout.label(1))
        assertEquals("1", MosqueIconLayout.label(0))
        assertEquals("60", MosqueIconLayout.label(61))
    }

    @Test
    fun sizePxScalesWithDensityAndEnforcesMinimum() {
        assertEquals(72, MosqueIconLayout.sizePx(3.0f))
        assertEquals(63, MosqueIconLayout.sizePx(2.625f))
        assertEquals(24, MosqueIconLayout.sizePx(1.0f))
        assertEquals(1, MosqueIconLayout.sizePx(0.0f))
    }

    @Test
    fun digitBoxPxScalesCorrectlyForSize72() {
        val box = MosqueIconLayout.digitBoxPx(72)
        assertEquals(4, box.size)
        assertEquals(15.0f, box[0], 0.001f)
        assertEquals(28.5f, box[1], 0.001f)
        assertEquals(57.0f, box[2], 0.001f)
        assertEquals(66.0f, box[3], 0.001f)
    }

    @Test
    fun digitBoxIsContainedWithinMosqueBody() {
        assertTrue(
            "DIGIT_LEFT gövde sol sınırından büyük veya eşit olmalı",
            MosqueIconLayout.DIGIT_LEFT >= 4f
        )
        assertTrue(
            "DIGIT_RIGHT gövde sağ sınırından küçük veya eşit olmalı",
            MosqueIconLayout.DIGIT_RIGHT <= 20f
        )
        assertTrue(
            "DIGIT_TOP gövde üst sınırından büyük veya eşit olmalı",
            MosqueIconLayout.DIGIT_TOP >= 8.5f
        )
        assertTrue(
            "DIGIT_BOTTOM gövde alt sınırından küçük veya eşit olmalı",
            MosqueIconLayout.DIGIT_BOTTOM <= 23f
        )
    }
}
