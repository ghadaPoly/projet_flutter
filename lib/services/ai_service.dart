// ai_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class AiService {
  // ── Même base URL que cv_service.dart ─────────────────────────────────────
  static const String _nerApiBase = 'http://10.0.2.2:5000';

  // ==========================================================================
  // POINT D'ENTRÉE PRINCIPAL
  // ==========================================================================
  Future<Map<String, dynamic>> analyzeCvWithJob({
    required String cvText,
    required List<String> cvKeywords, // ← mots-clés déjà extraits par NER
    required String jobTitle,
    required String jobDescription,
    required List<String> requirements,
  }) async {
    // 1. Normalise tout en minuscules sans accents
    final cvSkills = _normalizeSet(cvKeywords);
    final jobReqs = _normalizeSet(requirements);
    final cvLower = _removeDiacritics(cvText.toLowerCase());
    final jobLower = _removeDiacritics((jobTitle + ' ' + jobDescription).toLowerCase());

    // 2. Matching skills CV ↔ requirements job
    final matched = <String>{};
    final missing = <String>{};

    for (final req in jobReqs) {
      // Cherche la compétence soit dans les keywords NER, soit dans le texte brut
      if (cvSkills.contains(req) || cvLower.contains(req)) {
        matched.add(req);
      } else {
        missing.add(req);
      }
    }

    // 3. Calcul du score de base (0–100)
    final double baseScore = jobReqs.isEmpty
        ? 50.0
        : (matched.length / jobReqs.length) * 100;

    // 4. Bonus contextuels (max +15 au total)
    double bonus = 0;

    // Bonus titre : le titre du job apparaît dans le CV
    final titleWords = jobTitle.toLowerCase().split(RegExp(r'\s+'));
    final titleMatchCount = titleWords.where((w) => w.length > 3 && cvLower.contains(w)).length;
    if (titleMatchCount > 0) {
      bonus += min(8.0, titleMatchCount * 3.0); // max +8
    }

    // Bonus expérience : années mentionnées
    final expMatch = RegExp(r'(\d+)\s*(?:ans?|years?)').firstMatch(cvLower);
    if (expMatch != null) {
      final years = int.tryParse(expMatch.group(1) ?? '') ?? 0;
      if (years >= 3) bonus += 5;
      else if (years >= 1) bonus += 2;
    }

    // Bonus diplôme
    if (cvLower.contains('master') || cvLower.contains('ingénieur') || cvLower.contains('engineer')) {
      bonus += 2;
    }

    // 5. Score final clampé 0–100 (pas de plancher artificiel)
    final int finalScore = (baseScore + bonus).clamp(0, 100).round();

    // 6. Niveau et commentaire
    final level = _scoreLevel(finalScore);

    // 7. Suggestions basées sur les vraies lacunes
    final suggestions = _buildSuggestions(
      missing: missing.toList(),
      finalScore: finalScore,
      cvLower: cvLower,
    );

    // 8. Compétences supplémentaires du CV non demandées (valeur ajoutée)
    final bonusSkills = cvSkills
        .difference(jobReqs)
        .where((s) => s.length > 2)
        .take(5)
        .toList();

    return {
      'score': finalScore,
      'level': level['label'],
      'color': level['color'], // pour l'UI
      'matched': matched.toList()..sort(),
      'missing': missing.toList()..sort(),
      'bonusSkills': bonusSkills,
      'suggestions': suggestions,
      'comment': _buildComment(finalScore, matched.length, jobReqs.length),
      // Détail du calcul (utile pour debug)
      'debug': {
        'baseScore': baseScore.toStringAsFixed(1),
        'bonus': bonus.toStringAsFixed(1),
        'matchedCount': matched.length,
        'totalReqs': jobReqs.length,
      },
    };
  }

  // ==========================================================================
  // HELPERS PRIVÉS
  // ==========================================================================

  /// Normalise une liste en Set minuscule sans accents
  Set<String> _normalizeSet(List<String> items) {
    return items
        .map((s) => _removeDiacritics(s.toLowerCase().trim()))
        .where((s) => s.length > 1)
        .toSet();
  }

  /// Supprime les accents pour une comparaison robuste
  String _removeDiacritics(String s) {
    const from = 'àáâãäçèéêëìíîïñòóôõöùúûüýÿ';
    const to   = 'aaaaaceeeeiiiinooooouuuuyy';
    var result = s;
    for (int i = 0; i < from.length; i++) {
      result = result.replaceAll(from[i], to[i]);
    }
    return result;
  }

  Map<String, String> _scoreLevel(int score) {
    if (score >= 80) return {'label': 'Excellent',   'color': '0xFF4CAF50'};
    if (score >= 65) return {'label': 'Bon',          'color': '0xFF8BC34A'};
    if (score >= 50) return {'label': 'Moyen',        'color': '0xFFFF9800'};
    return             {'label': 'Faible',            'color': '0xFFF44336'};
  }

  List<String> _buildSuggestions({
    required List<String> missing,
    required int finalScore,
    required String cvLower,
  }) {
    final suggestions = <String>[];

    // Suggère les 3 premières compétences manquantes
    for (final skill in missing.take(3)) {
      suggestions.add('Acquérir ou mentionner : $skill');
    }

    if (!cvLower.contains('projet') && !cvLower.contains('project')) {
      suggestions.add('Ajoutez une section Projets avec vos réalisations concrètes');
    }
    if (!cvLower.contains('github') && !cvLower.contains('gitlab')) {
      suggestions.add('Indiquez vos dépôts GitHub / GitLab');
    }
    if (finalScore < 50 && suggestions.length < 4) {
      suggestions.add('Reformulez votre CV en ciblant les mots-clés de l\'offre');
    }

    return suggestions.take(4).toList();
  }

  String _buildComment(int score, int matchedCount, int totalReqs) {
    if (totalReqs == 0) return 'Aucun critère défini pour ce poste.';
    final pct = totalReqs > 0 ? ((matchedCount / totalReqs) * 100).round() : 0;

    if (score >= 80) {
      return 'Profil très adapté — $matchedCount/$totalReqs critères satisfaits ($pct%). Candidature fortement recommandée.';
    } else if (score >= 65) {
      return 'Bon profil — $matchedCount/$totalReqs critères satisfaits ($pct%). Quelques compétences à renforcer.';
    } else if (score >= 50) {
      return 'Profil partiel — $matchedCount/$totalReqs critères satisfaits ($pct%). Des lacunes importantes à combler.';
    } else {
      return 'Profil insuffisant — $matchedCount/$totalReqs critères satisfaits ($pct%). Ce poste nécessite des compétences non présentes dans le CV.';
    }
  }
}