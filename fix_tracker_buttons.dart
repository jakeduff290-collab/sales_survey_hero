import 'dart:io';

void main() {
  var file = File('android/app/src/main/kotlin/com/example/sales_survey_hero/FloatingCameraService.kt');
  var lines = file.readAsLinesSync();
  var cleanLines = <String>[];
  
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i];
    
    // 1. Keep the actual function definition
    if (line.contains('private fun logScanToDatabase')) {
      cleanLines.add(line);
    }
    // 2. Keep the correct call inside takePhoto()
    else if (line.contains('logScanToDatabase()') && 
            (i > 0 && lines[i-1].contains('extractWithGemini'))) {
      cleanLines.add(line);
    }
    // 3. Neutralize all accidental copy-pasted calls on other buttons
    else if (line.contains('logScanToDatabase()')) {
      cleanLines.add('// Neutralized accidental tracker call');
    } 
    // 4. Keep everything else normal
    else {
      cleanLines.add(line);
    }
  }
  
  file.writeAsStringSync(cleanLines.join('\n'));
  print('\n*** ACCIDENTAL BUTTON TRACKERS NEUTRALIZED ***\n');
}
