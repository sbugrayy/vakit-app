package com.sbugrayy.vakit.notification

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.Rect
import android.graphics.Typeface
import androidx.core.content.ContextCompat
import androidx.core.graphics.drawable.IconCompat
import com.sbugrayy.vakit.R
import kotlin.math.min

object StatusIcons {
    fun minuteIcon(context: Context, minutes: Int): IconCompat {
        val size = MosqueIconLayout.sizePx(
            context.resources.displayMetrics.density
        )

        val drawable = ContextCompat.getDrawable(
            context,
            R.drawable.ic_stat_mosque
        ) ?: return IconCompat.createWithResource(
            context,
            R.drawable.ic_stat_vakit
        )

        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, size, size)
        drawable.draw(canvas)

        val box = MosqueIconLayout.digitBoxPx(size)
        val boxWidth = box[2] - box[0]
        val boxHeight = box[3] - box[1]
        val boxCenterX = (box[0] + box[2]) / 2f
        val boxCenterY = (box[1] + box[3]) / 2f

        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            typeface = Typeface.create("sans-serif-condensed", Typeface.BOLD)
            xfermode = PorterDuffXfermode(PorterDuff.Mode.DST_OUT)
        }

        paint.textSize = boxHeight
        val zeroBounds = Rect()
        paint.getTextBounds("00", 0, 2, zeroBounds)
        val zeroWidth = zeroBounds.width().toFloat()
        val zeroHeight = zeroBounds.height().toFloat()
        if (zeroWidth > 0f && zeroHeight > 0f) {
            paint.textSize *= min(boxWidth / zeroWidth, boxHeight / zeroHeight)
        }

        val label = MosqueIconLayout.label(minutes)
        val bounds = Rect()
        paint.getTextBounds(label, 0, label.length, bounds)
        val x = boxCenterX - bounds.exactCenterX()
        val y = boxCenterY - bounds.exactCenterY()
        canvas.drawText(label, x, y, paint)

        return IconCompat.createWithBitmap(bitmap)
    }
}
