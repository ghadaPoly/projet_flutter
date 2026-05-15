// matching_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cv.dart';
import '../models/job.dart';
import '../services/ai_service.dart';
import 'jobs_provider.dart';

final aiServiceProvider = Provider<AiService>((ref) => AiService());

// ── État du matching ────────────────────────────────────────────────────────
class MatchingState {
  final List<Map<String, dynamic>> results;
  final bool isLoading;
  final String? error;

  const MatchingState({
    this.results = const [],
    this.isLoading = false,
    this.error,
  });

  MatchingState copyWith({
    List<Map<String, dynamic>>? results,
    bool? isLoading,
    String? error,
  }) {
    return MatchingState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ── Provider ────────────────────────────────────────────────────────────────
final matchesProvider =
    StateNotifierProvider<MatchesNotifier, MatchingState>(
  (ref) => MatchesNotifier(ref),
);

class MatchesNotifier extends StateNotifier<MatchingState> {
  final Ref ref;

  MatchesNotifier(this.ref) : super(const MatchingState());

  Future<void> calculateMatches(CvModel cv) async {
    // Garde-fou : ne pas relancer si déjà en cours
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, results: [], error: null);

    try {
      final jobs = ref.read(jobsProvider);
      final aiService = ref.read(aiServiceProvider);
      final results = <Map<String, dynamic>>[];

      for (final job in jobs) {
        final analysis = await aiService.analyzeCvWithJob(
          cvText: cv.extractedText,
          cvKeywords: cv.keywords,        // ← NER keywords déjà extraits
          jobTitle: job.title,
          jobDescription: job.description,
          requirements: job.requirements,
        );

        results.add({
          'job': job,
          'analysis': analysis,
        });
      }

      // Tri par score décroissant
      results.sort((a, b) {
        final scoreA = (a['analysis']['score'] as num?)?.toInt() ?? 0;
        final scoreB = (b['analysis']['score'] as num?)?.toInt() ?? 0;
        return scoreB.compareTo(scoreA);
      });

      state = state.copyWith(isLoading: false, results: results);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du matching : $e',
      );
    }
  }

  void reset() => state = const MatchingState();
}