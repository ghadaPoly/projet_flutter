// cv_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:uuid/uuid.dart';

import '../models/cv.dart';

class CvService {
  final Uuid _uuid = const Uuid();

  // ── Changez cette URL selon votre déploiement ──────────────────────────────
  // Développement local (émulateur Android) :  http://10.0.2.2:5000
  // Développement local (appareil physique)  :  http://<IP_LAN>:5000
  // Production                               :  https://votre-api.com
static const String _nerApiBase = 'http://localhost:5000';  // ───────────────────────────────────────────────────────────────────────────

  // ======================== MOBILE / DESKTOP ================================
  Future<CvModel> processCv(
      String filePath, String fileName, String userId) async {
    String fullText = '';

    try {
      final fileBytes = await File(filePath).readAsBytes();
      fullText = _extractTextFromPdfBytes(fileBytes, fileName);
    } catch (e) {
      fullText = 'Impossible d\'extraire le texte : $e';
    }

    final keywords = await _extractSkillsFromApi(fullText);

    return CvModel(
      id: _uuid.v4(),
      userId: userId,
      fileName: fileName,
      extractedText: fullText,
      keywords: keywords,
      uploadDate: DateTime.now(),
    );
  }

  // ============================ WEB (Bytes) =================================
  Future<CvModel> processCvFromBytes(
      Uint8List bytes, String fileName, String userId) async {
    // ⚠️  Avant : le texte n'était PAS extrait sur Web → NER vide
    // ✅  Maintenant : on extrait le texte depuis les bytes directement
    final fullText = _extractTextFromPdfBytes(bytes, fileName);

    final keywords = await _extractSkillsFromApi(fullText);

    return CvModel(
      id: _uuid.v4(),
      userId: userId,
      fileName: fileName,
      extractedText: fullText,
      keywords: keywords,
      uploadDate: DateTime.now(),
    );
  }

  // ======================== EXTRACTION TEXTE PDF ============================
  String _extractTextFromPdfBytes(Uint8List bytes, String fileName) {
    try {
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final PdfTextExtractor extractor = PdfTextExtractor(document);

      final buffer = StringBuffer();
      buffer.writeln('=== CV : $fileName ===');
      buffer.writeln('Nombre de pages : ${document.pages.count}');
      buffer.writeln();

      for (int i = 0; i < document.pages.count; i++) {
        final pageText = extractor.extractText(startPageIndex: i);
        buffer.writeln(pageText);
        buffer.writeln();
      }

      document.dispose();
      return buffer.toString();
    } catch (e) {
      return 'Erreur extraction PDF : $e';
    }
  }

  // ====================== NER via API Flask/spaCy ===========================
  Future<List<String>> _extractSkillsFromApi(String text) async {
    // Fallback local si l'API est inaccessible
    if (text.trim().isEmpty) return [];

    try {
      final response = await http
          .post(
            Uri.parse('$_nerApiBase/extract-skills'),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode({'text': text}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        // L'API renvoie { skills, tech_skills, ner_entities, noun_phrases }
        // On utilise "skills" = fusion de tout
        final List<dynamic> rawSkills = data['skills'] ?? [];
        final skills = rawSkills
            .map((e) => e.toString().trim())
            .where((s) => s.length > 2)
            .toList();

        // Si NER n'a rien trouvé → fallback local
        if (skills.isEmpty) return _localFallback(text);

        return skills..sort();
      } else {
        print('NER API status: ${response.statusCode}');
        return _localFallback(text);
      }
    } catch (e) {
      print('NER API unreachable, using local fallback: $e');
      return _localFallback(text);
    }
  }

  // ====================== FALLBACK LOCAL (sans API) =========================
  // Utilisé si le serveur Python est down.
  List<String> _localFallback(String text) {
    const techList = [
      'flutter', 'dart', 'firebase', 'react', 'node', 'python', 'java',
      'javascript', 'typescript', 'sql', 'git', 'api', 'android', 'ios',
      'mobile', 'devops', 'agile', 'scrum', 'figma', 'docker', 'kubernetes',
      'aws', 'azure', 'kotlin', 'swift', 'mongodb', 'postgresql', 'mysql',
      'redis', 'graphql', 'rest', 'machine learning', 'deep learning',
    ];

    final lower = text.toLowerCase();
    return techList.where((skill) => lower.contains(skill)).toList()..sort();
  }
}