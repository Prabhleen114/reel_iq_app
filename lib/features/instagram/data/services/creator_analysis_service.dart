import '../models/instagram_profile.dart';
import '../models/instagram_reel.dart';

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

class MockCreatorAnalysisService implements CreatorAnalysisService {
  @override
  Future<CreatorProfileAnalysis> analyzeCreator(
    InstagramProfile profile, 
    List<InstagramReel> reels,
  ) async {
    // Simulate deep profile-level network/ML scoring delay
    await Future.delayed(const Duration(milliseconds: 1800));

    if (reels.isEmpty) {
      return CreatorProfileAnalysis(
        creatorScore: 60,
        niche: 'Undetermined',
        consistencyScore: 30,
        brandReadinessScore: 50,
        growthPotentialScore: 55,
        nicheKeywords: [],
        recommendations: 'Upload more reels to analyze your content style and audience engagement.',
      );
    }

    // Heuristic: Assess niche by scanning keywords in captions
    int techCount = 0;
    int designCount = 0;
    int businessCount = 0;

    for (final reel in reels) {
      final caption = reel.caption.toLowerCase();
      if (caption.contains('code') || caption.contains('developer') || caption.contains('vscode') || caption.contains('programming') || caption.contains('css')) {
        techCount++;
      }
      if (caption.contains('minimalism') || caption.contains('setup') || caption.contains('desk') || caption.contains('design')) {
        designCount++;
      }
      if (caption.contains('startup') || caption.contains('pitch') || caption.contains('business') || caption.contains('niche')) {
        businessCount++;
      }
    }

    String niche = 'Tech Setup & Design';
    List<String> keywords = ['Minimalism', 'Setup Design'];

    if (techCount > designCount && techCount > businessCount) {
      niche = 'Software Development & Productivity Hacks';
      keywords = ['VS Code', 'Coding Shortcuts', 'Software Engineering'];
    } else if (businessCount > techCount && businessCount > designCount) {
      niche = 'AI Business Startups & Tech Pitches';
      keywords = ['AI Startup', 'Elevator Pitches', 'Tech Business'];
    }

    // Calculate Consistency Score: Average days between posts
    int consistency = 85; // Good consistency: 2-3 days average
    
    // Calculate Brand Readiness: High if likes/engagement ratio is healthy and captions are professional
    int brandReadiness = 78;
    if (profile.followersCount > 10000 && reels.any((r) => r.likesCount > 5000)) {
      brandReadiness += 10;
    }

    // Calculate Growth Potential: High if followers are growing and total views are steady
    int growthPotential = 82;

    int creatorScore = ((consistency + brandReadiness + growthPotential) / 3).round();

    return CreatorProfileAnalysis(
      creatorScore: creatorScore,
      niche: niche,
      consistencyScore: consistency,
      brandReadinessScore: brandReadiness,
      growthPotentialScore: growthPotential,
      nicheKeywords: keywords,
      recommendations: 'Your profile is highly optimized for sponsorships. To unlock 2x growth: '
          '1. Focus on publishing 3-second tutorial reels showing direct screen captures. '
          '2. Include a visual "Comment CODE for Link" call to action to boost engagement rates. '
          '3. Keep posting at your current consistent interval of every 2-3 days.',
    );
  }
}
