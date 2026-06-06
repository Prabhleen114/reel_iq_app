import 'package:flutter/foundation.dart';
import '../../../analysis/data/models/analysis_models.dart';
import '../../../analysis/data/services/analysis_api_service.dart';
import '../models/instagram_reel.dart';

class ConnectedReelAnalysis {
  final String reelId;
  final int hookScore;
  final int ctaScore;
  final int captionScore;
  final int engagementScore;
  final int viralScore;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> improvements;
  final List<SuggestedTextItem> suggestedHooks;
  final List<SuggestedTextItem> suggestedCtas;
  final List<SuggestedTextItem> suggestedCaptions;

  ConnectedReelAnalysis({
    required this.reelId,
    required this.hookScore,
    required this.ctaScore,
    required this.captionScore,
    required this.engagementScore,
    required this.viralScore,
    required this.strengths,
    required this.weaknesses,
    required this.improvements,
    this.suggestedHooks = const [],
    this.suggestedCtas = const [],
    this.suggestedCaptions = const [],
  });
}

abstract class ReelAnalysisService {
  Future<ConnectedReelAnalysis> analyzeReel(InstagramReel reel);
}

class RealReelAnalysisService implements ReelAnalysisService {
  final AnalysisApiService _apiService;

  RealReelAnalysisService(this._apiService);

  @override
  Future<ConnectedReelAnalysis> analyzeReel(InstagramReel reel) async {
    if (reel.videoUrl != null && reel.videoUrl!.isNotEmpty) {
      final apiResponse = await _apiService.analyzeReelFromUrl(
        reel.videoUrl!,
        'Reel ${reel.id}',
        reel.caption,
      );
      if (apiResponse != null) {
        final insights = apiResponse.insights;
        return ConnectedReelAnalysis(
          reelId: reel.id,
          hookScore: insights.hookScore,
          ctaScore: insights.ctaScore,
          captionScore: insights.captionScore,
          engagementScore: insights.engagementScore,
          viralScore: insights.viralScore,
          strengths: insights.strengths.isNotEmpty ? insights.strengths : ['Visual clarity: Content displays centered framing.'],
          weaknesses: insights.weaknesses.isNotEmpty ? insights.weaknesses : ['Uncertain drop-offs: Check pacing in the mid-clip.'],
          improvements: insights.improvements.isNotEmpty ? insights.improvements : ['Experiment with 3-second jump cuts.'],
          suggestedHooks: insights.suggestedHooks,
          suggestedCtas: insights.suggestedCtas,
          suggestedCaptions: insights.suggestedCaptions,
        );
      }
    }
    
    throw Exception("Failed to analyze reel: Backend returned null or videoUrl is missing.");
  }
}
