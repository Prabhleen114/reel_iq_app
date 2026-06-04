class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;

  // Production fields
  final bool isPro;
  final int creatorLevel;
  final int creatorXp;
  final int creatorStreak;
  final int analysesPerformed;
  final String instagramHandle;
  final DateTime? planExpiry;
  final DateTime createdAt;
  final List<String> completedQuests;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.isPro = false,
    this.creatorLevel = 1,
    this.creatorXp = 0,
    this.creatorStreak = 0,
    this.analysesPerformed = 0,
    this.instagramHandle = '',
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
      creatorLevel: map['creatorLevel'] ?? 1,
      creatorXp: map['creatorXp'] ?? 0,
      creatorStreak: map['creatorStreak'] ?? 0,
      analysesPerformed: map['analysesPerformed'] ?? 0,
      instagramHandle: map['instagramHandle'] ?? '',
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
      'creatorLevel': creatorLevel,
      'creatorXp': creatorXp,
      'creatorStreak': creatorStreak,
      'analysesPerformed': analysesPerformed,
      'instagramHandle': instagramHandle,
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
    int? creatorLevel,
    int? creatorXp,
    int? creatorStreak,
    int? analysesPerformed,
    String? instagramHandle,
    DateTime? planExpiry,
    List<String>? completedQuests,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isPro: isPro ?? this.isPro,
      creatorLevel: creatorLevel ?? this.creatorLevel,
      creatorXp: creatorXp ?? this.creatorXp,
      creatorStreak: creatorStreak ?? this.creatorStreak,
      analysesPerformed: analysesPerformed ?? this.analysesPerformed,
      instagramHandle: instagramHandle ?? this.instagramHandle,
      planExpiry: planExpiry ?? this.planExpiry,
      createdAt: createdAt,
      completedQuests: completedQuests ?? this.completedQuests,
    );
  }
}
