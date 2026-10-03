package com.sbugrayy.vakit.location

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Address
import android.location.Geocoder
import android.location.Location
import android.location.LocationManager
import android.os.Build
import android.os.CancellationSignal
import android.os.Handler
import android.os.Looper
import androidx.annotation.RequiresApi
import androidx.core.content.ContextCompat
import com.sbugrayy.vakit.MainActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Locale
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean
import java.util.function.Consumer

class LocationMethodHandler(
    private val activity: MainActivity
) : MethodChannel.MethodCallHandler {

    private val mainHandler = Handler(Looper.getMainLooper())
    private val executor = Executors.newSingleThreadExecutor()

    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        when (call.method) {
            "requestLocationPermission" -> {
                activity.requestLocationPermission(result)
            }
            "getCurrentLocation" -> handleGetCurrentLocation(result)
            "reverseGeocode" -> handleReverseGeocode(call, result)
            else -> result.notImplemented()
        }
    }

    private fun handleGetCurrentLocation(result: MethodChannel.Result) {
        if (!hasLocationPermission()) {
            result.error(
                "permission_denied",
                "Konum izni verilmedi",
                null
            )
            return
        }

        val locationManager = activity.getSystemService(
            Context.LOCATION_SERVICE
        ) as? LocationManager

        if (locationManager == null) {
            result.error(
                "unavailable",
                "Konum servisi bulunamadı",
                null
            )
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val provider = getPreferredProvider(locationManager)
            if (provider != null) {
                fetchCurrentLocationApi30(
                    locationManager = locationManager,
                    provider = provider,
                    result = result
                )
                return
            }
        }

        fallbackToLastKnownLocation(locationManager, result)
    }

    @RequiresApi(Build.VERSION_CODES.R)
    private fun fetchCurrentLocationApi30(
        locationManager: LocationManager,
        provider: String,
        result: MethodChannel.Result
    ) {
        val cancellationSignal = CancellationSignal()
        val completed = AtomicBoolean(false)

        val timeoutRunnable = Runnable {
            cancellationSignal.cancel()
            if (completed.compareAndSet(false, true)) {
                fallbackToLastKnownLocation(locationManager, result)
            }
        }
        mainHandler.postDelayed(timeoutRunnable, LOCATION_TIMEOUT_MS)

        Api30LocationHelper.getCurrentLocation(
            locationManager = locationManager,
            provider = provider,
            cancellationSignal = cancellationSignal,
            executor = ContextCompat.getMainExecutor(activity),
            onLocation = { location ->
                mainHandler.removeCallbacks(timeoutRunnable)
                if (completed.compareAndSet(false, true)) {
                    if (location != null) {
                        result.success(
                            mapOf(
                                "latitude" to location.latitude,
                                "longitude" to location.longitude
                            )
                        )
                    } else {
                        fallbackToLastKnownLocation(locationManager, result)
                    }
                }
            },
            onError = {
                mainHandler.removeCallbacks(timeoutRunnable)
                if (completed.compareAndSet(false, true)) {
                    fallbackToLastKnownLocation(locationManager, result)
                }
            }
        )
    }

    private fun fallbackToLastKnownLocation(
        locationManager: LocationManager,
        result: MethodChannel.Result
    ) {
        postToMain {
            val location = getLastKnownLocation(locationManager)
            if (location != null) {
                result.success(
                    mapOf(
                        "latitude" to location.latitude,
                        "longitude" to location.longitude
                    )
                )
            } else {
                result.error(
                    "unavailable",
                    "Konum alınamadı",
                    null
                )
            }
        }
    }

    private fun getLastKnownLocation(
        locationManager: LocationManager
    ): Location? {
        val providers = mutableListOf<String>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            providers.add(LocationManager.FUSED_PROVIDER)
        }
        providers.add(LocationManager.GPS_PROVIDER)
        providers.add(LocationManager.NETWORK_PROVIDER)
        providers.add(LocationManager.PASSIVE_PROVIDER)

        val allProviders = try {
            locationManager.allProviders
        } catch (e: Exception) {
            emptyList<String>()
        }

        var bestLocation: Location? = null
        for (provider in providers) {
            if (!allProviders.contains(provider)) continue
            try {
                val loc = locationManager.getLastKnownLocation(provider)
                    ?: continue
                if (bestLocation == null || loc.time > bestLocation.time) {
                    bestLocation = loc
                }
            } catch (e: SecurityException) {
                // İzin verilmemiş olabilir
            } catch (e: Exception) {
                // Sağlayıcı hatası
            }
        }
        return bestLocation
    }

    private fun getPreferredProvider(
        locationManager: LocationManager
    ): String? {
        val all = try {
            locationManager.allProviders
        } catch (e: Exception) {
            emptyList<String>()
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            all.contains(LocationManager.FUSED_PROVIDER) &&
            isProviderEnabled(locationManager, LocationManager.FUSED_PROVIDER)
        ) {
            return LocationManager.FUSED_PROVIDER
        }
        if (all.contains(LocationManager.NETWORK_PROVIDER) &&
            isProviderEnabled(
                locationManager,
                LocationManager.NETWORK_PROVIDER
            )
        ) {
            return LocationManager.NETWORK_PROVIDER
        }
        if (all.contains(LocationManager.GPS_PROVIDER) &&
            isProviderEnabled(locationManager, LocationManager.GPS_PROVIDER)
        ) {
            return LocationManager.GPS_PROVIDER
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            all.contains(LocationManager.FUSED_PROVIDER)
        ) {
            return LocationManager.FUSED_PROVIDER
        }
        if (all.contains(LocationManager.NETWORK_PROVIDER)) {
            return LocationManager.NETWORK_PROVIDER
        }
        if (all.contains(LocationManager.GPS_PROVIDER)) {
            return LocationManager.GPS_PROVIDER
        }

        return null
    }

    private fun isProviderEnabled(
        locationManager: LocationManager,
        provider: String
    ): Boolean {
        return try {
            locationManager.isProviderEnabled(provider)
        } catch (e: Exception) {
            false
        }
    }

    private fun handleReverseGeocode(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        val args = call.arguments as? Map<*, *>
        val lat = (args?.get("latitude") as? Number)?.toDouble()
        val lon = (args?.get("longitude") as? Number)?.toDouble()

        if (lat == null || lon == null) {
            result.error(
                "invalid_argument",
                "Enlem ve boylam gereklidir",
                null
            )
            return
        }

        if (!Geocoder.isPresent()) {
            result.error(
                "unavailable",
                "Ters coğrafi kodlama kullanılamıyor",
                null
            )
            return
        }

        val geocoder = Geocoder(activity, Locale("tr", "TR"))

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            Api33GeocoderHelper.reverseGeocode(
                geocoder = geocoder,
                lat = lat,
                lon = lon,
                onSuccess = { addresses ->
                    postToMain {
                        sendGeocodeResult(addresses, result)
                    }
                },
                onError = {
                    postToMain {
                        result.error(
                            "unavailable",
                            "Ters coğrafi kodlama başarısız oldu",
                            null
                        )
                    }
                }
            )
        } else {
            executor.execute {
                try {
                    @Suppress("DEPRECATION")
                    val addresses = geocoder.getFromLocation(lat, lon, 1)
                    postToMain {
                        sendGeocodeResult(addresses, result)
                    }
                } catch (e: Exception) {
                    postToMain {
                        result.error(
                            "unavailable",
                            "Ters coğrafi kodlama başarısız oldu",
                            null
                        )
                    }
                }
            }
        }
    }

    private fun sendGeocodeResult(
        addresses: List<Address>?,
        result: MethodChannel.Result
    ) {
        if (addresses.isNullOrEmpty()) {
            result.error(
                "unavailable",
                "Adres bulunamadı",
                null
            )
            return
        }

        val address = addresses[0]
        val fields = AddressFields(
            adminArea = address.adminArea,
            subAdminArea = address.subAdminArea,
            locality = address.locality,
            subLocality = address.subLocality
        )
        val (province, district) = fields.toPlace()
        result.success(
            mapOf(
                "province" to province,
                "district" to district
            )
        )
    }

    private fun hasLocationPermission(): Boolean {
        val fineGranted = ContextCompat.checkSelfPermission(
            activity,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
        val coarseGranted = ContextCompat.checkSelfPermission(
            activity,
            Manifest.permission.ACCESS_COARSE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
        return fineGranted || coarseGranted
    }

    private fun postToMain(action: () -> Unit) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            action()
        } else {
            mainHandler.post(action)
        }
    }

    companion object {
        const val CHANNEL_NAME = "com.sbugrayy.vakit/konum"
        private const val LOCATION_TIMEOUT_MS = 15_000L
    }
}

@RequiresApi(Build.VERSION_CODES.R)
private object Api30LocationHelper {
    fun getCurrentLocation(
        locationManager: LocationManager,
        provider: String,
        cancellationSignal: CancellationSignal,
        executor: java.util.concurrent.Executor,
        onLocation: (Location?) -> Unit,
        onError: () -> Unit
    ) {
        try {
            locationManager.getCurrentLocation(
                provider,
                cancellationSignal,
                executor,
                Consumer { location ->
                    onLocation(location)
                }
            )
        } catch (e: Exception) {
            onError()
        }
    }
}

@RequiresApi(Build.VERSION_CODES.TIRAMISU)
private object Api33GeocoderHelper {
    fun reverseGeocode(
        geocoder: Geocoder,
        lat: Double,
        lon: Double,
        onSuccess: (List<Address>) -> Unit,
        onError: () -> Unit
    ) {
        val completed = AtomicBoolean(false)
        try {
            geocoder.getFromLocation(
                lat,
                lon,
                1,
                object : Geocoder.GeocodeListener {
                    override fun onGeocode(addresses: MutableList<Address>) {
                        if (completed.compareAndSet(false, true)) {
                            onSuccess(addresses)
                        }
                    }

                    override fun onError(errorMessage: String?) {
                        if (completed.compareAndSet(false, true)) {
                            onError()
                        }
                    }
                }
            )
        } catch (e: Exception) {
            if (completed.compareAndSet(false, true)) {
                onError()
            }
        }
    }
}
