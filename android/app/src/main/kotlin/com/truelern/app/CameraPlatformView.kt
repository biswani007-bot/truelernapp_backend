package com.truelern.app

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Matrix
import android.graphics.SurfaceTexture
import android.hardware.camera2.*
import android.os.Handler
import android.os.HandlerThread
import android.util.Log
import android.util.Size
import android.view.Surface
import android.view.TextureView
import android.view.View
import androidx.core.content.ContextCompat
import io.flutter.plugin.platform.PlatformView

class CameraPlatformView(
    private val context: Context,
    private val activity: Activity,
    private val id: Int,
    private val creationParams: Map<String?, Any?>?
) : PlatformView, TextureView.SurfaceTextureListener {

    companion object {
        private const val TAG = "CameraPlatformView"
        var activeInstance: CameraPlatformView? = null
            private set

        fun isFrontCameraAvailable(context: Context): Boolean {
            val cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as? CameraManager ?: return false
            return try {
                cameraManager.cameraIdList.any { id ->
                    val chars = cameraManager.getCameraCharacteristics(id)
                    chars.get(CameraCharacteristics.LENS_FACING) == CameraCharacteristics.LENS_FACING_FRONT
                }
            } catch (e: Exception) {
                false
            }
        }
    }

    private val textureView: TextureView = TextureView(context)
    private var cameraManager: CameraManager? = null
    private var cameraDevice: CameraDevice? = null
    private var captureSession: CameraCaptureSession? = null
    private var previewSize: Size? = null

    private var backgroundThread: HandlerThread? = null
    private var backgroundHandler: Handler? = null

    private var isCameraOpen = false
    private var isStoppedByUser = false

    init {
        activeInstance = this
        cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as? CameraManager
        textureView.surfaceTextureListener = this
    }

    override fun getView(): View = textureView

    override fun onSurfaceTextureAvailable(surfaceTexture: SurfaceTexture, width: Int, height: Int) {
        startBackgroundThread()
        if (!isStoppedByUser) {
            openCamera(width, height)
        }
    }

    override fun onSurfaceTextureSizeChanged(surfaceTexture: SurfaceTexture, width: Int, height: Int) {
        configureTransform(width, height)
    }

    override fun onSurfaceTextureDestroyed(surfaceTexture: SurfaceTexture): Boolean {
        stopCameraInternal()
        stopBackgroundThread()
        return true
    }

    override fun onSurfaceTextureUpdated(surfaceTexture: SurfaceTexture) {}

    fun startCamera() {
        isStoppedByUser = false
        if (textureView.isAvailable) {
            startBackgroundThread()
            openCamera(textureView.width, textureView.height)
        }
    }

    fun stopCamera() {
        isStoppedByUser = true
        stopCameraInternal()
    }

    private fun startBackgroundThread() {
        if (backgroundThread == null) {
            backgroundThread = HandlerThread("CameraBackground").also { it.start() }
            backgroundHandler = Handler(backgroundThread!!.looper)
        }
    }

    private fun stopBackgroundThread() {
        backgroundThread?.quitSafely()
        try {
            backgroundThread?.join(500)
            backgroundThread = null
            backgroundHandler = null
        } catch (e: InterruptedException) {
            Log.e(TAG, "Error stopping background thread", e)
        }
    }

    private fun getFrontCameraId(): String? {
        val manager = cameraManager ?: return null
        return try {
            // Find front-facing camera first
            for (id in manager.cameraIdList) {
                val chars = manager.getCameraCharacteristics(id)
                val facing = chars.get(CameraCharacteristics.LENS_FACING)
                if (facing == CameraCharacteristics.LENS_FACING_FRONT) {
                    return id
                }
            }
            // Fallback to any available camera if no front camera
            manager.cameraIdList.firstOrNull()
        } catch (e: Exception) {
            Log.e(TAG, "Error discovering camera", e)
            null
        }
    }

    private fun openCamera(width: Int, height: Int) {
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            Log.w(TAG, "Camera permission not granted")
            return
        }

        if (isCameraOpen) {
            return
        }

        val cameraId = getFrontCameraId()
        if (cameraId == null) {
            Log.e(TAG, "No camera available")
            return
        }

        val manager = cameraManager ?: return

        try {
            val characteristics = manager.getCameraCharacteristics(cameraId)
            val map = characteristics.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP)
            val sizes = map?.getOutputSizes(SurfaceTexture::class.java)

            // Choose best 16:9 preview size or standard size
            previewSize = chooseOptimalSize(sizes, width, height)
            configureTransform(width, height)

            manager.openCamera(cameraId, object : CameraDevice.StateCallback() {
                override fun onOpened(camera: CameraDevice) {
                    cameraDevice = camera
                    isCameraOpen = true
                    startPreviewSession()
                }

                override fun onDisconnected(camera: CameraDevice) {
                    camera.close()
                    cameraDevice = null
                    isCameraOpen = false
                }

                override fun onError(camera: CameraDevice, error: Int) {
                    Log.e(TAG, "Camera device error: $error")
                    camera.close()
                    cameraDevice = null
                    isCameraOpen = false
                }
            }, backgroundHandler)
        } catch (e: SecurityException) {
            Log.e(TAG, "SecurityException opening camera", e)
        } catch (e: Exception) {
            Log.e(TAG, "Exception opening camera", e)
        }
    }

    private fun chooseOptimalSize(choices: Array<Size>?, textureViewWidth: Int, textureViewHeight: Int): Size {
        if (choices == null || choices.isEmpty()) {
            return Size(1280, 960)
        }
        Log.i(TAG, "Available camera preview sizes: ${choices.joinToString { "${it.width}x${it.height}" }}")

        // Prefer 4:3 aspect ratio resolution for taller, natural mobile camera view
        val targetAspect4By3 = 4.0 / 3.0
        val candidates4By3 = choices.filter {
            val aspect = it.width.toDouble() / it.height.toDouble()
            Math.abs(aspect - targetAspect4By3) < 0.05 || Math.abs((1.0 / aspect) - targetAspect4By3) < 0.05
        }

        if (candidates4By3.isNotEmpty()) {
            val chosen = candidates4By3.minByOrNull { Math.abs(it.width - 1280) } ?: candidates4By3[0]
            Log.i(TAG, "Selected 4:3 previewSize: ${chosen.width}x${chosen.height}")
            return chosen
        }

        // Fallback to 16:9 if 4:3 is not supported
        val targetAspect16By9 = 16.0 / 9.0
        val candidates16By9 = choices.filter {
            val aspect = it.width.toDouble() / it.height.toDouble()
            Math.abs(aspect - targetAspect16By9) < 0.05 || Math.abs((1.0 / aspect) - targetAspect16By9) < 0.05
        }
        val chosen = candidates16By9.minByOrNull { Math.abs(it.width - 1280) } ?: choices[0]
        Log.i(TAG, "Selected 16:9 fallback previewSize: ${chosen.width}x${chosen.height}")
        return chosen
    }

    private fun configureTransform(viewWidth: Int, viewHeight: Int) {
        if (viewWidth == 0 || viewHeight == 0) return

        val matrix = Matrix()
        val preview = previewSize
        if (preview != null && preview.width > 0 && preview.height > 0) {
            val viewCenterX = viewWidth / 2f
            val viewCenterY = viewHeight / 2f

            val viewAspect = viewWidth.toFloat() / viewHeight.toFloat()
            val bufferAspect = preview.width.toFloat() / preview.height.toFloat()

            // Center-crop / aspect-fill without distortion:
            // Preserves natural camera aspect ratio without stretching (sx == sy in physical aspect)
            // Preserves non-mirrored orientation (scaleX and scaleY are positive)
            if (viewAspect > bufferAspect) {
                // View is wider than camera buffer: scale height to match width scale
                val scaleY = viewAspect / bufferAspect
                matrix.setScale(1f, scaleY, viewCenterX, viewCenterY)
            } else if (viewAspect < bufferAspect) {
                // View is taller than camera buffer: scale width to match height scale
                val scaleX = bufferAspect / viewAspect
                matrix.setScale(scaleX, 1f, viewCenterX, viewCenterY)
            } else {
                matrix.setScale(1f, 1f, viewCenterX, viewCenterY)
            }
        }

        textureView.setTransform(matrix)
    }

    private fun startPreviewSession() {
        val camera = cameraDevice ?: return
        val surfaceTexture = textureView.surfaceTexture ?: return
        val size = previewSize ?: Size(1280, 960)

        surfaceTexture.setDefaultBufferSize(size.width, size.height)
        val surface = Surface(surfaceTexture)

        try {
            val previewRequestBuilder = camera.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW).apply {
                addTarget(surface)
                set(CaptureRequest.CONTROL_MODE, CameraMetadata.CONTROL_MODE_AUTO)
                set(CaptureRequest.CONTROL_AF_MODE, CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE)
            }

            camera.createCaptureSession(
                listOf(surface),
                object : CameraCaptureSession.StateCallback() {
                    override fun onConfigured(session: CameraCaptureSession) {
                        if (cameraDevice == null) return
                        captureSession = session
                        try {
                            session.setRepeatingRequest(
                                previewRequestBuilder.build(),
                                null,
                                backgroundHandler
                            )
                            textureView.post {
                                configureTransform(textureView.width, textureView.height)
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "Failed to start repeating preview request", e)
                        }
                    }

                    override fun onConfigureFailed(session: CameraCaptureSession) {
                        Log.e(TAG, "Capture session configuration failed")
                    }
                },
                backgroundHandler
            )
        } catch (e: Exception) {
            Log.e(TAG, "Error starting preview session", e)
        }
    }

    private fun stopCameraInternal() {
        try {
            captureSession?.stopRepeating()
            captureSession?.close()
            captureSession = null
        } catch (e: Exception) {
            Log.e(TAG, "Error closing capture session", e)
        }
        try {
            cameraDevice?.close()
            cameraDevice = null
        } catch (e: Exception) {
            Log.e(TAG, "Error closing camera device", e)
        }
        isCameraOpen = false
    }

    override fun dispose() {
        if (activeInstance == this) {
            activeInstance = null
        }
        stopCameraInternal()
        stopBackgroundThread()
    }
}
