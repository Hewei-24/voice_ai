// lib/services/ai_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:voice_ai/config/api_config.dart';

class AIService extends ChangeNotifier {
  String _currentResponse = '';
  bool _isLoading = false;
  String? _error;
  final List<Map<String, String>> _history = [];

  String get currentResponse => _currentResponse;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, String>> get history => _history;

  Future<String> getAIResponse(String question, {String? context}) async {
    final apiConfig = APIConfig();

    if (!apiConfig.isConfigured) {
      _error = '请先在设置中配置有效的API密钥';
      notifyListeners();
      return _error!;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${apiConfig.apiKey}',
      };

      final prompt = '''
        老师提问：$question
        ${context != null ? '上下文：$context' : ''}
        
        请提供一个适合学生回答的简洁答案（最多3句话）：
      ''';

      final body = {
        'model': apiConfig.selectedModel,
        'messages': [
          {
            'role': 'system',
            'content': '你是一个课堂助手，帮助学生回答老师的问题。回答要简洁、准确、适合学生身份。'
          },
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens': 200,
        'temperature': 0.7,
      };

      final response = await http.post(
        Uri.parse(apiConfig.apiUrl),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'].trim();
        _currentResponse = content;

        _history.add({
          'question': question,
          'answer': content,
          'time': DateTime.now().toString(),
        });

        if (_history.length > 10) {
          _history.removeAt(0);
        }
      } else {
        _error = '请求失败: ${response.statusCode}';
        if (kDebugMode) {
          print('API错误: ${response.body}');
        }
      }
    } catch (e) {
      _error = '请求失败: ${e.toString()}';
      if (kDebugMode) {
        print('AI服务错误: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return _currentResponse;
  }

  void clearResponse() {
    _currentResponse = '';
    _error = null;
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  void retryLastRequest(String lastQuestion) {
    if (lastQuestion.isNotEmpty) {
      getAIResponse(lastQuestion);
    }
  }
}