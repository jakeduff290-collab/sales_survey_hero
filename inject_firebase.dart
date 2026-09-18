import 'dart:io';
void main() {
  var file = File('android/app/build.gradle');
  if (!file.existsSync()) file = File('android/app/build.gradle.kts');
  if (file.existsSync()) {
    var content = file.readAsStringSync();
    if (!content.contains('firebase-firestore')) {
      content = content.replaceFirst(
        'dependencies {', 
        'dependencies {\n    implementation("com.google.firebase:firebase-firestore")'
      );
      file.writeAsStringSync(content);
    }
  }
}
