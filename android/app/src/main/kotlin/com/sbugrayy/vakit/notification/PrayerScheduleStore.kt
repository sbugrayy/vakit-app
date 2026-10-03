package com.sbugrayy.vakit.notification

import android.content.Context
import android.content.SharedPreferences

class PrayerScheduleStore(context: Context) {
    private val prefs: SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    var enabled: Boolean
        get() = prefs.getBoolean(KEY_ENABLED, true)
        set(value) {
            prefs.edit().putBoolean(KEY_ENABLED, value).apply()
        }

    fun savePayload(json: String) {
        prefs.edit().putString(KEY_PAYLOAD, json).apply()
    }

    fun loadPayload(): SchedulePayload? {
        val json = prefs.getString(KEY_PAYLOAD, null) ?: return null
        return try {
            SchedulePayload.parse(json)
        } catch (e: Exception) {
            null
        }
    }

    companion object {
        private const val PREFS_NAME = "vakit_bildirim"
        private const val KEY_ENABLED = "enabled"
        private const val KEY_PAYLOAD = "payload_json"
    }
}
