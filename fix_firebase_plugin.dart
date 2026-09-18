import 'dart:io';

void main() {
  var settingsFile = File('android/settings.gradle');
  if (!settingsFile.existsSync()) settingsFile = File('android/settings.gradle.kts');
  
  if (settingsFile.existsSync()) {
    var content = settingsFile.readAsStringSync();
    if (!content.contains('com.google.gms.google-services')) {
      if (settingsFile.path.endsWith('.kts')) {
        content = content.replaceFirst('plugins {', 'plugins {\n    id("com.google.gms.google-services") version "4.4.1" apply false');
      } else {
        content = content.replaceFirst('plugins {', 'plugins {\n    id "com.google.gms.google-services" version "4.4.1" apply false');
      }
      settingsFile.writeAsStringSync(content);
    }
  } else {
     var rootBuild = File('android/build.gradle');
     if (rootBuild.existsSync()) {
        var content = rootBuild.readAsStringSync();
        if (!content.contains('google-services')) {
            content = content.replaceFirst('dependencies {', 'dependencies {\n        classpath "com.google.gms:google-services:4.4.1"');
            rootBuild.writeAsStringSync(content);
        }
     }
  }

  var appFile = File('android/app/build.gradle');
  if (!appFile.existsSync()) appFile = File('android/app/build.gradle.kts');
  
  if (appFile.existsSync()) {
    var content = appFile.readAsStringSync();
    if (!content.contains('com.google.gms.google-services')) {
      if (appFile.path.endsWith('.kts')) {
        content = content.replaceFirst('plugins {', 'plugins {\n    id("com.google.gms.google-services")');
      } else {
        content = content.replaceFirst('plugins {', 'plugins {\n    id "com.google.gms.google-services"');
      }
      appFile.writeAsStringSync(content);
    }
  }
  print('\n*** FIREBASE PLUGIN INJECTED ***\n');
}
