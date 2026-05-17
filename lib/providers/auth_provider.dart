import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
// riverpod
// statenotif : gère un état qui change, authnotif: classe qui contient la logique, usermodel:type de données stockées 
final authProvider = StateNotifierProvider<AuthNotifier, UserModel?>((ref) => AuthNotifier());
// ref : fct qui crée l'objet car riverpod a besoin de savoir comment creer l'obj
class AuthNotifier extends StateNotifier<UserModel?> {
  AuthNotifier() : super(null);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // inscription
  Future<String?> signUp(String email, String password, String name) async {
    try {
      // objet contenant les informations du compte créé : credential -> user -> uid
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // un objet utilisateur personnalisé pq firebase store uniquement email +mdp
      final userModel = UserModel(
        // ! : pas nul
        uid: credential.user!.uid,
        email: email,
        name: name,
      );
      // acces a firestore
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(userModel.toMap());
      // Mise à jour du state :  l'util est cnt mtn
      state = userModel;
      return null;
    } catch (e) {
      return "Erreur d'inscription: ${e.toString()}";
    }
  }

  // cnx
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

  // decnx
  Future<void> logout() async {
    await _auth.signOut();
    state = null;
  }
}