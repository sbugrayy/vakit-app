package com.sbugrayy.vakit.notification

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.fail
import org.junit.Test

class SchedulePayloadTest {
    private val validJson = """
        {
          "locationLabel": "İstanbul",
          "utcOffsetMinutes": 180,
          "days": [
            {
              "date": "2026-09-30",
              "times": [
                {"key": "imsak", "label": "İmsak", "epochMillis": 1790735280000},
                {"key": "gunes", "label": "Güneş", "epochMillis": 1790740320000},
                {"key": "ogle", "label": "Öğle", "epochMillis": 1790762340000},
                {"key": "ikindi", "label": "İkindi", "epochMillis": 1790774280000},
                {"key": "aksam", "label": "Akşam", "epochMillis": 1790783760000},
                {"key": "yatsi", "label": "Yatsı", "epochMillis": 1790788500000}
              ]
            }
          ]
        }
    """.trimIndent()

    @Test
    fun parseValidPayloadAndRoundTrip() {
        val payload = SchedulePayload.parse(validJson)
        assertEquals("İstanbul", payload.locationLabel)
        assertEquals(180, payload.utcOffsetMinutes)
        assertEquals(1, payload.days.size)
        assertEquals(6, payload.days[0].times.size)

        val json = payload.toJson()
        val parsedAgain = SchedulePayload.parse(json)
        assertEquals(payload, parsedAgain)
    }

    @Test
    fun preservesTurkishLabels() {
        val payload = SchedulePayload.parse(validJson)
        val labels = payload.days[0].times.map { it.label }
        val expected = listOf(
            "İmsak",
            "Güneş",
            "Öğle",
            "İkindi",
            "Akşam",
            "Yatsı"
        )
        assertEquals(expected, labels)
    }

    @Test(expected = IllegalArgumentException::class)
    fun throwsOnMissingDays() {
        val json = """{"locationLabel": "İstanbul", "utcOffsetMinutes": 180}"""
        SchedulePayload.parse(json)
    }

    @Test(expected = IllegalArgumentException::class)
    fun throwsOnMissingEpochMillis() {
        val json = """
            {
              "locationLabel": "İstanbul",
              "utcOffsetMinutes": 180,
              "days": [
                {
                  "date": "2026-09-30",
                  "times": [
                    {"key": "imsak", "label": "İmsak"},
                    {"key": "gunes", "label": "Güneş", "epochMillis": 1790740320000},
                    {"key": "ogle", "label": "Öğle", "epochMillis": 1790762340000},
                    {"key": "ikindi", "label": "İkindi", "epochMillis": 1790774280000},
                    {"key": "aksam", "label": "Akşam", "epochMillis": 1790783760000},
                    {"key": "yatsi", "label": "Yatsı", "epochMillis": 1790788500000}
                  ]
                }
              ]
            }
        """.trimIndent()
        SchedulePayload.parse(json)
    }

    @Test(expected = IllegalArgumentException::class)
    fun throwsOnFiveTimesInDay() {
        val json = """
            {
              "locationLabel": "İstanbul",
              "utcOffsetMinutes": 180,
              "days": [
                {
                  "date": "2026-09-30",
                  "times": [
                    {"key": "imsak", "label": "İmsak", "epochMillis": 1790735280000},
                    {"key": "gunes", "label": "Güneş", "epochMillis": 1790740320000},
                    {"key": "ogle", "label": "Öğle", "epochMillis": 1790762340000},
                    {"key": "ikindi", "label": "İkindi", "epochMillis": 1790774280000},
                    {"key": "aksam", "label": "Akşam", "epochMillis": 1790783760000}
                  ]
                }
              ]
            }
        """.trimIndent()
        SchedulePayload.parse(json)
    }

    @Test
    fun roundTripWithDistrictId() {
        val payload = SchedulePayload(
            locationLabel = "İstanbul",
            utcOffsetMinutes = 180,
            days = SchedulePayload.parse(validJson).days,
            districtId = "9541"
        )
        val json = payload.toJson()
        val parsedAgain = SchedulePayload.parse(json)
        assertEquals(payload, parsedAgain)
        assertEquals("9541", parsedAgain.districtId)
    }

    @Test
    fun legacyPayloadWithoutDistrictIdHasNull() {
        val payload = SchedulePayload.parse(validJson)
        assertNull(payload.districtId)
    }
}
