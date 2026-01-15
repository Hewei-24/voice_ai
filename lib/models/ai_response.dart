class AIResponse {
  final String answer;
  final String? reasoning;
  final double confidence;
  final DateTime timestamp;

  AIResponse({
    required this.answer,
    this.reasoning,
    required this.confidence,
    required this.timestamp,
  });

  factory AIResponse.fromJson(Map<String, dynamic> json) {
    return AIResponse(
      answer: json['answer'] ?? '',
      reasoning: json['reasoning'],
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}