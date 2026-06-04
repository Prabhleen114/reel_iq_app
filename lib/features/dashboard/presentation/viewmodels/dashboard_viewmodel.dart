import 'package:flutter/material.dart';
import '../../data/models/reel_analysis_model.dart';
import '../../data/repositories/analysis_repository.dart';

class DashboardViewModel extends ChangeNotifier {
  final AnalysisRepository _analysisRepository;

  List<ReelAnalysisModel> _analyses = [];
  bool _isLoading = false;
  String? _errorMessage;

  DashboardViewModel(this._analysisRepository);

  List<ReelAnalysisModel> get analyses => _analyses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalReelsAnalyzed => _analyses.length;

  int get averageViralScore {
    if (_analyses.isEmpty) return 0;
    final total = _analyses.fold<int>(0, (sum, item) => sum + item.viralScore);
    return (total / _analyses.length).round();
  }

  Future<void> loadAnalyses(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _analyses = await _analysisRepository.getAnalysesForUser(userId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAnalysis(String id, String userId) async {
    try {
      await _analysisRepository.deleteAnalysis(id);
      await loadAnalyses(userId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
