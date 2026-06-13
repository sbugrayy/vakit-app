package com.example.receiver

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class VakitReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        Log.d("VakitReceiver", "Broadcast received with action: $action")

        if (action == Intent.ACTION_BOOT_COMPLETED ||
            action == Intent.ACTION_MY_PACKAGE_REPLACED ||
            action == VakitNotificationHelper.ACTION_PRAYER_ALARM
        ) {
            // Recalculability logic is identical: schedule next alarm & update notification
            VakitNotificationHelper.scheduleNextAlarm(context)
        }
    }
}
