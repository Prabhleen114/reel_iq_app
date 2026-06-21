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
  final int totalPosts;
  final int totalReels;
  final int followingCount;
  final String audiencePersona;
  final DateTime? lastOpenedDate;
  final bool onboardingCompleted;
  final List<String> interests;
  final String cameraConfidence;
  final DateTime? planExpiry;
  final DateTime? proActivatedAt;
  final String planName;
  final String subscriptionId;
  final String subscriptionStatus;
  final DateTime? nextBillingDate;
  final DateTime createdAt;
  final List<String> completedQuests;

  bool get hasActivePro => isPro && subscriptionStatus == 'active';

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
    this.totalPosts = 0,
    this.totalReels = 0,
    this.followingCount = 0,
    this.audiencePersona = '',
    this.lastOpenedDate,
    this.onboardingCompleted = false,
    this.interests = const [],
    this.cameraConfidence = '',
    this.planExpiry,
    this.proActivatedAt,
    this.planName = '',
    this.subscriptionId = '',
    this.subscriptionStatus = '',
    this.nextBillingDate,
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
      totalPosts: map['totalPosts'] ?? 0,
      totalReels: map['totalReels'] ?? 0,
      followingCount: map['followingCount'] ?? 0,
      audiencePersona: map['audiencePersona'] ?? '',
      lastOpenedDate: map['lastOpenedDate'] != null ? DateTime.tryParse(map['lastOpenedDate'] as String) : null,
      onboardingCompleted: map['onboardingCompleted'] ?? false,
      interests: List<String>.from(map['interests'] ?? []),
      cameraConfidence: map['cameraConfidence'] ?? '',
      planExpiry: map['planExpiry'] != null ? DateTime.tryParse(map['planExpiry'] as String) : null,
      proActivatedAt: map['proActivatedAt'] != null ? DateTime.tryParse(map['proActivatedAt'] as String) : null,
      planName: map['planName'] ?? '',
      subscriptionId: map['subscriptionId'] ?? '',
      subscriptionStatus: map['subscriptionStatus'] ?? '',
      nextBillingDate: map['nextBillingDate'] != null ? DateTime.tryParse(map['nextBillingDate'] as String) : null,
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now() : DateTime.now(),
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
      'totalPosts': totalPosts,
      'totalReels': totalReels,
      'followingCount': followingCount,
      'audiencePersona': audiencePersona,
      'lastOpenedDate': lastOpenedDate?.toIso8601String(),
      'onboardingCompleted': onboardingCompleted,
      'interests': interests,
      'cameraConfidence': cameraConfidence,
      'planExpiry': planExpiry?.toIso8601String(),
      'proActivatedAt': proActivatedAt?.toIso8601String(),
      'planName': planName,
      'subscriptionId': subscriptionId,
      'subscriptionStatus': subscriptionStatus,
      'nextBillingDate': nextBillingDate?.toIso8601String(),
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
    int? totalPosts,
    int? totalReels,
    int? followingCount,
    String? audiencePersona,
    DateTime? lastOpenedDate,
    bool? onboardingCompleted,
    List<String>? interests,
    String? cameraConfidence,
    DateTime? planExpiry,
    DateTime? proActivatedAt,
    String? planName,
    String? subscriptionId,
    String? subscriptionStatus,
    DateTime? nextBillingDate,
    DateTime? createdAt,
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
      totalPosts: totalPosts ?? this.totalPosts,
      totalReels: totalReels ?? this.totalReels,
      followingCount: followingCount ?? this.followingCount,
      audiencePersona: audiencePersona ?? this.audiencePersona,
      lastOpenedDate: lastOpenedDate ?? this.lastOpenedDate,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      interests: interests ?? this.interests,
      cameraConfidence: cameraConfidence ?? this.cameraConfidence,
      planExpiry: planExpiry ?? this.planExpiry,
      proActivatedAt: proActivatedAt ?? this.proActivatedAt,
      planName: planName ?? this.planName,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      createdAt: createdAt ?? this.createdAt,
      completedQuests: completedQuests ?? this.completedQuests,
    );
  }
}
