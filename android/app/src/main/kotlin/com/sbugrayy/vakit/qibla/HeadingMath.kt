package com.sbugrayy.vakit.qibla

import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.sin

/**
 * Açıyı [0, 360) aralığına normalize eder.
 */
fun normalize(degrees: Double): Double {
    if (degrees.isNaN()) return 0.0
    val mod = degrees % 360.0
    val positive = if (mod < 0.0) mod + 360.0 else mod
    return if (positive >= 360.0 || positive == 0.0) 0.0 else positive
}

/**
 * Manyetik azimuta manyetik sapma açısını (declination) ekleyerek
 * gerçek kuzeye göre açıyı hesaplar.
 */
fun applyDeclination(magneticAzimuth: Double, declination: Double): Double {
    return normalize(magneticAzimuth + declination)
}

/**
 * Açıları birim vektör (cos, sin) uzayında üstel yumuşatan filtre.
 * 359° ve 1° gibi sınır geçişlerinde sıçrama yapmaz.
 */
class HeadingSmoother(
    private val alpha: Double = 0.2
) {
    private var smoothedX: Double = 0.0
    private var smoothedY: Double = 0.0
    private var hasValue: Boolean = false

    fun update(degrees: Double): Double {
        if (degrees.isNaN()) return 0.0
        val rad = Math.toRadians(degrees)
        val x = cos(rad)
        val y = sin(rad)

        if (!hasValue) {
            smoothedX = x
            smoothedY = y
            hasValue = true
            return normalize(degrees)
        }

        smoothedX = alpha * x + (1.0 - alpha) * smoothedX
        smoothedY = alpha * y + (1.0 - alpha) * smoothedY

        val smoothedRad = atan2(smoothedY, smoothedX)
        return normalize(Math.toDegrees(smoothedRad))
    }

    fun reset() {
        smoothedX = 0.0
        smoothedY = 0.0
        hasValue = false
    }
}
