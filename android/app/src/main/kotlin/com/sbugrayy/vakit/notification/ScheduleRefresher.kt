package com.sbugrayy.vakit.notification

import android.content.Context
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL

object ScheduleRefresher {
    enum class Outcome { UPDATED, SKIPPED, RETRY }

    internal fun fetch(url: String): String {
        val connection = URL(url).openConnection() as HttpURLConnection
        try {
            connection.connectTimeout = 15_000
            connection.readTimeout = 15_000
            connection.requestMethod = "GET"
            connection.doInput = true

            val responseCode = connection.responseCode
            if (responseCode != HttpURLConnection.HTTP_OK) {
                throw IOException("HTTP response code: $responseCode")
            }

            return connection.inputStream.bufferedReader(Charsets.UTF_8)
                .use { reader -> reader.readText() }
        } finally {
            connection.disconnect()
        }
    }

    fun refresh(context: Context): Outcome {
        return try {
            val store = PrayerScheduleStore(context)
            if (!store.enabled) {
                return Outcome.SKIPPED
            }

            val payload = store.loadPayload() ?: return Outcome.SKIPPED
            val districtId = payload.districtId ?: return Outcome.SKIPPED

            val url = "https://ezanvakti.emushaf.net/vakitler/$districtId"
            val json = try {
                fetch(url)
            } catch (e: IOException) {
                return Outcome.RETRY
            }

            val parsed = try {
                DiyanetScheduleParser.parse(json)
            } catch (e: IllegalArgumentException) {
                return Outcome.RETRY
            }

            val updatedPayload = SchedulePayload(
                locationLabel = payload.locationLabel,
                utcOffsetMinutes = parsed.utcOffsetMinutes,
                days = parsed.days,
                districtId = districtId
            )

            store.savePayload(updatedPayload.toJson())
            NotificationEngine.refresh(context)
            Outcome.UPDATED
        } catch (e: Exception) {
            Outcome.RETRY
        }
    }
}
