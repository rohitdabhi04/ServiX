import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? user;
  String? role;
  bool isLoading = true;

  AuthProvider() {
    _init();
  }

  void _init() {
    _firebaseAuth.authStateChanges().listen((firebaseUser) async {
      user = firebaseUser;

      if (user != null) {
        // Fetch role directly from Firestore — no need to call login()
        final doc = await _firestore.collection('users').doc(user!.uid).get();
        role = doc.data()?['role'];
      } else {
        role = null;
      }

      isLoading = false;
      notifyListeners();
    });
  }

  Future<void> logout(BuildContext context) async {
    await _firebaseAuth.signOut();

    user = null;
    role = null;

    notifyListeners();

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }
}
