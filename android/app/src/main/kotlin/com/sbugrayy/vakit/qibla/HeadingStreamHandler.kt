package com.sbugrayy.vakit.qibla

import android.content.Context
import android.hardware.GeomagneticField
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import io.flutter.plugin.common.EventChannel

class HeadingStreamHandler(
    private val context: Context
) : EventChannel.StreamHandler, SensorEventListener {

    private val mainHandler = Handler(Looper.getMainLooper())
    private val sensorManager =
        context.getSystemService(Context.SENSOR_SERVICE) as? SensorManager

    private var eventSink: EventChannel.EventSink? = null

    private var isUsingRotationVector: Boolean = false
    private var rotationSensor: Sensor? = null
    private var accelerometerSensor: Sensor? = null
    private var magneticSensor: Sensor? = null

    private var declination: Double = 0.0
    private var trueNorth: Boolean = false

    private val headingSmoother = HeadingSmoother()
    private var lastEmissionTimeMs: Long = 0L
    private var lastAccuracy: Int = SensorManager.SENSOR_STATUS_UNRELIABLE

    private val rotationMatrix = FloatArray(9)
    private val orientationAngles = FloatArray(3)
    private val accelerometerReading = FloatArray(3)
    private val magnetometerReading = FloatArray(3)
    private var hasAccelerometerReading: Boolean = false
    private var hasMagnetometerReading: Boolean = false

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        val sm = sensorManager
        if (sm == null) {
            events?.error(
                "no_sensor",
                "Pusula sensörü bulunamadı",
                null
            )
            return
        }

        // Önceki dinleyicileri kaldır ve durumu sıfırla
        sm.unregisterListener(this)
        headingSmoother.reset()
        lastEmissionTimeMs = 0L
        hasAccelerometerReading = false
        hasMagnetometerReading = false
        lastAccuracy = SensorManager.SENSOR_STATUS_UNRELIABLE

        // Koordinatları ve manyetik sapmayı çözümle
        val args = arguments as? Map<*, *>
        val lat = (args?.get("latitude") as? Number)?.toDouble()
        val lon = (args?.get("longitude") as? Number)?.toDouble()

        if (lat != null && lon != null) {
            try {
                val field = GeomagneticField(
                    lat.toFloat(),
                    lon.toFloat(),
                    0f,
                    System.currentTimeMillis()
                )
                declination = field.declination.toDouble()
                trueNorth = true
            } catch (e: Exception) {
                declination = 0.0
                trueNorth = false
            }
        } else {
            declination = 0.0
            trueNorth = false
        }

        // Sensör seçimi: önce ROTATION_VECTOR, yoksa ACCELEROMETER + MAG
        val rotSensor = sm.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
        if (rotSensor != null) {
            isUsingRotationVector = true
            rotationSensor = rotSensor
            val registered = sm.registerListener(
                this,
                rotSensor,
                SensorManager.SENSOR_DELAY_GAME,
                mainHandler
            )
            if (!registered) {
                events?.error(
                    "no_sensor",
                    "Pusula sensörü bulunamadı",
                    null
                )
            }
        } else {
            val accSensor = sm.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
            val magSensor = sm.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD)
            if (accSensor != null && magSensor != null) {
                isUsingRotationVector = false
                accelerometerSensor = accSensor
                magneticSensor = magSensor
                val regAcc = sm.registerListener(
                    this,
                    accSensor,
                    SensorManager.SENSOR_DELAY_GAME,
                    mainHandler
                )
                val regMag = sm.registerListener(
                    this,
                    magSensor,
                    SensorManager.SENSOR_DELAY_GAME,
                    mainHandler
                )
                if (!regAcc || !regMag) {
                    sm.unregisterListener(this)
                    events?.error(
                        "no_sensor",
                        "Pusula sensörü bulunamadı",
                        null
                    )
                }
            } else {
                events?.error(
                    "no_sensor",
                    "Pusula sensörü bulunamadı",
                    null
                )
            }
        }
    }

    override fun onCancel(arguments: Any?) {
        sensorManager?.unregisterListener(this)
        rotationSensor = null
        accelerometerSensor = null
        magneticSensor = null
        eventSink = null
        headingSmoother.reset()
        lastEmissionTimeMs = 0L
        hasAccelerometerReading = false
        hasMagnetometerReading = false
        lastAccuracy = SensorManager.SENSOR_STATUS_UNRELIABLE
        declination = 0.0
        trueNorth = false
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        if (isUsingRotationVector) {
            if (sensor?.type == Sensor.TYPE_ROTATION_VECTOR) {
                lastAccuracy = accuracy
            }
        } else {
            if (sensor?.type == Sensor.TYPE_MAGNETIC_FIELD) {
                lastAccuracy = accuracy
            }
        }
    }

    override fun onSensorChanged(event: SensorEvent) {
        if (isUsingRotationVector) {
            if (event.sensor.type != Sensor.TYPE_ROTATION_VECTOR) return
            SensorManager.getRotationMatrixFromVector(
                rotationMatrix,
                event.values
            )
        } else {
            if (event.sensor.type == Sensor.TYPE_ACCELEROMETER) {
                System.arraycopy(event.values, 0, accelerometerReading, 0, 3)
                hasAccelerometerReading = true
            } else if (event.sensor.type == Sensor.TYPE_MAGNETIC_FIELD) {
                System.arraycopy(event.values, 0, magnetometerReading, 0, 3)
                hasMagnetometerReading = true
                lastAccuracy = event.accuracy
            } else {
                return
            }

            if (!hasAccelerometerReading || !hasMagnetometerReading) {
                return
            }

            val success = SensorManager.getRotationMatrix(
                rotationMatrix,
                null,
                accelerometerReading,
                magnetometerReading
            )
            if (!success) return
        }

        val now = SystemClock.elapsedRealtime()
        if (lastEmissionTimeMs != 0L &&
            (now - lastEmissionTimeMs) < THROTTLE_MS
        ) {
            return
        }
        lastEmissionTimeMs = now

        SensorManager.getOrientation(rotationMatrix, orientationAngles)
        val rawAzimuth = normalize(
            Math.toDegrees(orientationAngles[0].toDouble())
        )
        if (rawAzimuth.isNaN()) return

        val adjustedHeading = if (trueNorth) {
            applyDeclination(rawAzimuth, declination)
        } else {
            rawAzimuth
        }

        val smoothedHeading = headingSmoother.update(adjustedHeading)

        val data = mapOf(
            "heading" to smoothedHeading,
            "accuracy" to lastAccuracy,
            "trueNorth" to trueNorth
        )
        eventSink?.success(data)
    }

    companion object {
        const val CHANNEL_NAME = "com.sbugrayy.vakit/kible"
        private const val THROTTLE_MS = 60L
    }
}
