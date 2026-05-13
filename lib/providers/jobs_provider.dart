// lib/providers/jobs_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job.dart';
import '../data/jobs_data.dart';   // Ou le chemin où tu as mis jobs_data.dart

final jobsProvider = StateNotifierProvider<JobsNotifier, List<JobModel>>((ref) => JobsNotifier());

class JobsNotifier extends StateNotifier<List<JobModel>> {
  JobsNotifier() : super([]) {
    loadJobs();
  }

  void loadJobs() {
    state = JobsData.jobs;
  }

  // Recherche dans les offres
  List<JobModel> searchJobs(String query) {
    if (query.trim().isEmpty) return state;
    
    final lowerQuery = query.toLowerCase().trim();
    return state.where((job) {
      return job.title.toLowerCase().contains(lowerQuery) ||
             job.company.toLowerCase().contains(lowerQuery) ||
             job.location.toLowerCase().contains(lowerQuery) ||
             job.description.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}