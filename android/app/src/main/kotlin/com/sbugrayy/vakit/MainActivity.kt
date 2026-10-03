package com.sbugrayy.vakit

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.sbugrayy.vakit.notification.NotificationEngine
import com.sbugrayy.vakit.notification.NotificationMethodHandler
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NotificationMethodHandler.CHANNEL_NAME
        )
        channel.setMethodCallHandler(NotificationMethodHandler(this))
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
        pendingPermissionResult?.success(false)
        pendingPermissionResult = result

        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            NOTIFICATION_PERMISSION_REQUEST_CODE
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
            val callback = pendingPermissionResult
            pendingPermissionResult = null
            callback?.success(granted)
            // İzin yeni verildiyse bildirimin hemen görünmesi için tazele
            NotificationEngine.refresh(this)
        }
    }

    override fun onResume() {
        super.onResume()
        // Kullanıcı ayarlardan izin durumunu değiştirdiyse zamanlamayı tazele
        NotificationEngine.refresh(this)
    }

    override fun onDestroy() {
        // Bekleyen istek varsa sızdırılmasını veya askıda kalmasını engelle
        pendingPermissionResult?.success(false)
        pendingPermissionResult = null
        super.onDestroy()
    }

    companion object {
        private const val NOTIFICATION_PERMISSION_REQUEST_CODE = 1004
    }
}
