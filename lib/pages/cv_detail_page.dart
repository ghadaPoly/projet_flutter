// cv_detail_page.dart
import 'package:flutter/material.dart';
import '../models/cv.dart';

class CvDetailPage extends StatelessWidget {
  final CvModel cv;

  const CvDetailPage({super.key, required this.cv});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Détail du CV"),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cv.fileName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("Uploadé le : ${cv.uploadDate.day}/${cv.uploadDate.month}/${cv.uploadDate.year}"),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            const Text("Compétences détectées :", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: cv.keywords.map((keyword) => Chip(
                label: Text(keyword),
                backgroundColor: Colors.indigo[50],
              )).toList(),
            ),

            const SizedBox(height: 30),
            const Text("Texte extrait :", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(cv.extractedText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}