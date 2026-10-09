package com.sbugrayy.vakit.notification

import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter
import java.time.format.ResolverStyle
import kotlin.math.roundToInt
import org.json.JSONArray
import org.json.JSONObject

data class ParsedSchedule(
    val utcOffsetMinutes: Int,
    val days: List<ScheduleDay>
)

object DiyanetScheduleParser {
    private val DATE_FORMATTER = DateTimeFormatter.ofPattern("dd.MM.uuuu")
        .withResolverStyle(ResolverStyle.STRICT)

    private val PRAYER_MAPPINGS = listOf(
        Triple("imsak", "İmsak", "Imsak"),
        Triple("gunes", "Güneş", "Gunes"),
        Triple("ogle", "Öğle", "Ogle"),
        Triple("ikindi", "İkindi", "Ikindi"),
        Triple("aksam", "Akşam", "Aksam"),
        Triple("yatsi", "Yatsı", "Yatsi")
    )

    // Diyanet /vakitler yanıtını ScheduleDay listesine çevirir.
    fun parse(json: String): ParsedSchedule {
        try {
            val array = JSONArray(json)
            if (array.length() == 0) {
                throw IllegalArgumentException("Schedule array is empty")
            }

            data class DayEntry(
                val localDate: LocalDate,
                val offsetMinutes: Int,
                val scheduleDay: ScheduleDay
            )

            val parsedDays = ArrayList<DayEntry>(array.length())

            for (i in 0 until array.length()) {
                val dayObj = array.getJSONObject(i)

                if (!dayObj.has("MiladiTarihKisa") ||
                    dayObj.isNull("MiladiTarihKisa")
                ) {
                    throw IllegalArgumentException(
                        "Missing MiladiTarihKisa at index $i"
                    )
                }
                val dateStr = dayObj.getString("MiladiTarihKisa")
                val localDate = LocalDate.parse(dateStr, DATE_FORMATTER)

                if (!dayObj.has("GreenwichOrtalamaZamani") ||
                    dayObj.isNull("GreenwichOrtalamaZamani")
                ) {
                    throw IllegalArgumentException(
                        "Missing GreenwichOrtalamaZamani at index $i"
                    )
                }
                val offsetHours = dayObj.getDouble("GreenwichOrtalamaZamani")
                val offsetMinutes = (offsetHours * 60).roundToInt()
                val zoneOffset = ZoneOffset.ofTotalSeconds(offsetMinutes * 60)

                val times = ArrayList<ScheduleMoment>(6)
                for ((key, label, jsonKey) in PRAYER_MAPPINGS) {
                    if (!dayObj.has(jsonKey) || dayObj.isNull(jsonKey)) {
                        throw IllegalArgumentException(
                            "Missing prayer time $jsonKey at index $i"
                        )
                    }
                    val timeStr = dayObj.getString(jsonKey)
                    val localTime = parseTime(timeStr)
                    val epochMillis = LocalDateTime.of(localDate, localTime)
                        .toInstant(zoneOffset)
                        .toEpochMilli()

                    times.add(ScheduleMoment(key, label, epochMillis))
                }

                val isoDate = localDate.toString()
                parsedDays.add(
                    DayEntry(
                        localDate,
                        offsetMinutes,
                        ScheduleDay(isoDate, times)
                    )
                )
            }

            parsedDays.sortBy { it.localDate }

            val sortedScheduleDays = parsedDays.map { it.scheduleDay }
            val firstDayOffset = parsedDays.first().offsetMinutes

            return ParsedSchedule(firstDayOffset, sortedScheduleDays)
        } catch (e: IllegalArgumentException) {
            throw e
        } catch (e: Exception) {
            throw IllegalArgumentException(
                "Failed to parse Diyanet schedule: ${e.message}",
                e
            )
        }
    }

    private fun parseTime(timeStr: String): LocalTime {
        val parts = timeStr.split(":")
        if (parts.size != 2) {
            throw IllegalArgumentException("Invalid time format: $timeStr")
        }
        val hour = parts[0].toInt()
        val minute = parts[1].toInt()
        return LocalTime.of(hour, minute)
    }
}
