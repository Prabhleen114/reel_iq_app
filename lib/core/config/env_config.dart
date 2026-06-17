import 'dart:io';
import 'package:flutter/foundation.dart';

class EnvConfig {
  /// The production base URL for your backend API
  static const String _prodBaseUrl = 'https://api.reeliq.app'; // Production URL to be configured in real DNS

  /// Determines the Base URL based on environment
  static String get baseUrl {
    if (kReleaseMode) {
      return _prodBaseUrl;
    }

    // Development URLs
    if (kIsWeb) return 'http://127.0.0.1:8000';
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }
}
