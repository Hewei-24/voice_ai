import 'dart:async';
import 'package:flutter/foundation.dart';

class AudioRecorderService extends ChangeNotifier {
  bool _isRecording = false;
  Timer? _recordingTimer;
  List<String> _recordedTexts = [];

  bool get isRecording => _isRecording;
  List<String> get recordedTexts => _recordedTexts;

  Future<bool> startRecording() async {
    // Windows平台不需要权限检查
    _isRecording = true;
    _recordedTexts.clear();

    // 模拟录音过程
    _startRecordingSimulation();

    notifyListeners();
    return true;
  }

  void _startRecordingSimulation() {
    // 模拟录音计时器
    _recordingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      // 模拟检测到语音
      if (_isRecording) {
        _recordedTexts.add('检测到语音片段 ${timer.tick}');
        notifyListeners();
      }
    });
  }

  Future<void> stopRecording() async {
    _isRecording = false;
    _recordingTimer?.cancel();
    _recordingTimer = null;
    notifyListeners();
  }

  void clearRecordings() {
    _recordedTexts.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    super.dispose();
  }
}