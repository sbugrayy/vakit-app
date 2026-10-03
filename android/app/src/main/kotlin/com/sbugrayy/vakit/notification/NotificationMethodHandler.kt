package com.sbugrayy.vakit.notification

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.sbugrayy.vakit.MainActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class NotificationMethodHandler(
    private val activity: MainActivity
) : MethodChannel.MethodCallHandler {

    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        when (call.method) {
            "syncSchedule" -> handleSyncSchedule(call, result)
            "setEnabled" -> handleSetEnabled(call, result)
            "getStatus" -> handleGetStatus(result)
            "requestNotificationPermission" -> {
                activity.requestNotificationPermission(result)
            }
            "openExactAlarmSettings" -> handleOpenExactAlarmSettings(result)
            else -> result.notImplemented()
        }
    }

    private fun handleSyncSchedule(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        val args = call.arguments as? Map<*, *>
        if (args == null) {
            result.error("invalid_payload", "Arguments must be a map", null)
            return
        }

        val payload = args["payload"] as? String
        val enabled = args["enabled"] as? Boolean

        if (payload == null || enabled == null) {
            result.error(
                "invalid_payload",
                "Missing or invalid payload/enabled arguments",
                null
            )
            return
        }

        try {
            NotificationEngine.sync(activity, payload, enabled)
            result.success(null)
        } catch (e: IllegalArgumentException) {
            result.error("invalid_payload", e.message, null)
        }
    }

    private fun handleSetEnabled(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        val args = call.arguments as? Map<*, *>
        val enabled = args?.get("enabled") as? Boolean

        if (enabled == null) {
            result.error(
                "invalid_argument",
                "Missing or invalid enabled argument",
                null
            )
            return
        }

        NotificationEngine.setEnabled(activity, enabled)
        result.success(null)
    }

    private fun handleGetStatus(result: MethodChannel.Result) {
        val areNotificationsEnabled =
            NotificationManagerCompat.from(activity).areNotificationsEnabled()

        val notificationsGranted =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                val hasPermission = ContextCompat.checkSelfPermission(
                    activity,
                    Manifest.permission.POST_NOTIFICATIONS
                ) == PackageManager.PERMISSION_GRANTED
                hasPermission && areNotificationsEnabled
            } else {
                areNotificationsEnabled
            }

        val scheduler = PrayerAlarmScheduler(activity)
        val store = PrayerScheduleStore(activity)

        val status = mapOf(
            "notificationsGranted" to notificationsGranted,
            "exactAlarmAllowed" to scheduler.canScheduleExact(),
            "enabled" to store.enabled
        )
        result.success(status)
    }

    private fun handleOpenExactAlarmSettings(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            try {
                val uri = Uri.parse("package:${activity.packageName}")
                val intent = Intent(
                    Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM,
                    uri
                )
                activity.startActivity(intent)
                result.success(true)
            } catch (e: Exception) {
                // Özel ROM'larda ayarlar aktivitesi bulunamazsa çökme olmasın
                result.success(false)
            }
        } else {
            result.success(false)
        }
    }

    companion object {
        const val CHANNEL_NAME = "com.sbugrayy.vakit/bildirim"
    }
}
