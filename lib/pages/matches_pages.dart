// matching_page.dart — UI complète du matching CV ↔ Jobs
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/matching_provider.dart';
import '../providers/cv_provider.dart';
import '../models/cv.dart';
import '../models/job.dart';

class MatchingPage extends ConsumerStatefulWidget {
  const MatchingPage({super.key});

  @override
  ConsumerState<MatchingPage> createState() => _MatchingPageState();
}

class _MatchingPageState extends ConsumerState<MatchingPage> {
  CvModel? _selectedCv;

  @override
  Widget build(BuildContext context) {
    final cvs = ref.watch(cvProvider);
    final matchingState = ref.watch(matchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Matching CV ↔ Offres'),
        backgroundColor: Colors.indigo,
      ),
      body: Column(
        children: [
          // ── Sélection du CV ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<CvModel>(
              value: _selectedCv,
              decoration: InputDecoration(
                labelText: 'Choisir un CV',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.description),
              ),
              items: cvs.map((cv) => DropdownMenuItem(
                value: cv,
                child: Text(cv.fileName, overflow: TextOverflow.ellipsis),
              )).toList(),
              onChanged: (cv) {
                setState(() => _selectedCv = cv);
                ref.read(matchesProvider.notifier).reset();
              },
            ),
          ),

          // ── Bouton lancer le matching ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: matchingState.isLoading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.compare_arrows, color: Colors.white),
                label: Text(
                  matchingState.isLoading ? 'Analyse en cours…' : 'Lancer le matching',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                onPressed: matchingState.isLoading || _selectedCv == null
                    ? null
                    : () => ref.read(matchesProvider.notifier)
                        .calculateMatches(_selectedCv!),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Erreur ──────────────────────────────────────────────────────
          if (matchingState.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                matchingState.error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),

          // ── Résultats ────────────────────────────────────────────────────
          Expanded(
            child: matchingState.results.isEmpty && !matchingState.isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          _selectedCv == null
                              ? 'Sélectionnez un CV pour commencer'
                              : 'Aucun résultat',
                          style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: matchingState.results.length,
                    itemBuilder: (context, index) {
                      final result = matchingState.results[index];
                      final job = result['job'] as JobModel;
                      final analysis = result['analysis'] as Map<String, dynamic>;
                      return _MatchCard(job: job, analysis: analysis);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Carte de résultat ────────────────────────────────────────────────────────
class _MatchCard extends StatelessWidget {
  final JobModel job;
  final Map<String, dynamic> analysis;

  const _MatchCard({required this.job, required this.analysis});

  @override
  Widget build(BuildContext context) {
    final int score = analysis['score'] as int;
    final String level = analysis['level'] as String;
    final int colorValue = int.tryParse(analysis['color'] as String) ?? 0xFF9E9E9E;
    final Color scoreColor = Color(colorValue);

    final matched = List<String>.from(analysis['matched'] ?? []);
    final missing = List<String>.from(analysis['missing'] ?? []);
    final suggestions = List<String>.from(analysis['suggestions'] ?? []);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 3,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        // ── En-tête ────────────────────────────────────────────────────────
        title: Row(
          children: [
            // Score circulaire
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: score / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(scoreColor),
                    strokeWidth: 5,
                  ),
                  Center(
                    child: Text(
                      '$score%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: scoreColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Titre + entreprise
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(job.company,
                      style: const TextStyle(
                          color: Colors.indigo, fontSize: 13)),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: scoreColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      level,
                      style: TextStyle(
                        color: scoreColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // ── Détail (expansion) ─────────────────────────────────────────────
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  analysis['comment'] as String,
                  style: const TextStyle(color: Colors.black87),
                ),

                if (matched.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _SectionTitle(
                      icon: Icons.check_circle,
                      label: 'Compétences validées (${matched.length})',
                      color: Colors.green),
                  _ChipWrap(items: matched, color: Colors.green),
                ],

                if (missing.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SectionTitle(
                      icon: Icons.cancel,
                      label: 'Compétences manquantes (${missing.length})',
                      color: Colors.red),
                  _ChipWrap(items: missing, color: Colors.red),
                ],

                if (suggestions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SectionTitle(
                      icon: Icons.lightbulb,
                      label: 'Suggestions',
                      color: Colors.orange),
                  ...suggestions.map((s) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ',
                                style: TextStyle(color: Colors.orange)),
                            Expanded(child: Text(s)),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets helper ───────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionTitle(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}

class _ChipWrap extends StatelessWidget {
  final List<String> items;
  final Color color;

  const _ChipWrap({required this.items, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: items
            .map((item) => Chip(
                  label: Text(item,
                      style: TextStyle(fontSize: 11, color: color)),
                  backgroundColor: color.withOpacity(0.1),
                  side: BorderSide(color: color.withOpacity(0.3)),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ))
            .toList(),
      ),
    );
  }
}