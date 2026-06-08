import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/public_profile_analysis_model.dart';

class PublicInstagramService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Set this to true if testing on Android Emulator, false if testing on physical Android device
  static const bool _isEmulator = false;

  static String _getBaseUrl() {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    if (Platform.isAndroid) {
      return _isEmulator ? 'http://10.0.2.2:8000' : 'http://192.168.0.119:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  /// Analyze a public profile with caching logic
  Future<PublicProfileAnalysisModel> analyzeProfile(String userId, String rawUsername) async {
    // 1. Normalize username
    final username = rawUsername.trim().replaceAll('@', '').toLowerCase();
    if (username.isEmpty) {
      throw Exception('Username cannot be empty');
    }

    // 2. Check cache (within last 24 hours)
    final cacheRef = await _firestore
        .collection('public_profile_analysis')
        .where('searchedUsername', isEqualTo: username)
        .get();

    if (cacheRef.docs.isNotEmpty) {
      final models = cacheRef.docs
          .map((doc) => PublicProfileAnalysisModel.fromMap(doc.data(), doc.id))
          .toList();
          
      // Sort in-memory to avoid requiring composite index
      models.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      final cachedModel = models.first;
      
      final cacheAge = DateTime.now().difference(cachedModel.createdAt);
      if (cacheAge.inHours < 24) {
        return cachedModel;
      }
    }

    // 3. Call backend if no valid cache
    final baseUrl = _getBaseUrl();
    try {
      final uri = Uri.parse('$baseUrl/instagram/public-profile-analysis');
      debugPrint('[API REQUEST] $uri');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username}),
      ).timeout(const Duration(seconds: 45)); // Give backend time to scrape and run groq

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Failed to analyze profile');
      }

      final data = json.decode(response.body);
      
      // 4. Save to Firestore
      final newDocRef = _firestore.collection('public_profile_analysis').doc();
      final model = PublicProfileAnalysisModel(
        id: newDocRef.id,
        userId: userId,
        searchedUsername: username,
        profileSnapshot: data['profileSnapshot'],
        aiAnalysis: data['aiAnalysis'],
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      );

      await newDocRef.set(model.toMap());
      
      return model;
      
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
         throw Exception('Request timed out. The profile might be too large or the server is busy.');
      }
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network or server error: $e');
    }
  }

  /// Fetch history for dashboard
  Future<List<PublicProfileAnalysisModel>> fetchUserHistory(String userId) async {
    final query = await _firestore
        .collection('public_profile_analysis')
        .where('userId', isEqualTo: userId)
        .get();
        
    final models = query.docs
        .map((doc) => PublicProfileAnalysisModel.fromMap(doc.data(), doc.id))
        .toList();
        
    // Sort in-memory to avoid requiring composite index
    models.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return models;
  }
}
