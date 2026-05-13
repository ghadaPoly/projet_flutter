// matches_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jobmatch_ai/models/cv.dart';
import 'package:jobmatch_ai/models/job.dart';
import '../providers/matching_provider.dart';
import '../providers/cv_provider.dart';
import '../providers/auth_provider.dart';

class MatchesPage extends ConsumerStatefulWidget {
  const MatchesPage({super.key});

  @override
  ConsumerState<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends ConsumerState<MatchesPage> {
  CvModel? selectedCv;

  @override
  Widget build(BuildContext context) {
    final cvs = ref.watch(cvProvider);
    final matches = ref.watch(matchesProvider);
    final isLoading = ref.read(matchesProvider.notifier).isLoading; // À améliorer plus tard

    return Scaffold(
      appBar: AppBar(
        title: const Text("JobMatch AI - Recommandations"),
        backgroundColor: Colors.indigo,
      ),
      body: Column(
        children: [
          // Sélection du CV
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<CvModel>(
              value: selectedCv,
              decoration: const InputDecoration(
                labelText: "Choisir un CV",
                border: OutlineInputBorder(),
              ),
              items: cvs.map((cv) => DropdownMenuItem(
                    value: cv,
                    child: Text(cv.fileName, overflow: TextOverflow.ellipsis),
                  )).toList(),
              onChanged: (cv) {
                setState(() => selectedCv = cv);
                if (cv != null) {
                  ref.read(matchesProvider.notifier).calculateMatches(cv);
                }
              },
            ),
          ),

          // Résultats
          Expanded(
            child: matches.isEmpty
                ? const Center(
                    child: Text(
                      "Sélectionnez un CV pour voir les recommandations IA",
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final item = matches[index];
                      final job = item['job'] as JobModel;
                      final analysis = item['analysis'] as Map<String, dynamic>;
                      final score = analysis['score'] ?? 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      job.title,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: score >= 80 ? Colors.green : score >= 60 ? Colors.orange : Colors.red,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      "$score%",
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              Text(job.company, style: const TextStyle(fontSize: 16)),
                              Text(job.location),
                              const SizedBox(height: 12),
                              Text(analysis['comment'] ?? "", style: const TextStyle(fontStyle: FontStyle.italic)),
                              const SizedBox(height: 12),
                              if (analysis['suggestions'] != null)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Suggestions d'amélioration :", style: TextStyle(fontWeight: FontWeight.bold)),
                                    ... (analysis['suggestions'] as List).map((s) => Text("• $s")).toList(),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}