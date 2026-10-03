package com.sbugrayy.vakit

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.sbugrayy.vakit.location.LocationMethodHandler
import com.sbugrayy.vakit.notification.NotificationEngine
import com.sbugrayy.vakit.notification.NotificationMethodHandler
import com.sbugrayy.vakit.qibla.HeadingStreamHandler
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingNotificationPermissionResult: MethodChannel.Result? =
        null
    private var pendingLocationPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val notificationChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NotificationMethodHandler.CHANNEL_NAME
        )
        notificationChannel.setMethodCallHandler(
            NotificationMethodHandler(this)
        )

        val locationChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            LocationMethodHandler.CHANNEL_NAME
        )
        locationChannel.setMethodCallHandler(LocationMethodHandler(this))

        val qiblaChannel = EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            HeadingStreamHandler.CHANNEL_NAME
        )
        qiblaChannel.setStreamHandler(
            HeadingStreamHandler(applicationContext)
        )
    }

    fun requestNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.success(true)
            return
        }

        val isGranted = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.POST_NOTIFICATIONS
        ) == PackageManager.PERMISSION_GRANTED

        if (isGranted) {
            result.success(true)
            return
        }

        // Aynı anda ikinci istek gelirse öncekini success(false) ile kapat
        pendingNotificationPermissionResult?.success(false)
        pendingNotificationPermissionResult = result

        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            NOTIFICATION_PERMISSION_REQUEST_CODE
        )
    }

    fun requestLocationPermission(result: MethodChannel.Result) {
        val fineGranted = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
        val coarseGranted = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_COARSE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED

        if (fineGranted || coarseGranted) {
            result.success(true)
            return
        }

        // Aynı anda ikinci istek gelirse öncekini success(false) ile kapat
        pendingLocationPermissionResult?.success(false)
        pendingLocationPermissionResult = result

        ActivityCompat.requestPermissions(
            this,
            arrayOf(
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION
            ),
            LOCATION_PERMISSION_REQUEST_CODE
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(
            requestCode,
            permissions,
            grantResults
        )
        if (requestCode == NOTIFICATION_PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED
            val callback = pendingNotificationPermissionResult
            pendingNotificationPermissionResult = null
            callback?.success(granted)
            // İzin yeni verildiyse bildirimin hemen görünmesi için tazele
            NotificationEngine.refresh(this)
        } else if (requestCode == LOCATION_PERMISSION_REQUEST_CODE) {
            val granted = grantResults.any {
                it == PackageManager.PERMISSION_GRANTED
            }
            val callback = pendingLocationPermissionResult
            pendingLocationPermissionResult = null
            callback?.success(granted)
        }
    }

    override fun onResume() {
        super.onResume()
        // Kullanıcı ayarlardan izin durumunu değiştirdiyse zamanlamayı tazele
        NotificationEngine.refresh(this)
    }

    override fun onDestroy() {
        // Bekleyen istek varsa sızdırılmasını veya askıda kalmasını engelle
        pendingNotificationPermissionResult?.success(false)
        pendingNotificationPermissionResult = null
        pendingLocationPermissionResult?.success(false)
        pendingLocationPermissionResult = null
        super.onDestroy()
    }

    companion object {
        private const val NOTIFICATION_PERMISSION_REQUEST_CODE = 1004
        private const val LOCATION_PERMISSION_REQUEST_CODE = 1005
    }
}

