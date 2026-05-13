// jobs_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/jobs_provider.dart';
import '../models/job.dart';

class JobsPage extends ConsumerStatefulWidget {
  const JobsPage({super.key});

  @override
  ConsumerState<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends ConsumerState<JobsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<JobModel> filteredJobs = [];

  @override
  void initState() {
    super.initState();
    // Chargement initial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final jobs = ref.read(jobsProvider);
      setState(() => filteredJobs = jobs);
    });
  }

  void _filterJobs(String query) {
    final notifier = ref.read(jobsProvider.notifier);
    setState(() {
      filteredJobs = notifier.searchJobs(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final allJobs = ref.watch(jobsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Offres d'Emploi"),
        backgroundColor: Colors.indigo,
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterJobs,
              decoration: InputDecoration(
                hintText: "Rechercher une offre...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),

          // Liste des offres
          Expanded(
            child: filteredJobs.isEmpty
                ? const Center(
                    child: Text("Aucune offre trouvée", style: TextStyle(fontSize: 18)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredJobs.length,
                    itemBuilder: (context, index) {
                      final job = filteredJobs[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.business, size: 18, color: Colors.indigo),
                                  const SizedBox(width: 8),
                                  Text(job.company, style: const TextStyle(fontSize: 16)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 18, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(job.location),
                                  const Spacer(),
                                  Text(
                                    job.salaryRange,
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                job.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 6,
                                children: job.requirements
                                    .map((req) => Chip(
                                          label: Text(req, style: const TextStyle(fontSize: 12)),
                                          backgroundColor: Colors.indigo[50],
                                        ))
                                    .toList(),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Pour l'instant on affiche juste un message
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Intérêt pour ${job.title} enregistré !"),
                                        backgroundColor: Colors.indigo,
                                      ),
                                    );
                                  },
                                  child: const Text("Voir détails / Postuler"),
                                ),
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