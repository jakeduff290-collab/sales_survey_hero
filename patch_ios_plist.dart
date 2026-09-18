import 'dart:io';
void main() {
  var file = File('ios/Runner/Info.plist');
  if (file.existsSync()) {
    var content = file.readAsStringSync();
    if (!content.contains('NSCameraUsageDescription')) {
      content = content.replaceFirst(
        '<dict>',
        '<dict>\n\t<key>NSCameraUsageDescription</key>\n\t<string>Required to scan utility bills.</string>\n\t<key>NSMicrophoneUsageDescription</key>\n\t<string>Required for camera plugin.</string>'
      );
      file.writeAsStringSync(content);
      print("*** iOS PERMISSIONS INJECTED ***");
    }
  }
}
