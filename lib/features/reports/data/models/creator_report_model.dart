/// Represents a weekly AI-generated performance report for a creator.
class CreatorReport {
  final String id;
  final String userId;
  final DateTime weekStart;
  final DateTime weekEnd;
  final DateTime generatedAt;

  // What worked this week
  final List<String> whatWorked;

  // What didn't perform well
  final List<String> whatFailed;

  // Dominant content themes detected
  final List<String> topThemes;

  // Niche detected this week
  final String detectedNiche;

  // Average viral score across all analyses this week
  final int averageViralScore;

  // Total reels analyzed this week
  final int reelsAnalyzed;

  // AI-generated strategy recommendations for next week
  final String nextWeekStrategy;

  // Specific actionable items (max 5)
  final List<String> actionItems;

  // Trend direction vs. previous week
  final ReportTrend trend;

  // Optional: Estimated audience growth prediction
  final String growthPrediction;

  CreatorReport({
    required this.id,
    required this.userId,
    required this.weekStart,
    required this.weekEnd,
    required this.generatedAt,
    required this.whatWorked,
    required this.whatFailed,
    required this.topThemes,
    required this.detectedNiche,
    required this.averageViralScore,
    required this.reelsAnalyzed,
    required this.nextWeekStrategy,
    required this.actionItems,
    required this.trend,
    required this.growthPrediction,
  });

  factory CreatorReport.fromMap(Map<String, dynamic> map) {
    return CreatorReport(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      weekStart: DateTime.tryParse(map['weekStart'] ?? '') ?? DateTime.now(),
      weekEnd: DateTime.tryParse(map['weekEnd'] ?? '') ?? DateTime.now(),
      generatedAt: DateTime.tryParse(map['generatedAt'] ?? '') ?? DateTime.now(),
      whatWorked: List<String>.from(map['whatWorked'] ?? []),
      whatFailed: List<String>.from(map['whatFailed'] ?? []),
      topThemes: List<String>.from(map['topThemes'] ?? []),
      detectedNiche: map['detectedNiche'] ?? 'General',
      averageViralScore: map['averageViralScore'] ?? 0,
      reelsAnalyzed: map['reelsAnalyzed'] ?? 0,
      nextWeekStrategy: map['nextWeekStrategy'] ?? '',
      actionItems: List<String>.from(map['actionItems'] ?? []),
      trend: ReportTrend.fromString(map['trend'] ?? 'stable'),
      growthPrediction: map['growthPrediction'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'weekStart': weekStart.toIso8601String(),
      'weekEnd': weekEnd.toIso8601String(),
      'generatedAt': generatedAt.toIso8601String(),
      'whatWorked': whatWorked,
      'whatFailed': whatFailed,
      'topThemes': topThemes,
      'detectedNiche': detectedNiche,
      'averageViralScore': averageViralScore,
      'reelsAnalyzed': reelsAnalyzed,
      'nextWeekStrategy': nextWeekStrategy,
      'actionItems': actionItems,
      'trend': trend.value,
      'growthPrediction': growthPrediction,
    };
  }

  String get weekLabel {
    final start = '${weekStart.day}/${weekStart.month}';
    final end = '${weekEnd.day}/${weekEnd.month}/${weekEnd.year}';
    return '$start – $end';
  }
}

enum ReportTrend {
  improving,
  stable,
  declining;

  String get value {
    switch (this) {
      case ReportTrend.improving:
        return 'improving';
      case ReportTrend.stable:
        return 'stable';
      case ReportTrend.declining:
        return 'declining';
    }
  }

  static ReportTrend fromString(String value) {
    switch (value) {
      case 'improving':
        return ReportTrend.improving;
      case 'declining':
        return ReportTrend.declining;
      default:
        return ReportTrend.stable;
    }
  }

  String get label {
    switch (this) {
      case ReportTrend.improving:
        return '📈 Improving';
      case ReportTrend.stable:
        return '➡️ Stable';
      case ReportTrend.declining:
        return '📉 Needs Attention';
    }
  }
}
