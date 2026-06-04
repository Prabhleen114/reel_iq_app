import 'package:flutter/material.dart';
import '../../data/models/instagram_profile.dart';
import '../../data/models/instagram_reel.dart';
import '../../data/services/instagram_service.dart';
import '../../data/services/reel_analysis_service.dart';
import '../../data/services/creator_analysis_service.dart';

class InstagramViewModel extends ChangeNotifier {
  final InstagramService _instagramService;
  final ReelAnalysisService _reelAnalysisService;
  final CreatorAnalysisService _creatorAnalysisService;

  InstagramProfile _profile = InstagramProfile.disconnected();
  List<InstagramReel> _reels = [];
  final Map<String, ConnectedReelAnalysis> _analyses = {};
  CreatorProfileAnalysis? _creatorAnalysis;
  
  bool _isLoading = false;
  bool _isConnecting = false;
  bool _isAnalyzingReel = false;
  bool _isAnalyzingCreator = false;
  String? _errorMessage;

  InstagramViewModel(
    this._instagramService,
    this._reelAnalysisService,
    this._creatorAnalysisService,
  );

  InstagramProfile get profile => _profile;
  List<InstagramReel> get reels => _reels;
  CreatorProfileAnalysis? get creatorAnalysis => _creatorAnalysis;
  
  bool get isConnected => _profile.isConnected;
  bool get isLoading => _isLoading;
  bool get isConnecting => _isConnecting;
  bool get isAnalyzingReel => _isAnalyzingReel;
  bool get isAnalyzingCreator => _isAnalyzingCreator;
  String? get errorMessage => _errorMessage;

  ConnectedReelAnalysis? getAnalysis(String reelId) => _analyses[reelId];

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> checkConnection() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final savedProfile = await _instagramService.getConnectedProfile();
      if (savedProfile != null && savedProfile.isConnected) {
        _profile = savedProfile;
        await fetchLibrary();
      } else {
        _profile = InstagramProfile.disconnected();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> connect() async {
    _isConnecting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _instagramService.connectAccount();
      _isConnecting = false;
      notifyListeners();
      await fetchLibrary();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isConnecting = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> disconnect() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _instagramService.disconnectAccount();
      _profile = InstagramProfile.disconnected();
      _reels = [];
      _analyses.clear();
      _creatorAnalysis = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchLibrary() async {
    if (!_profile.isConnected || _profile.accessToken == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _reels = await _instagramService.fetchReels(_profile.accessToken!);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ConnectedReelAnalysis?> inspectReel(InstagramReel reel) async {
    if (_analyses.containsKey(reel.id)) {
      return _analyses[reel.id];
    }

    _isAnalyzingReel = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final analysis = await _reelAnalysisService.analyzeReel(reel);
      _analyses[reel.id] = analysis;
      _isAnalyzingReel = false;
      notifyListeners();
      return analysis;
    } catch (e) {
      _errorMessage = e.toString();
      _isAnalyzingReel = false;
      notifyListeners();
      return null;
    }
  }

  Future<CreatorProfileAnalysis?> analyzeCreatorProfile() async {
    if (_creatorAnalysis != null) return _creatorAnalysis;
    if (!_profile.isConnected || _reels.isEmpty) return null;

    _isAnalyzingCreator = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _creatorAnalysis = await _creatorAnalysisService.analyzeCreator(_profile, _reels);
      _isAnalyzingCreator = false;
      notifyListeners();
      return _creatorAnalysis;
    } catch (e) {
      _errorMessage = e.toString();
      _isAnalyzingCreator = false;
      notifyListeners();
      return null;
    }
  }
}
