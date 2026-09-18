import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: Platform.isIOS 
        ? const FirebaseOptions(
            apiKey: 'AIzaSyB48LK4w48RbEQCuSnOsiy2_lOc82ualso',
            appId: '1:806442937742:ios:40a22bab6953f2fb7f48df',
            messagingSenderId: '806442937742',
            projectId: 'survey-hero-9abc1',
          ) 
        : null,
    );
  runApp(const SurveyHeroApp());
}

class SurveyHeroApp extends StatelessWidget {
  const SurveyHeroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Survey Hero',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFE2F952),
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE2F952),
          secondary: Color(0xFFE2F952),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

// This widget acts as the traffic cop
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If the stream is still loading, show a blank screen
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xFFE2F952))),
          );
        }
        
        // If Firebase says the user has a valid session, let them in!
        if (snapshot.hasData) {
          return const DashboardScreen();
        }
        
        // Otherwise, send them to the login paywall
        return const LoginScreen();
      },
    );
  }
}
