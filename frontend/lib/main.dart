import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  // Entry point of the application
  runApp(const SpeechFeedbackApp());
}

class SpeechFeedbackApp extends StatelessWidget {
  // Main application widget
  const SpeechFeedbackApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Builds the MaterialApp with a title, theme, and home screen
    return MaterialApp(
      title: 'Speech Feedback App',
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
