import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../analysis/data/models/analysis_models.dart';

class ReelAnalysisModel {
  final String id;
  final String userId;
  final String title;
  final String? videoPath;
  final String? videoUrl;
  final int viralScore;
  final String hookStrength;
  final String retentionPrediction;
  final String engagementPrediction;
  final List<String> suggestions;
  final DateTime createdAt;
  final List<SuggestedTextItem> suggestedHooks;
  final List<SuggestedTextItem> suggestedCtas;
  final List<SuggestedTextItem> suggestedCaptions;
  final int hookScore;
  final int ctaScore;
  final int captionScore;
  final int trendScore;
  final String transcript;

  ReelAnalysisModel({
    required this.id,
    required this.userId,
    required this.title,
    this.videoPath,
    this.videoUrl,
    required this.viralScore,
    required this.hookStrength,
    required this.retentionPrediction,
    required this.engagementPrediction,
    required this.suggestions,
    required this.createdAt,
    this.suggestedHooks = const [],
    this.suggestedCtas = const [],
    this.suggestedCaptions = const [],
    this.hookScore = 70,
    this.ctaScore = 65,
    this.captionScore = 75,
    this.trendScore = 70,
    this.transcript = '',
  });

  factory ReelAnalysisModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parsedDate;
    final rawDate = map['createdAt'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.parse(rawDate);
    } else {
      parsedDate = DateTime.now();
    }

    return ReelAnalysisModel(
      id: docId,
      userId: map['userId'] ?? '',
      title: map['title'] ?? 'Untitled Reel',
      videoPath: map['videoPath'],
      videoUrl: map['videoUrl'],
      viralScore: map['viralScore'] ?? 0,
      hookStrength: map['hookStrength'] ?? 'Moderate',
      retentionPrediction: map['retentionPrediction'] ?? 'Medium',
      engagementPrediction: map['engagementPrediction'] ?? 'Medium',
      suggestions: List<String>.from(map['suggestions'] ?? []),
      createdAt: parsedDate,
      suggestedHooks: (map['suggestedHooks'] as List?)
              ?.map((item) => SuggestedTextItem.fromJson(Map<String, dynamic>.from(item)))
              .toList() ??
          const [],
      suggestedCtas: (map['suggestedCtas'] as List?)
              ?.map((item) => SuggestedTextItem.fromJson(Map<String, dynamic>.from(item)))
              .toList() ??
          const [],
      suggestedCaptions: (map['suggestedCaptions'] as List?)
              ?.map((item) => SuggestedTextItem.fromJson(Map<String, dynamic>.from(item)))
              .toList() ??
          const [],
      hookScore: map['hookScore'] ?? 70,
      ctaScore: map['ctaScore'] ?? 65,
      captionScore: map['captionScore'] ?? 75,
      trendScore: map['trendScore'] ?? 70,
      transcript: map['transcript'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'videoPath': videoPath,
      'videoUrl': videoUrl,
      'viralScore': viralScore,
      'hookStrength': hookStrength,
      'retentionPrediction': retentionPrediction,
      'engagementPrediction': engagementPrediction,
      'suggestions': suggestions,
      'createdAt': createdAt.toIso8601String(),
      'suggestedHooks': suggestedHooks.map((item) => item.toJson()).toList(),
      'suggestedCtas': suggestedCtas.map((item) => item.toJson()).toList(),
      'suggestedCaptions': suggestedCaptions.map((item) => item.toJson()).toList(),
      'hookScore': hookScore,
      'ctaScore': ctaScore,
      'captionScore': captionScore,
      'trendScore': trendScore,
      'transcript': transcript,
    };
  }
}
