// ignore_for_file: file_names
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _fAuth = FirebaseAuth.instance;
  // Stream<User?> get authStream => _fAuth.authStateChanges();

  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential result = await _fAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      return user;
    } catch (e) {
      return null;
    }
  }

  Future<User?> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential result = await _fAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      return user;
    } catch (e) {
      return null;
    }
  }

  void signOut() async {
    await _fAuth.signOut();
  }
}
