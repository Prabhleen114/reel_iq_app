class SuggestedTextItem {
  final String type;
  final String text;

  SuggestedTextItem({required this.type, required this.text});

  factory SuggestedTextItem.fromJson(Map<String, dynamic> json) {
    return SuggestedTextItem(
      type: json['type'] ?? '',
      text: json['text'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'text': text,
    };
  }
}

class BackendInsights {
  final int hookScore;
  final int ctaScore;
  final int viralScore;
  final int engagementScore;
  final int captionScore;
  final int trendScore;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> improvements;
  final List<SuggestedTextItem> suggestedHooks;
  final List<SuggestedTextItem> suggestedCtas;
  final List<SuggestedTextItem> suggestedCaptions;

  BackendInsights({
    required this.hookScore,
    required this.ctaScore,
    required this.viralScore,
    required this.engagementScore,
    required this.captionScore,
    required this.trendScore,
    required this.strengths,
    required this.weaknesses,
    required this.improvements,
    required this.suggestedHooks,
    required this.suggestedCtas,
    required this.suggestedCaptions,
  });

  factory BackendInsights.fromJson(Map<String, dynamic> json) {
    return BackendInsights(
      hookScore: json['hook_score'] ?? 0,
      ctaScore: json['cta_score'] ?? 0,
      viralScore: json['viral_score'] ?? 0,
      engagementScore: json['engagement_score'] ?? 0,
      captionScore: json['caption_score'] ?? 0,
      trendScore: json['trend_score'] ?? 0,
      strengths: List<String>.from(json['strengths'] ?? []),
      weaknesses: List<String>.from(json['weaknesses'] ?? []),
      improvements: List<String>.from(json['improvements'] ?? []),
      suggestedHooks: (json['suggested_hooks'] as List?)
              ?.map((item) => SuggestedTextItem.fromJson(Map<String, dynamic>.from(item)))
              .toList() ??
          [],
      suggestedCtas: (json['suggested_ctas'] as List?)
              ?.map((item) => SuggestedTextItem.fromJson(Map<String, dynamic>.from(item)))
              .toList() ??
          [],
      suggestedCaptions: (json['suggested_captions'] as List?)
              ?.map((item) => SuggestedTextItem.fromJson(Map<String, dynamic>.from(item)))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hook_score': hookScore,
      'cta_score': ctaScore,
      'viral_score': viralScore,
      'engagement_score': engagementScore,
      'caption_score': captionScore,
      'trend_score': trendScore,
      'strengths': strengths,
      'weaknesses': weaknesses,
      'improvements': improvements,
      'suggested_hooks': suggestedHooks.map((item) => item.toJson()).toList(),
      'suggested_ctas': suggestedCtas.map((item) => item.toJson()).toList(),
      'suggested_captions': suggestedCaptions.map((item) => item.toJson()).toList(),
    };
  }
}

class BackendAnalysisResponse {
  final double durationSeconds;
  final int sceneChanges;
  final String captionText;
  final String transcript;
  final BackendInsights insights;

  BackendAnalysisResponse({
    required this.durationSeconds,
    required this.sceneChanges,
    required this.captionText,
    required this.transcript,
    required this.insights,
  });

  factory BackendAnalysisResponse.fromJson(Map<String, dynamic> json) {
    return BackendAnalysisResponse(
      durationSeconds: (json['duration_seconds'] as num?)?.toDouble() ?? 0.0,
      sceneChanges: json['scene_changes'] ?? 0,
      captionText: json['caption_text'] ?? '',
      transcript: json['transcript'] ?? '',
      insights: BackendInsights.fromJson(json['insights'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'duration_seconds': durationSeconds,
      'scene_changes': sceneChanges,
      'caption_text': captionText,
      'transcript': transcript,
      'insights': insights.toJson(),
    };
  }
}
