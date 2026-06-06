import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/dashboard/data/models/reel_analysis_model.dart';
import '../../features/dashboard/data/models/content_calendar_model.dart';
import 'mock_config.dart';

/// Centralised Firestore CRUD helper.
/// All methods silently no-op when [MockConfig.useMockMode] is true.
class FirestoreService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  bool get _isLive => !MockConfig.useMockMode;

  // ─────────────────────────────────────────────
  // USERS
  // ─────────────────────────────────────────────

  Future<void> saveUser(UserModel user) async {
    if (!_isLive) return;
    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreService.saveUser error: $e');
    }
  }

  Future<UserModel?> getUser(String uid) async {
    if (!_isLive) return null;
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
    } catch (e) {
      debugPrint('FirestoreService.getUser error: $e');
    }
    return null;
  }

  Future<void> updateUserField(String uid, Map<String, dynamic> fields) async {
    if (!_isLive) return;
    try {
      await _db.collection('users').doc(uid).update(fields);
    } catch (e) {
      debugPrint('FirestoreService.updateUserField error: $e');
    }
  }

  // ─────────────────────────────────────────────
  // ANALYSES
  // ─────────────────────────────────────────────

  Future<void> saveAnalysis(String uid, ReelAnalysisModel analysis) async {
    if (!_isLive) return;
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('analyses')
          .doc(analysis.id)
          .set(analysis.toMap());
    } catch (e) {
      debugPrint('FirestoreService.saveAnalysis error: $e');
    }
  }

  Future<List<ReelAnalysisModel>> getAnalyses(String uid) async {
    if (!_isLive) return [];
    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('analyses')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      return snapshot.docs
          .map((doc) => ReelAnalysisModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('FirestoreService.getAnalyses error: $e');
    }
    return [];
  }

  // ─────────────────────────────────────────────
  // CONTENT CALENDARS
  // ─────────────────────────────────────────────

  Future<void> saveCalendar(String uid, ContentCalendarModel calendar) async {
    if (!_isLive) return;
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('calendars')
          .doc(calendar.id)
          .set(calendar.toJson());
    } catch (e) {
      debugPrint('FirestoreService.saveCalendar error: $e');
    }
  }

  Future<List<ContentCalendarModel>> getCalendars(String uid) async {
    if (!_isLive) return [];
    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('calendars')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();
      return snapshot.docs
          .map((doc) => ContentCalendarModel.fromJson(doc.data(), docId: doc.id))
          .toList();
    } catch (e) {
      debugPrint('FirestoreService.getCalendars error: $e');
    }
    return [];
  }

  Future<void> deleteCalendar(String uid, String calendarId) async {
    if (!_isLive) return;
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('calendars')
          .doc(calendarId)
          .delete();
    } catch (e) {
      debugPrint('FirestoreService.deleteCalendar error: $e');
    }
  }

  // ─────────────────────────────────────────────
  // INSTAGRAM CONNECTION
  // ─────────────────────────────────────────────

  Future<void> saveInstagramConnection(String uid, Map<String, dynamic> data) async {
    if (!_isLive) return;
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('integrations')
          .doc('instagram')
          .set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreService.saveInstagramConnection error: $e');
    }
  }

  Future<Map<String, dynamic>?> getInstagramConnection(String uid) async {
    if (!_isLive) return null;
    try {
      final doc = await _db
          .collection('users')
          .doc(uid)
          .collection('integrations')
          .doc('instagram')
          .get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint('FirestoreService.getInstagramConnection error. (Suppressed raw exception to prevent JS interop crash)');
      throw Exception('Could not verify Instagram connection. Please check your network.');
    }
    return null;
  }

  // ─────────────────────────────────────────────
  // INSTAGRAM ANALYSIS
  // ─────────────────────────────────────────────

  Future<void> saveInstagramAnalysis(String uid, Map<String, dynamic> analysis) async {
    if (!_isLive) return;
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('instagram_analysis')
          .add(analysis);
    } catch (e) {
      debugPrint('FirestoreService.saveInstagramAnalysis error. (Suppressed raw exception to prevent JS interop crash)');
    }
  }

  Future<Map<String, dynamic>?> getLatestInstagramAnalysis(String uid) async {
    if (!_isLive) return null;
    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('instagram_analysis')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return {...snapshot.docs.first.data(), 'id': snapshot.docs.first.id};
      }
    } catch (e) {
      debugPrint('FirestoreService.getLatestInstagramAnalysis error. (Suppressed raw exception to prevent JS interop crash)');
      throw Exception('Database read error. Please check your connection or permissions.');
    }
    return null;
  }

  // ─────────────────────────────────────────────
  // CREATOR REPORTS
  // ─────────────────────────────────────────────

  Future<void> saveReport(String uid, Map<String, dynamic> report) async {
    if (!_isLive) return;
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('reports')
          .add(report);
    } catch (e) {
      debugPrint('FirestoreService.saveReport error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getReports(String uid) async {
    if (!_isLive) return [];
    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('reports')
          .orderBy('generatedAt', descending: true)
          .limit(10)
          .get();
      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    } catch (e) {
      debugPrint('FirestoreService.getReports error: $e');
    }
    return [];
  }
}
