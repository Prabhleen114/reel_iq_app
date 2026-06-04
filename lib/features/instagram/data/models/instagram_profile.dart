class InstagramProfile {
  final String username;
  final String displayName;
  final String photoUrl;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final int reelsCount;
  final String? accessToken;
  final bool isConnected;

  // V3 Production fields
  final String? userId;
  final DateTime? lastSyncAt;
  final DateTime? tokenExpiry;
  final String? biography;
  final String? website;

  InstagramProfile({
    required this.username,
    required this.displayName,
    required this.photoUrl,
    required this.followersCount,
    required this.followingCount,
    required this.postsCount,
    required this.reelsCount,
    this.accessToken,
    required this.isConnected,
    this.userId,
    this.lastSyncAt,
    this.tokenExpiry,
    this.biography,
    this.website,
  });

  factory InstagramProfile.disconnected() {
    return InstagramProfile(
      username: '',
      displayName: '',
      photoUrl: '',
      followersCount: 0,
      followingCount: 0,
      postsCount: 0,
      reelsCount: 0,
      isConnected: false,
    );
  }

  factory InstagramProfile.fromMap(Map<String, dynamic> map) {
    return InstagramProfile(
      username: map['username'] ?? '',
      displayName: map['displayName'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      followersCount: (map['followersCount'] ?? map['followers_count'] ?? 0) as int,
      followingCount: (map['followingCount'] ?? map['follows_count'] ?? 0) as int,
      postsCount: (map['postsCount'] ?? map['media_count'] ?? 0) as int,
      reelsCount: map['reelsCount'] ?? 0,
      accessToken: map['accessToken'],
      isConnected: map['isConnected'] ?? true,
      userId: (map['userId'] ?? map['id'])?.toString(),
      lastSyncAt: map['lastSyncAt'] != null
          ? DateTime.tryParse(map['lastSyncAt'] as String)
          : null,
      tokenExpiry: map['tokenExpiry'] != null
          ? DateTime.tryParse(map['tokenExpiry'] as String)
          : null,
      biography: map['biography'],
      website: map['website'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
      'reelsCount': reelsCount,
      'accessToken': accessToken,
      'isConnected': isConnected,
      'userId': userId,
      'lastSyncAt': lastSyncAt?.toIso8601String(),
      'tokenExpiry': tokenExpiry?.toIso8601String(),
      'biography': biography,
      'website': website,
    };
  }

  InstagramProfile copyWith({
    String? username,
    String? displayName,
    String? photoUrl,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    int? reelsCount,
    String? accessToken,
    bool? isConnected,
    String? userId,
    DateTime? lastSyncAt,
    DateTime? tokenExpiry,
    String? biography,
    String? website,
  }) {
    return InstagramProfile(
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      reelsCount: reelsCount ?? this.reelsCount,
      accessToken: accessToken ?? this.accessToken,
      isConnected: isConnected ?? this.isConnected,
      userId: userId ?? this.userId,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      tokenExpiry: tokenExpiry ?? this.tokenExpiry,
      biography: biography ?? this.biography,
      website: website ?? this.website,
    );
  }
}
