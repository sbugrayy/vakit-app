package com.example.receiver

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.RectF
import android.graphics.Typeface
import android.os.Build
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import androidx.core.graphics.drawable.IconCompat
import com.example.MainActivity
import com.example.R
import com.example.data.VakitRepository
import com.example.model.PrayerType
import java.util.Calendar
import java.util.Locale
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

object VakitNotificationHelper {

    private const val CHANNEL_ID = "vakit_channel_id"
    private const val CHANNEL_NAME = "Vakit Ezan Bildirimleri"
    private const val NOTIFICATION_ID = 2026

    const val ACTION_PRAYER_ALARM = "com.example.vakit.ACTION_PRAYER_ALARM"

    private val notificationScope = CoroutineScope(Dispatchers.Default)
    private var updateTickerStarted = false

    /**
     * Set up the Notification Channel for Android 8.0+ (Oreo) inside the system.
     */
    fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val importance = NotificationManager.IMPORTANCE_LOW // Low priority for persistent sidebar, does not chirp
            val channel = NotificationChannel(CHANNEL_ID, CHANNEL_NAME, importance).apply {
                description = "Sıradaki vakit ezan saatlerini gösteren kalıcı bildirim kanalı."
                setShowBadge(false)
            }
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    /**
     * Start a lightweight background ticker executing every 1 minute to refresh 
     * the remaining minutes countdown within the custom notification widget.
     */
    fun startUpdateTicker(context: Context) {
        if (updateTickerStarted) return
        updateTickerStarted = true

        notificationScope.launch {
            while (true) {
                try {
                    val repository = VakitRepository(context.applicationContext)
                    val timings = repository.getCachedTimings()
                    if (timings != null) {
                        val nextInfo = repository.getNextPrayerInfo(timings)
                        showPersistentNotification(context.applicationContext, nextInfo.name, nextInfo.time, nextInfo.isTomorrow)
                    }
                } catch (e: Exception) {
                    Log.e("VakitNotificationHelper", "Error in notification ticker loop", e)
                }
                delay(60000L) // update every 1 minute
            }
        }
    }

    /**
     * Dismisses the active countdown notification when there are no prayers within the 60m window.
     */
    fun cancelNotification(context: Context) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.cancel(NOTIFICATION_ID)
    }

    /**
     * Generates a beautiful custom mosque badge Bitmap on the fly with anti-aliasing.
     * Draws a gorgeous emerald-green mosque silhouette with the remaining minutes countdown written inside.
     */
    fun createMosqueIconWithText(context: Context, minutes: Int, showNumber: Boolean): Bitmap {
        val size = 192 // 192x192 is perfect for large notifications icon
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        
        canvas.drawColor(android.graphics.Color.TRANSPARENT)
        
        val paint = Paint().apply {
            isAntiAlias = true
            style = Paint.Style.FILL
            color = android.graphics.Color.parseColor("#1B5E20") // Rich spiritual Islamic green
        }
        
        val bottomMargin = size * 0.95f
        
        // 1. Central building (base for dome)
        val baseLeft = size * 0.25f
        val baseTop = size * 0.52f
        val baseRight = size * 0.75f
        val baseBottom = bottomMargin
        canvas.drawRect(baseLeft, baseTop, baseRight, baseBottom, paint)
        
        // 2. Central Dome
        val domeLeft = size * 0.30f
        val domeTop = size * 0.30f
        val domeRight = size * 0.70f
        val domeBottom = size * 0.70f
        val domeRect = RectF(domeLeft, domeTop, domeRight, domeBottom)
        canvas.drawArc(domeRect, 180f, 180f, true, paint)
        
        // 3. Spire & Moon
        val spireX = size / 2f
        val spireTop = size * 0.22f
        val spireBottom = size * 0.32f
        paint.strokeWidth = 3f
        paint.style = Paint.Style.STROKE
        canvas.drawLine(spireX, spireTop, spireX, spireBottom, paint)
        
        val cresRect = RectF(spireX - 6, spireTop - 8, spireX + 6, spireTop + 4)
        canvas.drawArc(cresRect, -90f, 180f, false, paint)
        
        paint.style = Paint.Style.FILL
        
        // 4. Left Minaret
        val mlLeft = size * 0.10f
        val mlTop = size * 0.25f
        val mlRight = size * 0.21f
        canvas.drawRect(mlLeft, mlTop, mlRight, bottomMargin, paint)
        
        val pathLeftCap = Path().apply {
            moveTo(mlLeft + (mlRight - mlLeft) / 2f, size * 0.12f)
            lineTo(mlLeft, mlTop)
            lineTo(mlRight, mlTop)
            close()
        }
        canvas.drawPath(pathLeftCap, paint)
        
        // 5. Right Minaret
        val mrLeft = size * 0.79f
        val mrTop = size * 0.25f
        val mrRight = size * 0.90f
        canvas.drawRect(mrLeft, mrTop, mrRight, bottomMargin, paint)
        
        val pathRightCap = Path().apply {
            moveTo(mrLeft + (mrRight - mrLeft) / 2f, size * 0.12f)
            lineTo(mrLeft, mrTop)
            lineTo(mrRight, mrTop)
            close()
        }
        canvas.drawPath(pathRightCap, paint)
        
        // 6. Print countdown text beautifully inside the center
        if (showNumber) {
            val textPaint = Paint().apply {
                isAntiAlias = true
                color = android.graphics.Color.WHITE
                textSize = if (minutes >= 10) size * 0.38f else size * 0.46f
                typeface = Typeface.create("sans-serif-black", Typeface.BOLD)
                textAlign = Paint.Align.CENTER
            }
            val textY = if (minutes >= 10) size * 0.74f else size * 0.78f
            canvas.drawText(minutes.toString(), size / 2f, textY, textPaint)
        }
        
        return bitmap
    }

    /**
     * Generates a monochrome alpha template Icon Compat specifically for the Android status-bar.
     * It draws a beautiful white mosque silhouette and uses PorterDuff.Mode.DST_OUT to punch 
     * out a clean transparent countdown number in the center of the dome.
     * 
     * If showNumber is false (countdown has not started), it draws a beautiful crescent & star (hilal ve yıldız).
     */
    fun createSmallIconWithText(context: Context, minutes: Int, showNumber: Boolean): IconCompat {
        val size = 96 // standard status-bar icon pixel canvas (4x of 24dp)
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        bitmap.eraseColor(android.graphics.Color.TRANSPARENT)

        val paint = Paint().apply {
            isAntiAlias = true
            style = Paint.Style.FILL
            color = android.graphics.Color.WHITE // Solid white template
        }

        if (!showNumber) {
            // DRAWS A BEAUTIFUL CRESCENT AND STAR (HILAL VE YILDIZ)
            // Save layer to safely use PorterDuff DST_OUT without clearing background
            val saveCount = canvas.saveLayer(0f, 0f, size.toFloat(), size.toFloat(), null)

            canvas.save()
            // Rotate the canvas slightly to tilt the crescent beautifully
            canvas.rotate(-20f, size / 2f, size / 2f)

            // Outer circle of crescent
            val cx1 = size * 0.44f
            val cy1 = size * 0.50f
            val r1 = size * 0.30f
            canvas.drawCircle(cx1, cy1, r1, paint)

            // Inner circle (which punches the moon shape)
            val punchPaint = Paint().apply {
                isAntiAlias = true
                style = Paint.Style.FILL
                xfermode = PorterDuffXfermode(PorterDuff.Mode.DST_OUT)
            }
            // Offset left for the waning crescent shape (back of moon on the right)
            val cx2 = cx1 - size * 0.10f
            val cy2 = cy1 - size * 0.02f
            val r2 = size * 0.30f
            canvas.drawCircle(cx2, cy2, r2, punchPaint)

            canvas.restore() // Restore rotation
            canvas.restoreToCount(saveCount) // Restore DST_OUT layer

            // Draw beautiful upright six-pointed star to the upper-right of the crescent
            val starCx = size * 0.72f
            val starCy = size * 0.32f
            val starOuter = size * 0.09f
            val starInner = size * 0.045f
            
            val path = Path()
            val points = 6
            var angle = -Math.PI / 2 // Start at top
            val angleIncrement = Math.PI / points
            for (i in 0 until points * 2) {
                val r = if (i % 2 == 0) starOuter else starInner
                val x = starCx + r * Math.cos(angle).toFloat()
                val y = starCy + r * Math.sin(angle).toFloat()
                if (i == 0) {
                    path.moveTo(x, y)
                } else {
                    path.lineTo(x, y)
                }
                angle += angleIncrement
            }
            path.close()
            canvas.drawPath(path, paint)

        } else {
            // REDESIGNED MOSQUE WITH A CLEAN BOTTOM-RIGHT NUMBER BADGE
            // Save layer to safely use PorterDuff DST_OUT without clearing the background
            val saveCount = canvas.saveLayer(0f, 0f, size.toFloat(), size.toFloat(), null)

            // 1. Draw solid white mosque silhouette (shifted slightly left to balance the badge on the right)
            paint.color = android.graphics.Color.WHITE
            paint.style = Paint.Style.FILL

            val bottomMargin = size * 0.84f

            // Mosque Base structure
            val baseLeft = size * 0.18f
            val baseTop = size * 0.48f
            val baseRight = size * 0.62f
            canvas.drawRect(baseLeft, baseTop, baseRight, bottomMargin, paint)

            // Dome shape (half-circle)
            val domeLeft = size * 0.22f
            val domeTop = size * 0.22f
            val domeRight = size * 0.58f
            val domeBottom = size * 0.58f
            val domeRect = RectF(domeLeft, domeTop, domeRight, domeBottom)
            canvas.drawArc(domeRect, 180f, 180f, true, paint)

            // Dome top spire
            val spireX = size * 0.40f
            paint.strokeWidth = 3f
            paint.style = Paint.Style.STROKE
            canvas.drawLine(spireX, size * 0.13f, spireX, size * 0.22f, paint)
            paint.style = Paint.Style.FILL

            // Left Minaret
            val mlLeft = size * 0.05f
            val mlTop = size * 0.22f
            val mlRight = size * 0.13f
            canvas.drawRect(mlLeft, mlTop, mlRight, bottomMargin, paint)
            
            val leftCap = Path().apply {
                moveTo(mlLeft + (mlRight - mlLeft) / 2f, size * 0.10f)
                lineTo(mlLeft, mlTop)
                lineTo(mlRight, mlTop)
                close()
            }
            canvas.drawPath(leftCap, paint)

            // Right Minaret
            val mrLeft = size * 0.67f
            val mrTop = size * 0.22f
            val mrRight = size * 0.75f
            canvas.drawRect(mrLeft, mrTop, mrRight, bottomMargin, paint)
            
            val rightCap = Path().apply {
                moveTo(mrLeft + (mrRight - mrLeft) / 2f, size * 0.10f)
                lineTo(mrLeft, mrTop)
                lineTo(mrRight, mrTop)
                close()
            }
            canvas.drawPath(rightCap, paint)

            // 2. Clear a beautiful cut-out GAP for the badge at bottom-right of the canvas (DST_OUT)
            val gapPaint = Paint().apply {
                isAntiAlias = true
                style = Paint.Style.FILL
                xfermode = PorterDuffXfermode(PorterDuff.Mode.DST_OUT)
            }
            val gapLeft = size * 0.42f
            val gapTop = size * 0.38f
            val gapRight = size * 1.00f
            val gapBottom = size * 1.00f
            val gapRect = RectF(gapLeft, gapTop, gapRight, gapBottom)
            canvas.drawRoundRect(gapRect, size * 0.15f, size * 0.15f, gapPaint)

            // 3. Draw the solid white Badge background (rounded rectangle)
            val badgeLeft = size * 0.50f
            val badgeTop = size * 0.46f
            val badgeRight = size * 0.98f
            val badgeBottom = size * 0.90f
            val badgeRect = RectF(badgeLeft, badgeTop, badgeRight, badgeBottom)
            paint.color = android.graphics.Color.WHITE
            paint.style = Paint.Style.FILL
            canvas.drawRoundRect(badgeRect, size * 0.11f, size * 0.11f, paint)

            // 4. Punch out the number inside the badge (DST_OUT)
            val textPaint = Paint().apply {
                isAntiAlias = true
                xfermode = PorterDuffXfermode(PorterDuff.Mode.DST_OUT)
                textSize = if (minutes >= 10) size * 0.26f else size * 0.32f
                typeface = Typeface.create("sans-serif-black", Typeface.BOLD)
                textAlign = Paint.Align.CENTER
            }
            val badgeCx = (badgeLeft + badgeRight) / 2f
            
            // Mathematically precise vertical centering
            val textHeight = textPaint.descent() - textPaint.ascent()
            val textOffset = textHeight / 2f - textPaint.descent()
            val badgeCy = (badgeTop + badgeBottom) / 2f
            val textY = badgeCy + textOffset

            canvas.drawText(minutes.toString(), badgeCx, textY, textPaint)

            canvas.restoreToCount(saveCount)
        }

        return IconCompat.createWithBitmap(bitmap)
    }

    /**
     * Build and display/update the ongoing, non-dismissable notification showing the next prayer.
     */
    fun showPersistentNotification(context: Context, nextPrayerName: String, nextPrayerTime: String, isTomorrow: Boolean) {
        createNotificationChannel(context)

        val repository = VakitRepository(context)
        val timings = repository.getCachedTimings() ?: return
        val cityName = repository.getSavedCityName().lowercase().replaceFirstChar { 
            if (it.isLowerCase()) it.titlecase(Locale.getDefault()) else it.toString() 
        }

        val nextInfo = repository.getNextPrayerInfo(timings)
        val diffMillis = nextInfo.calendar.timeInMillis - System.currentTimeMillis()
        val minutesRemaining = (diffMillis / (1000 * 60))

        val isUnder60m = (minutesRemaining in 0..60L)

        val countdownText: String
        val smallIcon: IconCompat
        val largeMosqueBitmap: Bitmap

        if (isUnder60m) {
            val mins = minutesRemaining.toInt()
            val timeText = if (mins <= 0) "Giriş vakti" else "$mins dk"
            countdownText = "${nextInfo.name} ($timeText)"
            // Generate dynamic monochrome status bar icon with transparent countdown text punches
            smallIcon = createSmallIconWithText(context, mins, true)
            // Generate dynamic emerald-white large icon with text countdown
            largeMosqueBitmap = createMosqueIconWithText(context, mins, true)
        } else {
            val totalMins = if (minutesRemaining < 0) 0L else minutesRemaining
            val hours = totalMins / 60
            val mins = totalMins % 60
            val timeText = if (hours > 0) "${hours}s ${mins}d" else "$mins dk"
            countdownText = "${nextInfo.name} ($timeText)"
            // Simple neat static monochrome mosque icon for status bar
            smallIcon = createSmallIconWithText(context, 0, false)
            // Elegant static green mosque icon for large notification drawer
            largeMosqueBitmap = createMosqueIconWithText(context, 0, false)
        }

        val collapsedRemoteViews = RemoteViews(context.packageName, R.layout.notification_prayer_times_collapsed)
        collapsedRemoteViews.setTextViewText(R.id.notification_city_name, cityName)
        collapsedRemoteViews.setTextViewText(R.id.notification_countdown_text, countdownText)

        val expandedRemoteViews = RemoteViews(context.packageName, R.layout.notification_prayer_times)

        // Bind standard properties to expanded content
        expandedRemoteViews.setTextViewText(R.id.notification_city_name, cityName)
        expandedRemoteViews.setTextViewText(R.id.notification_countdown_text, countdownText)

        // Put the custom dynamic mosque badge with count in the ImageView inside custom layout card
        expandedRemoteViews.setViewVisibility(R.id.notification_mosque_badge, View.VISIBLE)
        expandedRemoteViews.setImageViewBitmap(R.id.notification_mosque_badge, largeMosqueBitmap)

        // Bind prayer times horizontally
        expandedRemoteViews.setTextViewText(R.id.time_imsak, timings.Imsak)
        expandedRemoteViews.setTextViewText(R.id.time_gunes, timings.Sunrise)
        expandedRemoteViews.setTextViewText(R.id.time_ogle, timings.Dhuhr)
        expandedRemoteViews.setTextViewText(R.id.time_ikindi, timings.Asr)
        expandedRemoteViews.setTextViewText(R.id.time_aksam, timings.Maghrib)
        expandedRemoteViews.setTextViewText(R.id.time_yatsi, timings.Isha)

        // Highlight the current next prayer item inside horizontal list
        val orange = android.graphics.Color.parseColor("#FFE67E22")
        val gray = android.graphics.Color.parseColor("#90928E")
        val white = android.graphics.Color.parseColor("#FFFFFF")

        val mapping = listOf(
            Triple("İmsak", R.id.name_imsak, R.id.time_imsak),
            Triple("Güneş", R.id.name_gunes, R.id.time_gunes),
            Triple("Öğle", R.id.name_ogle, R.id.time_ogle),
            Triple("İkindi", R.id.name_ikindi, R.id.time_ikindi),
            Triple("Akşam", R.id.name_aksam, R.id.time_aksam),
            Triple("Yatsı", R.id.name_yatsi, R.id.time_yatsi)
        )

        for ((name, nameId, timeId) in mapping) {
            val isNext = (name == nextInfo.name)
            if (isNext) {
                expandedRemoteViews.setTextColor(nameId, orange)
                expandedRemoteViews.setTextColor(timeId, orange)
            } else {
                expandedRemoteViews.setTextColor(nameId, gray)
                expandedRemoteViews.setTextColor(timeId, white)
            }
        }

        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(smallIcon) // Custom dynamic punch-out status-bar icon!
            .setLargeIcon(largeMosqueBitmap) // Mirror the mosque badge here in high res for the notifications shelf
            .setCustomContentView(collapsedRemoteViews)
            .setCustomBigContentView(expandedRemoteViews)
            .setOngoing(true) // Keeps the notification non-dismissable
            .setPriority(NotificationCompat.PRIORITY_LOW) // Silent ongoing display
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setContentIntent(pendingIntent)
            .setShowWhen(false)
            .setOnlyAlertOnce(true)

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, builder.build())
        Log.d("VakitNotificationHelper", "Persistent custom layout notification of prayer times displayed/updated (Under 60m: $isUnder60m, left: $minutesRemaining mins).")
    }

    /**
     * Compute the next upcoming prayer time from the cache, update notification, and schedule precise alarm.
     */
    fun scheduleNextAlarm(context: Context) {
        val repository = VakitRepository(context)
        val timings = repository.getCachedTimings()

        if (timings == null) {
            Log.w("VakitNotificationHelper", "No cached timings to schedule alarm.")
            return
        }

        val info = repository.getNextPrayerInfo(timings)
        val targetMilli = info.calendar.timeInMillis
        val diffMillis = targetMilli - System.currentTimeMillis()
        val minutesRemaining = diffMillis / (1000 * 60)

        // 1. Refresh or clear notifications
        showPersistentNotification(context, info.name, info.time, info.isTomorrow)

        // 2. Schedule precise alarm using AlarmManager
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, VakitReceiver::class.java).apply {
            action = ACTION_PRAYER_ALARM
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        if (minutesRemaining <= 60) {
            // Under 60m remaining: Start dynamic background ticker
            startUpdateTicker(context)

            // Trigger are now-dependent: Schedule alarm exactly in 1 minute to refresh the countdown ticker safely
            val nextTickMilli = System.currentTimeMillis() + 60 * 1000
            val triggerMilli = if (nextTickMilli < targetMilli) nextTickMilli else targetMilli
            
            if (triggerMilli > System.currentTimeMillis()) {
                scheduleExact(alarmManager, triggerMilli, pendingIntent)
                Log.d("VakitNotificationHelper", "Under 60m. Scheduled next countdown ticker in 1 min at: ${java.util.Date(triggerMilli)}")
            }
        } else {
            // More than 60m remaining: Schedule alarm to fire exactly when count down starts!
            val triggerMilli = targetMilli - (60 * 60 * 1000) // target time minus 60m
            if (triggerMilli > System.currentTimeMillis()) {
                scheduleExact(alarmManager, triggerMilli, pendingIntent)
                Log.d("VakitNotificationHelper", "More than 60m. Scheduled countdown start alarm at: ${java.util.Date(triggerMilli)}")
            } else {
                // If by some reason (e.g., target calculation delay) target - 60 is in the past, trigger right now
                val nextTickMilli = System.currentTimeMillis() + 60 * 1000
                scheduleExact(alarmManager, nextTickMilli, pendingIntent)
                Log.d("VakitNotificationHelper", "Fallback: Scheduled next ticker in 1 min at: ${java.util.Date(nextTickMilli)}")
            }
        }
    }

    private fun scheduleExact(alarmManager: AlarmManager, triggerMilli: Long, pendingIntent: PendingIntent) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (alarmManager.canScheduleExactAlarms()) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerMilli, pendingIntent)
            } else {
                alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerMilli, pendingIntent)
            }
        } else {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerMilli, pendingIntent)
        }
    }
}
