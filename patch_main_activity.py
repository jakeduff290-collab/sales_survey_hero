path = 'android/app/src/main/kotlin/com/example/sales_survey_hero/MainActivity.kt'

code = '''package com.example.sales_survey_hero

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.survey_hero/service"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "startCamera") {
                val intent = Intent(this, FloatingCameraService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    startForegroundService(intent)
                } else {
                    startService(intent)
                }
                result.success("Camera Service Started")
            } else {
                result.notImplemented()
            }
        }
    }
}
'''

with open(path, 'w') as f:
    f.write(code)

print("MainActivity patched for Flutter MethodChannel!")
