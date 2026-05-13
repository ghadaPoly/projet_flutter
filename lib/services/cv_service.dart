// cv_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:google_mlkit_entity_extraction/google_mlkit_entity_extraction.dart';
import 'package:uuid/uuid.dart';
import '../models/cv.dart';

class CvService {
  final Uuid _uuid = const Uuid();
  final EntityExtractor _entityExtractor = EntityExtractor(
    language: EntityExtractorLanguage.french,
  );

  Future<CvModel> processCv(String filePath, String fileName, String userId) async {
    String fullText = "Erreur d'extraction du PDF";

    try {
      final fileBytes = await File(filePath).readAsBytes();
      
      final PdfDocument document = PdfDocument(inputBytes: fileBytes);
      final PdfTextExtractor extractor = PdfTextExtractor(document);

      fullText = "=== CV: $fileName ===\n";
      fullText += "Nombre de pages: ${document.pages.count}\n\n";

      // Extraction du texte de toutes les pages
      for (int i = 0; i < document.pages.count; i++) {
        String pageText = extractor.extractText(startPageIndex: i);
        fullText += "--- Page ${i + 1} ---\n";
        fullText += "$pageText\n\n";
      }

      document.dispose();
      print("✅ Texte extrait avec succès (${fullText.length} caractères)");
    } catch (e) {
      fullText = "Erreur lors de l'extraction : $e";
      print("❌ Erreur Syncfusion: $e");
    }

    final keywords = await _extractSkillsNER(fullText);

    return CvModel(
      id: _uuid.v4(),
      userId: userId,
      fileName: fileName,
      extractedText: fullText,
      keywords: keywords,
      uploadDate: DateTime.now(),
    );
  }

  Future<List<String>> _extractSkillsNER(String text) async {
    if (text.trim().isEmpty) return _extractTechKeywords(text);

    try {
      final entities = await _entityExtractor.annotateText(text);
      Set<String> skills = {};

      for (var entity in entities) {
        String entityText = entity.text.trim();
        if (entityText.length > 2) {
          skills.add(entityText);
        }
      }

      skills.addAll(_extractTechKeywords(text));
      return skills.toList()..sort();
    } catch (e) {
      print("Erreur ML Kit: $e");
      return _extractTechKeywords(text);
    }
  }

  List<String> _extractTechKeywords(String text) {
    const techList = ['flutter', 'dart', 'firebase', 'react', 'node', 'python', 'java', 'javascript', 'sql', 'git', 'api', 'android', 'ios', 'mobile', 'devops'];
    final lower = text.toLowerCase();
    return techList.where((skill) => lower.contains(skill)).toList();
  }

  // Version Web
  Future<CvModel> processCvFromBytes(Uint8List bytes, String fileName, String userId) async {
    final keywords = _extractTechKeywords("CV Web: $fileName");

    return CvModel(
      id: _uuid.v4(),
      userId: userId,
      fileName: fileName,
      extractedText: "CV chargé via Web - Extraction texte disponible sur mobile",
      keywords: keywords,
      uploadDate: DateTime.now(),
    );
  }
}