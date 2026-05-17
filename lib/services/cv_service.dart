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

static const String _nerApiBase = 'http://localhost:5000';  

  // monile / desktop
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

  // web 
  Future<CvModel> processCvFromBytes(
      Uint8List bytes, String fileName, String userId) async {

    final fullText = _extractTextFromPdfBytes(bytes, fileName);

    final keywords = await _extractSkillsFromApi(fullText);

    return CvModel(
      // nb de 128 bits (v4 : random, aucun lien avec l'ordinateur ou hour ,anonyme)
      id: _uuid.v4(),
      userId: userId,
      fileName: fileName,
      extractedText: fullText,
      keywords: keywords,
      uploadDate: DateTime.now(),
    );
  }

  // extraction text from pdf
  String _extractTextFromPdfBytes(Uint8List bytes, String fileName) {
    try {
      // analyse de la structure du doc pdf en byes bl biblio pdfdpcument
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      // lire le texte du pdf
      final PdfTextExtractor extractor = PdfTextExtractor(document);

      final buffer = StringBuffer();

      buffer.writeln('=== CV : $fileName ===');
      buffer.writeln('Nombre de pages : ${document.pages.count}');
      buffer.writeln();

      for (int i = 0; i < document.pages.count; i++) {
        //  Demande à l'extracteur de lire la page numéro i
        final pageText = extractor.extractText(startPageIndex: i);
        buffer.writeln(pageText);
        buffer.writeln();
      }
// free the memory
      document.dispose();
      // stringbuffer n string normal
      return buffer.toString();
    } catch (e) {
      return 'Erreur extraction PDF : $e';
    }
  }

  //NER via API Flask/spaCy
  Future<List<String>> _extractSkillsFromApi(String text) async {
    // Fallback local ken l'api me yemchich
    if (text.trim().isEmpty) return [];

    try {
      final response = await http
          .post(
            Uri.parse('$_nerApiBase/extract-skills'),
            //type des donnees envoyees
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode({'text': text}),
          )
          // exception ou fallback 
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        // L'API yrajaa skills, tech_skills, ner_entities, noun_phrases 

        final List<dynamic> rawSkills = data['skills'] ?? [];
        final skills = rawSkills
            .map((e) => e.toString().trim())
            .where((s) => s.length > 2)
            .toList();

        // si vide fallback local
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

  // fallback local sans api nestaamlo8h ken l'api tayah
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