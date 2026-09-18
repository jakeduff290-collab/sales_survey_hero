import 'dart:io';

void main() {
  var file = File('android/app/src/main/kotlin/com/example/sales_survey_hero/FloatingCameraService.kt');
  var content = file.readAsStringSync();
  
  var localSolarPrompt = '''
                                val solarPrompt = """You are a residential solar data extractor. Analyze this utility bill and extract only the following JSON data. Return NO OTHER TEXT.
- "customer_name": The account holder's name
- "monthly_kwh": The total electricity usage for this month in kWh
- "current_rate_plan": The name of the utility rate plan (e.g., TOU-D-PRIME)
- "annual_true_up": If present, the current NEM balance"""
                                extractWithGemini(rawText, solarPrompt)''';
  
  content = content.replaceFirst('extractWithGemini(rawText, solarPrompt)', localSolarPrompt);
  file.writeAsStringSync(content);
  print('\n*** SOLAR PROMPT INJECTED ***\n');
}
