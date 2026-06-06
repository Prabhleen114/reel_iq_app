import 'package:cloud_firestore/cloud_firestore.dart';

class PublicProfileAnalysisModel {
  final String id;
  final String userId;
  final String searchedUsername;
  final Map<String, dynamic> profileSnapshot;
  final Map<String, dynamic> aiAnalysis;
  final DateTime createdAt;
  final DateTime lastUpdated;

  PublicProfileAnalysisModel({
    required this.id,
    required this.userId,
    required this.searchedUsername,
    required this.profileSnapshot,
    required this.aiAnalysis,
    required this.createdAt,
    required this.lastUpdated,
  });

  factory PublicProfileAnalysisModel.fromMap(Map<String, dynamic> map, String id) {
    return PublicProfileAnalysisModel(
      id: id,
      userId: map['userId'] ?? '',
      searchedUsername: map['searchedUsername'] ?? '',
      profileSnapshot: Map<String, dynamic>.from(map['profileSnapshot'] ?? {}),
      aiAnalysis: Map<String, dynamic>.from(map['aiAnalysis'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastUpdated: (map['lastUpdated'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'searchedUsername': searchedUsername,
      'profileSnapshot': profileSnapshot,
      'aiAnalysis': aiAnalysis,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}
