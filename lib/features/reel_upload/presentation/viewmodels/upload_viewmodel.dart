import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../dashboard/data/models/reel_analysis_model.dart';
import '../../../dashboard/data/repositories/analysis_repository.dart';

class UploadViewModel extends ChangeNotifier {
  final AnalysisRepository _analysisRepository;
  final ImagePicker _picker = ImagePicker();

  File? _videoFile;
  String _title = '';
  bool _isLoading = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;

  UploadViewModel(this._analysisRepository);

  File? get videoFile => _videoFile;
  String get title => _title;
  bool get isLoading => _isLoading;
  double get uploadProgress => _uploadProgress;
  String? get errorMessage => _errorMessage;

  void setTitle(String value) {
    _title = value;
    notifyListeners();
  }

  Future<void> pickVideo() async {
    _errorMessage = null;
    try {
      final XFile? pickedFile = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 3),
      );
      
      if (pickedFile != null) {
        _videoFile = File(pickedFile.path);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to pick video: ${e.toString()}';
      notifyListeners();
    }
  }

  void clearVideo() {
    _videoFile = null;
    _title = '';
    _uploadProgress = 0.0;
    _errorMessage = null;
    notifyListeners();
  }

  Future<ReelAnalysisModel?> uploadReel(String userId) async {
    if (_videoFile == null) {
      _errorMessage = 'Please select a video first.';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _uploadProgress = 0.0;
    _errorMessage = null;
    notifyListeners();

    try {
      final analysis = await _analysisRepository.runAiAnalysis(
        userId: userId,
        title: _title,
        videoFile: _videoFile!,
        onUploadProgress: (progress) {
          _uploadProgress = progress;
          notifyListeners();
        },
      );
      
      _isLoading = false;
      _videoFile = null;
      _title = '';
      _uploadProgress = 0.0;
      notifyListeners();
      return analysis;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
}
