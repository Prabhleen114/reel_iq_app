import 'dart:math';
import '../models/hook_test_model.dart';

class HookTestingRepository {
  Future<List<HookTestModel>> analyzeHooks({
    required String hookA,
    required String hookB,
    required String hookC,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 1200));

    final random = Random();

    // Helper to evaluate a single hook text and return simulated details
    HookTestModel evaluateHook(String label, String hookText) {
      if (hookText.trim().isEmpty) {
        return HookTestModel(
          label: label,
          hookText: "Empty Hook Input",
          score: 0,
          feedback: "Please provide a valid hook script to analyze.",
        );
      }

      // Simple pseudo-analysis based on words, structure & random variance
      final words = hookText.split(' ').length;
      final hasNumber = RegExp(r'\d+').hasMatch(hookText);
      final hasQuestion = hookText.contains('?');
      final hasCTA = hookText.toLowerCase().contains('read') || 
                     hookText.toLowerCase().contains('watch') || 
                     hookText.toLowerCase().contains('here') ||
                     hookText.toLowerCase().contains('secret');

      int baseScore = 60;
      final List<String> reasons = [];

      // Hook rules heuristics
      if (words < 4) {
        baseScore -= 10;
        reasons.add("Too short. A great hook needs at least 4-7 words to establish context.");
      } else if (words > 15) {
        baseScore -= 12;
        reasons.add("Too wordy. Keep the hook statement under 12 words to fit quickly on screen.");
      } else {
        baseScore += 10;
        reasons.add("Ideal length. Fits standard pacing and reads quickly.");
      }

      if (hasNumber) {
        baseScore += 8;
        reasons.add("Includes numerical values (e.g. stats, list items), which increases click interest.");
      } else {
        reasons.add("Missing a concrete figure. Adding metrics (like '3 tips' or '10x') increases curiosity.");
      }

      if (hasQuestion) {
        baseScore += 6;
        reasons.add("Uses an interrogative structure to engage the viewer's curiosity directly.");
      }

      if (hasCTA) {
        baseScore += 7;
        reasons.add("Contains compelling high-intent keywords (e.g. 'secret', 'hacks', 'reveal').");
      }

      // Add a bit of random variance to keep it dynamic
      int finalScore = baseScore + random.nextInt(15);
      finalScore = finalScore.clamp(40, 99);

      // Generate localized feedback
      String feedback;
      if (finalScore >= 85) {
        feedback = "Outstanding! ${reasons.firstWhere((r) => r.contains('Ideal') || r.contains('numerical') || r.contains('interrogative'), orElse: () => 'Engaging hook phrasing.')} Bold typography will maximize retention.";
      } else if (finalScore >= 70) {
        feedback = "Good potential. ${reasons.firstWhere((r) => r.contains('Missing') || r.contains('Too'), orElse: () => 'Structure is moderate.')} Consider making it more punchy by cutting filler words.";
      } else {
        feedback = "Weak start. Reframe the hook as a direct benefit or curiosity gap. Use specific metrics to attract attention immediately.";
      }

      return HookTestModel(
        label: label,
        hookText: hookText,
        score: finalScore,
        feedback: feedback,
      );
    }

    final resultA = evaluateHook("Hook A", hookA);
    final resultB = evaluateHook("Hook B", hookB);
    final resultC = evaluateHook("Hook C", hookC);

    final results = [resultA, resultB, resultC];
    
    // Find the highest score to flag as the best hook
    int highestScore = -1;
    int bestIdx = -1;
    for (int i = 0; i < results.length; i++) {
      if (results[i].score > highestScore && results[i].score > 0) {
        highestScore = results[i].score;
        bestIdx = i;
      }
    }

    if (bestIdx != -1) {
      final best = results[bestIdx];
      results[bestIdx] = HookTestModel(
        label: best.label,
        hookText: best.hookText,
        score: best.score,
        feedback: best.feedback,
        isBest: true,
      );
    }

    return results;
  }
}
