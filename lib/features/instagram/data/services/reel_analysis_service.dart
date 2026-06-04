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

class MockReelAnalysisService implements ReelAnalysisService {
  final AnalysisApiService _apiService;

  MockReelAnalysisService(this._apiService);

  @override
  Future<ConnectedReelAnalysis> analyzeReel(InstagramReel reel) async {
    // 1. Try FastAPI URL Backend
    if (reel.videoUrl != null && reel.videoUrl!.isNotEmpty) {
      try {
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
      } catch (e) {
        debugPrint('ReelIQ Warning: Instagram Reel backend analyze failed: $e');
      }
    }
    
    // 2. Mock Fallback
    debugPrint('ReelIQ: FastAPI backend offline for Reel library. Falling back to local rules engine.');
    // Simulate complex AI analysis delay
    await Future.delayed(const Duration(milliseconds: 1400));

    final captionLower = reel.caption.toLowerCase();

    // Deterministic metrics based on caption heuristics
    int hookScore = 70;
    int ctaScore = 65;
    int captionScore = 75;
    
    final List<String> strengths = [];
    final List<String> weaknesses = [];
    final List<String> improvements = [];

    // Hook logic: Look at first sentence curiosity cues
    final sentences = reel.caption.split(RegExp(r'[.!?]'));
    final firstSentence = sentences.isNotEmpty ? sentences.first : '';
    
    if (firstSentence.contains('how') || firstSentence.contains('why') || firstSentence.contains('one') || firstSentence.contains('stop')) {
      hookScore += 18;
      strengths.add('High-impact hook: Uses psychological triggers ("stop", "why", numerical stats) in the first sentence.');
    } else {
      hookScore -= 8;
      weaknesses.add('Weak visual/textual hook: Caption does not open with a strong curiosity gap.');
      improvements.add('Open the first line with a clear problem statement or a bold assertion (e.g. "Stop doing X").');
    }

    // CTA logic: Look for calls to action at the end
    if (captionLower.contains('👇') || captionLower.contains('comment') || captionLower.contains('link') || captionLower.contains('save')) {
      ctaScore += 22;
      strengths.add('Strong call-to-action: Explicitly instructs users to comment, click a link, or save.');
    } else {
      ctaScore -= 12;
      weaknesses.add('Missing/weak CTA: No direction telling users what to do next after watching.');
      improvements.add('Add a direct, high-value CTA (e.g., "Comment ROADMAP and I will DM you the link").');
    }

    // Caption formatting/hashtag logic
    final hashtagsCount = RegExp(r'#\w+').allMatches(reel.caption).length;
    if (hashtagsCount >= 3 && hashtagsCount <= 7) {
      captionScore += 15;
      strengths.add('Hashtag balance: Uses an optimal number of relevant keywords ($hashtagsCount tags).');
    } else if (hashtagsCount > 10) {
      captionScore -= 5;
      weaknesses.add('Over-tagged caption: Excessive hashtags ($hashtagsCount) can trigger spam-filters or look messy.');
      improvements.add('Reduce total hashtags to 5 targeted niche terms instead of a cluster.');
    } else {
      improvements.add('Add 3-5 niche hashtags (e.g. #vscode, #webdeveloper) to feed the routing algorithms.');
    }

    // Compute final scores
    int engagementScore = ((reel.likesCount * 3 + reel.commentsCount * 8) / (reel.viewCount ?? 10000) * 1000).clamp(50, 98).round();
    int viralScore = ((hookScore * 0.4) + (ctaScore * 0.3) + (captionScore * 0.2) + (engagementScore * 0.1)).round().clamp(50, 99);

    if (viralScore >= 85) {
      strengths.add('Excellent retention probability: Fast delivery, punchy structure, and high viewer interaction rates.');
    } else {
      weaknesses.add('Retention drop-offs: Pacing and formatting could be optimized to keep users engaged past 3 seconds.');
      improvements.add('Incorporate visual pattern interrupts (e.g. split screens, text overlays) every 2.5 seconds.');
    }

    final mockTopic = reel.caption.trim().isEmpty ? 'Reel' : reel.caption.split(' ').take(3).join(' ');
    final mockHooks = [
      SuggestedTextItem(type: 'Curiosity', text: 'The secret behind $mockTopic that nobody tells you... 👇'),
      SuggestedTextItem(type: 'Problem-Solving', text: 'Stop wasting hours! Here is how to master $mockTopic instead.'),
      SuggestedTextItem(type: 'Bold Statement', text: 'One simple change to double your results with $mockTopic.'),
    ];
    final mockCtas = [
      SuggestedTextItem(type: 'Comment-Trigger', text: 'Comment GUIDE below and I will DM you the code! 📥'),
      SuggestedTextItem(type: 'Save-Trigger', text: 'Save this reel so you don\'t lose it later! 💾'),
      SuggestedTextItem(type: 'Share-Trigger', text: 'Share this with a friend who needs this! 🚀'),
    ];
    final mockCaptions = [
      SuggestedTextItem(type: 'Value-Packed', text: 'Here is how to get started with $mockTopic: \n\n1️⃣ Keep it simple\n2️⃣ Follow for more tips!'),
      SuggestedTextItem(type: 'Short & Punchy', text: 'If you are struggling with $mockTopic, try this simple adjustment.'),
      SuggestedTextItem(type: 'Storytelling', text: 'It took me years to realize this, but consistency in $mockTopic always wins.'),
    ];

    return ConnectedReelAnalysis(
      reelId: reel.id,
      hookScore: hookScore,
      ctaScore: ctaScore,
      captionScore: captionScore,
      engagementScore: engagementScore,
      viralScore: viralScore,
      strengths: strengths,
      weaknesses: weaknesses,
      improvements: improvements,
      suggestedHooks: mockHooks,
      suggestedCtas: mockCtas,
      suggestedCaptions: mockCaptions,
    );
  }
}
