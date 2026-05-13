import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';

final authProvider = StateNotifierProvider<AuthNotifier, UserModel?>((ref) => AuthNotifier());

class AuthNotifier extends StateNotifier<UserModel?> {
  AuthNotifier() : super(null);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ====================== INSCRIPTION ======================
  Future<String?> signUp(String email, String password, String name) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userModel = UserModel(
        uid: credential.user!.uid,
        email: email,
        name: name,
      );

      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(userModel.toMap());

      state = userModel;
      return null;
    } catch (e) {
      return "Erreur d'inscription: ${e.toString()}";
    }
  }

  // ====================== CONNEXION ======================
  Future<String?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final docSnapshot = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      if (docSnapshot.exists) {
        state = UserModel.fromMap(docSnapshot.data()!);
      } else {
        state = UserModel(
          uid: credential.user!.uid,
          email: email,
          name: "Utilisateur",
        );
      }
      return null;
    } catch (e) {
      return "Erreur de connexion: ${e.toString()}";
    }
  }

  // ====================== DÉCONNEXION ======================
  Future<void> logout() async {
    await _auth.signOut();
    state = null;
  }
}