import 'dart:io';

void main() {
  var file = File('lib/main.dart');
  var content = file.readAsStringSync();
  
  var iosOptions = '''Firebase.initializeApp(
      options: Platform.isIOS 
        ? const FirebaseOptions(
            apiKey: 'AIzaSyB48LK4w48RbEQCuSnOsiy2_lOc82ualso',
            appId: '1:806442937742:ios:40a22bab6953f2fb7f48df',
            messagingSenderId: '806442937742',
            projectId: 'survey-hero-9abc1',
          ) 
        : null,
    )''';
    
  if (content.contains('Firebase.initializeApp()')) {
    content = content.replaceFirst('Firebase.initializeApp()', iosOptions);
    if (!content.contains("import 'dart:io'")) {
      content = "import 'dart:io';\n" + content;
    }
    file.writeAsStringSync(content);
    print("\n*** IOS FIREBASE KEYS INJECTED ***\n");
  } else {
    print("\n*** ERROR: Could not find initialization string ***\n");
  }
}
