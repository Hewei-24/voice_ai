import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:voice_ai/services/ai_service.dart';
import 'package:voice_ai/services/keyword_detector.dart';
import 'package:voice_ai/widgets/recording_widget.dart';
import 'package:voice_ai/widgets/ai_response_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _currentQuestion = '';

  @override
  Widget build(BuildContext context) {
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
              // 用户信息卡片
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
                            '灵敏度: ${(keywordDetector.sensitivity * 100).toInt()}%',
                            style: const TextStyle(fontSize: 12),
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
                  });
                  // 自动触发AI回答
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
                      onPressed: _currentQuestion.isNotEmpty
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // 清除所有内容
          setState(() {
            _currentQuestion = '';
          });
          aiService.clearResponse();
        },
        icon: const Icon(Icons.refresh),
        label: const Text('清空'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

// 设置页面
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final keywordDetector = context.watch<KeywordDetectorService>();
    final aiService = context.watch<AIService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
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

            // AI设置
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
                    'AI设置',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: aiService.currentResponse,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'OpenAI API密钥',
                      border: const OutlineInputBorder(),
                      hintText: 'sk-...',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.visibility_off),
                        onPressed: () {
                          // 切换可见性
                        },
                      ),
                    ),
                    obscureText: true,
                    onChanged: (value) {
                      aiService.saveApiKey(value);
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '注意：API密钥仅存储在本地设备上',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
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
                    subtitle: Text('所有语音数据仅在本地处理，不会上传到服务器'),
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