// ai_response_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:voice_ai/services/ai_service.dart';

class AIResponseWidget extends StatelessWidget {
  final String question;

  const AIResponseWidget({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    final aiService = context.watch<AIService>();

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
          const Text(
            '问题',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            question,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'AI回答',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          if (aiService.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (aiService.error != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      aiService.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            )
          else if (aiService.currentResponse.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  aiService.currentResponse,
                  style: const TextStyle(fontSize: 14),
                ),
              )
            else
              const Text(
                '等待AI回答...',
                style: TextStyle(color: Colors.grey),
              ),
        ],
      ),
    );
  }
}