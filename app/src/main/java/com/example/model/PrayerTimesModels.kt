package com.example.model

import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class AladhanResponse(
    val code: Int,
    val status: String,
    val data: AladhanData
)

@JsonClass(generateAdapter = true)
data class AladhanData(
    val timings: AladhanTimings,
    val date: AladhanDate
)

@JsonClass(generateAdapter = true)
data class AladhanTimings(
    val Fajr: String,
    val Sunrise: String,
    val Dhuhr: String,
    val Asr: String,
    val Sunset: String,
    val Maghrib: String,
    val Isha: String,
    val Imsak: String
)

@JsonClass(generateAdapter = true)
data class AladhanDate(
    val readable: String,
    val timestamp: String,
    val gregorian: GregorianDate
)

@JsonClass(generateAdapter = true)
data class GregorianDate(
    val date: String,
    val format: String,
    val day: String,
    val weekday: Weekday,
    val month: Month,
    val year: String
)

@JsonClass(generateAdapter = true)
data class Weekday(
    val en: String
)

@JsonClass(generateAdapter = true)
data class Month(
    val number: Int,
    val en: String
)

// Internal domain model representing a single pray time slot
data class PrayerTimeItem(
    val id: String, // e.g. "Fajr"
    val name: String, // e.g. "İmsak"
    val time: String, // e.g. "03:31"
    val hour: Int,
    val minute: Int
)

enum class PrayerType(val key: String, val turkishName: String) {
    FAJR("Fajr", "İmsak"),
    SUNRISE("Sunrise", "Güneş"),
    DHUHR("Dhuhr", "Öğle"),
    ASR("Asr", "İkindi"),
    MAGHRIB("Maghrib", "Akşam"),
    ISHA("Isha", "Yatsı")
}
