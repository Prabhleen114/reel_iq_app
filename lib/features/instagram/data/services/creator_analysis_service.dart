import '../models/instagram_profile.dart';
import '../models/instagram_reel.dart';
import 'instagram_oauth_service.dart';

class CreatorProfileAnalysis {
  final int creatorScore;
  final String niche;
  final int consistencyScore;
  final int brandReadinessScore;
  final int growthPotentialScore;
  final List<String> nicheKeywords;
  final String recommendations;

  CreatorProfileAnalysis({
    required this.creatorScore,
    required this.niche,
    required this.consistencyScore,
    required this.brandReadinessScore,
    required this.growthPotentialScore,
    required this.nicheKeywords,
    required this.recommendations,
  });
}

abstract class CreatorAnalysisService {
  Future<CreatorProfileAnalysis> analyzeCreator(
    InstagramProfile profile, 
    List<InstagramReel> reels,
  );
}

class RealCreatorAnalysisService implements CreatorAnalysisService {
  final InstagramOAuthService _oauthService;

  RealCreatorAnalysisService(this._oauthService);

  @override
  Future<CreatorProfileAnalysis> analyzeCreator(
    InstagramProfile profile,
    List<InstagramReel> reels,
  ) async {
    if (reels.isEmpty) {
      return CreatorProfileAnalysis(
        creatorScore: 0,
        niche: 'Undetermined',
        consistencyScore: 0,
        brandReadinessScore: 0,
        growthPotentialScore: 0,
        nicheKeywords: [],
        recommendations: 'Upload more reels to analyze your content style and audience engagement.',
      );
    }

    try {
      final mediaData = reels.map((r) => <String, dynamic>{
        'id': r.id,
        'caption': r.caption,
        'likes_count': r.likesCount,
        'comments_count': r.commentsCount,
      }).toList();

      final response = await _oauthService.analyzeProfile(profile.toMap(), mediaData);
      final analysis = response['analysis'] ?? response;

      return CreatorProfileAnalysis(
        creatorScore: analysis['creator_score'] ?? 0,
        niche: analysis['niche'] ?? 'Undetermined',
        consistencyScore: analysis['consistency_score'] ?? 0,
        brandReadinessScore: analysis['brand_readiness_score'] ?? 0,
        growthPotentialScore: analysis['growth_potential_score'] ?? 0,
        nicheKeywords: List<String>.from(analysis['niche_keywords'] ?? []),
        recommendations: analysis['recommendations'] ?? 'Keep posting consistently.',
      );
    } catch (e) {
      // Fallback in case of failure so the app doesn't crash completely
      return CreatorProfileAnalysis(
        creatorScore: 60,
        niche: 'Backend Analysis Failed',
        consistencyScore: 50,
        brandReadinessScore: 50,
        growthPotentialScore: 50,
        nicheKeywords: [],
        recommendations: 'Failed to reach AI backend: $e',
      );
    }
  }
}
