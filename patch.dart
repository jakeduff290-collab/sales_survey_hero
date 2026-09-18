import 'dart:io';

void main() {
  var f = File('android/app/src/main/kotlin/com/example/sales_survey_hero/FloatingCameraService.kt');
  var c = f.readAsStringSync();
  
  var code = '''
                                        try {
                                            val prefs = applicationContext.getSharedPreferences("FlutterSharedPreferences", android.content.Context.MODE_PRIVATE)
                                            val company = prefs.getString("flutter.company_code", null)
                                            val username = prefs.getString("flutter.username", null)
                                            if (company != null && username != null) {
                                                com.google.firebase.firestore.FirebaseFirestore.getInstance().collection("companies").document(company).collection("reps").document(username).set(mapOf("total_scans" to com.google.firebase.firestore.FieldValue.increment(1), "last_active" to com.google.firebase.firestore.FieldValue.serverTimestamp()), com.google.firebase.firestore.SetOptions.merge()).addOnSuccessListener {
                                                    android.widget.Toast.makeText(applicationContext, "Tracker: +1 Logged!", android.widget.Toast.LENGTH_SHORT).show()
                                                }
                                            }
                                        } catch (e: Exception) {}
''';

  if (!c.contains('Tracker: +1 Logged!')) {
    f.writeAsStringSync(c.replaceAll('lastExtractedText = formattedText', 'lastExtractedText = formattedText\n' + code));
    print('SUCCESS: Tracker surgically injected!');
  } else {
    print('Tracker already injected!');
  }
}
