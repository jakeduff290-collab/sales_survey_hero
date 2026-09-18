import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AIExtractorService {
  static const String _functionUrl = 'https://us-central1-survey-hero-9abc1.cloudfunctions.net/extractBillData';

  static Future<String> extractData(String prompt, String base64Image) async {
    try {
      final response = await http.post(
        Uri.parse(_functionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prompt': prompt,
          'base64Image': base64Image,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // --- THE REAL ROI TRACKER ---
        // We only log a point if the server actually returned data
        try {
          final prefs = await SharedPreferences.getInstance();
          final company = prefs.getString('company_code');
          final username = prefs.getString('username');
          
          if (company != null && username != null) {
            await FirebaseFirestore.instance
                .collection('companies').doc(company)
                .collection('reps').doc(username)
                .set({
                  'total_scans': FieldValue.increment(1),
                  'last_active': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));
          }
        } catch (dbError) {
          print('Failed to log scan: $dbError');
        }

        return data['extractedData'] ?? 'No data extracted.';
      } else {
        print('Server error: ${response.statusCode}');
        return 'Error: Server rejected the request.';
      }
    } catch (e) {
      print('Network error: $e');
      return 'Error: Could not connect to the secure server.';
    }
  }
}
