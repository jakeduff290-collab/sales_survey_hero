import 'dart:io';
void main() {
  var file = File('android/app/build.gradle');
  if (!file.existsSync()) file = File('android/app/build.gradle.kts');
  if (file.existsSync()) {
    var content = file.readAsStringSync();
    var customDeps = '''
    implementation("androidx.camera:camera-core:1.3.1")
    implementation("androidx.camera:camera-camera2:1.3.1")
    implementation("androidx.camera:camera-lifecycle:1.3.1")
    implementation("androidx.camera:camera-view:1.3.1")
    implementation("com.google.mlkit:text-recognition:16.0.0")
    implementation("com.google.firebase:firebase-config")
    implementation("com.google.firebase:firebase-firestore")
    ''';
    if (!content.contains('androidx.camera:camera-core')) {
      content = content.replaceFirst('dependencies {', 'dependencies {\n' + customDeps);
      file.writeAsStringSync(content);
    }
    print("Dependencies injected!");
  }
}
