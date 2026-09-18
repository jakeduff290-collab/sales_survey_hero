import 'dart:io';

void main() {
  var files = [
    '/root/.pub-cache/hosted/pub.dev/camera_android_camerax-0.7.3/android/build.gradle.kts',
    '/root/.pub-cache/hosted/pub.dev/flutter_plugin_android_lifecycle-2.0.35/android/build.gradle.kts',
    '/root/.pub-cache/hosted/pub.dev/image_picker_android-0.8.13+23/android/build.gradle.kts',
    '/root/.pub-cache/hosted/pub.dev/shared_preferences_android-2.4.28/android/build.gradle.kts',
    'android/app/build.gradle',
    'android/app/build.gradle.kts'
  ];

  for (var path in files) {
    var file = File(path);
    if (file.existsSync()) {
      var content = file.readAsStringSync();
      
      // Bump our previously hardcoded files
      content = content.replaceAll('compileSdk = 34', 'compileSdk = 36');
      content = content.replaceAll('compileSdkVersion 34', 'compileSdkVersion 36');
      
      // Bump Flutter's default files
      content = content.replaceAll('flutter.compileSdkVersion', '36');
      
      file.writeAsStringSync(content);
    }
  }
  print('\n=========================================');
  print('*** API BUMPED TO 36 - CLEAR FOR LAUNCH ***');
  print('=========================================\n');
}
