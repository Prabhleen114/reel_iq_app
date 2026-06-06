import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:reeliq/features/analysis/data/services/analysis_api_service.dart';
import 'package:reeliq/features/instagram/data/models/instagram_reel.dart';
import 'package:reeliq/features/instagram/data/services/reel_analysis_service.dart';

void main() {
  group('AnalysisApiService Integration Test', () {
    late AnalysisApiService apiService;
    late File testVideo;

    setUp(() {
      apiService = AnalysisApiService(baseUrl: 'http://127.0.0.1:8000');
      testVideo = File('backend/test_video.mp4');
    });

    test('health check verification', () async {
      expect(testVideo.existsSync(), isTrue, reason: 'test_video.mp4 must exist for integration tests');
    });

    test('analyzeReel uploads and parses JSON correctly', () async {
      final response = await apiService.analyzeReel(testVideo, 'Test Reel via Unit Test');
      
      expect(response, isNotNull);
      expect(response!.durationSeconds, greaterThan(0));
      expect(response.sceneChanges, greaterThanOrEqualTo(0));
      expect(response.insights, isNotNull);
      
      final insights = response.insights;
      expect(insights.hookScore, between(50, 100));
      expect(insights.ctaScore, between(50, 100));
      expect(insights.viralScore, between(50, 100));
      expect(insights.engagementScore, between(50, 100));
      expect(insights.captionScore, between(50, 100));
      expect(insights.trendScore, between(50, 100));
      
      expect(insights.strengths, isNotEmpty);
      expect(insights.weaknesses, isNotEmpty);
      expect(insights.improvements, isNotEmpty);
      expect(insights.suggestedHooks, isNotEmpty);
      expect(insights.suggestedHooks.first.type, isNotEmpty);
      expect(insights.suggestedHooks.first.text, isNotEmpty);
      expect(insights.suggestedCtas, isNotEmpty);
      expect(insights.suggestedCaptions, isNotEmpty);
      
      print('Parsed upload scores:');
      print('  Hook Score: ${insights.hookScore}');
      print('  CTA Score: ${insights.ctaScore}');
      print('  Viral Score: ${insights.viralScore}');
      print('  Engagement Score: ${insights.engagementScore}');
      print('  Caption Score: ${insights.captionScore}');
      print('  Trend Score: ${insights.trendScore}');
      print('Strengths: ${insights.strengths}');
      print('Weaknesses: ${insights.weaknesses}');
      print('Improvements: ${insights.improvements}');
      print('Suggested Hooks: ${insights.suggestedHooks.map((e) => "${e.type}: ${e.text}").toList()}');
    });

    test('RealReelAnalysisService analyzeReel calls analyze-url and parses successfully', () async {
      final reelService = RealReelAnalysisService(apiService);
      final reel = InstagramReel(
        id: 'test-reel-id',
        thumbnailUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4',
        caption: 'How to build an AI startup in 24 hours #ai #startup #coding',
        likesCount: 1500,
        commentsCount: 200,
        publishDate: DateTime.now(),
        videoUrl: 'https://www.w3schools.com/html/mov_bbb.mp4',
      );
      
      final analysis = await reelService.analyzeReel(reel);
      expect(analysis, isNotNull);
      expect(analysis.reelId, equals(reel.id));
      expect(analysis.hookScore, between(50, 100));
      expect(analysis.viralScore, between(50, 100));
      expect(analysis.strengths, isNotEmpty);
      expect(analysis.suggestedHooks, isNotEmpty);
      expect(analysis.suggestedHooks.first.type, isNotEmpty);
      expect(analysis.suggestedHooks.first.text, isNotEmpty);
      expect(analysis.suggestedCtas, isNotEmpty);
      expect(analysis.suggestedCaptions, isNotEmpty);
      
      print('Parsed Reel URL Analysis:');
      print('  Hook Score: ${analysis.hookScore}');
      print('  CTA Score: ${analysis.ctaScore}');
      print('  Caption Score: ${analysis.captionScore}');
      print('  Engagement Score: ${analysis.engagementScore}');
      print('  Viral Score: ${analysis.viralScore}');
      print('  Strengths: ${analysis.strengths}');
      print('  Weaknesses: ${analysis.weaknesses}');
      print('  Improvements: ${analysis.improvements}');
      print('  Suggested Hooks: ${analysis.suggestedHooks.map((e) => "${e.type}: ${e.text}").toList()}');
      print('  Suggested CTAs: ${analysis.suggestedCtas.map((e) => "${e.type}: ${e.text}").toList()}');
      print('  Suggested Captions: ${analysis.suggestedCaptions.map((e) => "${e.type}: ${e.text}").toList()}');
    });
  });
}

Matcher between(int min, int max) => allOf(greaterThanOrEqualTo(min), lessThanOrEqualTo(max));
