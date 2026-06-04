import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Configuration — fill these in from your Meta Developer App dashboard.
/// See: https://developers.facebook.com/apps/
class InstagramOAuthConfig {
  /// Your Meta App ID from https://developers.facebook.com/apps/
  static const String appId = 'YOUR_META_APP_ID';

  /// Your Meta App Secret (keep server-side only in production).
  static const String appSecret = 'YOUR_META_APP_SECRET';

  /// OAuth redirect URI registered in your Meta App dashboard.
  /// Must be HTTPS and exactly match what's in the developer console.
  static const String redirectUri = 'https://reeliq.app/auth/instagram/callback';

  /// Scopes requested from the Instagram Basic Display API.
  static const List<String> scopes = [
    'instagram_basic',
    'instagram_content_publish',
    'pages_show_list',
    'pages_read_engagement',
  ];

  static String get authorizeUrl =>
      'https://api.instagram.com/oauth/authorize'
      '?client_id=$appId'
      '&redirect_uri=${Uri.encodeComponent(redirectUri)}'
      '&scope=${scopes.join(',')}'
      '&response_type=code';
}

/// Result returned after a successful OAuth token exchange.
class InstagramTokenResult {
  final String accessToken;
  final String tokenType;
  final int? expiresIn;
  final String userId;

  InstagramTokenResult({
    required this.accessToken,
    required this.tokenType,
    this.expiresIn,
    required this.userId,
  });
}

/// Handles the real Instagram Graph API OAuth 2.0 flow and data fetching.
///
/// IMPORTANT: Real Instagram connection requires:
/// 1. A Meta Developer account at https://developers.facebook.com
/// 2. An App with Instagram Basic Display API enabled
/// 3. Approved permissions: instagram_basic
/// 4. Registered redirect URI matching [InstagramOAuthConfig.redirectUri]
/// 5. App Review approval for production (development mode works without it)
///
/// In mock mode, this service is never instantiated — MockInstagramService handles all calls.
class InstagramOAuthService {
  static const String _graphBase = 'https://graph.instagram.com';
  static const String _oauthBase = 'https://api.instagram.com';

  /// Generates the OAuth authorization URL to open in a WebView.
  String getAuthorizeUrl() => InstagramOAuthConfig.authorizeUrl;

  /// Exchanges an authorization code for a short-lived access token,
  /// then immediately exchanges it for a long-lived token.
  Future<InstagramTokenResult> exchangeCodeForToken(String code) async {
    // Step 1: Short-lived token
    final shortTokenResponse = await http.post(
      Uri.parse('$_oauthBase/oauth/access_token'),
      body: {
        'client_id': InstagramOAuthConfig.appId,
        'client_secret': InstagramOAuthConfig.appSecret,
        'grant_type': 'authorization_code',
        'redirect_uri': InstagramOAuthConfig.redirectUri,
        'code': code,
      },
    );

    if (shortTokenResponse.statusCode != 200) {
      throw Exception(
          'Instagram token exchange failed: ${shortTokenResponse.body}');
    }

    final shortData = json.decode(shortTokenResponse.body) as Map<String, dynamic>;
    final shortToken = shortData['access_token'] as String;
    final userId = (shortData['user_id'] ?? '').toString();

    // Step 2: Long-lived token (60 days)
    final longTokenResponse = await http.get(
      Uri.parse(
          '$_graphBase/access_token'
          '?grant_type=ig_exchange_token'
          '&client_secret=${InstagramOAuthConfig.appSecret}'
          '&access_token=$shortToken'),
    );

    if (longTokenResponse.statusCode == 200) {
      final longData =
          json.decode(longTokenResponse.body) as Map<String, dynamic>;
      return InstagramTokenResult(
        accessToken: longData['access_token'] as String,
        tokenType: longData['token_type'] as String? ?? 'bearer',
        expiresIn: longData['expires_in'] as int?,
        userId: userId,
      );
    }

    // Fall back to short-lived token if long exchange fails
    return InstagramTokenResult(
      accessToken: shortToken,
      tokenType: 'bearer',
      userId: userId,
    );
  }

  /// Fetches the authenticated user's Instagram profile.
  Future<Map<String, dynamic>> fetchUserProfile(String accessToken) async {
    final response = await http.get(
      Uri.parse(
          '$_graphBase/me'
          '?fields=id,username,name,biography,followers_count,follows_count,media_count,profile_picture_url,website'
          '&access_token=$accessToken'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch Instagram profile: ${response.body}');
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// Fetches the user's recent media (reels/posts).
  Future<List<Map<String, dynamic>>> fetchUserMedia(String accessToken,
      {int limit = 25}) async {
    final response = await http.get(
      Uri.parse(
          '$_graphBase/me/media'
          '?fields=id,caption,media_type,media_url,thumbnail_url,permalink,timestamp,like_count,comments_count'
          '&limit=$limit'
          '&access_token=$accessToken'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch Instagram media: ${response.body}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final List<dynamic> items = data['data'] ?? [];
    return items
        .where((item) => item['media_type'] == 'VIDEO' || item['media_type'] == 'REEL')
        .map((item) => item as Map<String, dynamic>)
        .toList();
  }

  /// Refreshes a long-lived token before it expires.
  Future<String> refreshToken(String accessToken) async {
    final response = await http.get(
      Uri.parse(
          '$_graphBase/refresh_access_token'
          '?grant_type=ig_refresh_token'
          '&access_token=$accessToken'),
    );

    if (response.statusCode != 200) {
      debugPrint('Token refresh failed: ${response.body}');
      return accessToken; // Return existing token as fallback
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    return data['access_token'] as String? ?? accessToken;
  }
}
