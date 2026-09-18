import 'dart:io';

void main() {
  var f = File('pubspec.yaml');
  var c = f.readAsStringSync();
  
  if (!c.contains('camera_android_camerax: 0.7.3')) {
    if (c.contains('dependency_overrides:')) {
       c = c.replaceFirst('dependency_overrides:', 'dependency_overrides:\n  camera_android_camerax: 0.7.3');
    } else {
       c += '\ndependency_overrides:\n  camera_android_camerax: 0.7.3\n';
    }
    f.writeAsStringSync(c);
  }
  print('\n=========================================');
  print('*** CAMERA PLUGIN DOWNGRADED ***');
  print('=========================================\n');
}
