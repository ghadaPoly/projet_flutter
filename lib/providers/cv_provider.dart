import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';   // ← Très important
import '../models/cv.dart';
import '../services/cv_service.dart';

final cvProvider = StateNotifierProvider<CvNotifier, List<CvModel>>((ref) => CvNotifier());

class CvNotifier extends StateNotifier<List<CvModel>> {
  CvNotifier() : super([]);

  final CvService _cvService = CvService();

  // Upload pour mobile et deskt
  Future<String?> uploadCv(String filePath, String fileName, String userId) async {
    try {
      final cv = await _cvService.processCv(filePath, fileName, userId);

      await FirebaseFirestore.instance
          .collection('cvs')
          .doc(cv.id)
          .set(cv.toMap());

      state = [cv, ...state];
      return null;
    } catch (e) {
      return "Erreur: ${e.toString()}";
    }
  }

  // Upload pour web en bytes
  Future<String?> uploadCvFromBytes(Uint8List bytes, String fileName, String userId) async {
    try {
      // transforme fichier en objet CvModel
      final cv = await _cvService.processCvFromBytes(bytes, fileName, userId);

      await FirebaseFirestore.instance
          .collection('cvs')
          .doc(cv.id)
          .set(cv.toMap());
    // ajoute le nouveau Ccv f awel liste
    // prends tous les precedents éléments de la liste et on rajoute le nv cv
      state = [cv, ...state];
      return null;
    } catch (e) {
      return "Erreur: ${e.toString()}";
    }
  }

  Future<void> loadUserCvs(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('cvs')
          .where('userId', isEqualTo: userId)
          .orderBy('uploadDate', descending: true)
          .get();

      state = snapshot.docs.map((doc) => CvModel.fromMap(doc.data())).toList();
    } catch (e) {
      print("Erreur load cvs: $e");
    }
  }
}