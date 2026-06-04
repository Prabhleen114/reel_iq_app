import 'package:flutter/foundation.dart';

class MockConfig {
  static bool _useMockMode = true;

  static bool get useMockMode => _useMockMode;

  static set useMockMode(bool value) {
    _useMockMode = value;
    if (kDebugMode) {
      print('ReelIQ: Mock Mode changed to $_useMockMode');
    }
  }

  /// Initial checks to see if Firebase is configured.
  /// If initialization throws, we automatically fallback to Mock Mode.
  static void setMockModeForced(bool forced) {
    _useMockMode = forced;
  }
}
