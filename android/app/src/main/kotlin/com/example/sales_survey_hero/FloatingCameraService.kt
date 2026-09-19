package com.example.sales_survey_hero

import android.app.*
import android.content.*
import android.graphics.*
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.os.*
import android.provider.MediaStore
import android.view.*
import android.widget.*
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import androidx.lifecycle.*
import com.google.firebase.Firebase
import com.google.firebase.remoteconfig.*
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import com.google.firebase.firestore.*
import org.json.*
import java.io.File
import java.net.*
import java.util.concurrent.*

class FloatingCameraService : Service(), LifecycleOwner {
    private lateinit var windowManager: WindowManager
    private lateinit var camRoot: FrameLayout
    private lateinit var pasteRoot: FrameLayout
    private var photoCapture: androidx.camera.core.ImageCapture? = null
    private lateinit var cameraExecutor: ExecutorService
    private val lifecycleRegistry = LifecycleRegistry(this)
    override val lifecycle: Lifecycle get() = lifecycleRegistry
    override fun onBind(intent: Intent?): IBinder? = null
    private val remoteConfig by lazy { Firebase.remoteConfig }
    private var extractionPrompt: String = ""
    private var lastExtractedText: String = ""

    companion object {
        private const val GEMINI_MODEL = "gemini-3.1-pro-preview"
        private const val DEFAULT_PROMPT = "Extract Full Name, Service Address, and Account Number."
        private const val SYSTEM_INSTRUCTION = "You are a high-speed data parser for CRM entry. Extract ONLY the fields requested in the instructions given. Output format: Return ONLY the exact extracted values, in the same order they were requested, separated by a double pipe \"||\". Do not include labels, keys, or any conversational text. If a field is not found, output an empty space."
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        intent?.getStringExtra("extraction_prompt")?.let { extractionPrompt = it }
        return super.onStartCommand(intent, flags, startId)
    }

    override fun onCreate() {
        super.onCreate()
        lifecycleRegistry.handleLifecycleEvent(Lifecycle.Event.ON_CREATE)
        lifecycleRegistry.handleLifecycleEvent(Lifecycle.Event.ON_START)
        lifecycleRegistry.handleLifecycleEvent(Lifecycle.Event.ON_RESUME)
        cameraExecutor = Executors.newSingleThreadExecutor()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        remoteConfig.setConfigSettingsAsync(remoteConfigSettings { minimumFetchIntervalInSeconds = 3600 })
        remoteConfig.setDefaultsAsync(mapOf("gemini_api_key" to ""))
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel("hero_cam", "Survey Hero Active", NotificationManager.IMPORTANCE_LOW)
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
        startForeground(101, NotificationCompat.Builder(this, "hero_cam").setContentTitle("Survey Hero Active").setSmallIcon(android.R.drawable.ic_menu_camera).build())
        val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY else WindowManager.LayoutParams.TYPE_PHONE
        setupCameraWidget(layoutType)
        setupPasteWidget(layoutType)
    }

    private fun animateClick(view: View) {
        view.setOnTouchListener { v, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> v.alpha = 0.5f
                MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> v.alpha = 1.0f
            }
            false
        }
    }

    private fun setupCameraWidget(layoutType: Int) {
        val camParams = WindowManager.LayoutParams(450, 600, layoutType, WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE, PixelFormat.TRANSLUCENT).apply { gravity = Gravity.TOP or Gravity.START; x = 30; y = 200 }
        camRoot = FrameLayout(this)
        val expandedView = FrameLayout(this).apply { setPadding(12, 12, 12, 12); background = GradientDrawable().apply { setColor(Color.TRANSPARENT); cornerRadius = 45f; setStroke(6, Color.parseColor("#E2F952")) } }
        val previewView = androidx.camera.view.PreviewView(this).apply {
            layoutParams = FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT)
            outlineProvider = object : ViewOutlineProvider() { override fun getOutline(view: View, outline: Outline) { outline.setRoundRect(0, 0, view.width, view.height, 40f) } }
            clipToOutline = true
        }
        val closeBtn = TextView(this).apply { text = "✕"; gravity = Gravity.CENTER; textSize = 22f; setTextColor(Color.parseColor("#FF4C4C")); layoutParams = FrameLayout.LayoutParams(100, 100).apply { gravity = Gravity.TOP or Gravity.START; setMargins(40, 30, 0, 0) }; setOnClickListener { stopSelf() } }
        val galleryBtn = View(this).apply { background = GradientDrawable().apply { shape = GradientDrawable.OVAL; setColor(Color.WHITE); setStroke(6, Color.parseColor("#E2F952")) }; layoutParams = FrameLayout.LayoutParams(100, 100).apply { gravity = Gravity.BOTTOM or Gravity.START; bottomMargin = 40; leftMargin = 40 }; setOnClickListener { takePhotoForGallery() } }
        val extractBtn = View(this).apply { background = GradientDrawable().apply { shape = GradientDrawable.OVAL; setColor(Color.parseColor("#E2F952")); setStroke(6, Color.WHITE) }; layoutParams = FrameLayout.LayoutParams(80, 80).apply { gravity = Gravity.BOTTOM or Gravity.END; bottomMargin = 40; rightMargin = 140 }; setOnClickListener { takePhoto() } }
        val collapsedTab = Button(this).apply { text = "▶"; visibility = View.GONE; background = GradientDrawable().apply { setColor(Color.parseColor("#E2F952")); cornerRadii = floatArrayOf(0f,0f, 30f,30f, 30f,30f, 0f,0f) }; layoutParams = FrameLayout.LayoutParams(90, 150)
            setOnClickListener { expandedView.visibility = View.VISIBLE; this.visibility = View.GONE; camParams.width = 450; camParams.height = 600; windowManager.updateViewLayout(camRoot, camParams) }
        }
        expandedView.addView(previewView); expandedView.addView(closeBtn); animateClick(galleryBtn); expandedView.addView(galleryBtn); animateClick(extractBtn); expandedView.addView(extractBtn); camRoot.addView(expandedView); camRoot.addView(collapsedTab)
        var cX = 0; var cY = 0; var cTouchX = 0f; var cTouchY = 0f
        camRoot.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> { cX = camParams.x; cY = camParams.y; cTouchX = event.rawX; cTouchY = event.rawY; true }
                MotionEvent.ACTION_MOVE -> { camParams.x = cX + (event.rawX - cTouchX).toInt(); camParams.y = cY + (event.rawY - cTouchY).toInt(); windowManager.updateViewLayout(camRoot, camParams); true }
                MotionEvent.ACTION_UP -> { if (camParams.x < 50 && expandedView.visibility == View.VISIBLE) { expandedView.visibility = View.GONE; collapsedTab.visibility = View.VISIBLE; camParams.width = WindowManager.LayoutParams.WRAP_CONTENT; camParams.height = WindowManager.LayoutParams.WRAP_CONTENT; camParams.x = 0; windowManager.updateViewLayout(camRoot, camParams) }; true }
                else -> false
            }
        }
        windowManager.addView(camRoot, camParams)
        val cameraProviderFuture = androidx.camera.lifecycle.ProcessCameraProvider.getInstance(this)
        cameraProviderFuture.addListener({
            val cameraProvider = cameraProviderFuture.get(); val preview = androidx.camera.core.Preview.Builder().build().also { it.setSurfaceProvider(previewView.surfaceProvider) }; photoCapture = androidx.camera.core.ImageCapture.Builder().build()
            try { cameraProvider.unbindAll(); cameraProvider.bindToLifecycle(this, androidx.camera.core.CameraSelector.DEFAULT_BACK_CAMERA, preview, photoCapture) } catch (e: Exception) {}
        }, ContextCompat.getMainExecutor(this))
    }

    private fun setupPasteWidget(layoutType: Int) {
        val pasteParams = WindowManager.LayoutParams(WindowManager.LayoutParams.WRAP_CONTENT, WindowManager.LayoutParams.WRAP_CONTENT, layoutType, WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE, PixelFormat.TRANSLUCENT).apply { gravity = Gravity.TOP or Gravity.END; x = 30; y = 400 }
        pasteRoot = FrameLayout(this)
        val expandedView = Button(this).apply { text = "📋 PASTE"; setTextColor(Color.WHITE); textSize = 14f; background = GradientDrawable().apply { setColor(Color.parseColor("#1A1A1A")); cornerRadius = 25f; setStroke(4, Color.parseColor("#E2F952")) }; layoutParams = FrameLayout.LayoutParams(FrameLayout.LayoutParams.WRAP_CONTENT, 120); setPadding(40, 0, 40, 0)
            setOnClickListener { val intent = Intent("com.survey_hero.EXECUTE_AUTO_FILL"); intent.putExtra("survey_data", lastExtractedText); sendBroadcast(intent) }
        }
        val collapsedTab = Button(this).apply { text = "◀"; visibility = View.GONE; background = GradientDrawable().apply { setColor(Color.parseColor("#E2F952")); cornerRadii = floatArrayOf(30f,30f, 0f,0f, 0f,0f, 30f,30f) }; layoutParams = FrameLayout.LayoutParams(90, 150)
            setOnClickListener { expandedView.visibility = View.VISIBLE; this.visibility = View.GONE; pasteParams.x = 30; windowManager.updateViewLayout(pasteRoot, pasteParams) }
        }
        pasteRoot.addView(expandedView); pasteRoot.addView(collapsedTab)
        var pX = 0; var pY = 0; var pTouchX = 0f; var pTouchY = 0f
        pasteRoot.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> { pX = pasteParams.x; pY = pasteParams.y; pTouchX = event.rawX; pTouchY = event.rawY; false }
                MotionEvent.ACTION_MOVE -> { pasteParams.x = pX - (event.rawX - pTouchX).toInt(); pasteParams.y = pY + (event.rawY - pTouchY).toInt(); windowManager.updateViewLayout(pasteRoot, pasteParams); true }
                MotionEvent.ACTION_UP -> { if (pasteParams.x < 50 && expandedView.visibility == View.VISIBLE) { expandedView.visibility = View.GONE; collapsedTab.visibility = View.VISIBLE; pasteParams.x = 0; windowManager.updateViewLayout(pasteRoot, pasteParams) }; true }
                else -> false
            }
        }
        windowManager.addView(pasteRoot, pasteParams)
    }

    private fun logScanToDatabase() {
        try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val company = prefs.getString("flutter.company_code", null)
            val username = prefs.getString("flutter.username", null)
            if (company != null && username != null) {
                FirebaseFirestore.getInstance().collection("companies").document(company).collection("reps").document(username).set(mapOf("total_scans" to FieldValue.increment(1), "last_active" to FieldValue.serverTimestamp()), SetOptions.merge())
                    .addOnSuccessListener { Handler(Looper.getMainLooper()).post { Toast.makeText(applicationContext, "🔥 ROI TRACKER LOGGED!", Toast.LENGTH_LONG).show() } }
            }
        } catch (e: Exception) {}
    }

        private fun takePhotoForSolar() {
        Handler(Looper.getMainLooper()).post { Toast.makeText(applicationContext, "Extracting Solar...", Toast.LENGTH_SHORT).show() }
        val photoFile = File(getExternalFilesDir(Environment.DIRECTORY_PICTURES), "scan_${System.currentTimeMillis()}.jpg")
        photoCapture?.takePicture(androidx.camera.core.ImageCapture.OutputFileOptions.Builder(photoFile).build(), ContextCompat.getMainExecutor(this),
            object : androidx.camera.core.ImageCapture.OnImageSavedCallback {
                override fun onError(exc: androidx.camera.core.ImageCaptureException) { Handler(Looper.getMainLooper()).post { Toast.makeText(applicationContext, "Capture Failed", Toast.LENGTH_SHORT).show() } }
                override fun onImageSaved(output: androidx.camera.core.ImageCapture.OutputFileResults) {
                    try {
                        TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS).process(InputImage.fromFilePath(applicationContext, Uri.fromFile(photoFile)))
                            .addOnSuccessListener { visionText ->
                                val rawText = visionText.text.trim()
                                if (rawText.isEmpty()) { Handler(Looper.getMainLooper()).post { Toast.makeText(applicationContext, "No text detected", Toast.LENGTH_SHORT).show() }; return@addOnSuccessListener }
                                                                val solarPrompt = """You are a residential solar data extractor. Analyze this utility bill and extract only the following JSON data. Return NO OTHER TEXT.
- "customer_name": The account holder's name
- "monthly_kwh": The total electricity usage for this month in kWh
- "current_rate_plan": The name of the utility rate plan (e.g., TOU-D-PRIME)
- "annual_true_up": If present, the current NEM balance"""
                                extractWithGemini(rawText, solarPrompt) { formattedText, usedFallback ->
                                    logScanToDatabase()
                                    Handler(Looper.getMainLooper()).post {
                                        lastExtractedText = formattedText
                                        try {
                                            val params = camRoot.layoutParams as WindowManager.LayoutParams
                                            params.flags = params.flags and WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE.inv()
                                            windowManager.updateViewLayout(camRoot, params)
                                            (getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager).setPrimaryClip(ClipData.newPlainText("Solar Data", formattedText))
                                            params.flags = params.flags or WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                                            windowManager.updateViewLayout(camRoot, params)
                                            val label = if (usedFallback) "Copied (offline): " else "Copied: "
                                            Toast.makeText(applicationContext, "$label${formattedText.take(40)}...", Toast.LENGTH_LONG).show()
                                        } catch (e: Exception) {}
                                    }
                                }
                            }
                    } catch (e: Exception) {}
                }
            }
        )
    }

    private fun takePhoto() {
        Handler(Looper.getMainLooper()).post { Toast.makeText(applicationContext, "Extracting...", Toast.LENGTH_SHORT).show() }
        val photoFile = File(getExternalFilesDir(Environment.DIRECTORY_PICTURES), "scan_${System.currentTimeMillis()}.jpg")
        photoCapture?.takePicture(androidx.camera.core.ImageCapture.OutputFileOptions.Builder(photoFile).build(), ContextCompat.getMainExecutor(this),
            object : androidx.camera.core.ImageCapture.OnImageSavedCallback {
                override fun onError(exc: androidx.camera.core.ImageCaptureException) { Handler(Looper.getMainLooper()).post { Toast.makeText(applicationContext, "Capture Failed", Toast.LENGTH_SHORT).show() } }
                override fun onImageSaved(output: androidx.camera.core.ImageCapture.OutputFileResults) {
                    try {
                        TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS).process(InputImage.fromFilePath(applicationContext, Uri.fromFile(photoFile)))
                            .addOnSuccessListener { visionText ->
                                val rawText = visionText.text.trim()
                                if (rawText.isEmpty()) { Handler(Looper.getMainLooper()).post { Toast.makeText(applicationContext, "No text detected", Toast.LENGTH_SHORT).show() }; return@addOnSuccessListener }
                                extractWithGemini(rawText, extractionPrompt) { formattedText, usedFallback ->
                                    logScanToDatabase()
                                    Handler(Looper.getMainLooper()).post {
                                        lastExtractedText = formattedText
                                        try {
                                            val params = camRoot.layoutParams as WindowManager.LayoutParams
                                            params.flags = params.flags and WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE.inv()
                                            windowManager.updateViewLayout(camRoot, params)
                                            (getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager).setPrimaryClip(ClipData.newPlainText("Extracted Data", formattedText))
                                            params.flags = params.flags or WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                                            windowManager.updateViewLayout(camRoot, params)
                                            val label = if (usedFallback) "Copied (offline): " else "Copied: "
                                            Toast.makeText(applicationContext, "$label${formattedText.take(40)}...", Toast.LENGTH_LONG).show()
                                        } catch (e: Exception) {}
                                    }
                                }
                            }
                    } catch (e: Exception) {}
                }
            })
    }

    private fun takePhotoForGallery() {}
    override fun onDestroy() { super.onDestroy(); lifecycleRegistry.handleLifecycleEvent(Lifecycle.Event.ON_DESTROY); try { windowManager.removeView(camRoot); windowManager.removeView(pasteRoot) } catch (e: Exception) {}; cameraExecutor.shutdown() }
    
    private fun extractWithGemini(rawOcrText: String, prompt: String, callback: (String, Boolean) -> Unit) {
        remoteConfig.fetchAndActivate().addOnCompleteListener {
            val apiKey = remoteConfig.getString("gemini_api_key")
            if (apiKey.isBlank()) { callback(parseWithFixedTemplate(toTitleCase(rawOcrText)), true); return@addOnCompleteListener }
            cameraExecutor.execute {
                val result = callGeminiApi(apiKey, rawOcrText, prompt)
                if (result != null) callback(result, false) else callback(parseWithFixedTemplate(toTitleCase(rawOcrText)), true)
            }
        }
    }
    
    private fun callGeminiApi(apiKey: String, rawOcrText: String, prompt: String): String? {
        return try {
            val fieldInstruction = if (prompt.isNotBlank()) prompt else DEFAULT_PROMPT
            val reqBody = JSONObject().apply { put("system_instruction", JSONObject().apply { put("parts", JSONArray().put(JSONObject().put("text", SYSTEM_INSTRUCTION))) }); put("contents", JSONArray().put(JSONObject().apply { put("parts", JSONArray().put(JSONObject().put("text", "Instructions:\n$fieldInstruction\n\n=== RAW OCR TEXT ===\n$rawOcrText\n=== END ==="))) })) }
            val conn = URL("https://generativelanguage.googleapis.com/v1beta/models/$GEMINI_MODEL:generateContent?key=$apiKey").openConnection() as HttpURLConnection
            conn.requestMethod = "POST"; conn.setRequestProperty("Content-Type", "application/json"); conn.doOutput = true; conn.connectTimeout = 15000; conn.readTimeout = 15000; conn.outputStream.use { it.write(reqBody.toString().toByteArray()) }
            val respCode = conn.responseCode
            val stream = if (respCode in 200..299) conn.inputStream else conn.errorStream
            val respText = stream.bufferedReader().use { it.readText() }
            if (respCode !in 200..299) null else JSONObject(respText).getJSONArray("candidates").getJSONObject(0).getJSONObject("content").getJSONArray("parts").getJSONObject(0).getString("text").trim()
        } catch (e: Exception) { null }
    }
    
    private fun parseWithFixedTemplate(text: String): String {
        var name = ""; var address = ""; var account = ""
        try { Regex("Account Number\\s*([\\d\\s]+)", RegexOption.IGNORE_CASE).find(text)?.let { account = it.groupValues[1].replace(" ", "").trim() }
            Regex("Service For\\s*\\n(.*?)\\n(.*?)\\n(.*)", RegexOption.IGNORE_CASE).find(text)?.let { name = it.groupValues[1].trim(); address = (it.groupValues[2].trim() + ", " + it.groupValues[3].trim()).take(30) }
        } catch (e: Exception) {}
        if (name.isEmpty() && account.isEmpty()) return text
        return "$name || $address || $account"
    }
    
    private fun toTitleCase(text: String): String { return text.lowercase().split(" ").joinToString(" ") { word -> word.replaceFirstChar { if (it.isLowerCase()) it.titlecase() else it.toString() } } }
}