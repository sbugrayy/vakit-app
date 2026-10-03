package com.sbugrayy.vakit.notification

import kotlin.math.roundToInt

object MosqueIconLayout {
    const val VIEWPORT = 24f
    const val ICON_DP = 24f

    // ic_stat_mosque.xml gövdesindeki rakam kutusu (viewport birimi)
    const val DIGIT_LEFT = 5f
    const val DIGIT_TOP = 9.5f
    const val DIGIT_RIGHT = 19f
    const val DIGIT_BOTTOM = 22f

    fun label(minutes: Int): String {
        return minutes.coerceIn(1, 60).toString()
    }

    fun sizePx(density: Float): Int {
        return (ICON_DP * density).roundToInt().coerceAtLeast(1)
    }

    fun digitBoxPx(sizePx: Int): FloatArray {
        val k = sizePx / VIEWPORT
        return floatArrayOf(
            DIGIT_LEFT * k,
            DIGIT_TOP * k,
            DIGIT_RIGHT * k,
            DIGIT_BOTTOM * k
        )
    }
}
