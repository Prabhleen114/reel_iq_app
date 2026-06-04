import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'mock_config.dart';

/// Wraps Firebase Crashlytics for crash reporting and non-fatal error logging.
/// All methods silently no-op in mock mode or debug builds without Firebase.
class CrashlyticsService {
  FirebaseCrashlytics? _crashlytics;

  CrashlyticsService() {
    if (!MockConfig.useMockMode) {
      try {
        _crashlytics = FirebaseCrashlytics.instance;
      } catch (e) {
        debugPrint('CrashlyticsService: Crashlytics unavailable — $e');
      }
    }
  }

  /// Call after Firebase.initializeApp() to wire Flutter errors to Crashlytics.
  Future<void> initialize() async {
    if (_crashlytics == null) return;
    try {
      // Pass all uncaught framework errors to Crashlytics
      FlutterError.onError = _crashlytics!.recordFlutterFatalError;
      // In production builds, also capture Dart async errors
      if (!kDebugMode) {
        await _crashlytics!.setCrashlyticsCollectionEnabled(true);
      } else {
        // Disable in debug so we see full stack traces in console
        await _crashlytics!.setCrashlyticsCollectionEnabled(false);
      }
    } catch (e) {
      debugPrint('CrashlyticsService.initialize error: $e');
    }
  }

  /// Attach the authenticated user's ID to crash reports.
  Future<void> setUserId(String uid) async {
    if (_crashlytics == null) return;
    try {
      await _crashlytics!.setUserIdentifier(uid);
    } catch (e) {
      debugPrint('CrashlyticsService.setUserId error: $e');
    }
  }

  /// Record a non-fatal exception (e.g. API call failures).
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    debugPrint('CrashlyticsService: ${fatal ? 'FATAL' : 'Error'} — $reason: $exception');
    if (_crashlytics == null) return;
    try {
      await _crashlytics!.recordError(
        exception,
        stack,
        reason: reason,
        fatal: fatal,
      );
    } catch (e) {
      debugPrint('CrashlyticsService.recordError failed: $e');
    }
  }

  /// Add a custom key/value to crash reports for better debugging context.
  Future<void> setCustomKey(String key, Object value) async {
    if (_crashlytics == null) return;
    try {
      await _crashlytics!.setCustomKey(key, value);
    } catch (e) {
      debugPrint('CrashlyticsService.setCustomKey error: $e');
    }
  }

  /// Log a breadcrumb message to trace user steps before a crash.
  Future<void> log(String message) async {
    if (_crashlytics == null) return;
    try {
      await _crashlytics!.log(message);
    } catch (e) {
      debugPrint('CrashlyticsService.log error: $e');
    }
  }
}
