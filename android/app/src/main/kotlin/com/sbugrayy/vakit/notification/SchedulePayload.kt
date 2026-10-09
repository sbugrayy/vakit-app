package com.sbugrayy.vakit.notification

import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject

data class ScheduleMoment(
    val key: String,
    val label: String,
    val epochMillis: Long
)

data class ScheduleDay(
    val date: String,
    val times: List<ScheduleMoment>
)

data class SchedulePayload(
    val locationLabel: String,
    val utcOffsetMinutes: Int,
    val days: List<ScheduleDay>,
    val districtId: String? = null
) {
    fun toJson(): String {
        val root = JSONObject()
        root.put("locationLabel", locationLabel)
        root.put("utcOffsetMinutes", utcOffsetMinutes)
        if (districtId != null) {
            root.put("districtId", districtId)
        }

        val daysArray = JSONArray()
        for (day in days) {
            val dayObj = JSONObject()
            dayObj.put("date", day.date)

            val timesArray = JSONArray()
            for (time in day.times) {
                val timeObj = JSONObject()
                timeObj.put("key", time.key)
                timeObj.put("label", time.label)
                timeObj.put("epochMillis", time.epochMillis)
                timesArray.put(timeObj)
            }
            dayObj.put("times", timesArray)
            daysArray.put(dayObj)
        }
        root.put("days", daysArray)

        return root.toString()
    }

    companion object {
        fun parse(json: String): SchedulePayload {
            try {
                val root = JSONObject(json)
                if (!root.has("locationLabel") ||
                    !root.has("utcOffsetMinutes") ||
                    !root.has("days")
                ) {
                    throw IllegalArgumentException(
                        "Payload missing required root fields"
                    )
                }

                val locationLabel = root.getString("locationLabel")
                val utcOffsetMinutes = root.getInt("utcOffsetMinutes")
                val districtId = if (root.has("districtId") && !root.isNull("districtId")) {
                    val value = root.get("districtId")
                    if (value is String) value else null
                } else {
                    null
                }
                val daysArray = root.getJSONArray("days")
                val days = ArrayList<ScheduleDay>(daysArray.length())

                for (i in 0 until daysArray.length()) {
                    val dayObj = daysArray.getJSONObject(i)
                    if (!dayObj.has("date") || !dayObj.has("times")) {
                        throw IllegalArgumentException(
                            "Day at index $i missing required fields"
                        )
                    }

                    val date = dayObj.getString("date")
                    val timesArray = dayObj.getJSONArray("times")
                    if (timesArray.length() != 6) {
                        throw IllegalArgumentException(
                            "Day must contain 6 times, found ${timesArray.length()}"
                        )
                    }

                    val times = ArrayList<ScheduleMoment>(6)
                    for (j in 0 until 6) {
                        val timeObj = timesArray.getJSONObject(j)
                        if (!timeObj.has("key") ||
                            !timeObj.has("label") ||
                            !timeObj.has("epochMillis")
                        ) {
                            throw IllegalArgumentException(
                                "Moment at day $i, time $j missing fields"
                            )
                        }

                        val key = timeObj.getString("key")
                        val label = timeObj.getString("label")
                        val epochMillis = timeObj.getLong("epochMillis")
                        times.add(ScheduleMoment(key, label, epochMillis))
                    }

                    days.add(ScheduleDay(date, times))
                }

                return SchedulePayload(
                    locationLabel,
                    utcOffsetMinutes,
                    days,
                    districtId
                )
            } catch (e: JSONException) {
                throw IllegalArgumentException(
                    "JSON parsing failed: ${e.message}",
                    e
                )
            }
        }
    }
}
