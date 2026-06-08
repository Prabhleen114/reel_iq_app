import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/content_calendar_model.dart';

class PlannerApiService {
  final String baseUrl;

  // Set this to true if testing on Android Emulator, false if testing on physical Android device
  static const bool _isEmulator = false;
  
  static String _getBaseUrl() {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    if (Platform.isAndroid) {
      return _isEmulator ? 'http://10.0.2.2:8000' : 'http://192.168.0.119:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  PlannerApiService({String? baseUrl}) : baseUrl = baseUrl ?? _getBaseUrl();

  Future<ContentCalendarModel?> generateCalendar({
    required String niche,
    required String audience,
    required String goal,
    required String frequency,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/generate-calendar');
      debugPrint('[API REQUEST] $uri');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'niche': niche,
          'audience': audience,
          'goal': goal,
          'frequency': frequency,
        }),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final calendarId = 'cal_${DateTime.now().millisecondsSinceEpoch}';
        return ContentCalendarModel.fromJson(data, docId: calendarId);
      } else {
        debugPrint('ReelIQ: Server returned error status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ReelIQ Warning: Calendar API error: $e. Falling back to local generator.');
    }

    // Fallback to local calendar generation
    return _generateMockCalendar(niche, audience, goal, frequency);
  }

  ContentCalendarModel _generateMockCalendar(
      String niche, String audience, String goal, String frequency) {
    final days = <ContentCalendarDay>[];
    final calendarId = 'mock_cal_${DateTime.now().millisecondsSinceEpoch}';

    final ideas = [
      ("Top 3 Mistakes in $niche", "Sharing the most common mistakes $audience make and how to fix them.", "Easy"),
      ("How to reach $goal fast", "A quick step-by-step workflow customized for $audience.", "Medium"),
      ("My favorite tool for $niche", "Highlighting a specific tool that helps $audience automate or simplify.", "Easy"),
      ("Busting a common $niche myth", "Debunking a widespread belief to capture attention and build authority.", "Medium"),
      ("Before vs After $goal", "A visual representation showing the transformation of $audience.", "Hard"),
      ("1 simple tip for $niche", "An actionable bite-sized advice that anyone can try today.", "Easy"),
      ("The secret behind $niche success", "A breakdown of what successful creators in this niche do differently.", "Medium"),
      ("Stop doing this in $niche", "An audit style reel pointing out inefficient habits.", "Easy"),
      ("Tutorial: Master $niche in 60s", "A fast-paced step-by-step masterclass style guide.", "Hard"),
      ("A day in the life of a $niche creator", "A behind-the-scenes look to build personal connection with $audience.", "Medium")
    ];

    final times = ["8:30 AM", "12:00 PM", "3:00 PM", "6:00 PM", "7:30 PM", "9:00 PM"];

    for (int i = 0; i < 30; i++) {
      final dayNum = i + 1;
      final ideaTemplate = ideas[i % ideas.length];
      
      days.add(ContentCalendarDay(
        day: dayNum,
        title: ideaTemplate.$1,
        idea: ideaTemplate.$2,
        hook: i % 2 == 0 
            ? "Stop scrolling if you want to achieve $goal with $niche! 🚨" 
            : "Here is the secret about $niche they don't want you to know... 👇",
        caption: "If you are a part of $audience and your goal is to master $niche, this daily tip is for you!\n\nHere is what you need to do:\n1️⃣ Understand the fundamentals\n2️⃣ Practice daily\n3️⃣ Learn from mistakes\n\nSave this reel for later!",
        cta: i % 2 == 0 
            ? "Comment '${niche.split(' ').first.toUpperCase()}' for a free resource! 📥" 
            : "Follow for more daily tips! 🚀",
        postingTime: times[i % times.length],
        difficulty: ideaTemplate.$3,
      ));
    }

    return ContentCalendarModel(
      id: calendarId,
      niche: niche,
      audience: audience,
      goal: goal,
      frequency: frequency,
      createdAt: DateTime.now(),
      days: days,
    );
  }
}
