import 'dart:io';

void main() {
  // 1. Clean up the project-level file where the error is
  var projFile = File('android/build.gradle.kts');
  if (!projFile.existsSync()) projFile = File('android/build.gradle');
  if (projFile.existsSync()) {
    var lines = projFile.readAsLinesSync();
    lines.removeWhere((l) => l.contains('firebase-firestore-ktx'));
    projFile.writeAsStringSync(lines.join('\n'));
  }

  // 2. Inject it properly into the app-level dependencies block
  var appFile = File('android/app/build.gradle');
  var isKts = false;
  if (!appFile.existsSync()) {
    appFile = File('android/app/build.gradle.kts');
    isKts = true;
  }
  
  if (appFile.existsSync()) {
    var lines = appFile.readAsLinesSync();
    lines.removeWhere((l) => l.contains('firebase-firestore-ktx')); // Clean old mistakes
    
    var depIndex = lines.indexWhere((l) => l.trim().startsWith('dependencies {'));
    if (depIndex != -1) {
      if (isKts) {
        lines.insert(depIndex + 1, '    implementation("com.google.firebase:firebase-firestore")');
      } else {
        lines.insert(depIndex + 1, '    implementation "com.google.firebase:firebase-firestore"');
      }
    }
    appFile.writeAsStringSync(lines.join('\n'));
  }
  
  print('\n=========================================');
  print('*** GRADLE FILES FIXED ***');
  print('=========================================\n');
}
