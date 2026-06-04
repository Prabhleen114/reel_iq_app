import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/mock_config.dart';

class ProfileViewModel extends ChangeNotifier {
  bool _useMockMode = MockConfig.useMockMode;
  String _instagramHandle = '@priya_creations';
  bool _isPro = false;
  int _creatorLevel = 5;
  int _creatorXp = 340;
  int _creatorStreak = 12;
  int _analysesPerformed = 2;
  List<String> _completedQuests = ["Generate 3 Hooks"];
  
  ProfileViewModel() {
    _loadProfileData();
  }

  bool get useMockMode => _useMockMode;
  String get instagramHandle => _instagramHandle;
  bool get isPro => _isPro;
  int get creatorLevel => _creatorLevel;
  int get creatorXp => _creatorXp;
  int get creatorStreak => _creatorStreak;
  int get analysesPerformed => _analysesPerformed;
  List<String> get completedQuests => _completedQuests;

  int get maxFreeAnalyses => 5;
  int get xpNeededForNextLevel => 500;

  Future<void> _loadProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _useMockMode = prefs.getBool('reeliq_mock_mode') ?? MockConfig.useMockMode;
      MockConfig.useMockMode = _useMockMode;
      
      _instagramHandle = prefs.getString('reeliq_instagram_handle') ?? '@priya_creations';
      _isPro = prefs.getBool('reeliq_is_pro') ?? false;
      _creatorLevel = prefs.getInt('reeliq_creator_level') ?? 5;
      _creatorXp = prefs.getInt('reeliq_creator_xp') ?? 340;
      _creatorStreak = prefs.getInt('reeliq_creator_streak') ?? 12;
      _analysesPerformed = prefs.getInt('reeliq_analyses_performed') ?? 2;
      _completedQuests = prefs.getStringList('reeliq_completed_quests') ?? ["Generate 3 Hooks"];
      
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
      await prefs.setInt('reeliq_creator_level', _creatorLevel);
      await prefs.setInt('reeliq_creator_xp', _creatorXp);
      await prefs.setInt('reeliq_creator_streak', _creatorStreak);
      await prefs.setInt('reeliq_analyses_performed', _analysesPerformed);
      await prefs.setStringList('reeliq_completed_quests', _completedQuests);
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

  void addXp(int amount) {
    _creatorXp += amount;
    if (_creatorXp >= xpNeededForNextLevel) {
      _creatorLevel += 1;
      _creatorXp -= xpNeededForNextLevel;
    }
    saveProfileData();
    notifyListeners();
  }

  void incrementStreak() {
    _creatorStreak += 1;
    saveProfileData();
    notifyListeners();
  }

  void recordAnalysisPerformed() {
    _analysesPerformed += 1;
    saveProfileData();
    notifyListeners();
  }

  void completeQuest(String quest) {
    if (!_completedQuests.contains(quest)) {
      _completedQuests.add(quest);
      addXp(50); // standard quest reward
      saveProfileData();
      notifyListeners();
    }
  }

  void resetQuests() {
    _completedQuests.clear();
    saveProfileData();
    notifyListeners();
  }

  void refresh() {
    _loadProfileData();
  }
}
