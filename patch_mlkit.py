import re

# 1. Add ML Kit Dependency to Gradle
gradle_path = 'android/app/build.gradle'
with open(gradle_path, 'r') as f:
    gradle_code = f.read()

if 'play-services-mlkit-text-recognition' not in gradle_code:
    gradle_code = gradle_code.replace('dependencies {', 'dependencies {\n    implementation "com.google.android.gms:play-services-mlkit-text-recognition:19.0.0"\n')
    with open(gradle_path, 'w') as f:
        f.write(gradle_code)

# 2. Embed ML Kit directly into the Background Service
kt_path = 'android/app/src/main/kotlin/com/example/sales_survey_hero/FloatingCameraService.kt'
with open(kt_path, 'r') as f:
    kt_code = f.read()

imports = """
import android.os.Handler
import android.os.Looper
import android.net.Uri
import android.content.ClipboardManager
import android.content.ClipData
import android.content.Context
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import com.google.mlkit.vision.common.InputImage
"""

if 'com.google.mlkit.vision.text.TextRecognition' not in kt_code:
    kt_code = kt_code.replace('package com.example.sales_survey_hero', 'package com.example.sales_survey_hero\n' + imports)

# 3. Fix the threading, apply Title Case, and copy to Clipboard
old_take_photo_regex = r'private fun takePhoto\(\).*?private fun takePhotoForGallery\(\)'

new_take_photo = """private fun takePhoto() {
        Handler(Looper.getMainLooper()).post { 
            Toast.makeText(this@FloatingCameraService, "Extracting...", Toast.LENGTH_SHORT).show() 
        }
        val photoFile = File(getExternalFilesDir(Environment.DIRECTORY_PICTURES), "scan_${System.currentTimeMillis()}.jpg")
        val outputOptions = androidx.camera.core.ImageCapture.OutputFileOptions.Builder(photoFile).build()
        
        photoCapture?.takePicture(outputOptions, ContextCompat.getMainExecutor(this),
            object : androidx.camera.core.ImageCapture.OnImageSavedCallback {
                override fun onError(exc: androidx.camera.core.ImageCaptureException) {
                    Handler(Looper.getMainLooper()).post { 
                        Toast.makeText(this@FloatingCameraService, "Capture Failed", Toast.LENGTH_SHORT).show() 
                    }
                }
                override fun onImageSaved(output: androidx.camera.core.ImageCapture.OutputFileResults) {
                    try {
                        val image = InputImage.fromFilePath(this@FloatingCameraService, Uri.fromFile(photoFile))
                        val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
                        
                        recognizer.process(image)
                            .addOnSuccessListener { visionText ->
                                val formattedText = toTitleCase(visionText.text)
                                val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                                val clip = ClipData.newPlainText("Extracted Data", formattedText)
                                clipboard.setPrimaryClip(clip)
                                
                                Handler(Looper.getMainLooper()).post { 
                                    Toast.makeText(this@FloatingCameraService, "Finished! Ready to Paste.", Toast.LENGTH_LONG).show() 
                                }
                            }
                            .addOnFailureListener { 
                                Handler(Looper.getMainLooper()).post { 
                                    Toast.makeText(this@FloatingCameraService, "OCR Failed", Toast.LENGTH_SHORT).show() 
                                }
                            }
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
            })
    }

    private fun takePhotoForGallery()"""

kt_code = re.sub(old_take_photo_regex, new_take_photo, kt_code, flags=re.DOTALL)

with open(kt_path, 'w') as f:
    f.write(kt_code)

print("Patch applied successfully.")
