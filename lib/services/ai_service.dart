import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AIService extends ChangeNotifier {
  String _apiKey = '';
  String _apiUrl = 'https://api.openai.com/v1/chat/completions';
  String _currentResponse = '';
  bool _isLoading = false;
  String _selectedModel = 'gpt-3.5-turbo';

  String get currentResponse => _currentResponse;
  bool get isLoading => _isLoading;

  AIService() {
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _apiKey = prefs.getString('openai_api_key') ?? '';
    } catch (e) {
      if (kDebugMode) {
        print('加载API密钥失败: $e');
      }
    }
  }

  Future<void> saveApiKey(String apiKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('openai_api_key', apiKey);
      _apiKey = apiKey;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('保存API密钥失败: $e');
      }
    }
  }

  Future<String> getAIResponse(String question, {String? context}) async {
    if (_apiKey.isEmpty) {
      return '请先设置API密钥';
    }

    _isLoading = true;
    notifyListeners();

    try {
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      };

      final prompt = '''
        你是我的课堂助手。老师正在提问，我需要一个合适的回答。
        
        老师的问题或上下文：$context
        
        具体问题：$question
        
        请提供一个简洁、准确、专业的回答。如果问题需要具体知识，请基于常识给出合理回答。
        格式要求：
        1. 直接给出答案
        2. 保持简洁（最多3句话）
        3. 使用中文回答
        4. 如果是开放性问题，提供思考方向
      ''';

      final body = {
        'model': _selectedModel,
        'messages': [
          {
            'role': 'system',
            'content': '你是一个专业的课堂助手，帮助学生在课堂上回答问题。'
          },
          {
            'role': 'user',
            'content': prompt
          }
        ],
        'max_tokens': 500,
        'temperature': 0.7,
      };

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        _currentResponse = content;
        _isLoading = false;
        notifyListeners();
        return content;
      } else {
        _isLoading = false;
        notifyListeners();
        return 'API请求失败: ${response.statusCode}';
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        print('AI服务错误: $e');
      }
      return '请求失败: $e';
    }
  }

  void clearResponse() {
    _currentResponse = '';
    notifyListeners();
  }
}