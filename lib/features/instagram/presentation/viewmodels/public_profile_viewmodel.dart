import 'package:flutter/material.dart';
import '../../data/models/public_profile_analysis_model.dart';
import '../../data/services/public_instagram_service.dart';

class PublicProfileViewModel extends ChangeNotifier {
  final PublicInstagramService _service = PublicInstagramService();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  PublicProfileAnalysisModel? _currentAnalysis;
  PublicProfileAnalysisModel? get currentAnalysis => _currentAnalysis;

  Future<void> analyzeUsername(String userId, String username) async {
    _isLoading = true;
    _error = null;
    _currentAnalysis = null;
    notifyListeners();

    try {
      _currentAnalysis = await _service.analyzeProfile(userId, username);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _currentAnalysis = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
