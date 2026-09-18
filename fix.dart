import 'dart:io';

void main() {
  var f = File('android/app/src/main/kotlin/com/example/sales_survey_hero/FloatingCameraService.kt');
  var c = f.readAsStringSync();
  
  // 1. Nuke the mangled Termux code from previous attempts
  c = c.replaceAll(RegExp(r'try\s*\{\s*val prefs[\s\S]*?\} catch \(e: Exception\) \{\}'), '');
  
  // 2. The target insertion point
  var target = 'val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager';
  
  // 3. The tracker, structured as a contiguous string so Termux doesn't drop characters
  var tracker = 'try { val prefs = applicationContext.getSharedPreferences("FlutterSharedPreferences", android.content.Context.MODE_PRIVATE); ' +
                'val company = prefs.getString("flutter.company_code", null); ' +
                'val username = prefs.getString("flutter.username", null); ' +
                'if (company != null && username != null) { ' +
                'com.google.firebase.firestore.FirebaseFirestore.getInstance().collection("companies").document(company).collection("reps").document(username)' +
                '.set(mapOf("total_scans" to com.google.firebase.firestore.FieldValue.increment(1), "last_active" to com.google.firebase.firestore.FieldValue.serverTimestamp()), com.google.firebase.firestore.SetOptions.merge())' +
                '.addOnSuccessListener { android.widget.Toast.makeText(applicationContext, "🔥 ROI TRACKER LOGGED!", android.widget.Toast.LENGTH_LONG).show() } } } catch (e: Exception) {}';
  
  // 4. Inject and save
  f.writeAsStringSync(c.replaceFirst(target, tracker + '\n                                            ' + target));
  print('\n=========================================');
  print('*** KOTLIN FILE FIXED AND TRACKER INJECTED ***');
  print('=========================================\n');
}
