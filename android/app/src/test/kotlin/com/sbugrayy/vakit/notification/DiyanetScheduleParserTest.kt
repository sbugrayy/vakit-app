package com.sbugrayy.vakit.notification

import java.time.LocalDateTime
import java.time.ZoneOffset
import org.junit.Assert.assertEquals
import org.junit.Test

class DiyanetScheduleParserTest {

    private val sampleItemJson = """
        [
          {
            "MiladiTarihKisa": "30.09.2026",
            "GreenwichOrtalamaZamani": 3.0,
            "Imsak": "05:28",
            "Gunes": "06:52",
            "Ogle": "12:59",
            "Ikindi": "16:18",
            "Aksam": "18:56",
            "Yatsi": "20:15",
            "KibleSaati": "11:32",
            "HicriTarihUzun": "19 Rebiulahir 1448"
          }
        ]
    """.trimIndent()

    @Test
    fun parseSampleItemMatchesExpectedValues() {
        val parsed = DiyanetScheduleParser.parse(sampleItemJson)

        assertEquals(180, parsed.utcOffsetMinutes)
        assertEquals(1, parsed.days.size)

        val day = parsed.days[0]
        assertEquals("2026-09-30", day.date)
        assertEquals(6, day.times.size)

        val expectedLabels = listOf(
            "İmsak",
            "Güneş",
            "Öğle",
            "İkindi",
            "Akşam",
            "Yatsı"
        )
        val actualLabels = day.times.map { it.label }
        assertEquals(expectedLabels, actualLabels)

        val aksamMoment = day.times.first { it.key == "aksam" }
        val expectedAksamEpoch = LocalDateTime.of(2026, 9, 30, 18, 56)
            .toInstant(ZoneOffset.ofHours(3))
            .toEpochMilli()
        assertEquals(expectedAksamEpoch, aksamMoment.epochMillis)
    }

    @Test
    fun sortsMultipleDaysChronologically() {
        val mixedOrderJson = """
            [
              {
                "MiladiTarihKisa": "02.10.2026",
                "GreenwichOrtalamaZamani": 3.0,
                "Imsak": "05:30",
                "Gunes": "06:54",
                "Ogle": "12:58",
                "Ikindi": "16:15",
                "Aksam": "18:52",
                "Yatsi": "20:11"
              },
              {
                "MiladiTarihKisa": "01.10.2026",
                "GreenwichOrtalamaZamani": 3.0,
                "Imsak": "05:29",
                "Gunes": "06:53",
                "Ogle": "12:58",
                "Ikindi": "16:16",
                "Aksam": "18:54",
                "Yatsi": "20:13"
              }
            ]
        """.trimIndent()

        val parsed = DiyanetScheduleParser.parse(mixedOrderJson)
        assertEquals(2, parsed.days.size)
        assertEquals("2026-10-01", parsed.days[0].date)
        assertEquals("2026-10-02", parsed.days[1].date)
    }

    @Test(expected = IllegalArgumentException::class)
    fun throwsOnEmptyArray() {
        DiyanetScheduleParser.parse("[]")
    }

    @Test(expected = IllegalArgumentException::class)
    fun throwsOnMissingAksamField() {
        val missingAksamJson = """
            [
              {
                "MiladiTarihKisa": "30.09.2026",
                "GreenwichOrtalamaZamani": 3.0,
                "Imsak": "05:28",
                "Gunes": "06:52",
                "Ogle": "12:59",
                "Ikindi": "16:18",
                "Yatsi": "20:15"
              }
            ]
        """.trimIndent()
        DiyanetScheduleParser.parse(missingAksamJson)
    }

    @Test(expected = IllegalArgumentException::class)
    fun throwsOnInvalidDate31Feb() {
        val invalidDateJson = """
            [
              {
                "MiladiTarihKisa": "31.02.2026",
                "GreenwichOrtalamaZamani": 3.0,
                "Imsak": "05:28",
                "Gunes": "06:52",
                "Ogle": "12:59",
                "Ikindi": "16:18",
                "Aksam": "18:56",
                "Yatsi": "20:15"
              }
            ]
        """.trimIndent()
        DiyanetScheduleParser.parse(invalidDateJson)
    }
}
