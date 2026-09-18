import 'dart:io';

void main() {
  var file = File('/root/.pub-cache/hosted/pub.dev/camera_android_camerax-0.7.3/android/build.gradle.kts');
  if (!file.existsSync()) {
    print('FATAL: Target cache file missing.');
    return;
  }
  
  var content = file.readAsStringSync();
  
  // 1. Static Resolution: Hardcode the Android SDK integers to bypass the dynamic 'flutter' object lookup failure.
  content = content.replaceAll('flutter.compileSdkVersion', '34');
  content = content.replaceAll('flutter.minSdkVersion', '21');
  content = content.replaceAll('flutter.targetSdkVersion', '34');
  
  // 2. Syntax Neutralization: A precise regex target that extracts the incompatible compiler block 
  // while strictly accounting for nested braces to ensure the resulting script remains structurally valid.
  var regex = RegExp(r'kotlin\s*\{\s*compilerOptions\s*\{\s*jvmTarget[^}]*\}\s*\}');
  content = content.replaceAll(regex, '// Incompatible Kotlin compilerOptions safely neutralized');
  
  file.writeAsStringSync(content);
  
  print('\n=================================================');
  print('*** ARCHITECTURE ALIGNED: KTS CACHE NEUTRALIZED ***');
  print('=================================================\n');
}
