import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'mock_config.dart';

/// Analytics service wrapping Firebase Analytics.
/// All events silently no-op in mock mode or when Firebase is unavailable.
class AnalyticsService {
  FirebaseAnalytics? _analytics;

  AnalyticsService() {
    if (!MockConfig.useMockMode) {
      try {
        _analytics = FirebaseAnalytics.instance;
      } catch (e) {
        debugPrint('AnalyticsService: Firebase Analytics unavailable — $e');
      }
    }
  }

  Future<void> _log(String name, [Map<String, Object>? params]) async {
    if (_analytics == null) return;
    try {
      await _analytics!.logEvent(name: name, parameters: params);
    } catch (e) {
      debugPrint('AnalyticsService._log error: $e');
    }
  }

  // ─── User Identity ───────────────────────────────────────
  Future<void> setUserId(String uid) async {
    if (_analytics == null) return;
    try {
      await _analytics!.setUserId(id: uid);
    } catch (e) {
      debugPrint('AnalyticsService.setUserId error: $e');
    }
  }

  // ─── Analysis Events ─────────────────────────────────────
  Future<void> logReelAnalyzed({required String title, required int viralScore}) async {
    await _log('reel_analyzed', {
      'reel_title': title,
      'viral_score': viralScore,
    });
  }

  Future<void> logReelUploadStarted() async {
    await _log('reel_upload_started');
  }

  // ─── Content Planner Events ───────────────────────────────
  Future<void> logCalendarGenerated({required String niche, required String frequency}) async {
    await _log('calendar_generated', {
      'niche': niche,
      'frequency': frequency,
    });
  }

  // ─── Rewrite / Copy Events ────────────────────────────────
  Future<void> logRewriteCopied({required String type}) async {
    await _log('rewrite_copied', {'rewrite_type': type});
  }

  // ─── Instagram Events ─────────────────────────────────────
  Future<void> logInstagramConnected() async {
    await _log('instagram_connected');
  }

  Future<void> logCompetitorAudited() async {
    await _log('competitor_audited');
  }

  Future<void> logReelInspected() async {
    await _log('reel_inspected');
  }

  // ─── Subscription Events ─────────────────────────────────
  Future<void> logProUpgradeStarted() async {
    await _log('pro_upgrade_started');
  }

  Future<void> logProUpgradeCompleted() async {
    await _log('pro_upgrade_completed');
  }

  // ─── Creator Report Events ────────────────────────────────
  Future<void> logCreatorReportGenerated() async {
    await _log('creator_report_generated');
  }

  // ─── Onboarding Events ────────────────────────────────────
  Future<void> logOnboardingCompleted() async {
    await _log('onboarding_completed');
  }

  Future<void> logScreenView({required String screenName}) async {
    if (_analytics == null) return;
    try {
      await _analytics!.logScreenView(screenName: screenName);
    } catch (e) {
      debugPrint('AnalyticsService.logScreenView error: $e');
    }
  }
}
