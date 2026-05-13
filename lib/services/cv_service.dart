import 'dart:io';
import 'package:pdfx/pdfx.dart';
import 'package:uuid/uuid.dart';
import '../models/cv.dart';
import 'dart:typed_data'; // Uint8List

class CvService {
  final Uuid _uuid = const Uuid();

  Future<CvModel> processCv(String filePath, String fileName, String userId) async {
    final file = File(filePath);
    String fullText = "Impossible d'extraire le texte du PDF (limitation technique)";

    try {
      final document = await PdfDocument.openFile(file.path);
      
      // Pour l'instant on met un texte placeholder
      // On pourra améliorer plus tard avec un autre package
      fullText = "CV chargé avec succès : ${document.pagesCount} pages.\n";
      fullText += "Nom du fichier : $fileName\n";
      fullText += "Extraction complète sera disponible dans la version finale.";

      await document.close();
    } catch (e) {
      fullText = "Erreur lors de l'ouverture du PDF : $e";
    }

    final keywords = _extractKeywords(fullText);

    return CvModel(
      id: _uuid.v4(),
      userId: userId,
      fileName: fileName,
      extractedText: fullText,
      keywords: keywords,
      uploadDate: DateTime.now(),
    );
  }

  List<String> _extractKeywords(String text) {
    const commonSkills = [
      'flutter', 'dart', 'firebase', 'react', 'node', 'python', 'java',
      'sql', 'javascript', 'mobile', 'api', 'android', 'ios', 'git',
      'github', 'agile', 'scrum', 'devops'
    ];

    final lowerText = text.toLowerCase();
    return commonSkills.where((skill) => lowerText.contains(skill)).toList();
  }
  Future<CvModel> processCvFromBytes(Uint8List bytes, String fileName, String userId) async {
  String fullText = "CV chargé avec succès (Web) : $fileName\n";
  fullText += "Extraction du texte sera disponible dans la version finale.";

  final keywords = _extractKeywords(fullText);

  return CvModel(
    id: _uuid.v4(),
    userId: userId,
    fileName: fileName,
    extractedText: fullText,
    keywords: keywords,
    uploadDate: DateTime.now(),
  );
}
}