package com.example.sensor

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.util.Log
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

class QiblaManager(context: Context) : SensorEventListener {

    private val sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private val accelerometer: Sensor? = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
    private val magnetometer: Sensor? = sensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD)

    private var gravity = FloatArray(3)
    private var geomagnetic = FloatArray(3)
    private var hasGravity = false
    private var hasGeomagnetic = false

    // Exposed Flows for UI
    private val _compassAzimuth = MutableStateFlow(0f)
    val compassAzimuth: StateFlow<Float> = _compassAzimuth // Rotation offset from North in degrees (0 to 360)

    private val _sensorAccuracyLow = MutableStateFlow(false)
    val sensorAccuracyLow: StateFlow<Boolean> = _sensorAccuracyLow

    // Smoothing factor (Low-pass filter coefficient)
    private val alpha = 0.12f

    fun startListening() {
        if (accelerometer != null) {
            sensorManager.registerListener(this, accelerometer, SensorManager.SENSOR_DELAY_UI)
        }
        if (magnetometer != null) {
            sensorManager.registerListener(this, magnetometer, SensorManager.SENSOR_DELAY_UI)
        }
        Log.d("QiblaManager", "Registered compass sensor listeners.")
    }

    fun stopListening() {
        sensorManager.unregisterListener(this)
        hasGravity = false
        hasGeomagnetic = false
        Log.d("QiblaManager", "Unregistered compass sensor listeners.")
    }

    override fun onSensorChanged(event: SensorEvent) {
        when (event.sensor.type) {
            Sensor.TYPE_ACCELEROMETER -> {
                gravity = lowPassFilter(event.values.clone(), gravity)
                hasGravity = true
            }
            Sensor.TYPE_MAGNETIC_FIELD -> {
                geomagnetic = lowPassFilter(event.values.clone(), geomagnetic)
                hasGeomagnetic = true
                _sensorAccuracyLow.value = event.accuracy <= SensorManager.SENSOR_STATUS_ACCURACY_LOW
            }
        }

        if (hasGravity && hasGeomagnetic) {
            val rMatrix = FloatArray(9)
            val iMatrix = FloatArray(9)
            if (SensorManager.getRotationMatrix(rMatrix, iMatrix, gravity, geomagnetic)) {
                val orientation = FloatArray(3)
                SensorManager.getOrientation(rMatrix, orientation)
                
                // Get azimuth around Z axis (Z points skyward, -Pi to Pi)
                val azimuthRad = orientation[0]
                var azimuthDeg = Math.toDegrees(azimuthRad.toDouble()).toFloat()
                
                // Convert azimuth to range 0..360
                azimuthDeg = (azimuthDeg + 360f) % 360f

                // Interpolate heading to resolve "modulo wrap-around jump jitter" at 360/0 boundary
                val current = _compassAzimuth.value
                val diff = azimuthDeg - current
                val smoothedAzimuth = if (diff < -180f) {
                    current + alpha * (diff + 360f)
                } else if (diff > 180f) {
                    current + alpha * (diff - 360f)
                } else {
                    current + alpha * diff
                }

                _compassAzimuth.value = (smoothedAzimuth + 360f) % 360f
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        if (sensor?.type == Sensor.TYPE_MAGNETIC_FIELD) {
            _sensorAccuracyLow.value = accuracy <= SensorManager.SENSOR_STATUS_ACCURACY_LOW
        }
    }

    private fun lowPassFilter(input: FloatArray, output: FloatArray?): FloatArray {
        if (output == null) return input
        for (i in input.indices) {
            output[i] = output[i] + alpha * (input[i] - output[i])
        }
        return output
    }

    /**
     * Calculates the great-circle geodesical bearing from user location to the Kaaba.
     */
    fun calculateQiblaBearing(userLat: Double, userLon: Double): Float {
        val lat1 = Math.toRadians(userLat)
        val lon1 = Math.toRadians(userLon)

        // Kaaba Coordinates: 21.4225 N, 39.8262 E
        val lat2 = Math.toRadians(21.422487)
        val lon2 = Math.toRadians(39.826206)

        val dLon = lon2 - lon1

        val y = Math.sin(dLon) * Math.cos(lat2)
        val x = Math.cos(lat1) * Math.sin(lat2) - Math.sin(lat1) * Math.cos(lat2) * Math.cos(dLon)

        val bearingRad = Math.atan2(y, x)
        val bearingDeg = Math.toDegrees(bearingRad).toFloat()

        return (bearingDeg + 360f) % 360f
    }
}
