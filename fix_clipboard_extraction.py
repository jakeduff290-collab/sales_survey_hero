import re
kt_path = 'android/app/src/main/kotlin/com/example/sales_survey_hero/FloatingCameraService.kt'
with open(kt_path, 'r') as f:
    kt_code = f.read()

new_take_photo = """private fun takePhoto() {
        Handler(Looper.getMainLooper()).post { 
            Toast.makeText(applicationContext, "Extracting...", Toast.LENGTH_SHORT).show() 
        }
        val photoFile = File(getExternalFilesDir(Environment.DIRECTORY_PICTURES), "scan_${System.currentTimeMillis()}.jpg")
        val outputOptions = androidx.camera.core.ImageCapture.OutputFileOptions.Builder(photoFile).build()
        
        photoCapture?.takePicture(outputOptions, ContextCompat.getMainExecutor(this),
            object : androidx.camera.core.ImageCapture.OnImageSavedCallback {
                override fun onError(exc: androidx.camera.core.ImageCaptureException) {
                    Handler(Looper.getMainLooper()).post { 
                        Toast.makeText(applicationContext, "Capture Failed", Toast.LENGTH_SHORT).show() 
                    }
                }
                override fun onImageSaved(output: androidx.camera.core.ImageCapture.OutputFileResults) {
                    try {
                        val image = InputImage.fromFilePath(applicationContext, Uri.fromFile(photoFile))
                        val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
                        
                        recognizer.process(image)
                            .addOnSuccessListener { visionText ->
                                val rawText = visionText.text.trim()
                                val formattedText = if (rawText.isNotEmpty()) toTitleCase(rawText) else "No text detected"
                                
                                Handler(Looper.getMainLooper()).post {
                                    try {
                                        // FOCUS HACK: Android blocks background clipboard access.
                                        // Give the floating window temporary focus, copy text, then remove focus.
                                        val params = camRoot.layoutParams as WindowManager.LayoutParams
                                        params.flags = params.flags and WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE.inv()
                                        windowManager.updateViewLayout(camRoot, params)
                                        
                                        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                                        val clip = ClipData.newPlainText("Extracted Data", formattedText)
                                        clipboard.setPrimaryClip(clip)
                                        
                                        params.flags = params.flags or WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                                        windowManager.updateViewLayout(camRoot, params)
                                        
                                        // Display the exact text so we PROVE the extraction worked
                                        Toast.makeText(applicationContext, "Copied: $formattedText", Toast.LENGTH_LONG).show() 
                                    } catch (e: Exception) {
                                        Toast.makeText(applicationContext, "Clipboard Error: $formattedText", Toast.LENGTH_LONG).show()
                                    }
                                }
                            }
                            .addOnFailureListener { 
                                Handler(Looper.getMainLooper()).post { 
                                    Toast.makeText(applicationContext, "OCR Failed", Toast.LENGTH_SHORT).show() 
                                }
                            }
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
            })
    }"""
    
old_regex = r'private fun takePhoto\(\).*?(?=private fun takePhotoForGallery\(\))'
kt_code = re.sub(old_regex, new_take_photo + '\n\n    ', kt_code, flags=re.DOTALL)
    
with open(kt_path, 'w') as f:
    f.write(kt_code)
