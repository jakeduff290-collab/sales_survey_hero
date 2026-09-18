import 'dart:io';

void main() {
  var file = File('android/app/src/main/kotlin/com/example/sales_survey_hero/FloatingCameraService.kt');
  var code = file.readAsStringSync();
  
  // Find the exact line where the app copies the text to the clipboard
  var target = 'val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager';
  
  // The database tracker code, using absolute paths so Android doesn't complain about missing imports
  var trackerCode = '''
                                            try {
                                                val prefs = applicationContext.getSharedPreferences("FlutterSharedPreferences", android.content.Context.MODE_PRIVATE)
                                                val company = prefs.getString("flutter.company_code", null)
                                                val username = prefs.getString("flutter.username", null)
                                                
                                                if (company != null && username != null) {
                                                    com.google.firebase.firestore.FirebaseFirestore.getInstance()
                                                        .collection("companies").document(company)
                                                        .collection("reps").document(username)
                                                        .set(mapOf(
                                                            "total_scans" to com.google.firebase.firestore.FieldValue.increment(1),
                                                            "last_active" to com.google.firebase.firestore.FieldValue.serverTimestamp()
                                                        ), com.google.firebase.firestore.SetOptions.merge())
                                                        .addOnSuccessListener {
                                                            android.widget.Toast.makeText(applicationContext, "🔥 Tracker: +1 Logged!", android.widget.Toast.LENGTH_LONG).show()
                                                        }
                                                }
                                            } catch (e: Exception) {}
  ''';

  if (!code.contains('Tracker: +1 Logged!')) {
    file.writeAsStringSync(code.replaceFirst(target, trackerCode + '\n                                            ' + target));
    print('\n=========================================');
    print('SUCCESS: Tracker surgically injected!');
    print('=========================================\n');
  } else {
    print('\n=========================================');
    print('Tracker already exists in the file.');
    print('=========================================\n');
  }
}
