// recording_widget.dart - 简化版本
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:voice_ai/services/keyword_detector.dart';
import 'package:voice_ai/services/speech_to_text.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/foundation.dart';

class RecordingWidget extends StatefulWidget {
  final Function(String)? onKeywordDetected;

  const RecordingWidget({super.key, this.onKeywordDetected});

  @override
  State<RecordingWidget> createState() => _RecordingWidgetState();
}

class _RecordingWidgetState extends State<RecordingWidget> {
  late final SpeechToTextService _speechService;
  late final KeywordDetectorService _keywordDetector;
  String _detectedText = '';
  bool _isInitializing = false;
  bool _isWindows = defaultTargetPlatform == TargetPlatform.windows;

  @override
  void initState() {
    super.initState();
    _speechService = context.read<SpeechToTextService>();
    _keywordDetector = context.read<KeywordDetectorService>();
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    setState(() {
      _isInitializing = true;
    });

    try {
      final initialized = await _speechService.initialize();

      if (!initialized && !_isWindows) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('语音识别初始化失败，请检查麦克风权限'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('语音初始化错误: $e');
      }
    } finally {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  void _startListening() {
    try {
      _speechService.startListening(onResult: (text) {
        if (text.isNotEmpty) {
          final detected = _keywordDetector.detectKeyword(text);
          if (detected) {
            setState(() {
              _detectedText = text;
            });
            if (widget.onKeywordDetected != null) {
              widget.onKeywordDetected!(text);
            }
          }
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('启动监听失败: ${_isWindows ? "Windows平台可能需要额外配置" : e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _stopListening() {
    try {
      _speechService.stopListening();
    } catch (e) {
      if (kDebugMode) {
        print('停止监听错误: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isListening = _speechService.isListening;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '语音监听',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_isWindows)
                    Text(
                      '(Windows平台)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
              if (_isInitializing)
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(strokeWidth: 3),
                )
              else
                Switch(
                  value: isListening,
                  onChanged: (value) {
                    if (value) {
                      _startListening();
                    } else {
                      _stopListening();
                    }
                  },
                  activeTrackColor: Colors.blue.withOpacity(0.5),
                  activeThumbColor: Colors.blue,
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (isListening) ...[
            Row(
              children: [
                if (_isWindows)
                  const Icon(Icons.computer, color: Colors.blue)
                else
                  const SpinKitThreeBounce(
                    color: Colors.blue,
                    size: 20,
                  ),
                const SizedBox(width: 10),
                Text(
                  _isWindows ? '正在尝试监听...' : '正在监听中...',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const LinearProgressIndicator(
              backgroundColor: Colors.grey,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            if (_isWindows) ...[
              const SizedBox(height: 10),
              const Text(
                '注意：Windows平台可能需要额外配置\n请确保系统麦克风已启用',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                ),
              ),
            ],
          ] else ...[
            const Text(
              '点击开关开始监听语音\n当检测到关键词时会自动触发AI',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],

          if (_detectedText.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '检测到关键词',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _detectedText,
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}