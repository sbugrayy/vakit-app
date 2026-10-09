package com.sbugrayy.vakit.notification

data class CountdownDisplay(
    val hoursLeft: Int?,
    val minutesLeft: Int?,
    val nextTickAtMillis: Long?,
    // Saat kipinde saatten artan dakika (0..59); dakika kipinde null.
    val minutesPart: Int? = null
)

object StatusCountdown {
    const val MAX_MINUTES = 60
    private const val MINUTE_MILLIS = 60_000L
    private const val TICK_OFFSET_MILLIS = 1_000L

    // Kalan süreyi Chronometer'ın saat ve dakika hanesiyle tutarlı olacak
    // şekilde aşağı yuvarlar. Son 60 dakikada (kalan < 61 dk) dakika simgesi
    // gösterilir (60..0). 1 saatin üzerinde saat ve artan dakika özetlenir
    // (saat >= 1, dakika 0..59). Görünüm tiki saat kipinde de her dakika
    // (bir sonraki dakika sınırının 1 sn sonrasına) kurulur.
    fun displayAt(nextEpochMillis: Long, nowMillis: Long): CountdownDisplay {
        val remaining = nextEpochMillis - nowMillis
        if (remaining <= 0L) {
            return CountdownDisplay(
                hoursLeft = null,
                minutesLeft = null,
                nextTickAtMillis = null
            )
        }

        val total = (remaining / MINUTE_MILLIS).toInt()
        if (total <= MAX_MINUTES) {
            val nextTickAtMillis = if (total > 0) {
                nextEpochMillis -
                    total * MINUTE_MILLIS +
                    TICK_OFFSET_MILLIS
            } else {
                null
            }
            return CountdownDisplay(
                hoursLeft = null,
                minutesLeft = total,
                nextTickAtMillis = nextTickAtMillis,
                minutesPart = null
            )
        }

        val hoursLeft = total / 60
        val minutesPart = total % 60
        val nextTickAtMillis = nextEpochMillis -
            total * MINUTE_MILLIS +
            TICK_OFFSET_MILLIS
        return CountdownDisplay(
            hoursLeft = hoursLeft,
            minutesLeft = null,
            nextTickAtMillis = nextTickAtMillis,
            minutesPart = minutesPart
        )
    }
}
