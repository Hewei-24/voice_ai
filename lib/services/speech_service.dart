import 'package:flutter/foundation.dart';

class SpeechService extends ChangeNotifier {
  bool _isListening = false;
  String _recognizedText = '';
  final List<String> _keywords = ['小明', '同学', '回答', '问题'];
  String _customKeyword = '小明';

  bool get isListening => _isListening;
  String get recognizedText => _recognizedText;
  List<String> get keywords => _keywords;
  String get customKeyword => _customKeyword;

  void setCustomKeyword(String keyword) {
    _customKeyword = keyword;
    notifyListeners();
  }

  Future<bool> startListening() async {
    _isListening = true;
    _recognizedText = '';
    notifyListeners();
    return true;
  }

  void stopListening() {
    _isListening = false;
    notifyListeners();
  }

  void simulateSpeechRecognition(String text) {
    _recognizedText = text;
    notifyListeners();
  }

  bool detectKeyword(String text) {
    if (text.isEmpty) return false;

    final lowerText = text.toLowerCase();

    // 检查自定义关键词
    if (_customKeyword.isNotEmpty &&
        lowerText.contains(_customKeyword.toLowerCase())) {
      return true;
    }

    // 检查其他关键词
    for (var keyword in _keywords) {
      if (lowerText.contains(keyword.toLowerCase())) {
        return true;
      }
    }

    return false;
  }

  void clearText() {
    _recognizedText = '';
    notifyListeners();
  }
}