package com.sbugrayy.vakit.notification

data class CountdownDisplay(
    val hoursLeft: Int?,
    val minutesLeft: Int?,
    val nextTickAtMillis: Long?
)

object StatusCountdown {
    const val MAX_MINUTES = 60
    private const val MINUTE_MILLIS = 60_000L
    private const val HOUR_MILLIS = 3_600_000L
    private const val TICK_OFFSET_MILLIS = 1_000L

    // Kalan süreyi Chronometer'ın saat ve dakika hanesiyle tutarlı olacak
    // şekilde aşağı yuvarlar. Son 60 dakikada (kalan < 61 dk) dakika simgesi
    // gösterilir (60..0). 1 saatin üzerinde saat özetlenir (>= 1).
    fun displayAt(nextEpochMillis: Long, nowMillis: Long): CountdownDisplay {
        val remaining = nextEpochMillis - nowMillis
        if (remaining <= 0L) {
            return CountdownDisplay(
                hoursLeft = null,
                minutesLeft = null,
                nextTickAtMillis = null
            )
        }

        if (remaining / MINUTE_MILLIS <= MAX_MINUTES) {
            val minutesLeft = (remaining / MINUTE_MILLIS).toInt()
            val nextTickAtMillis = if (minutesLeft > 0) {
                nextEpochMillis -
                    minutesLeft * MINUTE_MILLIS +
                    TICK_OFFSET_MILLIS
            } else {
                null
            }
            return CountdownDisplay(
                hoursLeft = null,
                minutesLeft = minutesLeft,
                nextTickAtMillis = nextTickAtMillis
            )
        }

        val hoursLeft = (remaining / HOUR_MILLIS).toInt()
        val nextTickAtMillis = nextEpochMillis -
            maxOf(hoursLeft * HOUR_MILLIS, (MAX_MINUTES + 1) * MINUTE_MILLIS) +
            TICK_OFFSET_MILLIS
        return CountdownDisplay(
            hoursLeft = hoursLeft,
            minutesLeft = null,
            nextTickAtMillis = nextTickAtMillis
        )
    }
}
