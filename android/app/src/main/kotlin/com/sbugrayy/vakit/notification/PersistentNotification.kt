package com.sbugrayy.vakit.notification

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.sbugrayy.vakit.R

object PersistentNotification {
    const val NOTIFICATION_ID = 1001
    const val CHANNEL_ID = "vakit_kalici"
    private const val CONTENT_REQUEST_CODE = 1003

    private val NAME_IDS = intArrayOf(
        R.id.name_0,
        R.id.name_1,
        R.id.name_2,
        R.id.name_3,
        R.id.name_4,
        R.id.name_5
    )
    private val NAME_HL_IDS = intArrayOf(
        R.id.name_hl_0,
        R.id.name_hl_1,
        R.id.name_hl_2,
        R.id.name_hl_3,
        R.id.name_hl_4,
        R.id.name_hl_5
    )
    private val TIME_IDS = intArrayOf(
        R.id.time_0,
        R.id.time_1,
        R.id.time_2,
        R.id.time_3,
        R.id.time_4,
        R.id.time_5
    )
    private val TIME_HL_IDS = intArrayOf(
        R.id.time_hl_0,
        R.id.time_hl_1,
        R.id.time_hl_2,
        R.id.time_hl_3,
        R.id.time_hl_4,
        R.id.time_hl_5
    )

    fun show(context: Context, state: NotificationState) {
        if (!hasNotificationPermission(context)) {
            return
        }

        ensureChannel(context)

        val nextTime = NextPrayerCalculator.formatTime(
            state.next.epochMillis,
            state.utcOffsetMinutes
        )
        val title = "${state.locationLabel} • ${state.next.label} $nextTime"

        val summaryLine = state.day.times.mapIndexed { index, moment ->
            val time = NextPrayerCalculator.formatTime(
                moment.epochMillis,
                state.utcOffsetMinutes
            )
            if (index == state.nextIndex) {
                "▸${moment.label} $time"
            } else {
                "${moment.label} $time"
            }
        }.joinToString(" · ")

        val base = SystemClock.elapsedRealtime() +
            (state.next.epochMillis - System.currentTimeMillis())

        val collapsedView = RemoteViews(
            context.packageName,
            R.layout.notification_vakit_collapsed
        ).apply {
            setTextViewText(R.id.title, title)
            setChronometer(R.id.countdown, base, null, true)
            setChronometerCountDown(R.id.countdown, true)
        }

        val expandedView = RemoteViews(
            context.packageName,
            R.layout.notification_vakit_expanded
        ).apply {
            setTextViewText(R.id.title_expanded, title)
            setChronometer(R.id.countdown_expanded, base, null, true)
            setChronometerCountDown(R.id.countdown_expanded, true)

            for (i in 0 until minOf(state.day.times.size, 6)) {
                val moment = state.day.times[i]
                val time = NextPrayerCalculator.formatTime(
                    moment.epochMillis,
                    state.utcOffsetMinutes
                )
                val isNext = i == state.nextIndex

                setTextViewText(NAME_IDS[i], moment.label)
                setTextViewText(NAME_HL_IDS[i], moment.label)
                setTextViewText(TIME_IDS[i], time)
                setTextViewText(TIME_HL_IDS[i], time)

                setViewVisibility(
                    NAME_IDS[i],
                    if (isNext) View.GONE else View.VISIBLE
                )
                setViewVisibility(
                    NAME_HL_IDS[i],
                    if (isNext) View.VISIBLE else View.GONE
                )
                setViewVisibility(
                    TIME_IDS[i],
                    if (isNext) View.GONE else View.VISIBLE
                )
                setViewVisibility(
                    TIME_HL_IDS[i],
                    if (isNext) View.VISIBLE else View.GONE
                )
            }
        }

        val contentIntent = createContentPendingIntent(context)

        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_vakit)
            .setContentTitle(title)
            .setContentText(summaryLine)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setCustomContentView(collapsedView)
            .setCustomBigContentView(expandedView)
            .setShowWhen(false)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setContentIntent(contentIntent)

        notifySafely(context, NOTIFICATION_ID, builder)
    }

    fun showExpired(context: Context, locationLabel: String) {
        if (!hasNotificationPermission(context)) {
            return
        }

        ensureChannel(context)

        val contentIntent = createContentPendingIntent(context)
        val expiredText = context.getString(R.string.notification_expired_text)

        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_vakit)
            .setContentTitle(locationLabel)
            .setContentText(expiredText)
            .setStyle(NotificationCompat.BigTextStyle().bigText(expiredText))
            .setOngoing(false)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setContentIntent(contentIntent)

        notifySafely(context, NOTIFICATION_ID, builder)
    }

    fun cancel(context: Context) {
        NotificationManagerCompat.from(context).cancel(NOTIFICATION_ID)
    }

    private fun hasNotificationPermission(context: Context): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = context.getSystemService(
                Context.NOTIFICATION_SERVICE
            ) as? NotificationManager ?: return

            if (notificationManager.getNotificationChannel(CHANNEL_ID) == null) {
                val name = context.getString(R.string.notification_channel_name)
                val descriptionText = context.getString(
                    R.string.notification_channel_description
                )
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    name,
                    NotificationManager.IMPORTANCE_LOW
                ).apply {
                    description = descriptionText
                    setShowBadge(false)
                    setSound(null, null)
                    enableVibration(false)
                }
                notificationManager.createNotificationChannel(channel)
            }
        }
    }

    private fun createContentPendingIntent(context: Context): PendingIntent {
        val launchIntent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
            ?: Intent(Intent.ACTION_MAIN).apply {
                setPackage(context.packageName)
                addCategory(Intent.CATEGORY_LAUNCHER)
            }

        return PendingIntent.getActivity(
            context,
            CONTENT_REQUEST_CODE,
            launchIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
    }

    private fun notifySafely(
        context: Context,
        notificationId: Int,
        builder: NotificationCompat.Builder
    ) {
        try {
            NotificationManagerCompat.from(context).notify(
                notificationId,
                builder.build()
            )
        } catch (e: SecurityException) {
            // API 33+ izin çalışma anında iptal edilmişse çökmeyi engelle
        }
    }
}
