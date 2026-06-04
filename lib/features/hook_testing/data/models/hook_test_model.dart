class HookTestModel {
  final String label; // "Hook A", "Hook B", "Hook C"
  final String hookText;
  final int score;
  final String feedback;
  final bool isBest;

  HookTestModel({
    required this.label,
    required this.hookText,
    required this.score,
    required this.feedback,
    this.isBest = false,
  });

  factory HookTestModel.fromMap(Map<String, dynamic> map) {
    return HookTestModel(
      label: map['label'] ?? '',
      hookText: map['hookText'] ?? '',
      score: map['score'] ?? 0,
      feedback: map['feedback'] ?? '',
      isBest: map['isBest'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'hookText': hookText,
      'score': score,
      'feedback': feedback,
      'isBest': isBest,
    };
  }
}
