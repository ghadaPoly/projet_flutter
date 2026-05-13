// matching_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cv.dart';
import '../models/job.dart';
import '../services/gemini_service.dart';
import 'jobs_provider.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) => GeminiService());

final matchesProvider = StateNotifierProvider<MatchesNotifier, List<Map<String, dynamic>>>(
  (ref) => MatchesNotifier(ref),
);

class MatchesNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final Ref ref;
  bool isLoading = false;

  MatchesNotifier(this.ref) : super([]);

  Future<void> calculateMatches(CvModel cv) async {
    isLoading = true;
    state = []; // Reset

    try {
      final jobs = ref.read(jobsProvider);
      final gemini = ref.read(geminiServiceProvider);
      List<Map<String, dynamic>> results = [];

      for (var job in jobs) {
        final analysis = await gemini.analyzeCvWithJob(
          cvText: cv.extractedText,
          jobTitle: job.title,
          jobDescription: job.description,
          requirements: job.requirements,
        );

        results.add({
          'job': job,
          'analysis': analysis,
        });
      }

      // Trier par score descendant
      results.sort((a, b) {
        final scoreA = (a['analysis']['score'] as num?)?.toInt() ?? 0;
        final scoreB = (b['analysis']['score'] as num?)?.toInt() ?? 0;
        return scoreB.compareTo(scoreA);
      });

      state = results;
    } catch (e) {
      print("Erreur matching: $e");
    } finally {
      isLoading = false;
    }
  }
}