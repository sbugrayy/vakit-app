package com.sbugrayy.vakit.qibla

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class HeadingMathTest {

    @Test
    fun normalizeNegativeTenReturnsThreeFifty() {
        assertEquals(350.0, normalize(-10.0), 1e-9)
    }

    @Test
    fun normalizeThreeSeventyReturnsTen() {
        assertEquals(10.0, normalize(370.0), 1e-9)
    }

    @Test
    fun normalizeThreeSixtyReturnsZero() {
        assertEquals(0.0, normalize(360.0), 1e-9)
    }

    @Test
    fun normalizeZeroReturnsZero() {
        assertEquals(0.0, normalize(0.0), 1e-9)
    }

    @Test
    fun normalizeNegativeThreeSixtyReturnsZero() {
        assertEquals(0.0, normalize(-360.0), 1e-9)
    }

    @Test
    fun normalizeMultiplesOfThreeSixtyReturnZero() {
        assertEquals(0.0, normalize(720.0), 1e-9)
        assertEquals(0.0, normalize(-720.0), 1e-9)
    }

    @Test
    fun normalizeLargeNegativeValue() {
        assertEquals(350.0, normalize(-370.0), 1e-9)
    }

    @Test
    fun normalizeNaNReturnsZero() {
        assertEquals(0.0, normalize(Double.NaN), 1e-9)
    }

    @Test
    fun applyDeclinationWrapAround() {
        assertEquals(1.0, applyDeclination(355.0, 6.0), 1e-9)
    }

    @Test
    fun applyDeclinationNegativeDeclination() {
        assertEquals(354.0, applyDeclination(0.0, -6.0), 1e-9)
    }

    @Test
    fun applyDeclinationZeroDeclination() {
        assertEquals(180.0, applyDeclination(180.0, 0.0), 1e-9)
    }

    @Test
    fun smootherInitialValueAcceptedDirectly() {
        val smoother = HeadingSmoother(alpha = 0.2)
        assertEquals(123.45, smoother.update(123.45), 1e-9)
    }

    @Test
    fun smootherWrapsAroundNorthWithoutCrossingSouth() {
        val smoother = HeadingSmoother(alpha = 0.2)
        val initial = smoother.update(359.0)
        assertEquals(359.0, initial, 1e-6)

        var current = initial
        for (i in 1..50) {
            current = smoother.update(1.0)
            val inRange =
                (current in 340.0..360.0) || (current in 0.0..20.0)
            assertTrue(
                "Heading $current step $i in [340,360] or [0,20]",
                inRange
            )
            val notInSouth = current < 90.0 || current > 270.0
            assertTrue(
                "Heading $current step $i must not drop to south (~180)",
                notInSouth
            )
        }

        // Sabit girdiye (1.0) yakınsamalı
        assertEquals(1.0, current, 1e-2)
    }

    @Test
    fun smootherReverseBoundaryCrossing() {
        val smoother = HeadingSmoother(alpha = 0.2)
        val initial = smoother.update(1.0)
        assertEquals(1.0, initial, 1e-6)

        var current = initial
        for (i in 1..50) {
            current = smoother.update(359.0)
            val inRange =
                (current in 340.0..360.0) || (current in 0.0..20.0)
            assertTrue(
                "Heading $current step $i in [340,360] or [0,20]",
                inRange
            )
        }

        assertEquals(359.0, current, 1e-2)
    }

    @Test
    fun smootherResetClearsState() {
        val smoother = HeadingSmoother(alpha = 0.2)
        smoother.update(100.0)
        smoother.update(120.0)

        smoother.reset()

        // Sıfırlandıktan sonraki ilk değer doğrudan kabul edilmeli
        val fresh = smoother.update(250.0)
        assertEquals(250.0, fresh, 1e-6)
    }

    @Test
    fun smootherConvergesToConstantHeading() {
        val smoother = HeadingSmoother(alpha = 0.2)
        smoother.update(0.0)
        var current = 0.0
        for (i in 1..50) {
            current = smoother.update(90.0)
        }
        assertEquals(90.0, current, 1e-2)
    }
}
