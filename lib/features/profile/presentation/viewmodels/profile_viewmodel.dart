import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/mock_config.dart';

class ProfileViewModel extends ChangeNotifier {
  bool _useMockMode = MockConfig.useMockMode;
  String _instagramHandle = '@priya_creations';
  bool _isPro = false;
  int _analysesPerformed = 2;
  
  ProfileViewModel() {
    _loadProfileData();
  }

  bool get useMockMode => _useMockMode;
  String get instagramHandle => _instagramHandle;
  bool get isPro => _isPro;
  int get analysesPerformed => _analysesPerformed;

  int get maxFreeAnalyses => 5;

  Future<void> _loadProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _useMockMode = prefs.getBool('reeliq_mock_mode') ?? MockConfig.useMockMode;
      MockConfig.useMockMode = _useMockMode;
      
      _instagramHandle = prefs.getString('reeliq_instagram_handle') ?? '@priya_creations';
      _isPro = prefs.getBool('reeliq_is_pro') ?? false;
      _analysesPerformed = prefs.getInt('reeliq_analyses_performed') ?? 2;
      
      notifyListeners();
    } catch (e) {
      debugPrint('ReelIQ: Failed to load profile: $e');
    }
  }

  Future<void> saveProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('reeliq_mock_mode', _useMockMode);
      await prefs.setString('reeliq_instagram_handle', _instagramHandle);
      await prefs.setBool('reeliq_is_pro', _isPro);
      await prefs.setInt('reeliq_analyses_performed', _analysesPerformed);
    } catch (e) {
      debugPrint('ReelIQ: Failed to save profile: $e');
    }
  }

  void toggleMockMode(bool value) {
    _useMockMode = value;
    MockConfig.useMockMode = value;
    saveProfileData();
    notifyListeners();
  }

  void setInstagramHandle(String handle) {
    _instagramHandle = handle;
    saveProfileData();
    notifyListeners();
  }

  void toggleSubscription() {
    _isPro = !_isPro;
    saveProfileData();
    notifyListeners();
  }

  void recordAnalysisPerformed() {
    _analysesPerformed += 1;
    saveProfileData();
    notifyListeners();
  }

  void refresh() {
    _loadProfileData();
  }
}
