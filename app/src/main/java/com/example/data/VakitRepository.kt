package com.example.data

import android.content.Context
import android.location.Geocoder
import android.util.Log
import com.example.api.AladhanService
import com.example.model.AladhanResponse
import com.example.model.AladhanTimings
import com.example.model.PrayerTimeItem
import com.example.model.PrayerType
import com.squareup.moshi.Moshi
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.moshi.MoshiConverterFactory
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

class VakitRepository(private val context: Context) {

    private val sharedPrefs = context.getSharedPreferences("vakit_prefs", Context.MODE_PRIVATE)

    private val moshi = Moshi.Builder()
        .add(KotlinJsonAdapterFactory())
        .build()

    private val okHttpClient = OkHttpClient.Builder()
        .addInterceptor(HttpLoggingInterceptor().apply {
            level = HttpLoggingInterceptor.Level.BODY
        })
        .build()

    private val retrofit = Retrofit.Builder()
        .baseUrl("https://api.aladhan.com/")
        .client(okHttpClient)
        .addConverterFactory(MoshiConverterFactory.create(moshi))
        .build()

    private val service = retrofit.create(AladhanService::class.java)

    // Exposed Flows for State
    private val _isOffline = MutableStateFlow(false)
    val isOffline: StateFlow<Boolean> = _isOffline

    fun setOfflineState(offline: Boolean) {
        _isOffline.value = offline
    }

    // Save Location coordinates
    fun saveLocation(lat: Double, lon: Double) {
        sharedPrefs.edit()
            .putFloat("lat", lat.toFloat())
            .putFloat("lon", lon.toFloat())
            .apply()
    }

    fun getSavedLatitude(): Double {
        return sharedPrefs.getFloat("lat", 39.92f).toDouble() // Ankara default
    }

    fun getSavedLongitude(): Double {
        return sharedPrefs.getFloat("lon", 32.85f).toDouble() // Ankara default
    }

    // Save and Get City Name
    fun saveCityName(cityName: String) {
        sharedPrefs.edit().putString("city_name", cityName).apply()
    }

    fun getSavedCityName(): String {
        return sharedPrefs.getString("city_name", "Ankara") ?: "Ankara"
    }

    // Save Timings as Json
    fun saveTimings(timings: AladhanTimings, dateStr: String) {
        try {
            val timingsAdapter = moshi.adapter(AladhanTimings::class.java)
            val json = timingsAdapter.toJson(timings)
            sharedPrefs.edit()
                .putString("timings_json", json)
                .putString("cached_date", dateStr)
                .apply()
        } catch (e: Exception) {
            Log.e("VakitRepository", "Error saving timings to local DB", e)
        }
    }

    fun getCachedTimings(): AladhanTimings? {
        val json = sharedPrefs.getString("timings_json", null) ?: return null
        return try {
            val timingsAdapter = moshi.adapter(AladhanTimings::class.java)
            timingsAdapter.fromJson(json)
        } catch (e: Exception) {
            Log.e("VakitRepository", "Error reading cached timings", e)
            null
        }
    }

    fun getCachedDate(): String {
        return sharedPrefs.getString("cached_date", "") ?: ""
    }

    fun getTodayString(): String {
        val sdf = SimpleDateFormat("dd-MM-yyyy", Locale.getDefault())
        return sdf.format(Date())
    }

    /**
     * Try to fetch timings from API utilizing latitude and longitude GPS coordinates.
     * Fallback to Cache if network fails.
     */
    suspend fun fetchTimingsFromGps(lat: Double, lon: Double): AladhanTimings? {
        try {
            val response = service.getTimings(lat, lon)
            if (response.code == 200) {
                val timings = response.data.timings
                val dateStr = getTodayString()
                saveLocation(lat, lon)
                saveTimings(timings, dateStr)
                _isOffline.value = false

                // Try to resolve city name using Geocoder
                resolveAndSaveCityName(lat, lon)
                return timings
            }
        } catch (e: Exception) {
            Log.e("VakitRepository", "Network fetch failed for GPS, reading fallback cache", e)
            _isOffline.value = true
        }

        return getCachedTimings()
    }

    /**
     * Try to fetch timings by exact city name (e.g. for fallback).
     */
    suspend fun fetchTimingsByCityName(cityName: String): AladhanTimings? {
        try {
            val response = service.getTimingsByCity(city = cityName)
            if (response.code == 200) {
                val timings = response.data.timings
                val dateStr = getTodayString()
                saveCityName(cityName)
                saveTimings(timings, dateStr)
                _isOffline.value = false

                return timings
            }
        } catch (e: Exception) {
            Log.e("VakitRepository", "Network fetch failed for city name, reading fallback cache", e)
            _isOffline.value = true
        }
        return getCachedTimings()
    }

    /**
     * Reverse Geocoding using Android Geocoder API to get Turkish city or district names.
     */
    private fun resolveAndSaveCityName(lat: Double, lon: Double) {
        try {
            if (Geocoder.isPresent()) {
                val geocoder = Geocoder(context, Locale("tr", "TR"))
                val addresses = geocoder.getFromLocation(lat, lon, 1)
                if (!addresses.isNullOrEmpty()) {
                    val address = addresses[0]
                    val city = address.adminArea ?: address.locality ?: address.subAdminArea ?: "Konumum"
                    saveCityName(city)
                }
            }
        } catch (e: Exception) {
            Log.e("VakitRepository", "Geocoder resolution failed", e)
        }
    }

    /**
     * Parse timings string (e.g. "12:56") into a Calendar instance for today.
     */
    fun getPrayerCalendar(timeStr: String, daysOffset: Int = 0): Calendar {
        val parts = timeStr.trim().split(":")
        val hour = parts[0].replace(Regex("[^0-9]"), "").toInt()
        val minute = parts[1].replace(Regex("[^0-9]"), "").toInt()

        return Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, daysOffset)
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
    }

    /**
     * Map AladhanTimings into a list of display items in Turkish.
     */
    fun mapToListOfItems(timings: AladhanTimings): List<PrayerTimeItem> {
        return listOf(
            createTimeItem(PrayerType.FAJR, timings.Imsak), // Turkey Diyanet: Fajr refers to İmsak
            createTimeItem(PrayerType.SUNRISE, timings.Sunrise),
            createTimeItem(PrayerType.DHUHR, timings.Dhuhr),
            createTimeItem(PrayerType.ASR, timings.Asr),
            createTimeItem(PrayerType.MAGHRIB, timings.Maghrib),
            createTimeItem(PrayerType.ISHA, timings.Isha)
        )
    }

    private fun createTimeItem(type: PrayerType, timeStr: String): PrayerTimeItem {
        val parts = timeStr.trim().split(":")
        val hour = parts[0].replace(Regex("[^0-9]"), "").toIntOrNull() ?: 12
        val minute = parts[1].replace(Regex("[^0-9]"), "").toIntOrNull() ?: 0
        return PrayerTimeItem(
            id = type.name,
            name = type.turkishName,
            time = timeStr,
            hour = hour,
            minute = minute
        )
    }

    /**
     * Calculate next prayer name, formatted calendar, and countdown string.
     */
    fun getNextPrayerInfo(timings: AladhanTimings): NextPrayerInfo {
        val items = mapToListOfItems(timings)
        val now = Calendar.getInstance()

        // 1. Check if any prayer today matches the remaining times
        for (item in items) {
            val prayerCal = getPrayerCalendar(item.time, daysOffset = 0)
            if (prayerCal.after(now)) {
                return NextPrayerInfo(
                    type = PrayerType.valueOf(item.id),
                    name = item.name,
                    time = item.time,
                    calendar = prayerCal,
                    isTomorrow = false
                )
            }
        }

        // 2. If all have passed today, the next one is the first prayer of TOMORROW (İmsak)
        val firstPrayer = items.first()
        val tomorrowCal = getPrayerCalendar(firstPrayer.time, daysOffset = 1)
        return NextPrayerInfo(
            type = PrayerType.valueOf(firstPrayer.id),
            name = firstPrayer.name,
            time = firstPrayer.time,
            calendar = tomorrowCal,
            isTomorrow = true
        )
    }
}

data class NextPrayerInfo(
    val type: PrayerType,
    val name: String,
    val time: String,
    val calendar: Calendar,
    val isTomorrow: Boolean
)
