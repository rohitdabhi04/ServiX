import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  User? get user => FirebaseAuth.instance.currentUser;

  Future<void> saveUserRole(String role) async {
    final u = user;
    if (u == null) return;

    await db.collection("users").doc(u.uid).set({
      "role": role,
      "email": u.email,
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String?> getUserRole() async {
    final u = user;
    if (u == null) return null;

    final doc = await db.collection("users").doc(u.uid).get();
    return doc.data()?['role'];
  }
}