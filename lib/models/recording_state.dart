import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:voice_ai/services/keyword_detector.dart';
import 'package:voice_ai/services/speech_to_text.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:voice_ai/utils/permissions_handler.dart'; // 添加权限导入

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
  bool _permissionGranted = false;
  bool _isInitializing = false;

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

    // 首先检查麦克风权限
    final hasPermission = await PermissionsHandler.requestMicrophonePermission();

    if (hasPermission) {
      setState(() {
        _permissionGranted = true;
      });

      // 初始化语音识别
      final initialized = await _speechService.initialize();

      if (!initialized) {
        // 如果初始化失败，显示错误信息
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('语音识别初始化失败，请检查麦克风权限'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('需要麦克风权限才能使用语音监听功能'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    setState(() {
      _isInitializing = false;
    });
  }

  Future<void> _startListening() async {
    if (!_permissionGranted) {
      // 如果没有权限，先请求权限
      final hasPermission = await PermissionsHandler.requestMicrophonePermission();
      if (hasPermission) {
        setState(() {
          _permissionGranted = true;
        });

        // 重新初始化
        await _speechService.initialize();

        // 开始监听
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
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('需要麦克风权限才能使用语音监听功能'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // 已经有权限，直接开始监听
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
    }
  }

  void _stopListening() {
    _speechService.stopListening();
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
              const Text(
                '语音监听',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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

          if (!_permissionGranted) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '需要麦克风权限',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '请允许应用访问麦克风以使用语音监听功能',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isListening) ...[
            Row(
              children: [
                const SpinKitThreeBounce(
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 10),
                const Text(
                  '正在监听中...',
                  style: TextStyle(
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