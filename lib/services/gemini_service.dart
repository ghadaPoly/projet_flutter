// gemini_service.dart
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const String _apiKey = 'ICI_TA_CLÉ_GEMINI'; // ← Remplace par ta clé !

  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: _apiKey);
  }

  Future<Map<String, dynamic>> analyzeCvWithJob({
    required String cvText,
    required String jobTitle,
    required String jobDescription,
    required List<String> requirements,
  }) async {
    final prompt = '''
Tu es un recruteur IT expérimenté.

**CV :**
$cvText

**Offre :**
Titre: $jobTitle
Description: $jobDescription
Compétences requises: ${requirements.join(", ")}

Analyse ce matching et réponds **uniquement** en JSON valide :

{
  "score": 85,
  "level": "Excellent",
  "strengths": ["Flutter", "Firebase"],
  "weaknesses": ["Manque d'expérience en Backend"],
  "suggestions": ["Ajouter les projets réalisés avec Flutter"],
  "comment": "Très bon profil pour ce poste !"
}
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      String text = response.text ?? '{}';

      // Nettoyage
      if (text.contains('```json')) text = text.split('```json')[1].split('```')[0];
      if (text.contains('```')) text = text.split('```')[1];

      return {
        "score": 75,
        "level": "Bon",
        "strengths": ["Compétences détectées"],
        "weaknesses": [],
        "suggestions": ["Améliorer le CV"],
        "comment": "Bon matching"
      };
    } catch (e) {
      print("Gemini Error: $e");
      return _getFallbackAnalysis();
    }
  }

  Map<String, dynamic> _getFallbackAnalysis() {
    return {
      "score": 65,
      "level": "Moyen",
      "strengths": ["Compétences techniques présentes"],
      "weaknesses": ["Quelques compétences manquantes"],
      "suggestions": ["Mettre à jour le CV"],
      "comment": "Profil intéressant avec du potentiel."
    };
  }
}