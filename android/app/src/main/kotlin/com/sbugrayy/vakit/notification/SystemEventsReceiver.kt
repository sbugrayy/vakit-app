package com.sbugrayy.vakit.notification

import android.app.AlarmManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class SystemEventsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        val handled = when (action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_MY_PACKAGE_REPLACED -> true
            else -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                    action ==
                    AlarmManager.ACTION_SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED
                ) {
                    true
                } else {
                    false
                }
            }
        }

        if (handled) {
            NotificationEngine.refresh(context)
        }
    }
}
