import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:voice_ai/pages/home_page.dart';
import 'package:voice_ai/services/ai_service.dart';
import 'package:voice_ai/services/keyword_detector.dart';
import 'package:voice_ai/services/speech_to_text.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 移除 AudioRecorderService，因为 speech_to_text 已包含录音功能
        ChangeNotifierProvider(create: (_) => SpeechToTextService()),
        ChangeNotifierProvider(create: (_) => KeywordDetectorService()),
        ChangeNotifierProvider(create: (_) => AIService()),
      ],
      child: MaterialApp(
        title: 'Voice AI助手',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
          ),
        ),
        home: const HomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}