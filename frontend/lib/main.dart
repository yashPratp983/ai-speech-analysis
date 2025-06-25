
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const SpeechFeedbackApp());
}

class SpeechFeedbackApp extends StatelessWidget {
  const SpeechFeedbackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Speech Feedback App',
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}