import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:voice_ai/services/keyword_detector.dart';
import 'package:voice_ai/services/speech_to_text.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

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

  @override
  void initState() {
    super.initState();
    _speechService = context.read<SpeechToTextService>();
    _keywordDetector = context.read<KeywordDetectorService>();
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    await _speechService.initialize();
  }

  void _startListening() {
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