package com.neurolink.neuro_link

import android.Manifest
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Matrix
import android.os.Bundle
import android.util.Log
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.framework.image.MPImage
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarker
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarkerResult
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import kotlin.math.sqrt
import kotlin.math.max

class MainActivity : FlutterActivity() {
    private val CHANNEL = "neuro_link/facemesh"
    private val STREAM_CHANNEL = "neuro_link/gaze_stream"
    
    private var eventSink: EventChannel.EventSink? = null
    private var faceLandmarker: FaceLandmarker? = null
    private lateinit var cameraExecutor: ExecutorService
    private var cameraProvider: ProcessCameraProvider? = null

    // For EAR calculation
    private val closedThreshold = 0.22
    private val openThreshold = 0.28
    private var eyeClosed = false
    private var closedStart: Long = 0
    private val pulses = mutableListOf<Long>()
    private var lastEmittedAt: Long = 0
    private var quietDeadline: Long = 0

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        cameraExecutor = Executors.newSingleThreadExecutor()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    if (checkCameraPermission()) {
                        setupFaceLandmarker()
                        startCamera()
                        result.success(true)
                    } else {
                        requestCameraPermission()
                        result.success(false)
                    }
                }
                "stop" -> {
                    cameraProvider?.unbindAll()
                    faceLandmarker?.close()
                    faceLandmarker = null
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, STREAM_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )
    }

    private fun checkCameraPermission() = ContextCompat.checkSelfPermission(
        this, Manifest.permission.CAMERA
    ) == PackageManager.PERMISSION_GRANTED

    private fun requestCameraPermission() {
        ActivityCompat.requestPermissions(
            this, arrayOf(Manifest.permission.CAMERA), 1001
        )
    }

    private fun setupFaceLandmarker() {
        val baseOptions = BaseOptions.builder()
            .setModelAssetPath("face_landmarker.task")
            .build()

        val options = FaceLandmarker.FaceLandmarkerOptions.builder()
            .setBaseOptions(baseOptions)
            .setMinFaceDetectionConfidence(0.5f)
            .setMinTrackingConfidence(0.5f)
            .setMinFacePresenceConfidence(0.5f)
            .setNumFaces(1)
            .setRunningMode(RunningMode.LIVE_STREAM)
            .setResultListener(this::onFaceLandmarkerResult)
            .setErrorListener { error ->
                Log.e("FaceMesh", "MediaPipe Error: ${error.message}")
            }
            .build()

        faceLandmarker = FaceLandmarker.createFromOptions(context, options)
    }

    private fun startCamera() {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(this)
        cameraProviderFuture.addListener({
            cameraProvider = cameraProviderFuture.get()
            
            val imageAnalysis = ImageAnalysis.Builder()
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_RGBA_8888)
                .build()
                .also {
                    it.setAnalyzer(cameraExecutor) { imageProxy ->
                        processImageProxy(imageProxy)
                    }
                }

            val cameraSelector = CameraSelector.DEFAULT_FRONT_CAMERA

            try {
                cameraProvider?.unbindAll()
                cameraProvider?.bindToLifecycle(
                    this, cameraSelector, imageAnalysis
                )
            } catch (e: Exception) {
                Log.e("CameraX", "Binding failed", e)
            }
        }, ContextCompat.getMainExecutor(this))
    }

    private fun processImageProxy(imageProxy: ImageProxy) {
        val bitmap = Bitmap.createBitmap(imageProxy.width, imageProxy.height, Bitmap.Config.ARGB_8888)
        bitmap.copyPixelsFromBuffer(imageProxy.planes[0].buffer)
        
        // Mirror the image for front camera
        val matrix = Matrix()
        matrix.postScale(-1f, 1f, bitmap.width / 2f, bitmap.height / 2f)
        matrix.postRotate(imageProxy.imageInfo.rotationDegrees.toFloat())
        
        val rotatedBitmap = Bitmap.createBitmap(
            bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true
        )

        val mpImage = BitmapImageBuilder(rotatedBitmap).build()
        val timestamp = System.currentTimeMillis()
        
        faceLandmarker?.detectAsync(mpImage, timestamp)
        imageProxy.close()
    }

    private fun onFaceLandmarkerResult(result: FaceLandmarkerResult, mpImage: MPImage) {
        if (result.faceLandmarks().isEmpty()) return

        val landmarks = result.faceLandmarks()[0]
        
        // Compute Iris Center (Landmarks 468 = right iris center, 473 = left iris center)
        val rightIris = landmarks[468]
        val leftIris = landmarks[473]

        // Map Gaze Coordinates
        // This calculates an average gaze point using the iris relative to the face
        val gazeX = 1.0f - ((rightIris.x() + leftIris.x()) / 2f)
        val gazeY = (rightIris.y() + leftIris.y()) / 2f

        // EAR Calculation (Right Eye: 33, 160, 158, 133, 153, 144)
        val p1 = landmarks[33]
        val p2 = landmarks[160]
        val p3 = landmarks[158]
        val p4 = landmarks[133]
        val p5 = landmarks[153]
        val p6 = landmarks[144]

        val ear = (dist(p2, p6) + dist(p3, p5)) / (2.0 * dist(p1, p4))
        
        val blinkType = handleBlink(ear)

        val json = JSONObject()
        json.put("x", gazeX)
        json.put("y", gazeY)
        json.put("blink", blinkType)

        runOnUiThread {
            eventSink?.success(json.toString())
        }
    }

    private fun dist(p1: com.google.mediapipe.tasks.components.containers.NormalizedLandmark, 
                     p2: com.google.mediapipe.tasks.components.containers.NormalizedLandmark): Double {
        val dx = p1.x() - p2.x()
        val dy = p1.y() - p2.y()
        return sqrt((dx * dx + dy * dy).toDouble())
    }

    private fun handleBlink(ear: Double): String {
        val now = System.currentTimeMillis()
        var blinkType = "none"

        val closed = ear < closedThreshold
        val open = ear > openThreshold

        if (closed && !eyeClosed) {
            eyeClosed = true
            closedStart = now
        } else if (open && eyeClosed) {
            eyeClosed = false
            val dur = now - closedStart

            // Blink validity window
            if (dur in 70..480) {
                // Min inter-blink
                if (pulses.isEmpty() || now - pulses.last() >= 120) {
                    pulses.add(now)
                    quietDeadline = now + 430
                }
            }
        }

        if (pulses.isNotEmpty() && now > quietDeadline) {
            val count = pulses.size
            pulses.clear()
            lastEmittedAt = now

            blinkType = when {
                count >= 3 -> "triple"
                count == 2 -> "double"
                else -> "single"
            }
        }

        return blinkType
    }
}
