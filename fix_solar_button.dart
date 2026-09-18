import 'dart:io';

void main() {
  var file = File('android/app/src/main/kotlin/com/example/sales_survey_hero/FloatingCameraService.kt');
  var content = file.readAsStringSync();
  
  // 1. Add the new Solar Gemini Prompt right below the Gas one
  content = content.replaceFirst(
    'private val extractionPrompt =',
    'private val solarPrompt = """You are a residential solar data extractor. Analyze this utility bill and extract only the following JSON data. Return NO OTHER TEXT.\n- "customer_name": The account holder\'s name\n- "monthly_kwh": The total electricity usage for this month in kWh\n- "current_rate_plan": The name of the utility rate plan (e.g., TOU-D-PRIME)\n- "annual_true_up": If present, the current NEM balance"""\n\n    private val extractionPrompt ='
  );

  // 2. Shrink the Gas button and inject the Solar button UI
  content = content.replaceFirst(
    'val extractBtn = View(this).apply { background = GradientDrawable().apply { shape = GradientDrawable.OVAL; setColor(Color.parseColor("#E2F952")); setStroke(6, Color.WHITE) }; layoutParams = FrameLayout.LayoutParams(100, 100).apply { gravity = Gravity.BOTTOM or Gravity.END; bottomMargin = 40; rightMargin = 40 }; setOnClickListener { takePhoto() } }',
    'val extractBtn = View(this).apply { background = GradientDrawable().apply { shape = GradientDrawable.OVAL; setColor(Color.parseColor("#E2F952")); setStroke(6, Color.WHITE) }; layoutParams = FrameLayout.LayoutParams(80, 80).apply { gravity = Gravity.BOTTOM or Gravity.END; bottomMargin = 40; rightMargin = 140 }; setOnClickListener { takePhoto() } }\n        val solarBtn = View(this).apply { background = GradientDrawable().apply { shape = GradientDrawable.OVAL; setColor(Color.parseColor("#00BFFF")); setStroke(6, Color.WHITE) }; layoutParams = FrameLayout.LayoutParams(80, 80).apply { gravity = Gravity.BOTTOM or Gravity.END; bottomMargin = 40; rightMargin = 40 }; setOnClickListener { takePhotoForSolar() } }'
  );
  
  // 3. Add the Solar button to the rendering tree
  content = content.replaceFirst(
    'expandedView.addView(extractBtn);',
    'expandedView.addView(extractBtn); animateClick(solarBtn); expandedView.addView(solarBtn);'
  );

  // 4. Duplicate the takePhoto function specifically for the Solar prompt
  var takePhotoBlock = '''
    private fun takePhotoForSolar() {
        Handler(Looper.getMainLooper()).post { Toast.makeText(applicationContext, "Extracting Solar...", Toast.LENGTH_SHORT).show() }
        val photoFile = File(getExternalFilesDir(Environment.DIRECTORY_PICTURES), "scan_\${System.currentTimeMillis()}.jpg")
        photoCapture?.takePicture(androidx.camera.core.ImageCapture.OutputFileOptions.Builder(photoFile).build(), ContextCompat.getMainExecutor(this),
            object : androidx.camera.core.ImageCapture.OnImageSavedCallback {
                override fun onError(exc: androidx.camera.core.ImageCaptureException) { Handler(Looper.getMainLooper()).post { Toast.makeText(applicationContext, "Capture Failed", Toast.LENGTH_SHORT).show() } }
                override fun onImageSaved(output: androidx.camera.core.ImageCapture.OutputFileResults) {
                    try {
                        TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS).process(InputImage.fromFilePath(applicationContext, Uri.fromFile(photoFile)))
                            .addOnSuccessListener { visionText ->
                                val rawText = visionText.text.trim()
                                if (rawText.isEmpty()) { Handler(Looper.getMainLooper()).post { Toast.makeText(applicationContext, "No text detected", Toast.LENGTH_SHORT).show() }; return@addOnSuccessListener }
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
                                            Toast.makeText(applicationContext, "\$label\${formattedText.take(40)}...", Toast.LENGTH_LONG).show()
                                        } catch (e: Exception) {}
                                    }
                                }
                            }
                    } catch (e: Exception) {}
                }
            }
        )
    }
''';
  
  content = content.replaceFirst('private fun takePhoto()', takePhotoBlock + '\n    private fun takePhoto()');
  
  file.writeAsStringSync(content);
  print('\n*** SOLAR PIPELINE INJECTED ***\n');
}
