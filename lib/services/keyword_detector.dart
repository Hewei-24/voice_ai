import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KeywordDetectorService extends ChangeNotifier {
  List<String> _keywords = ['小明', '同学', '回答'];
  String _customName = '我的名字';
  double _sensitivity = 0.7;
  bool _isEnabled = true;

  List<String> get keywords => _keywords;
  String get customName => _customName;
  double get sensitivity => _sensitivity;
  bool get isEnabled => _isEnabled;

  KeywordDetectorService() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _customName = prefs.getString('customName') ?? '我的名字';
      _sensitivity = prefs.getDouble('sensitivity') ?? 0.7;
      _isEnabled = prefs.getBool('isEnabled') ?? true;

      // 构建关键词列表
      _keywords = [
        _customName,
        '同学',
        '回答',
        '这个问题',
        '你怎么看',
      ];

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('加载设置失败: $e');
      }
    }
  }

  Future<void> saveSettings({
    String? customName,
    double? sensitivity,
    bool? isEnabled,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (customName != null) {
      _customName = customName;
      await prefs.setString('customName', customName);
    }

    if (sensitivity != null) {
      _sensitivity = sensitivity;
      await prefs.setDouble('sensitivity', sensitivity);
    }

    if (isEnabled != null) {
      _isEnabled = isEnabled;
      await prefs.setBool('isEnabled', isEnabled);
    }

    // 重新构建关键词列表
    _keywords = [
      _customName,
      '同学',
      '回答',
      '这个问题',
      '你怎么看',
    ];

    notifyListeners();
  }

  bool detectKeyword(String text) {
    if (!_isEnabled || text.isEmpty) return false;

    final lowerText = text.toLowerCase();

    for (var keyword in _keywords) {
      if (lowerText.contains(keyword.toLowerCase())) {
        // 简单的置信度计算
        final keywordScore = _calculateKeywordScore(lowerText, keyword);
        if (keywordScore >= _sensitivity) {
          if (kDebugMode) {
            print('检测到关键词: $keyword, 分数: $keywordScore');
          }
          return true;
        }
      }
    }

    return false;
  }

  double _calculateKeywordScore(String text, String keyword) {
    if (text.isEmpty || keyword.isEmpty) return 0.0;

    final keywordLower = keyword.toLowerCase();
    final textLower = text.toLowerCase();

    // 检查完全匹配
    if (textLower.contains(' $keywordLower ') ||
        textLower.startsWith('$keywordLower ') ||
        textLower.endsWith(' $keywordLower')) {
      return 1.0;
    }

    // 检查部分匹配
    if (textLower.contains(keywordLower)) {
      return 0.8;
    }

    // 检查同义词或相关词
    final synonyms = _getSynonyms(keywordLower);
    for (var synonym in synonyms) {
      if (textLower.contains(synonym)) {
        return 0.6;
      }
    }

    return 0.0;
  }

  List<String> _getSynonyms(String keyword) {
    // 这里可以扩展更多同义词
    final Map<String, List<String>> synonymMap = {
      '同学': ['学生', '学员', '这位同学'],
      '回答': ['回复', '解答', '说一下'],
      '问题': ['题目', '疑问', '这个'],
    };

    return synonymMap[keyword] ?? [];
  }
}