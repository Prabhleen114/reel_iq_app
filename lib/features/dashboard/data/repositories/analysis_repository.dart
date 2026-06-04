import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/mock_config.dart';
import '../../../analysis/data/models/analysis_models.dart';
import '../../../analysis/data/services/analysis_api_service.dart';
import '../models/reel_analysis_model.dart';

class AnalysisRepository {
  final AnalysisApiService _apiService;

  AnalysisRepository(this._apiService);
  FirebaseFirestore get _firestore {
    if (MockConfig.useMockMode) {
      throw UnsupportedError('Firestore is not available in mock mode');
    }
    return FirebaseFirestore.instance;
  }
  
  FirebaseStorage get _storage {
    if (MockConfig.useMockMode) {
      throw UnsupportedError('Firebase Storage is not available in mock mode');
    }
    return FirebaseStorage.instance;
  }

  // In-memory mock database of analyses
  final List<ReelAnalysisModel> _mockAnalyses = [
    ReelAnalysisModel(
      id: 'mock-analysis-1',
      userId: 'mock-user-123',
      title: '3 Hooks to Triple Your Views',
      videoUrl: 'https://assets.mixkit.co/videos/preview/mixkit-girl-in-neon-sign-lighting-34507-large.mp4',
      viralScore: 88,
      hookStrength: 'Strong',
      retentionPrediction: 'Good',
      engagementPrediction: 'High',
      suggestions: [
        'Add neon captions for key terms',
        'Increase text contrast in the first 2 seconds',
        'Double-down on the Call to Action at the end'
      ],
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      suggestedHooks: [
        SuggestedTextItem(type: 'Curiosity', text: 'You are losing 90% of your Reel views in the first 3 seconds... 👇'),
        SuggestedTextItem(type: 'Problem-Solving', text: 'Here are 3 hook formulas that actually keep people watching.'),
        SuggestedTextItem(type: 'Bold Statement', text: 'Stop using boring intros. Do this instead.'),
      ],
      suggestedCtas: [
        SuggestedTextItem(type: 'Comment-Trigger', text: 'Comment HOOKS and I will DM you my top 50 templates! 📥'),
        SuggestedTextItem(type: 'Save-Trigger', text: 'Save this video to use these templates for your next Reel! 💾'),
      ],
      suggestedCaptions: [
        SuggestedTextItem(type: 'Value-Packed', text: 'Want to triple your Reel views? Here is the secret:\n\n1. Stop using boring intros\n2. Open with a problem\n3. Use pattern interrupts\n\nWhich of these hooks will you try first? let me know!'),
      ],
    ),
    ReelAnalysisModel(
      id: 'mock-analysis-2',
      userId: 'mock-user-123',
      title: 'Coding ASMR: Setup Tour',
      videoUrl: 'https://assets.mixkit.co/videos/preview/mixkit-typing-on-a-luminous-keyboard-in-the-dark-44222-large.mp4',
      viralScore: 74,
      hookStrength: 'Moderate',
      retentionPrediction: 'Good',
      engagementPrediction: 'Medium',
      suggestions: [
        'Improve first 3 seconds with a visual hook',
        'Add background low-fi music to maintain pacing',
        'Use zoom cuts every 3 seconds to keep interest'
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      suggestedHooks: [
        SuggestedTextItem(type: 'Curiosity', text: 'The ultimate workspace setup for developer productivity... 💻'),
        SuggestedTextItem(type: 'Problem-Solving', text: 'Is your desk setup holding you back? Let\'s fix it.'),
      ],
      suggestedCtas: [
        SuggestedTextItem(type: 'Comment-Trigger', text: 'Comment SETUP and I\'ll send you a link to everything on my desk! 🔌'),
        SuggestedTextItem(type: 'Share-Trigger', text: 'Share this setup with a fellow developer looking to upgrade! 🚀'),
      ],
      suggestedCaptions: [
        SuggestedTextItem(type: 'Short & Punchy', text: 'Quick desk tour! Coding ASMR style. Everything listed in my bio link.'),
      ],
    ),
    ReelAnalysisModel(
      id: 'mock-analysis-3',
      userId: 'mock-user-123',
      title: 'AI Startup Pitch in 30 Seconds',
      videoUrl: 'https://assets.mixkit.co/videos/preview/mixkit-digital-animation-of-screens-43093-large.mp4',
      viralScore: 92,
      hookStrength: 'Strong',
      retentionPrediction: 'Excellent',
      engagementPrediction: 'High',
      suggestions: [
        'Great pacing! Keep this format.',
        'Slightly increase vocal volume over backing track.',
        'Add interactive poll sticker in Instagram when publishing.'
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      suggestedHooks: [
        SuggestedTextItem(type: 'Bold Statement', text: 'How we built and pitched our AI startup in under 30 seconds.'),
        SuggestedTextItem(type: 'Curiosity', text: 'This 30-second presentation got us funding... 💰'),
      ],
      suggestedCtas: [
        SuggestedTextItem(type: 'Comment-Trigger', text: 'Comment PITCH and get our exact pitch deck template in your DMs! 📬'),
        SuggestedTextItem(type: 'Save-Trigger', text: 'Save this so you don\'t forget these slide structures! 💾'),
      ],
      suggestedCaptions: [
        SuggestedTextItem(type: 'Storytelling', text: 'Pitching an idea is hard, but keeping it to 30 seconds forces you to only tell the absolute essentials. Here is how we structured the slides and pitch to make it stick.'),
      ],
    ),
  ];

  Future<List<ReelAnalysisModel>> getAnalysesForUser(String userId) async {
    if (MockConfig.useMockMode) {
      await Future.delayed(const Duration(milliseconds: 600));
      return _mockAnalyses.where((a) => a.userId == userId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      final snapshot = await _firestore
          .collection('reels')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => ReelAnalysisModel.fromMap(doc.data(), doc.id))
          .toList();
    }
  }

  Future<ReelAnalysisModel> runAiAnalysis({
    required String userId,
    required String title,
    required File videoFile,
    Function(double)? onUploadProgress,
  }) async {
    String? localVideoPath = videoFile.path;

    // 1. Try FastAPI Backend
    if (onUploadProgress != null) {
      onUploadProgress(0.1);
    }
    
    try {
      final apiResponse = await _apiService.analyzeReel(videoFile, title);
      
      if (apiResponse != null) {
        if (onUploadProgress != null) {
          onUploadProgress(0.9);
        }
        
        final insights = apiResponse.insights;
        final suggestions = insights.improvements.isNotEmpty
            ? insights.improvements
            : ['Optimize pacing', 'Include a stronger opening visual hook'];

        final backendAnalysis = ReelAnalysisModel(
          id: MockConfig.useMockMode
              ? 'backend-analysis-${DateTime.now().millisecondsSinceEpoch}'
              : '',
          userId: userId,
          title: title.trim().isEmpty ? 'Reel ${DateTime.now().hour}:${DateTime.now().minute}' : title,
          videoPath: localVideoPath,
          videoUrl: insights.viralScore >= 80
              ? 'https://assets.mixkit.co/videos/preview/mixkit-girl-in-neon-sign-lighting-34507-large.mp4'
              : 'https://assets.mixkit.co/videos/preview/mixkit-typing-on-a-luminous-keyboard-in-the-dark-44222-large.mp4',
          viralScore: insights.viralScore,
          hookStrength: insights.hookScore >= 85
              ? 'Strong'
              : insights.hookScore >= 75
                  ? 'Moderate'
                  : 'Weak',
          retentionPrediction: insights.engagementScore >= 88
              ? 'Excellent'
              : insights.engagementScore >= 78
                  ? 'Good'
                  : insights.engagementScore >= 70
                      ? 'Fair'
                      : 'Low',
          engagementPrediction: insights.engagementScore >= 84
              ? 'High'
              : insights.engagementScore >= 72
                  ? 'Medium'
                  : 'Low',
          suggestions: suggestions,
          createdAt: DateTime.now(),
          suggestedHooks: insights.suggestedHooks,
          suggestedCtas: insights.suggestedCtas,
          suggestedCaptions: insights.suggestedCaptions,
          hookScore: insights.hookScore,
          ctaScore: insights.ctaScore,
          captionScore: insights.captionScore,
          trendScore: insights.trendScore,
          transcript: apiResponse.transcript,
        );

        if (onUploadProgress != null) {
          onUploadProgress(1.0);
        }

        if (MockConfig.useMockMode) {
          _mockAnalyses.insert(0, backendAnalysis);
          return backendAnalysis;
        } else {
          final docRef = await _firestore.collection('reels').add(backendAnalysis.toMap());
          return ReelAnalysisModel(
            id: docRef.id,
            userId: backendAnalysis.userId,
            title: backendAnalysis.title,
            videoPath: backendAnalysis.videoPath,
            videoUrl: backendAnalysis.videoUrl,
            viralScore: backendAnalysis.viralScore,
            hookStrength: backendAnalysis.hookStrength,
            retentionPrediction: backendAnalysis.retentionPrediction,
            engagementPrediction: backendAnalysis.engagementPrediction,
            suggestions: backendAnalysis.suggestions,
            createdAt: backendAnalysis.createdAt,
            suggestedHooks: backendAnalysis.suggestedHooks,
            suggestedCtas: backendAnalysis.suggestedCtas,
            suggestedCaptions: backendAnalysis.suggestedCaptions,
            hookScore: backendAnalysis.hookScore,
            ctaScore: backendAnalysis.ctaScore,
            captionScore: backendAnalysis.captionScore,
            trendScore: backendAnalysis.trendScore,
            transcript: backendAnalysis.transcript,
          );
        }
      }
    } catch (e) {
      debugPrint('ReelIQ Warning: Backend request failed: $e');
    }

    // 2. FALLBACK to Offline Mock Analysis Mode
    debugPrint('ReelIQ: Backend is offline. Falling back to Mock analysis engine.');

    String? finalVideoUrl;
    if (MockConfig.useMockMode) {
      // Simulate file upload progress
      for (int i = 1; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 150));
        if (onUploadProgress != null) {
          onUploadProgress(i / 10.0);
        }
      }
      
      // Use a stock video URL for mock visualization
      final randomVideoUrls = [
        'https://assets.mixkit.co/videos/preview/mixkit-girl-in-neon-sign-lighting-34507-large.mp4',
        'https://assets.mixkit.co/videos/preview/mixkit-typing-on-a-luminous-keyboard-in-the-dark-44222-large.mp4',
        'https://assets.mixkit.co/videos/preview/mixkit-digital-animation-of-screens-43093-large.mp4',
      ];
      finalVideoUrl = randomVideoUrls[Random().nextInt(randomVideoUrls.length)];
    } else {
      // Live Firebase Storage upload
      final fileName = 'reel_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final ref = _storage.ref().child('reels/$userId/$fileName');
      
      final uploadTask = ref.putFile(videoFile);
      
      if (onUploadProgress != null) {
        uploadTask.snapshotEvents.listen((event) {
          final progress = event.bytesTransferred / event.totalBytes;
          onUploadProgress(progress);
        });
      }
      
      final snapshot = await uploadTask;
      finalVideoUrl = await snapshot.ref.getDownloadURL();
    }

    // Generate AI metrics (Simulated AI Engine)
    final random = Random();
    final int score = 65 + random.nextInt(31); // 65 to 95
    
    String hookStrength;
    if (score >= 85) {
      hookStrength = 'Strong';
    } else if (score >= 75) {
      hookStrength = 'Moderate';
    } else {
      hookStrength = 'Weak';
    }

    String retentionPred;
    if (score >= 88) {
      retentionPred = 'Excellent';
    } else if (score >= 78) {
      retentionPred = 'Good';
    } else if (score >= 70) {
      retentionPred = 'Fair';
    } else {
      retentionPred = 'Low';
    }

    String engagementPred;
    if (score >= 84) {
      engagementPred = 'High';
    } else if (score >= 72) {
      engagementPred = 'Medium';
    } else {
      engagementPred = 'Low';
    }

    // Dynamic suggestions based on scores
    final List<String> suggestions = [];
    if (hookStrength == 'Weak' || hookStrength == 'Moderate') {
      suggestions.add('Improve first 3 seconds with a visual zoom or pattern interrupt');
      suggestions.add('Deliver the value proposition immediately in the hook sentence');
    } else {
      suggestions.add('Hook is highly engaging! Keep using the bold typography style.');
    }

    if (retentionPred == 'Low' || retentionPred == 'Fair') {
      suggestions.add('Increase overall pacing: trim silent pauses between clips');
      suggestions.add('Incorporate background ambient beats to maintain viewers focus');
    } else {
      suggestions.add('Pacing is superb. Retention levels are expected to perform above average.');
    }

    suggestions.add('Add a stronger CTA (e.g. "Save for later" or "Comment GUIDE below")');
    suggestions.add('Utilize color contrast styling in caption text to highlight keywords');

    final mockTopic = title.trim().isEmpty ? 'Reel' : title;
    final mockHooks = [
      SuggestedTextItem(type: 'Curiosity', text: 'The secret behind $mockTopic that nobody tells you... 👇'),
      SuggestedTextItem(type: 'Problem-Solving', text: 'Stop wasting hours! Here is how to master $mockTopic instead.'),
      SuggestedTextItem(type: 'Bold Statement', text: 'One simple change to double your results with $mockTopic.'),
    ];
    final mockCtas = [
      SuggestedTextItem(type: 'Comment-Trigger', text: 'Comment GUIDE below and I will DM you the code! 📥'),
      SuggestedTextItem(type: 'Save-Trigger', text: 'Save this reel so you don\'t lose it later! 💾'),
      SuggestedTextItem(type: 'Share-Trigger', text: 'Share this with a friend who needs this! 🚀'),
    ];
    final mockCaptions = [
      SuggestedTextItem(type: 'Value-Packed', text: 'Here is how to get started with $mockTopic: \n\n1️⃣ Keep it simple\n2️⃣ Follow for more tips!'),
      SuggestedTextItem(type: 'Short & Punchy', text: 'If you are struggling with $mockTopic, try this simple adjustment.'),
      SuggestedTextItem(type: 'Storytelling', text: 'It took me years to realize this, but consistency in $mockTopic always wins.'),
    ];

    final newAnalysis = ReelAnalysisModel(
      id: MockConfig.useMockMode 
          ? 'mock-analysis-${DateTime.now().millisecondsSinceEpoch}' 
          : '',
      userId: userId,
      title: title.trim().isEmpty ? 'Reel ${DateTime.now().hour}:${DateTime.now().minute}' : title,
      videoPath: localVideoPath,
      videoUrl: finalVideoUrl,
      viralScore: score,
      hookStrength: hookStrength,
      retentionPrediction: retentionPred,
      engagementPrediction: engagementPred,
      suggestions: suggestions,
      createdAt: DateTime.now(),
      suggestedHooks: mockHooks,
      suggestedCtas: mockCtas,
      suggestedCaptions: mockCaptions,
      hookScore: 78,
      ctaScore: 68,
      captionScore: 74,
      trendScore: 82,
      transcript: 'This is a mock offline transcript of your video. In mock mode, we skip speech-to-text and use local heuristic generators.',
    );

    if (MockConfig.useMockMode) {
      _mockAnalyses.insert(0, newAnalysis);
      return newAnalysis;
    } else {
      final docRef = await _firestore.collection('reels').add(newAnalysis.toMap());
      return ReelAnalysisModel(
        id: docRef.id,
        userId: newAnalysis.userId,
        title: newAnalysis.title,
        videoPath: newAnalysis.videoPath,
        videoUrl: newAnalysis.videoUrl,
        viralScore: newAnalysis.viralScore,
        hookStrength: newAnalysis.hookStrength,
        retentionPrediction: newAnalysis.retentionPrediction,
        engagementPrediction: newAnalysis.engagementPrediction,
        suggestions: newAnalysis.suggestions,
        createdAt: newAnalysis.createdAt,
        suggestedHooks: newAnalysis.suggestedHooks,
        suggestedCtas: newAnalysis.suggestedCtas,
        suggestedCaptions: newAnalysis.suggestedCaptions,
        hookScore: newAnalysis.hookScore,
        ctaScore: newAnalysis.ctaScore,
        captionScore: newAnalysis.captionScore,
        trendScore: newAnalysis.trendScore,
        transcript: newAnalysis.transcript,
      );
    }
  }

  Future<ReelAnalysisModel?> getAnalysisById(String id) async {
    if (MockConfig.useMockMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      final idx = _mockAnalyses.indexWhere((a) => a.id == id);
      return idx != -1 ? _mockAnalyses[idx] : null;
    } else {
      final doc = await _firestore.collection('reels').doc(id).get();
      if (doc.exists && doc.data() != null) {
        return ReelAnalysisModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    }
  }
  
  Future<void> deleteAnalysis(String id) async {
    if (MockConfig.useMockMode) {
      _mockAnalyses.removeWhere((a) => a.id == id);
    } else {
      await _firestore.collection('reels').doc(id).delete();
    }
  }
}
