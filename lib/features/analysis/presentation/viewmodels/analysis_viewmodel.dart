import 'package:flutter/material.dart';
import '../../../dashboard/data/models/reel_analysis_model.dart';
import '../../../dashboard/data/repositories/analysis_repository.dart';

class AnalysisViewModel extends ChangeNotifier {
  final AnalysisRepository _analysisRepository;

  ReelAnalysisModel? _analysis;
  bool _isLoading = false;
  String? _errorMessage;

  AnalysisViewModel(this._analysisRepository);

  ReelAnalysisModel? get analysis => _analysis;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadAnalysis(String id) async {
    _isLoading = true;
    _errorMessage = null;
    _analysis = null;
    notifyListeners();

    try {
      _analysis = await _analysisRepository.getAnalysisById(id);
      if (_analysis == null) {
        _errorMessage = "Analysis not found.";
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
