package com.example.ui.components

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.ui.theme.GoldAccent
import kotlin.math.cos
import kotlin.math.sin

@Composable
fun CompassView(
    azimuth: Float, // current raw heading from north
    qiblaBearing: Float, // angle to mecca
    sensorAccuracyLow: Boolean,
    modifier: Modifier = Modifier
) {
    val animatedAzimuth by animateFloatAsState(targetValue = azimuth, label = "compass_rotation")

    Column(
        modifier = modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Box(
            modifier = Modifier
                .size(280.dp)
                .padding(16.dp),
            contentAlignment = Alignment.Center
        ) {
            val primaryColor = MaterialTheme.colorScheme.primary
            val secondaryColor = MaterialTheme.colorScheme.secondary
            val onSurfaceColor = MaterialTheme.colorScheme.onSurface
            val cardColor = MaterialTheme.colorScheme.surfaceVariant

            Canvas(modifier = Modifier.fillMaxSize()) {
                val center = Offset(size.width / 2f, size.height / 2f)
                val radius = size.width / 2f - 10f

                // 1. Draw outer dial background
                drawCircle(
                    color = cardColor.copy(alpha = 0.5f),
                    radius = radius,
                    center = center
                )

                // 2. Draw compass outer ring
                drawCircle(
                    color = primaryColor.copy(alpha = 0.8f),
                    radius = radius,
                    center = center,
                    style = androidx.compose.ui.graphics.drawscope.Stroke(width = 4.dp.toPx())
                )

                // 3. Revolve everything on dial relative to phone's current direction
                // rotating -azimuth spins "North" back to local planetary North
                rotate(degrees = -animatedAzimuth, pivot = center) {
                    
                    // Draw outer graduation ticks every 30 degrees
                    for (i in 0 until 360 step 15) {
                        val angleRad = Math.toRadians(i.toDouble())
                        val isMajor = i % 90 == 0
                        val isIntermediate = i % 30 == 0
                        
                        val tickLength = if (isMajor) 15.dp.toPx() else if (isIntermediate) 10.dp.toPx() else 6.dp.toPx()
                        val strokeWidth = if (isMajor) 3.dp.toPx() else 1.5.dp.toPx()
                        val tickColor = if (isMajor) primaryColor else secondaryColor.copy(alpha = 0.6f)

                        val startX = center.x + (radius - tickLength) * sin(angleRad).toFloat()
                        val startY = center.y - (radius - tickLength) * cos(angleRad).toFloat()
                        val endX = center.x + radius * sin(angleRad).toFloat()
                        val endY = center.y - radius * cos(angleRad).toFloat()

                        drawLine(
                            color = tickColor,
                            start = Offset(startX, startY),
                            end = Offset(endX, endY),
                            strokeWidth = strokeWidth
                        )
                    }

                    // 4. Draw Turkish Cardinal Letter Markings (K, D, G, B)
                    val textPaint = android.graphics.Paint().apply {
                        isAntiAlias = true
                        textSize = 18.sp.toPx()
                        typeface = android.graphics.Typeface.create(android.graphics.Typeface.DEFAULT, android.graphics.Typeface.BOLD)
                    }

                    val drawCardinal: (String, Float, Color) -> Unit = { label, angle, color ->
                        val rad = Math.toRadians(angle.toDouble())
                        val labelRadius = radius - 30.dp.toPx()
                        val labelX = center.x + labelRadius * sin(rad).toFloat()
                        val labelY = center.y - labelRadius * cos(rad).toFloat()

                        textPaint.color = android.graphics.Color.argb(
                            (color.alpha * 255).toInt(),
                            (color.red * 255).toInt(),
                            (color.green * 255).toInt(),
                            (color.blue * 255).toInt()
                        )

                        val bounds = android.graphics.Rect()
                        textPaint.getTextBounds(label, 0, label.length, bounds)
                        
                        drawContext.canvas.nativeCanvas.drawText(
                            label,
                            labelX - bounds.width() / 2f,
                            labelY + bounds.height() / 2f,
                            textPaint
                        )
                    }

                    drawCardinal("K", 0f, primaryColor)
                    drawCardinal("D", 90f, onSurfaceColor)
                    drawCardinal("G", 180f, onSurfaceColor)
                    drawCardinal("B", 270f, onSurfaceColor)

                    // 5. Draw Gold Qibla Indicator Marker on the Rotating Dial Ring
                    val qiblaRad = Math.toRadians(qiblaBearing.toDouble())
                    val qiblaPointerRadius = radius - 15.dp.toPx()
                    val qX = center.x + qiblaPointerRadius * sin(qiblaRad).toFloat()
                    val qY = center.y - qiblaPointerRadius * cos(qiblaRad).toFloat()

                    drawCircle(
                        color = GoldAccent,
                        radius = 12.dp.toPx(),
                        center = Offset(qX, qY)
                    )

                    // Draw golden minaret / dome arrow structure pointing outward
                    val qiblaPath = Path().apply {
                        val baseRadLeft = Math.toRadians(qiblaBearing.toDouble() - 4.5)
                        val baseRadRight = Math.toRadians(qiblaBearing.toDouble() + 4.5)
                        val tipRad = Math.toRadians(qiblaBearing.toDouble())

                        val tipX = center.x + (radius - 4.dp.toPx()) * sin(tipRad).toFloat()
                        val tipY = center.y - (radius - 4.dp.toPx()) * cos(tipRad).toFloat()

                        val leftX = center.x + (radius - 32.dp.toPx()) * sin(baseRadLeft).toFloat()
                        val leftY = center.y - (radius - 32.dp.toPx()) * cos(baseRadLeft).toFloat()

                        val rightX = center.x + (radius - 32.dp.toPx()) * sin(baseRadRight).toFloat()
                        val rightY = center.y - (radius - 32.dp.toPx()) * cos(baseRadRight).toFloat()

                        moveTo(tipX, tipY)
                        lineTo(leftX, leftY)
                        lineTo(rightX, rightY)
                        close()
                    }
                    drawPath(path = qiblaPath, color = GoldAccent)
                }

                // 6. Draw local North-South screen aligned static pointer needles (Red side to North, Silver side to South)
                // This doesn't rotate, it acts as the baseline phone orientation guide
                val needleWidth = 14.dp.toPx()
                val needleLength = 55.dp.toPx()

                // North Pointer Needle (Pointing straight Up)
                val northNeedlePath = Path().apply {
                    moveTo(center.x, center.y - needleLength)
                    lineTo(center.x + needleWidth / 2f, center.y)
                    lineTo(center.x - needleWidth / 2f, center.y)
                    close()
                }
                drawPath(path = northNeedlePath, color = Color(0xFFC0392B)) // High visibility red

                // South Pointer Needle (Pointing straight Down)
                val southNeedlePath = Path().apply {
                    moveTo(center.x, center.y + needleLength)
                    lineTo(center.x + needleWidth / 2f, center.y)
                    lineTo(center.x - needleWidth / 2f, center.y)
                    close()
                }
                drawPath(path = southNeedlePath, color = Color(0xFFBDC3C7)) // Silver grey

                // Center pivot cap
                drawCircle(
                    color = primaryColor,
                    radius = 8.dp.toPx(),
                    center = center
                )
                drawCircle(
                    color = Color.White,
                    radius = 3.dp.toPx(),
                    center = center
                )
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Angle summary details
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    text = "${azimuth.toInt()}°",
                    style = MaterialTheme.typography.titleLarge,
                    color = MaterialTheme.colorScheme.onBackground
                )
                Text(
                    text = "Telefon Yönü",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.6f)
                )
            }

            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    text = "${qiblaBearing.toInt()}°",
                    style = MaterialTheme.typography.titleLarge,
                    color = GoldAccent
                )
                Text(
                    text = "Kıble Açısı",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.6f)
                )
            }
        }

        // Qibla direction comparison (tells user where to rotate)
        Spacer(modifier = Modifier.height(16.dp))
        val directionDiff = (qiblaBearing - azimuth + 360f) % 360f
        val alignText = when {
            directionDiff < 4f || directionDiff > 356f -> "Kıble Yönündesiniz! 🕋"
            directionDiff < 180f -> "Sağa Dönün (${directionDiff.toInt()}°)"
            else -> "Sola Dönün (${(360f - directionDiff).toInt()}°)"
        }
        val alignColor = if (directionDiff < 4f || directionDiff > 356f) {
            MaterialTheme.colorScheme.primary
        } else {
            GoldAccent
        }

        Text(
            text = alignText,
            style = MaterialTheme.typography.titleMedium,
            color = alignColor,
            modifier = Modifier.padding(8.dp)
        )

        // Calibration warning
        if (sensorAccuracyLow) {
            Row(
                modifier = Modifier.padding(16.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Default.Warning,
                    contentDescription = "Calibration Warning",
                    tint = Color(0xFFE67E22),
                    modifier = Modifier.size(20.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "Pusula hassasiyeti düşük. Lütfen cihazınızı 8 çizerek kalibre edin.",
                    style = MaterialTheme.typography.bodySmall,
                    color = Color(0xFFE67E22)
                )
            }
        }
    }
}
