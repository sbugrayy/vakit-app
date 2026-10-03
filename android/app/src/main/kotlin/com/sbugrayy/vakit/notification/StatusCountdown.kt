package com.sbugrayy.vakit.notification

data class CountdownDisplay(
    val hoursLeft: Int?,
    val minutesLeft: Int?,
    val nextTickAtMillis: Long?
)

object StatusCountdown {
    const val MINUTE_WINDOW_MILLIS = 60L * 60_000L
    private const val HOUR_MILLIS = 3_600_000L
    private const val MINUTE_MILLIS = 60_000L
    private const val TICK_OFFSET_MILLIS = 1_000L

    fun displayAt(nextEpochMillis: Long, nowMillis: Long): CountdownDisplay {
        val remaining = nextEpochMillis - nowMillis
        if (remaining <= 0L) {
            return CountdownDisplay(
                hoursLeft = null,
                minutesLeft = null,
                nextTickAtMillis = null
            )
        }

        if (remaining <= MINUTE_WINDOW_MILLIS) {
            val minutesLeft = ((remaining + 59_999L) / MINUTE_MILLIS).toInt()
            val nextTickAtMillis = if (minutesLeft > 1) {
                nextEpochMillis -
                    (minutesLeft - 1) * MINUTE_MILLIS +
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
            hoursLeft * HOUR_MILLIS +
            TICK_OFFSET_MILLIS
        return CountdownDisplay(
            hoursLeft = hoursLeft,
            minutesLeft = null,
            nextTickAtMillis = nextTickAtMillis
        )
    }
}
