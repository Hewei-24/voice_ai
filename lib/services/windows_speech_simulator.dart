// windows_speech_simulator.dart
import 'package:flutter/foundation.dart';

class WindowsSpeechSimulator extends ChangeNotifier {
  bool _isListening = false;
  String _lastWords = '';
  String _fullText = '';
  double _confidence = 1.0;

  bool get isListening => _isListening;
  String get lastWords => _lastWords;
  String get fullText => _fullText;
  double get confidence => _confidence;

  Future<bool> initialize() async {
    // Windows上总是返回true，因为我们要模拟
    return true;
  }

  void startListening({void Function(String text)? onResult}) {
    if (!_isListening) {
      _isListening = true;
      notifyListeners();

      // 模拟语音识别结果（仅用于演示）
      _simulateSpeechRecognition(onResult);
    }
  }

  void _simulateSpeechRecognition(void Function(String text)? onResult) {
    // 模拟5秒后的语音识别结果
    Future.delayed(const Duration(seconds: 3), () {
      if (_isListening) {
        // 模拟识别到的文本
        final simulatedText = "请解释一下什么是光合作用？";
        _lastWords = simulatedText;
        _fullText = simulatedText;

        if (onResult != null) {
          onResult(simulatedText);
        }
        notifyListeners();

        // 5秒后自动停止
        Future.delayed(const Duration(seconds: 2), () {
          stopListening();
        });
      }
    });
  }

  void stopListening() {
    if (_isListening) {
      _isListening = false;
      notifyListeners();
    }
  }

  void clearText() {
    _fullText = '';
    _lastWords = '';
    notifyListeners();
  }
}