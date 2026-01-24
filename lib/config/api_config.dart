import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class APIConfig extends ChangeNotifier {
  String _apiKey = '';
  String _apiUrl = 'https://api.deepseek.com/chat/completions';
  final List<String> _availableModels = ['deepseek-chat', 'deepseek-coder'];
  String _selectedModel = 'deepseek-chat';

  String get apiKey => _apiKey;
  String get apiUrl => _apiUrl;
  String get selectedModel => _selectedModel;
  List<String> get availableModels => _availableModels;
  bool get isConfigured => _apiKey.isNotEmpty;

  APIConfig() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _apiKey = prefs.getString('api_key') ?? '';

      // 获取保存的模型，如果是旧的模型名，则重置为默认值
      final savedModel = prefs.getString('selected_model') ?? 'deepseek-chat';

      // 检查保存的模型是否在可用模型中
      if (_availableModels.contains(savedModel)) {
        _selectedModel = savedModel;
      } else {
        // 如果不在可用模型中（比如是旧的 gpt-4），则使用默认值
        _selectedModel = 'deepseek-chat';
        await prefs.setString('selected_model', 'deepseek-chat');
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('加载API配置失败: $e');
      }
    }
  }

  Future<void> saveAPIKey(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('api_key', key);
      _apiKey = key;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('保存API密钥失败: $e');
      }
    }
  }

  Future<void> updateModel(String model) async {
    if (_availableModels.contains(model)) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_model', model);
      _selectedModel = model;
      notifyListeners();
    }
  }

  void clearAPIKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('api_key');
    _apiKey = '';
    notifyListeners();
  }

  String getMaskedKey() {
    if (_apiKey.length <= 8) return '未设置';
    return '${_apiKey.substring(0, 4)}...${_apiKey.substring(_apiKey.length - 4)}';
  }
}