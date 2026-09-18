import 'dart:io';

void main() {
  var file = File('/root/.pub-cache/hosted/pub.dev/camera_android_camerax-0.7.3/android/build.gradle.kts');
  if (file.existsSync()) {
    var content = file.readAsStringSync();
    
    // Replace the block causing compilation errors
    content = content.replaceAll(
      RegExp(r'kotlin\s*\{\s*compilerOptions\s*\{[^}]*\}\s*\}', multiLine: true),
      '// kotlin options patched'
    );
    
    file.writeAsStringSync(content);
    print('\n*** CAMERA PLUGIN PATCHED SUCCESSFULLY ***\n');
  } else {
    print('Plugin file not found.');
  }
}
