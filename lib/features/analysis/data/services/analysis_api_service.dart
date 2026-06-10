import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/analysis_models.dart';

class AnalysisApiService {
  final String baseUrl;

  // Set this to true if testing on Android Emulator, false if testing on physical Android device
  static const bool _isEmulator = false;

  static String _getBaseUrl() {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    if (Platform.isAndroid) {
      return _isEmulator ? 'http://10.0.2.2:8000' : 'http://192.168.29.25:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  AnalysisApiService({String? baseUrl}) : baseUrl = baseUrl ?? _getBaseUrl() {
    debugPrint('ReelIQ AnalysisApiService: Targeting backend at → ${baseUrl ?? _getBaseUrl()}');
  }

  /// Uploads video to FastAPI backend for frame extraction, Whisper transcription,
  /// Tesseract OCR text parsing, and AI scoring insights.
  /// Returns BackendAnalysisResponse if successful, or null on failure (triggering fallback).
  Future<BackendAnalysisResponse?> analyzeReel(File videoFile, String title) async {
    try {
      final uri = Uri.parse('$baseUrl/analyze-reel');
      final request = http.MultipartRequest('POST', uri);
      
      request.fields['title'] = title;
      request.files.add(await http.MultipartFile.fromPath('file', videoFile.path));
      
      debugPrint('[API REQUEST] $uri');
      debugPrint('ReelIQ API: Uploading video file to backend ($uri)...');
      
      // Setting a generous 5-minute timeout for local Whisper transcription runs
      final streamedResponse = await request.send().timeout(const Duration(minutes: 5));
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        debugPrint('ReelIQ API: Analysis completed successfully.');
        return BackendAnalysisResponse.fromJson(data);
      } else {
        debugPrint('ReelIQ API Warning: Server returned status code ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('ReelIQ API Warning: Could not connect to FastAPI server. Details: $e');
      return null;
    }
  }

  /// Sends a remote video URL to FastAPI backend to download, process, and analyze.
  /// Returns BackendAnalysisResponse if successful, or null on failure (triggering fallback).
  Future<BackendAnalysisResponse?> analyzeReelFromUrl(String videoUrl, String title, String caption) async {
    try {
      final uri = Uri.parse('$baseUrl/analyze-url');
      debugPrint('[API REQUEST] $uri');
      debugPrint('ReelIQ API: Sending URL request to backend ($uri)...');
      
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'video_url': videoUrl,
          'title': title,
          'caption': caption,
        }),
      ).timeout(const Duration(minutes: 5));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        debugPrint('ReelIQ API: URL analysis completed successfully.');
        return BackendAnalysisResponse.fromJson(data);
      } else {
        debugPrint('ReelIQ API Warning: URL analyze server returned status code ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('ReelIQ API Warning: Could not connect to FastAPI server for URL analysis. Details: $e');
      return null;
    }
  }
}
