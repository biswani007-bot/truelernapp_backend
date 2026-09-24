package com.truelern.app

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val PERMISSION_REQUEST_CODE = 4401
        private const val CHANNEL = "com.truelern.app/camera_controls"
        private const val VIEW_TYPE = "com.truelern.app/camera_preview"
    }

    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        flutterEngine.platformViewsController.registry.registerViewFactory(
            VIEW_TYPE,
            CameraPlatformViewFactory(this)
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPermissions" -> {
                    val cameraGranted = ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
                    val micGranted = ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
                    val cameraPermanentlyDenied = !cameraGranted && !ActivityCompat.shouldShowRequestPermissionRationale(this, Manifest.permission.CAMERA)
                    val micPermanentlyDenied = !micGranted && !ActivityCompat.shouldShowRequestPermissionRationale(this, Manifest.permission.RECORD_AUDIO)

                    result.success(mapOf(
                        "camera" to cameraGranted,
                        "microphone" to micGranted,
                        "cameraPermanentlyDenied" to cameraPermanentlyDenied,
                        "microphonePermanentlyDenied" to micPermanentlyDenied
                    ))
                }
                "requestPermissions" -> {
                    val cameraGranted = ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
                    val micGranted = ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED

                    if (cameraGranted && micGranted) {
                        result.success(mapOf(
                            "camera" to true,
                            "microphone" to true,
                            "cameraPermanentlyDenied" to false,
                            "microphonePermanentlyDenied" to false
                        ))
                        return@setMethodCallHandler
                    }

                    pendingPermissionResult = result
                    ActivityCompat.requestPermissions(
                        this,
                        arrayOf(Manifest.permission.CAMERA, Manifest.permission.RECORD_AUDIO),
                        PERMISSION_REQUEST_CODE
                    )
                }
                "openAppSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                            data = Uri.fromParts("package", packageName, null)
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("APP_SETTINGS_ERROR", e.localizedMessage, null)
                    }
                }
                "startCamera" -> {
                    CameraPlatformView.activeInstance?.startCamera()
                    result.success(true)
                }
                "stopCamera" -> {
                    CameraPlatformView.activeInstance?.stopCamera()
                    result.success(true)
                }
                "isFrontCameraAvailable" -> {
                    val available = CameraPlatformView.isFrontCameraAvailable(this)
                    result.success(available)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val cameraGranted = ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
            val micGranted = ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
            val cameraPermanentlyDenied = !cameraGranted && !ActivityCompat.shouldShowRequestPermissionRationale(this, Manifest.permission.CAMERA)
            val micPermanentlyDenied = !micGranted && !ActivityCompat.shouldShowRequestPermissionRationale(this, Manifest.permission.RECORD_AUDIO)

            pendingPermissionResult?.success(mapOf(
                "camera" to cameraGranted,
                "microphone" to micGranted,
                "cameraPermanentlyDenied" to cameraPermanentlyDenied,
                "microphonePermanentlyDenied" to micPermanentlyDenied
            ))
            pendingPermissionResult = null
        }
    }
}
