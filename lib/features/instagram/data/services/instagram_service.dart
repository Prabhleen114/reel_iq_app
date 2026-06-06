import '../models/instagram_profile.dart';
import '../models/instagram_reel.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import 'instagram_oauth_service.dart';

abstract class InstagramService {
  Future<InstagramProfile> connectAccount(String code);
  Future<List<InstagramReel>> fetchReels(String accessToken);
  Future<void> disconnectAccount();
  Future<InstagramProfile?> getConnectedProfile();
}

// ─────────────────────────────────────────────────────────────────────────────
// REAL INSTAGRAM SERVICE
// Uses InstagramOAuthService + Firestore for production connections.
// ─────────────────────────────────────────────────────────────────────────────

class RealInstagramService implements InstagramService {
  final InstagramOAuthService _oauthService;
  final FirestoreService _firestoreService;
  final AuthRepository _authRepository;

  InstagramProfile? _cachedProfile;

  RealInstagramService({
    required InstagramOAuthService oauthService,
    required FirestoreService firestoreService,
    required AuthRepository authRepository,
  })  : _oauthService = oauthService,
        _firestoreService = firestoreService,
        _authRepository = authRepository;

  String getOAuthUrl() => _oauthService.getAuthorizeUrl();

  String get _currentUserId {
    final uid = _authRepository.currentUser?.uid;
    if (uid == null) throw Exception('User not logged in');
    return uid;
  }

  Future<InstagramProfile> handleOAuthCode(String code) async {
    final tokenResult = await _oauthService.exchangeCodeForToken(code);
    final profileData =
        await _oauthService.fetchUserProfile(tokenResult.accessToken);

    final profile = InstagramProfile(
      username: profileData['username'] ?? '',
      displayName: profileData['name'] ?? profileData['username'] ?? '',
      photoUrl: profileData['profile_picture_url'] ?? '',
      followersCount: profileData['followers_count'] ?? 0,
      followingCount: profileData['follows_count'] ?? 0,
      postsCount: profileData['media_count'] ?? 0,
      reelsCount: 0,
      accessToken: tokenResult.accessToken,
      isConnected: true,
      userId: tokenResult.userId,
      lastSyncAt: DateTime.now(),
      tokenExpiry: tokenResult.expiresIn != null
          ? DateTime.now().add(Duration(seconds: tokenResult.expiresIn!))
          : DateTime.now().add(const Duration(days: 60)),
      biography: profileData['biography'],
      website: profileData['website'],
    );

    await _firestoreService.saveInstagramConnection(_currentUserId, profile.toMap());
    _cachedProfile = profile;
    return profile;
  }

  @override
  Future<InstagramProfile> connectAccount(String code) async {
    return await handleOAuthCode(code);
  }

  @override
  Future<List<InstagramReel>> fetchReels(String accessToken) async {
    final mediaItems =
        await _oauthService.fetchUserMedia(accessToken, limit: 25);
    return mediaItems.map((item) {
      return InstagramReel(
        id: item['id']?.toString() ?? '',
        thumbnailUrl: item['thumbnail_url'] ?? item['media_url'] ?? '',
        videoUrl: item['media_url'],
        caption: item['caption'] ?? '',
        likesCount: item['like_count'] ?? 0,
        commentsCount: item['comments_count'] ?? 0,
        publishDate:
            DateTime.tryParse(item['timestamp'] ?? '') ?? DateTime.now(),
        permalink: item['permalink'],
        viewCount: null,
      );
    }).toList();
  }

  @override
  Future<void> disconnectAccount() async {
    await _firestoreService.saveInstagramConnection(_currentUserId, {
      'isConnected': false,
      'accessToken': null,
      'disconnectedAt': DateTime.now().toIso8601String(),
    });
    _cachedProfile = null;
  }

  @override
  Future<InstagramProfile?> getConnectedProfile() async {
    if (_cachedProfile != null) return _cachedProfile;
    final data = await _firestoreService.getInstagramConnection(_currentUserId);
    if (data != null && data['isConnected'] == true) {
      _cachedProfile = InstagramProfile.fromMap(data);
      return _cachedProfile;
    }
    return null;
  }
}
