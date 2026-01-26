// home_page.dart (更新后的文件)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:voice_ai/services/ai_service.dart';
import 'package:voice_ai/services/keyword_detector.dart';
import 'package:voice_ai/services/speech_to_text.dart';
import 'package:voice_ai/widgets/recording_widget.dart';
import 'package:voice_ai/config/api_config.dart';
import 'package:voice_ai/widgets/ai_response_widget.dart'; // 添加这行

// home_page.dart 上半部分还需要修复 API 状态显示
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _currentQuestion = '';
  final TextEditingController _questionController = TextEditingController();

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apiConfig = context.watch<APIConfig>();
    final keywordDetector = context.watch<KeywordDetectorService>();
    final aiService = context.watch<AIService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice AI助手'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 状态卡片
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '关键词: ${keywordDetector.customName}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'API状态: ${apiConfig.isConfigured ? '已配置' : '未配置'}',
                            style: TextStyle(
                              color: apiConfig.isConfigured
                                  ? Colors.green
                                  : Colors.red,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '模型: ${apiConfig.selectedModel}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text(
                        keywordDetector.isEnabled ? '已启用' : '已禁用',
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: keywordDetector.isEnabled
                          ? Colors.green.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 语音监听组件
              RecordingWidget(
                onKeywordDetected: (text) {
                  setState(() {
                    _currentQuestion = text;
                    _questionController.text = text;
                  });
                  if (text.isNotEmpty) {
                    aiService.getAIResponse(text);
                  }
                },
              ),
              const SizedBox(height: 20),

              // 手动输入问题区域
              Container(
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
                    const Text(
                      '手动输入问题',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _questionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: '请输入老师的问题...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _currentQuestion = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed:
                          _currentQuestion.isNotEmpty && apiConfig.isConfigured
                              ? () {
                                  aiService.getAIResponse(_currentQuestion);
                                }
                              : null,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('获取AI回答'),
                    ),
                    if (!apiConfig.isConfigured)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '请先配置API密钥',
                          style: TextStyle(color: Colors.orange.shade700),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // AI回答显示
              if (_currentQuestion.isNotEmpty)
                AIResponseWidget(question: _currentQuestion),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (aiService.error != null)
            FloatingActionButton(
              heroTag: 'retry_fab',
              onPressed: () {
                aiService.retryLastRequest(_currentQuestion);
              },
              backgroundColor: Colors.orange,
              mini: true,
              child: const Icon(Icons.refresh),
            ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'clear_fab',
            onPressed: () {
              setState(() {
                _currentQuestion = '';
                _questionController.clear();
              });
              context.read<SpeechToTextService>().clearText();
              aiService.clearResponse();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('清空'),
            backgroundColor: Colors.blue,
          ),
        ],
      ),
    );
  }
}

// home_page.dart (修复 SettingsPage 部分)
// 设置页面
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final apiConfig = context.watch<APIConfig>();
    final keywordDetector = context.watch<KeywordDetectorService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // API设置
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'API设置',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: apiConfig.apiKey, // 修复：改为 apiKey
                    decoration: InputDecoration(
                      labelText: 'DeepSeek API密钥',
                      border: const OutlineInputBorder(),
                      hintText: '输入你的DeepSeek API密钥',
                      suffixIcon: IconButton(
                        icon: Icon(apiConfig.isConfigured
                            ? Icons.check_circle
                            : Icons.warning),
                        color: apiConfig.isConfigured
                            ? Colors.green
                            : Colors.orange,
                        onPressed: () {},
                      ),
                    ),
                    obscureText: true,
                    onChanged: (value) {
                      apiConfig.saveAPIKey(value);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: apiConfig.selectedModel,
                    decoration: const InputDecoration(labelText: 'AI模型'),
                    items: apiConfig.availableModels
                        .map((model) => DropdownMenuItem(
                              value: model,
                              child: Text(model),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        apiConfig.updateModel(value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  if (apiConfig.isConfigured)
                    Text(
                      '当前密钥: ${apiConfig.getMaskedKey()}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      apiConfig.clearAPIKey();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.1),
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('清除API密钥'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 关键词设置
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '关键词设置',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: keywordDetector.customName,
                    decoration: const InputDecoration(
                      labelText: '你的名字/关键词',
                      border: OutlineInputBorder(),
                      hintText: '例如：小明',
                    ),
                    onChanged: (value) {
                      keywordDetector.saveSettings(customName: value);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('检测灵敏度'),
                  Slider(
                    value: keywordDetector.sensitivity,
                    onChanged: (value) {
                      keywordDetector.saveSettings(sensitivity: value);
                    },
                    min: 0.1,
                    max: 1.0,
                    divisions: 9,
                    label: '${(keywordDetector.sensitivity * 100).toInt()}%',
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('启用关键词检测'),
                    value: keywordDetector.isEnabled,
                    onChanged: (value) {
                      keywordDetector.saveSettings(isEnabled: value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 使用说明
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '使用说明',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  ListTile(
                    leading: Icon(Icons.mic, color: Colors.blue),
                    title: Text('开启语音监听'),
                    subtitle: Text('系统会自动监听周围声音'),
                  ),
                  ListTile(
                    leading: Icon(Icons.flag, color: Colors.green),
                    title: Text('关键词触发'),
                    subtitle: Text('当检测到你的名字或关键词时自动触发AI'),
                  ),
                  ListTile(
                    leading: Icon(Icons.lightbulb, color: Colors.orange),
                    title: Text('AI回答'),
                    subtitle: Text('AI会基于听到的内容生成合适的回答'),
                  ),
                  ListTile(
                    leading: Icon(Icons.security, color: Colors.red),
                    title: Text('隐私保护'),
                    subtitle: Text('语音仅在本地识别，文本问题会发送到AI服务'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
