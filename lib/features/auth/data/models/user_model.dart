class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;

  // Production fields
  final bool isPro;
  final int appStreak;
  final int analysesPerformed;
  final String instagramHandle;
  final String profilePictureUrl;
  final int followersCount;
  final double engagementRate;
  final String niche;
  final String audiencePersona;
  final DateTime? lastOpenedDate;
  final bool onboardingCompleted;
  final List<String> interests;
  final String cameraConfidence;
  final DateTime? planExpiry;
  final DateTime createdAt;
  final List<String> completedQuests;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.isPro = false,
    this.appStreak = 1,
    this.analysesPerformed = 0,
    this.instagramHandle = '',
    this.profilePictureUrl = '',
    this.followersCount = 0,
    this.engagementRate = 0.0,
    this.niche = '',
    this.audiencePersona = '',
    this.lastOpenedDate,
    this.onboardingCompleted = false,
    this.interests = const [],
    this.cameraConfidence = '',
    this.planExpiry,
    DateTime? createdAt,
    this.completedQuests = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoUrl: map['photoUrl'],
      isPro: map['isPro'] ?? false,
      appStreak: map['appStreak'] ?? 1,
      analysesPerformed: map['analysesPerformed'] ?? 0,
      instagramHandle: map['instagramHandle'] ?? '',
      profilePictureUrl: map['profilePictureUrl'] ?? '',
      followersCount: map['followersCount'] ?? 0,
      engagementRate: (map['engagementRate'] ?? 0.0).toDouble(),
      niche: map['niche'] ?? '',
      audiencePersona: map['audiencePersona'] ?? '',
      lastOpenedDate: map['lastOpenedDate'] != null
          ? DateTime.tryParse(map['lastOpenedDate'] as String)
          : null,
      onboardingCompleted: map['onboardingCompleted'] ?? false,
      interests: List<String>.from(map['interests'] ?? []),
      cameraConfidence: map['cameraConfidence'] ?? '',
      planExpiry: map['planExpiry'] != null
          ? DateTime.tryParse(map['planExpiry'] as String)
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      completedQuests: List<String>.from(map['completedQuests'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'isPro': isPro,
      'appStreak': appStreak,
      'analysesPerformed': analysesPerformed,
      'instagramHandle': instagramHandle,
      'profilePictureUrl': profilePictureUrl,
      'followersCount': followersCount,
      'engagementRate': engagementRate,
      'niche': niche,
      'audiencePersona': audiencePersona,
      'lastOpenedDate': lastOpenedDate?.toIso8601String(),
      'onboardingCompleted': onboardingCompleted,
      'interests': interests,
      'cameraConfidence': cameraConfidence,
      'planExpiry': planExpiry?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'completedQuests': completedQuests,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isPro,
    int? appStreak,
    int? analysesPerformed,
    String? instagramHandle,
    String? profilePictureUrl,
    int? followersCount,
    double? engagementRate,
    String? niche,
    String? audiencePersona,
    DateTime? lastOpenedDate,
    bool? onboardingCompleted,
    List<String>? interests,
    String? cameraConfidence,
    DateTime? planExpiry,
    List<String>? completedQuests,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isPro: isPro ?? this.isPro,
      appStreak: appStreak ?? this.appStreak,
      analysesPerformed: analysesPerformed ?? this.analysesPerformed,
      instagramHandle: instagramHandle ?? this.instagramHandle,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      followersCount: followersCount ?? this.followersCount,
      engagementRate: engagementRate ?? this.engagementRate,
      niche: niche ?? this.niche,
      audiencePersona: audiencePersona ?? this.audiencePersona,
      lastOpenedDate: lastOpenedDate ?? this.lastOpenedDate,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      interests: interests ?? this.interests,
      cameraConfidence: cameraConfidence ?? this.cameraConfidence,
      planExpiry: planExpiry ?? this.planExpiry,
      createdAt: createdAt,
      completedQuests: completedQuests ?? this.completedQuests,
    );
  }
}
