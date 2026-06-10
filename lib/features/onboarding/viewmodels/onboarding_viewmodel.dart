import 'package:flutter/material.dart';
import '../../auth/data/models/user_model.dart';
import '../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../instagram/data/services/public_instagram_service.dart';
import '../../../../core/services/firestore_service.dart';

class OnboardingViewModel extends ChangeNotifier {
  final PublicInstagramService _instagramService = PublicInstagramService();
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  String _handle = '';
  String get handle => _handle;

  List<String> _interests = [];
  List<String> get interests => _interests;

  String _cameraConfidence = '';
  String get cameraConfidence => _cameraConfidence;

  // Instagram Data
  String _profilePictureUrl = '';
  int _followersCount = 0;
  double _engagementRate = 0.0;
  String _niche = '';
  String _audiencePersona = '';
  String _displayName = '';

  void setHandle(String value) {
    _handle = value;
    notifyListeners();
  }

  void toggleInterest(String interest) {
    if (_interests.contains(interest)) {
      _interests.remove(interest);
    } else {
      _interests.add(interest);
    }
    notifyListeners();
  }

  void setCameraConfidence(String confidence) {
    _cameraConfidence = confidence;
    notifyListeners();
  }

  Future<bool> analyzeInstagram(String userId) async {
    if (_handle.isEmpty) {
      _error = 'Please enter your Instagram handle.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint("Before analyzeProfile() - Calling for $_handle");
      final result = await _instagramService.analyzeProfile(userId, _handle);
      debugPrint("After analyzeProfile() - Received response");
      
      final snap = result.profileSnapshot;
      final ai = result.aiAnalysis;
      
      _profilePictureUrl = snap['profile_picture_url'] ?? snap['profilePictureUrl'] ?? '';
      _followersCount = snap['followers_count'] ?? snap['followersCount'] ?? 0;
      _engagementRate = (snap['engagement_rate'] ?? snap['engagementRate'] ?? 0.0).toDouble();
      _displayName = snap['display_name'] ?? snap['fullName'] ?? snap['username'] ?? _handle;

      _niche = ai['niche'] ?? '';
      _audiencePersona = ai['audiencePersona'] ?? '';

      debugPrint("Extracted values: followersCount=$_followersCount, followingCount=${snap['follows_count'] ?? snap['followingCount']}, mediaCount=${snap['media_count'] ?? snap['mediaCount']}, engagementRate=$_engagementRate, niche=$_niche");

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      debugPrint("Error in analyzeProfile: $_error");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> completeOnboarding(AuthViewModel authViewModel) async {
    final user = authViewModel.user;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final updatedUser = user.copyWith(
        instagramHandle: _handle,
        profilePictureUrl: _profilePictureUrl,
        followersCount: _followersCount,
        engagementRate: _engagementRate,
        niche: _niche,
        audiencePersona: _audiencePersona,
        interests: _interests,
        cameraConfidence: _cameraConfidence,
        onboardingCompleted: true,
      );

      debugPrint("Before saveUser() - Payload: ${updatedUser.toMap()}");
      await _firestoreService.saveUser(updatedUser);
      debugPrint("After saveUser() - Completed");
      // We don't have a direct setter in AuthViewModel, but authStateChanges will pick it up or we can just let GoRouter handle it after it saves to firestore.
      // However, we should probably update the local authViewModel state if possible, but AuthViewModel's user is a getter.
      // GoRouter redirect will run when auth state changes if we use a stream, but AuthViewModel might not trigger notifyListeners.
      // Let's call a method on AuthViewModel to refresh user if needed.
      await authViewModel.refreshUser(); // We'll add this method
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}
