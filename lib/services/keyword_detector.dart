import 'package:flutter/foundation.dart';
import 'package:pinyin/pinyin.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KeywordDetectorService extends ChangeNotifier {
  List<String> _keywords = ['小明', '同学', '回答'];
  String _customName = '我的名字';
  double _sensitivity = 0.7;
  bool _isEnabled = true;
  static final RegExp _noiseChars = RegExp(
    r'''[\s,\.!\?，。！？、;；:"“”'‘’()（）【】\[\]{}<>《》]+''',
  );
  static final RegExp _pinyinNoise = RegExp(r'[^a-z0-9]+');
  String _customNamePinyin = '';

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
      _customNamePinyin = _normalizePinyin(_toPinyin(_customName));

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
    _customNamePinyin = _normalizePinyin(_toPinyin(_customName));

    notifyListeners();
  }

  bool detectKeyword(String text) {
    if (!_isEnabled || text.isEmpty) return false;

    final lowerText = text.toLowerCase();
    final normalizedText = _normalizeText(lowerText);

    for (var keyword in _keywords) {
      // 简单的置信度计算
      final keywordScore =
          _calculateKeywordScore(lowerText, normalizedText, keyword);
      if (keywordScore >= _sensitivity) {
        if (kDebugMode) {
          print('检测到关键词: $keyword, 分数: $keywordScore');
        }
        return true;
      }
    }

    return false;
  }

  double _calculateKeywordScore(
    String text,
    String normalizedText,
    String keyword,
  ) {
    if (text.isEmpty || keyword.isEmpty) return 0.0;

    final keywordLower = keyword.toLowerCase();
    final textLower = text.toLowerCase();
    final normalizedKeyword = _normalizeText(keywordLower);

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

    // 去掉空格/标点后的匹配（中文更常见）
    if (normalizedKeyword.isNotEmpty &&
        normalizedText.contains(normalizedKeyword)) {
      return 0.8;
    }

    // 对自定义人名做一次容错匹配（例如“小明”被识别为“晓明/小名/小 明”）
    if (normalizedKeyword.isNotEmpty && keyword == _customName) {
      final keywordPinyin = _customNamePinyin;
      if (keywordPinyin.isNotEmpty) {
        final textPinyin = _normalizePinyin(_toPinyin(textLower));
        if (textPinyin.contains(keywordPinyin)) {
          return 0.85;
        }
        final pinyinFuzzyScore = _fuzzyContainsScore(textPinyin, keywordPinyin);
        if (pinyinFuzzyScore >= 0.7) {
          return 0.8;
        }
      }

      final fuzzyScore = _fuzzyContainsScore(
        normalizedText,
        normalizedKeyword,
      );
      if (fuzzyScore > 0) {
        return fuzzyScore;
      }
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

  String _normalizeText(String value) =>
      value.replaceAll(_noiseChars, '').trim();

  String _normalizePinyin(String value) =>
      value.toLowerCase().replaceAll(_pinyinNoise, '');

  String _toPinyin(String value) {
    try {
      return PinyinHelper.getPinyinE(
        value,
        separator: '',
        defPinyin: '',
        format: PinyinFormat.WITHOUT_TONE,
      );
    } catch (_) {
      return '';
    }
  }

  double _fuzzyContainsScore(String text, String keyword) {
    if (text.isEmpty || keyword.isEmpty) return 0.0;
    if (text.length < keyword.length) return 0.0;

    final keywordLength = keyword.length;
    final maxDistance = keywordLength <= 2 ? 1 : (keywordLength <= 4 ? 2 : 3);

    var bestScore = 0.0;
    final minWindow =
        (keywordLength - maxDistance).clamp(1, keywordLength).toInt();
    final maxWindow = (keywordLength + maxDistance)
        .clamp(1, keywordLength + maxDistance)
        .toInt();

    for (var windowLength = minWindow;
        windowLength <= maxWindow;
        windowLength++) {
      if (windowLength > text.length) {
        continue;
      }

      for (var i = 0; i <= text.length - windowLength; i++) {
        final candidate = text.substring(i, i + windowLength);
        final distance = _levenshteinDistance(
          keyword,
          candidate,
          maxDistance: maxDistance,
        );
        if (distance > maxDistance) {
          continue;
        }

        final maxLen =
            keywordLength > windowLength ? keywordLength : windowLength;
        final score = 1.0 - (distance / (maxLen * 2));
        if (score > bestScore) {
          bestScore = score;
          if (bestScore >= 0.95) {
            return bestScore;
          }
        }
      }
    }

    return bestScore;
  }

  int _levenshteinDistance(
    String a,
    String b, {
    required int maxDistance,
  }) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    var prev = List<int>.generate(b.length + 1, (i) => i);
    var curr = List<int>.filled(b.length + 1, 0);

    for (var i = 1; i <= a.length; i++) {
      curr[0] = i;
      var minInRow = curr[0];
      final aChar = a.codeUnitAt(i - 1);

      for (var j = 1; j <= b.length; j++) {
        final cost = aChar == b.codeUnitAt(j - 1) ? 0 : 1;
        final deletion = prev[j] + 1;
        final insertion = curr[j - 1] + 1;
        final substitution = prev[j - 1] + cost;
        final value = deletion < insertion
            ? (deletion < substitution ? deletion : substitution)
            : (insertion < substitution ? insertion : substitution);
        curr[j] = value;
        if (value < minInRow) {
          minInRow = value;
        }
      }

      if (minInRow > maxDistance) {
        return maxDistance + 1;
      }

      final tmp = prev;
      prev = curr;
      curr = tmp;
    }

    return prev[b.length];
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
