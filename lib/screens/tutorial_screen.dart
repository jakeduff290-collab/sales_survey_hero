import 'package:flutter/material.dart';

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How to Use Survey Hero', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFE2F952),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _buildStep(
            step: '1',
            title: 'Launch the Widgets',
            description: 'Select your AI Prompt on the dashboard and hit the massive LAUNCH POP-UPS button. The app will minimize, and the floating widgets will appear on your screen.',
            icon: Icons.rocket_launch,
          ),
          _buildStep(
            step: '2',
            title: 'Save the Bill (Left Button)',
            description: 'Ask the homeowner for their utility bill. Frame it up in the floating camera window and tap the LEFT (White) button to capture and save a picture of the document.',
            icon: Icons.save_alt,
          ),
          _buildStep(
            step: '3',
            title: 'Pull the Info (Right Button)',
            description: 'Tap the RIGHT (Yellow) button to send the bill to the AI. Wait a few seconds while Gemini pulls the exact information needed for your company.',
            icon: Icons.memory,
          ),
          _buildStep(
            step: '4',
            title: 'Auto-Fill the CRM',
            description: 'Open your CRM or Lead Form so the blank text boxes are visible on your screen. Tap the floating PASTE widget, and watch the data instantly populate into the fields.',
            icon: Icons.bolt,
          ),
        ],
      ),
    );
  }

  Widget _buildStep({required String step, required String title, required String description, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFE2F952),
            child: Text(step, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: const Color(0xFFE2F952), size: 20),
                    const SizedBox(width: 8),
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(description, style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
