import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechToTextService extends ChangeNotifier {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _lastWords = '';
  String _fullText = '';
  double _confidence = 1.0;

  bool get isListening => _isListening;
  String get lastWords => _lastWords;
  String get fullText => _fullText;
  double get confidence => _confidence;

  Future<bool> initialize() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        _isListening = status == 'listening';
        notifyListeners();
      },
      onError: (error) {
        if (kDebugMode) {
          print('语音识别错误: $error');
        }
      },
    );

    if (!available) {
      if (kDebugMode) {
        print('用户未授权麦克风权限');
      }
    }

    return available;
  }

  void startListening({void Function(String text)? onResult}) {
    if (!_isListening) {
      _speech.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          _fullText += ' $lastWords';
          _confidence = result.confidence;

          if (onResult != null) {
            onResult(_lastWords);
          }

          notifyListeners();
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        // 修复：使用正确的参数格式
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
        ),
        localeId: 'zh-CN', // 正确的参数位置
      );
    }
  }

  void stopListening() {
    if (_isListening) {
      _speech.stop();
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