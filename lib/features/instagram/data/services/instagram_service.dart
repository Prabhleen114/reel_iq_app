import '../models/instagram_profile.dart';
import '../models/instagram_reel.dart';
import '../../../../core/services/firestore_service.dart';
import 'instagram_oauth_service.dart';

abstract class InstagramService {
  Future<InstagramProfile> connectAccount();
  Future<List<InstagramReel>> fetchReels(String accessToken);
  Future<void> disconnectAccount();
  Future<InstagramProfile?> getConnectedProfile();
}

class MockInstagramService implements InstagramService {
  InstagramProfile? _connectedProfile;
  final List<InstagramReel> _mockLibrary = [
    InstagramReel(
      id: 'ig-reel-101',
      thumbnailUrl: 'https://images.unsplash.com/photo-1542751371-adc38448a05e',
      videoUrl:
          'https://assets.mixkit.co/videos/preview/mixkit-girl-in-neon-sign-lighting-34507-large.mp4',
      caption:
          'This ONE VS Code shortcut will save you hours of typing! 💻🔥 #codinghacks #developer #vscode #programming #softwareengineer',
      likesCount: 12450,
      commentsCount: 382,
      publishDate: DateTime.now().subtract(const Duration(days: 2)),
      permalink: 'https://instagram.com/reel/mock101',
      viewCount: 142000,
    ),
    InstagramReel(
      id: 'ig-reel-102',
      thumbnailUrl: 'https://images.unsplash.com/photo-1531403009284-440f080d1e12',
      videoUrl:
          'https://assets.mixkit.co/videos/preview/mixkit-typing-on-a-luminous-keyboard-in-the-dark-44222-large.mp4',
      caption:
          'Why you should STOP using plain CSS in 2026. 🤯 Here is what to use instead... 👇 #webdevelopment #css #reactjs #nextjs #coderlife',
      likesCount: 8930,
      commentsCount: 198,
      publishDate: DateTime.now().subtract(const Duration(days: 5)),
      permalink: 'https://instagram.com/reel/mock102',
      viewCount: 95400,
    ),
    InstagramReel(
      id: 'ig-reel-103',
      thumbnailUrl: 'https://images.unsplash.com/photo-1555066931-4365d14bab8c',
      videoUrl:
          'https://assets.mixkit.co/videos/preview/mixkit-digital-animation-of-screens-43093-large.mp4',
      caption:
          r"My $5,000 developer setup tour. Minimalism at its best! 🚀🖥️ Rate it 1-10 in comments! #setuptour #desksetup #developerlife #productivity",
      likesCount: 22100,
      commentsCount: 890,
      publishDate: DateTime.now().subtract(const Duration(days: 9)),
      permalink: 'https://instagram.com/reel/mock103',
      viewCount: 310200,
    ),
    InstagramReel(
      id: 'ig-reel-104',
      thumbnailUrl: 'https://images.unsplash.com/photo-1517694712202-14dd9538aa97',
      videoUrl:
          'https://assets.mixkit.co/videos/preview/mixkit-girl-in-neon-sign-lighting-34507-large.mp4',
      caption:
          'How I learned to code in 6 months with zero experience. (My roadmap revealed) 🗺️🎒 #learncode #programminglanguage #computerscience #careerchange',
      likesCount: 5400,
      commentsCount: 112,
      publishDate: DateTime.now().subtract(const Duration(days: 14)),
      permalink: 'https://instagram.com/reel/mock104',
      viewCount: 48900,
    ),
  ];

  @override
  Future<InstagramProfile> connectAccount() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    _connectedProfile = InstagramProfile(
      username: 'tech_creator_iq',
      displayName: 'Tech Creator IQ',
      photoUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61',
      followersCount: 45200,
      followingCount: 842,
      postsCount: 148,
      reelsCount: 42,
      accessToken: 'mock_meta_user_token_9923849182',
      isConnected: true,
      lastSyncAt: DateTime.now(),
      tokenExpiry: DateTime.now().add(const Duration(days: 60)),
    );
    return _connectedProfile!;
  }

  @override
  Future<List<InstagramReel>> fetchReels(String accessToken) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    if (_connectedProfile == null) {
      throw Exception('No connected Instagram account found.');
    }
    return _mockLibrary;
  }

  @override
  Future<void> disconnectAccount() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _connectedProfile = null;
  }

  @override
  Future<InstagramProfile?> getConnectedProfile() async {
    return _connectedProfile;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REAL INSTAGRAM SERVICE
// Uses InstagramOAuthService + Firestore for production connections.
// Activated when MockConfig.useMockMode = false AND Meta App ID is configured.
// ─────────────────────────────────────────────────────────────────────────────

class RealInstagramService implements InstagramService {
  final InstagramOAuthService _oauthService;
  final FirestoreService _firestoreService;
  final String _userId;

  InstagramProfile? _cachedProfile;

  RealInstagramService({
    required InstagramOAuthService oauthService,
    required FirestoreService firestoreService,
    required String userId,
  })  : _oauthService = oauthService,
        _firestoreService = firestoreService,
        _userId = userId;

  String getOAuthUrl() => _oauthService.getAuthorizeUrl();

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

    await _firestoreService.saveInstagramConnection(_userId, profile.toMap());
    _cachedProfile = profile;
    return profile;
  }

  @override
  Future<InstagramProfile> connectAccount() async {
    throw UnsupportedError(
        'In real mode, use getOAuthUrl() + handleOAuthCode() instead.');
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
    await _firestoreService.saveInstagramConnection(_userId, {
      'isConnected': false,
      'accessToken': null,
      'disconnectedAt': DateTime.now().toIso8601String(),
    });
    _cachedProfile = null;
  }

  @override
  Future<InstagramProfile?> getConnectedProfile() async {
    if (_cachedProfile != null) return _cachedProfile;
    final data = await _firestoreService.getInstagramConnection(_userId);
    if (data != null && data['isConnected'] == true) {
      _cachedProfile = InstagramProfile.fromMap(data);
      return _cachedProfile;
    }
    return null;
  }
}
