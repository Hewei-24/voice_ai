// main.dart - 简化版本，不使用条件导入
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:voice_ai/pages/home_page.dart';
import 'package:voice_ai/services/ai_service.dart';
import 'package:voice_ai/services/keyword_detector.dart';
import 'package:voice_ai/services/speech_to_text.dart';
import 'package:voice_ai/config/api_config.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => APIConfig()),
        ChangeNotifierProvider(create: (_) => SpeechToTextService()),
        ChangeNotifierProvider(create: (_) => KeywordDetectorService()),
        ChangeNotifierProxyProvider<APIConfig, AIService>(
          create: (context) => AIService(context.read<APIConfig>()),
          update: (context, apiConfig, aiService) {
            if (aiService == null) {
              return AIService(apiConfig);
            }
            aiService.updateConfig(apiConfig);
            return aiService;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Voice AI课堂助手',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            centerTitle: true,
          ),
        ),
        home: const HomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
