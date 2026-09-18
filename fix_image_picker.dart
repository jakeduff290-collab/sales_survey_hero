import 'dart:io';

void main() {
  var file = File('/root/.pub-cache/hosted/pub.dev/image_picker_android-0.8.13+23/android/build.gradle.kts');
  if (!file.existsSync()) {
    print('FATAL: Target cache file missing.');
    return;
  }
  
  var content = file.readAsStringSync();
  
  // 1. Hardcode SDK versions
  content = content.replaceAll('flutter.compileSdkVersion', '34');
  content = content.replaceAll('flutter.minSdkVersion', '21');
  content = content.replaceAll('flutter.targetSdkVersion', '34');
  
  // 2. Neutralize modern Kotlin compiler syntax
  var regex = RegExp(r'kotlin\s*\{\s*compilerOptions\s*\{\s*jvmTarget[^}]*\}\s*\}');
  content = content.replaceAll(regex, '// Incompatible Kotlin compilerOptions safely neutralized');
  
  file.writeAsStringSync(content);
  
  print('\n=================================================');
  print('*** IMAGE PICKER PLUGIN PATCHED ***');
  print('=================================================\n');
}
