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
  bool _isInitializing = false;
  bool _wantsListening = false;
  Future<bool>? _initializationFuture;

  @override
  void initState() {
    super.initState();
    _speechService = context.read<SpeechToTextService>();
    _keywordDetector = context.read<KeywordDetectorService>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeSpeech();
      }
    });
  }

  Future<bool> _initializeSpeech({bool startAfterInit = false}) async {
    if (_initializationFuture != null) {
      final ready = await _initializationFuture!;
      if (startAfterInit && ready && _wantsListening) {
        _speechService.startListening(onResult: _handleSpeechResult);
      }
      return ready;
    }

    setState(() {
      _isInitializing = true;
    });

    _initializationFuture = _speechService.initialize();
    final initialized = await _initializationFuture!;
    _initializationFuture = null;

    if (mounted) {
      setState(() {
        _isInitializing = false;
        if (startAfterInit && !initialized) {
          _wantsListening = false;
        }
      });
    }

    if (startAfterInit && initialized && _wantsListening) {
      _speechService.startListening(onResult: _handleSpeechResult);
    }

    return initialized;
  }

  Future<void> _startListening() async {
    setState(() {
      _wantsListening = true;
    });

    if (!_speechService.isAvailable) {
      final initialized = await _initializeSpeech(startAfterInit: true);
      if (!initialized) {
        return;
      }
      return;
    }

    _speechService.startListening(onResult: _handleSpeechResult);
  }

  void _stopListening() {
    setState(() {
      _wantsListening = false;
    });
    _speechService.stopListening();
  }

  void _handleSpeechResult(String text) {
    final isFinal = _speechService.partialTranscript.isEmpty;
    final candidates = <String>[
      if (text.isNotEmpty) text,
      if (isFinal) ..._speechService.lastAlternatives,
    ];

    for (final candidate in candidates) {
      if (candidate.isEmpty) {
        continue;
      }
      final detected = _keywordDetector.detectKeyword(candidate);
      if (!detected) {
        continue;
      }

      setState(() {
        _detectedText = candidate;
      });

      if (isFinal && widget.onKeywordDetected != null) {
        widget.onKeywordDetected!(candidate);
      }
      return;
    }
  }

  List<String> _buildTranscriptLines() {
    const maxLines = 3;
    final lines = _speechService.recentTranscriptLines.toList();
    final partial = _speechService.partialTranscript;
    if (partial.isNotEmpty) {
      if (lines.length >= maxLines) {
        lines.removeAt(0);
      }
      lines.add(partial);
    }
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _speechService,
      builder: (context, _) {
        final isListening = _speechService.isListening;
        final isAvailable = _speechService.isAvailable;
        final hasPermission = _speechService.hasPermission;
        final lastError = _speechService.lastErrorMessage;
        final lastStatus = _speechService.lastStatus;
        final transcriptLines = _buildTranscriptLines();

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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isInitializing)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      Switch(
                        value: _wantsListening,
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
                ],
              ),
              const SizedBox(height: 16),
              if (!isAvailable) ...[
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
                            Text(
                              _isInitializing || _wantsListening
                                  ? '正在启动识别'
                                  : '语音识别不可用',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isInitializing
                                  ? '正在准备离线中文模型...'
                                  : (hasPermission
                                      ? '将自动下载离线中文模型，或手动放入 assets/models'
                                      : '请在系统设置中允许麦克风权限'),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                            if (!_isInitializing && hasPermission)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  '示例: assets/models/vosk-model-small-cn-0.22.zip',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            if (lastStatus.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '状态: $lastStatus',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            if (lastError != null && lastError.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '错误: $lastError',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (!_isInitializing)
                        TextButton(
                          onPressed: _initializeSpeech,
                          child: const Text('重试初始化'),
                        ),
                    ],
                  ),
                ),
              ] else if (_wantsListening && !isListening) ...[
                Row(
                  children: [
                    const SpinKitThreeBounce(
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      '正在启动识别...',
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
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey.shade50,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '实时识别（保留最近3条）',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (var i = 0; i < 3; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          i < transcriptLines.length ? transcriptLines[i] : '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: i == transcriptLines.length - 1 &&
                                    _speechService.partialTranscript.isNotEmpty
                                ? Colors.blueGrey
                                : Colors.black87,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
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
      },
    );
  }
}
