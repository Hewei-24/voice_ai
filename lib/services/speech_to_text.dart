import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:vosk_flutter/vosk_flutter.dart';

class SpeechToTextService extends ChangeNotifier {
  static const String _modelAssetPath =
      'assets/models/vosk-model-small-cn-0.22.zip';
  static const String _modelDownloadUrl =
      'https://alphacephei.com/vosk/models/vosk-model-small-cn-0.22.zip';
  static const int _sampleRate = 16000;
  static const int _maxTranscriptLength = 200;
  static const int _maxTranscriptLines = 3;
  static const int _maxAlternatives = 5;

  VoskFlutterPlugin? _vosk;
  Model? _model;
  Recognizer? _recognizer;
  SpeechService? _speechService;
  StreamSubscription<String>? _partialSubscription;
  StreamSubscription<String>? _resultSubscription;

  bool _isListening = false;
  bool _isAvailable = false;
  bool _hasPermission = true;
  String _lastWords = '';
  String _fullText = '';
  final List<String> _recentTranscriptLines = <String>[];
  String _partialTranscript = '';
  List<String> _lastAlternatives = <String>[];
  double _confidence = 1.0;
  String _lastStatus = '';
  String? _lastErrorMessage;
  bool _lastErrorPermanent = false;
  void Function(String text)? _resultCallback;

  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable;
  bool get hasPermission => _hasPermission;
  String get lastWords => _lastWords;
  String get fullText => _fullText;
  List<String> get recentTranscriptLines =>
      List.unmodifiable(_recentTranscriptLines);
  String get partialTranscript => _partialTranscript;
  List<String> get lastAlternatives => List.unmodifiable(_lastAlternatives);
  double get confidence => _confidence;
  String get lastStatus => _lastStatus;
  String? get lastErrorMessage => _lastErrorMessage;
  bool get lastErrorPermanent => _lastErrorPermanent;

  Future<bool> initialize() async {
    _lastErrorMessage = null;
    _lastErrorPermanent = false;
    _lastStatus = '';
    notifyListeners();

    if (!Platform.isAndroid) {
      _isAvailable = false;
      _lastErrorMessage = '仅支持 Android';
      notifyListeners();
      return false;
    }

    try {
      _lastStatus = '准备离线中文模型...';
      notifyListeners();
      final modelPath = await _loadModelPath();
      _vosk ??= VoskFlutterPlugin.instance();
      _model ??= await _vosk!.createModel(modelPath);
      _recognizer = await _vosk!.createRecognizer(
        model: _model!,
        sampleRate: _sampleRate,
      );
      await _recognizer?.setMaxAlternatives(_maxAlternatives);
      _speechService = await _vosk!.initSpeechService(_recognizer!);
      await _bindStreams();
      _isAvailable = true;
      _hasPermission = true;
    } on MicrophoneAccessDeniedException {
      _isAvailable = false;
      _hasPermission = false;
      _lastErrorMessage = '麦克风权限被拒绝';
    } catch (e) {
      _isAvailable = false;
      _lastErrorMessage = _mapInitError(e);
    }

    notifyListeners();
    return _isAvailable;
  }

  Future<String> _loadModelPath() async {
    final loader = ModelLoader();

    try {
      _lastStatus = '加载内置模型中...';
      notifyListeners();
      final modelPath = await loader.loadFromAssets(_modelAssetPath);
      return modelPath;
    } catch (error) {
      if (!_isAssetMissingError(error)) {
        rethrow;
      }
    }

    _lastStatus = '正在下载中文模型...';
    notifyListeners();
    final modelPath = await loader.loadFromNetwork(_modelDownloadUrl);
    return modelPath;
  }

  Future<void> _bindStreams() async {
    await _partialSubscription?.cancel();
    await _resultSubscription?.cancel();
    _partialSubscription = _speechService
        ?.onPartial()
        .listen(_handlePartialResult, onError: _handleRecognitionError);
    _resultSubscription = _speechService
        ?.onResult()
        .listen(_handleFinalResult, onError: _handleRecognitionError);
  }

  void startListening({void Function(String text)? onResult}) async {
    _resultCallback = onResult;
    if (!_isListening) {
      if (!_isAvailable) {
        final ready = await initialize();
        if (!ready) {
          return;
        }
      }
      _lastErrorMessage = null;
      _lastErrorPermanent = false;
      _lastStatus = 'listening';
      _isListening = true;
      notifyListeners();
      await _speechService?.start(onRecognitionError: _handleRecognitionError);
    }
  }

  void stopListening() {
    if (_isListening) {
      _speechService?.stop();
      _isListening = false;
      _lastStatus = 'notListening';
      notifyListeners();
    }
  }

  void clearText() {
    _fullText = '';
    _lastWords = '';
    _partialTranscript = '';
    _recentTranscriptLines.clear();
    _lastAlternatives = <String>[];
    notifyListeners();
  }

  @override
  void dispose() {
    _partialSubscription?.cancel();
    _resultSubscription?.cancel();
    _speechService?.dispose();
    _recognizer?.dispose();
    _model?.dispose();
    super.dispose();
  }

  void _handlePartialResult(String payload) {
    final partial = _extractText(payload, 'partial');
    if (partial.isNotEmpty) {
      _lastWords = partial;
      _partialTranscript = partial;
      _lastAlternatives = <String>[];
      _resultCallback?.call(partial);
      notifyListeners();
    }
  }

  void _handleFinalResult(String payload) {
    final alternatives = _extractAlternatives(payload);
    _lastAlternatives = alternatives;

    var text = _extractText(payload, 'text');
    if (text.isEmpty && alternatives.isNotEmpty) {
      text = alternatives.first;
    }
    if (text.isNotEmpty) {
      _lastWords = text;
      _partialTranscript = '';
      _fullText = _truncateTranscript('$_fullText $text'.trim());
      _recentTranscriptLines.add(text);
      while (_recentTranscriptLines.length > _maxTranscriptLines) {
        _recentTranscriptLines.removeAt(0);
      }
      _resultCallback?.call(text);
      notifyListeners();
    }
  }

  void _handleRecognitionError(Object error) {
    _lastErrorMessage = error.toString();
    _lastErrorPermanent = true;
    _isListening = false;
    _lastStatus = 'error';
    notifyListeners();
  }

  String _extractText(String payload, String key) {
    try {
      final data = jsonDecode(payload);
      if (data is Map) {
        final value = data[key];
        if (value != null) {
          return value.toString().trim();
        }
        return '';
      }
    } catch (_) {}
    return payload.trim();
  }

  List<String> _extractAlternatives(String payload) {
    try {
      final data = jsonDecode(payload);
      if (data is Map && data['alternatives'] is List) {
        final alternatives = data['alternatives'] as List;
        return alternatives
            .whereType<Map>()
            .map((alt) => alt['text']?.toString().trim() ?? '')
            .where((text) => text.isNotEmpty)
            .toList(growable: false);
      }
    } catch (_) {}
    return const <String>[];
  }

  String _mapInitError(Object error) {
    final message = error.toString();
    if (message.contains('Unable to load asset')) {
      return '模型文件未找到，请下载并放入 assets/models';
    }
    if (message.contains('SocketException') ||
        message.contains('ClientException') ||
        message.contains('Failed host lookup')) {
      return '模型下载失败，请检查网络或手动放入 assets/models';
    }
    if (message.contains('MissingPluginException')) {
      return 'Vosk 插件未正确加载';
    }
    return message;
  }

  bool _isAssetMissingError(Object error) {
    if (error is FlutterError) {
      return error.message.contains('Unable to load asset');
    }
    return error.toString().contains('Unable to load asset');
  }

  String _truncateTranscript(String value) {
    if (value.length <= _maxTranscriptLength) {
      return value;
    }
    final start = value.length - _maxTranscriptLength + 1;
    return '…${value.substring(start)}';
  }
}
