import 'package:flutter/foundation.dart';
import '../../../../core/services/firestore_service.dart';
import '../../data/services/instagram_oauth_service.dart';

class InstagramProfileAnalysisViewModel extends ChangeNotifier {
  final InstagramOAuthService _oauthService;
  final FirestoreService _firestoreService;

  InstagramProfileAnalysisViewModel(this._oauthService, this._firestoreService);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Map<String, dynamic>? _analysisResult;
  Map<String, dynamic>? get analysisResult => _analysisResult;

  Map<String, dynamic>? _profileData;
  Map<String, dynamic>? get profileData => _profileData;

  Future<void> loadOrPerformAnalysis(String userId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // 1. Try to load latest from Firestore
      final existingAnalysis = await _firestoreService.getLatestInstagramAnalysis(userId);
      if (existingAnalysis != null) {
        _analysisResult = existingAnalysis['aiAnalysis'];
        _profileData = existingAnalysis['profileData'];
        _setLoading(false);
        return;
      }

      // 2. Otherwise, check if user is connected to Instagram
      final connectionData = await _firestoreService.getInstagramConnection(userId);
      if (connectionData == null || connectionData['isConnected'] != true || connectionData['accessToken'] == null) {
        _errorMessage = 'Instagram account not connected. Please connect your account first.';
        _setLoading(false);
        return;
      }

      final accessToken = connectionData['accessToken'];

      // 3. Fetch data via backend proxy
      final profile = await _oauthService.fetchUserProfile(accessToken);
      final media = await _oauthService.fetchUserMedia(accessToken);

      // 4. Send for AI analysis
      final analysis = await _oauthService.analyzeProfile(profile, media);

      _profileData = profile;
      _analysisResult = analysis['aiAnalysis'];

      // 5. Save to Firestore
      await _firestoreService.saveInstagramAnalysis(userId, {
        'userId': userId,
        'profileData': profile,
        'statistics': analysis['statistics'],
        'aiAnalysis': analysis['aiAnalysis'],
        'createdAt': DateTime.now().toIso8601String(),
      });

    } catch (e) {
      String errorStr = 'Unknown error';
      try {
        errorStr = e.toString();
      } catch (_) {
        errorStr = 'A database or network error occurred (FirebaseException).';
      }
      _errorMessage = 'Failed to load analysis: $errorStr';
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
