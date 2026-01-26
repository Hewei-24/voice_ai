// lib/services/ai_service.dart - 修复版本
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:voice_ai/config/api_config.dart';

class AIService extends ChangeNotifier {
  AIService(this._apiConfig);

  APIConfig _apiConfig;
  String _currentResponse = '';
  bool _isLoading = false;
  String? _error;
  final List<Map<String, String>> _history = [];

  String get currentResponse => _currentResponse;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, String>> get history => _history;

  void updateConfig(APIConfig apiConfig) {
    _apiConfig = apiConfig;
  }

  Future<String> getAIResponse(String question, {String? context}) async {
    if (!_apiConfig.isConfigured) {
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
        'Authorization': 'Bearer ${_apiConfig.apiKey}',
      };

      // 修复：使用更简洁的prompt
      final messages = [
        {
          'role': 'system',
          'content': '你是一个课堂助手，帮助学生回答老师的问题。回答要简洁、准确、适合学生身份。'
        },
        {
          'role': 'user',
          'content': question
        }
      ];

      final body = {
        'model': _apiConfig.selectedModel,
        'messages': messages,
        'max_tokens': 500, // 增加token限制
        'temperature': 0.7,
        'stream': false,
      };

      if (kDebugMode) {
        print('发送API请求到: ${_apiConfig.apiUrl}');
        print('请求体: ${jsonEncode(body)}');
      }

      final response = await http.post(
        Uri.parse(_apiConfig.apiUrl),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      if (kDebugMode) {
        print('API响应状态码: ${response.statusCode}');
        print('API响应体: ${response.body}');
      }

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(utf8.decode(response.bodyBytes));

          // 调试输出完整的响应结构
          if (kDebugMode) {
            print('解析后的数据: $data');
            print('数据keys: ${data.keys.toList()}');
          }

          // 尝试不同的响应格式解析
          String? content;

          // 方式1: 标准OpenAI格式
          if (data['choices'] != null &&
              data['choices'] is List &&
              data['choices'].isNotEmpty) {
            final firstChoice = data['choices'][0];
            if (firstChoice['message'] != null) {
              content = firstChoice['message']['content']?.toString().trim();
            }
          }

          // 方式2: 直接content字段
          if (content == null && data['content'] != null) {
            content = data['content'].toString().trim();
          }

          // 方式3: 其他可能的格式
          if (content == null && data['result'] != null) {
            content = data['result'].toString().trim();
          }

          // 方式4: 尝试从最外层查找
          if (content == null) {
            for (var key in data.keys) {
              if (key.toString().toLowerCase().contains('content') ||
                  key.toString().toLowerCase().contains('answer') ||
                  key.toString().toLowerCase().contains('text')) {
                final value = data[key];
                if (value is String && value.isNotEmpty) {
                  content = value.trim();
                  break;
                }
              }
            }
          }

          if (content != null && content.isNotEmpty) {
            _currentResponse = content;

            _history.add({
              'question': question,
              'answer': content,
              'time': DateTime.now().toString(),
            });

            if (_history.length > 10) {
              _history.removeAt(0);
            }

            if (kDebugMode) {
              print('成功获取AI回答: $content');
            }
          } else {
            _error = 'API返回了空内容或格式不正确';
            if (kDebugMode) {
              print('无法解析API响应内容');
              print('完整的响应数据: $data');
            }
          }
        } catch (e) {
          _error = '解析API响应失败: $e';
          if (kDebugMode) {
            print('JSON解析错误: $e');
            print('原始响应: ${response.body}');
          }
        }
      } else if (response.statusCode == 401) {
        _error = 'API密钥无效或已过期';
      } else if (response.statusCode == 429) {
        _error = '请求过于频繁，请稍后再试';
      } else if (response.statusCode == 400) {
        try {
          final errorData = jsonDecode(response.body);
          _error = '请求错误: ${errorData['error']?['message'] ?? '参数错误'}';
        } catch (_) {
          _error = '请求参数错误 (${response.statusCode})';
        }
      } else {
        _error = '请求失败: ${response.statusCode}';
        if (kDebugMode) {
          print('API错误响应: ${response.body}');
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