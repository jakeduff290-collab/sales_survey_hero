import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

import 'tutorial_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const platform = MethodChannel('com.survey_hero/service');

  String _companyCode = '...';
  String _username = 'Rep';
  final _customPromptController = TextEditingController();
  bool _isLaunching = false;
  
  // New Analytics State
  int _totalScans = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _companyCode = prefs.getString('company_code') ?? 'WAVE';
      _username = prefs.getString('username') ?? 'Rep';
      _customPromptController.text = prefs.getString('custom_prompt') ?? '';
    });
    
    _fetchStats();
  }

  // Pull down the rep's lifetime stats from the database
  Future<void> _fetchStats() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('companies').doc(_companyCode)
          .collection('reps').doc(_username).get();
          
      if (doc.exists && doc.data()!.containsKey('total_scans')) {
        setState(() {
          _totalScans = doc.data()!['total_scans'];
        });
      }
    } catch (e) {
      print('Network error fetching stats');
    }
  }

  Future<bool> _requestPermissions() async {
    var cameraStatus = await Permission.camera.status;
    if (!cameraStatus.isGranted) cameraStatus = await Permission.camera.request();

    var overlayStatus = await Permission.systemAlertWindow.status;
    if (!overlayStatus.isGranted) overlayStatus = await Permission.systemAlertWindow.request();

    return cameraStatus.isGranted && overlayStatus.isGranted;
  }

  Future<void> _openAccessibilityMenu() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFFE2F952), width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Enable Auto-Fill', style: TextStyle(color: Color(0xFFE2F952), fontWeight: FontWeight.bold)),
        content: const SingleChildScrollView(
          child: Text(
            'To allow Survey Hero to type into your CRM:\n\n'
            '1. Tap Continue below.\n'
            '2. Find "Survey Hero Auto-Fill" and turn it ON.\n\n'
            '⚠️ IMPORTANT:\nIf the switch is grayed out:\n'
            '• Go to Settings > Apps > Survey Hero.\n'
            '• Tap the 3 dots > "Allow restricted settings".',
            style: TextStyle(color: Colors.white70, height: 1.4, fontSize: 14)
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE2F952), foregroundColor: Colors.black),
            onPressed: () {
              Navigator.pop(context);
              platform.invokeMethod('openAccessibilitySettings');
            },
            child: const Text('CONTINUE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLaunch() async {
    final finalPrompt = _customPromptController.text.trim();
    
    if (finalPrompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ You must write an AI prompt before launching!'), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isLaunching = true);

    bool hasPermissions = await _requestPermissions();
    if (!hasPermissions) {
      setState(() => _isLaunching = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permissions required.'), backgroundColor: Colors.redAccent));
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_prompt', finalPrompt);

      // --- THE ROI TRACKER ---
      // Log the scan in the database instantly
      final repRef = FirebaseFirestore.instance.collection('companies').doc(_companyCode).collection('reps').doc(_username);
      await repRef.set({
        'total_scans': FieldValue.increment(1),
        'last_active': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      setState(() => _totalScans++); // Update the UI immediately

      await platform.invokeMethod('startCamera', {'prompt': finalPrompt});
      SystemNavigator.pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error launching service.'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLaunching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Math: Assume 3 minutes saved per bill scanned, divided by 60 for hours
    final double hoursSaved = (_totalScans * 3.0) / 60.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rep Dashboard', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFE2F952),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Welcome back, $_username', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('Company ID: $_companyCode', style: const TextStyle(fontSize: 14, color: Color(0xFFE2F952))),
            const SizedBox(height: 24),

            // --- NEW ANALYTICS UI ---
            Row(
              children: [
                Expanded(child: _buildStatCard('Bills Scanned', _totalScans.toString(), Icons.document_scanner)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Hours Saved', hoursSaved.toStringAsFixed(1), Icons.timer)),
              ],
            ),
            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE2F952).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2F952).withValues(alpha: 0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tips_and_updates, color: Color(0xFFE2F952), size: 20),
                      SizedBox(width: 8),
                      Text('How to Prompt the AI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFE2F952))),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Example:\n"Extract the Gas Account Number, the Customer\'s First and Last Name, and the Service Address. Return ONLY the data, separated by commas."',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('Your AI Extraction Prompt:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            TextField(
              controller: _customPromptController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type your instructions for Gemini here...',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF333333))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2F952))),
              ),
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE2F952),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 8,
                shadowColor: const Color(0xFFE2F952).withValues(alpha: 0.5),
              ),
              onPressed: _isLaunching ? null : _handleLaunch,
              child: _isLaunching
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text('LAUNCH POP-UPS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),

            const SizedBox(height: 40),

            Row(
              children: [
                Expanded(child: _buildMenuCard(Icons.settings, 'Settings', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())))),
                const SizedBox(width: 16),
                Expanded(child: _buildMenuCard(Icons.school, 'Tutorial', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TutorialScreen())))),
                const SizedBox(width: 16),
                Expanded(child: _buildMenuCard(Icons.security, 'Permissions', _openAccessibilityMenu)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFE2F952), size: 24),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildMenuCard(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF333333)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white54, size: 28),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
