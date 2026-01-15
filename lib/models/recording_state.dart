enum RecordingStatus {
  idle,
  listening,
  processing,
  speaking,
  error,
}

class RecordingState {
  final RecordingStatus status;
  final String? currentText;
  final String? aiResponse;
  final double? confidence;
  final bool isKeywordDetected;
  final String? errorMessage;

  RecordingState({
    this.status = RecordingStatus.idle,
    this.currentText,
    this.aiResponse,
    this.confidence,
    this.isKeywordDetected = false,
    this.errorMessage,
  });

  RecordingState copyWith({
    RecordingStatus? status,
    String? currentText,
    String? aiResponse,
    double? confidence,
    bool? isKeywordDetected,
    String? errorMessage,
  }) {
    return RecordingState(
      status: status ?? this.status,
      currentText: currentText ?? this.currentText,
      aiResponse: aiResponse ?? this.aiResponse,
      confidence: confidence ?? this.confidence,
      isKeywordDetected: isKeywordDetected ?? this.isKeywordDetected,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}