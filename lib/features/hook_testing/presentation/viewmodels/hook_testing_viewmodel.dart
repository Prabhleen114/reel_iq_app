import 'package:flutter/material.dart';
import '../../data/models/hook_test_model.dart';
import '../../data/repositories/hook_testing_repository.dart';

class HookTestingViewModel extends ChangeNotifier {
  final HookTestingRepository _hookTestingRepository;

  String _hookA = '';
  String _hookB = '';
  String _hookC = '';
  bool _isLoading = false;
  List<HookTestModel> _results = [];
  String? _errorMessage;

  HookTestingViewModel(this._hookTestingRepository);

  String get hookA => _hookA;
  String get hookB => _hookB;
  String get hookC => _hookC;
  bool get isLoading => _isLoading;
  List<HookTestModel> get results => _results;
  String? get errorMessage => _errorMessage;

  HookTestModel? get bestHook {
    if (_results.isEmpty) return null;
    try {
      return _results.firstWhere((r) => r.isBest);
    } catch (_) {
      return null;
    }
  }

  void setHookA(String value) {
    _hookA = value;
    notifyListeners();
  }

  void setHookB(String value) {
    _hookB = value;
    notifyListeners();
  }

  void setHookC(String value) {
    _hookC = value;
    notifyListeners();
  }

  void clearTest() {
    _hookA = '';
    _hookB = '';
    _hookC = '';
    _results = [];
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> runTest() async {
    if (_hookA.trim().isEmpty || _hookB.trim().isEmpty || _hookC.trim().isEmpty) {
      _errorMessage = 'Please enter scripts for all three hooks to perform side-by-side comparison.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    _results = [];
    notifyListeners();

    try {
      _results = await _hookTestingRepository.analyzeHooks(
        hookA: _hookA,
        hookB: _hookB,
        hookC: _hookC,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
