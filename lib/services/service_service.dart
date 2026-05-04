import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ServiceService {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  User? get user => FirebaseAuth.instance.currentUser;

  Future<void> addService({
    required String title,
    required String description,
    required String price,
    String category = "",
  }) async {
    final u = user;
    if (u == null) return;

    final userDoc = await db.collection("users").doc(u.uid).get();
    final userData = userDoc.data() ?? {};
    final providerName = userData['name'] ?? "Provider";
    final providerCity = userData['city'] ?? "";
    final providerArea = userData['area'] ?? "";
    final lat = (userData['latitude'] as num?)?.toDouble() ?? 0.0;
    final lng = (userData['longitude'] as num?)?.toDouble() ?? 0.0;

    await db.collection("services").add({
      "title": title,
      "description": description,
      "price": double.tryParse(price) ?? 0,
      "category": category,
      "providerId": u.uid,
      "providerName": providerName,
      "providerCity": providerCity,
      "providerArea": providerArea,
      "city": providerCity,
      "lat": lat,
      "lng": lng,
      "avgRating": 0.0,
      "totalReviews": 0,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getServices() {
    return db
        .collection("services")
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getServicesByCity(String city) {
    return db
        .collection("services")
        .where("city", isEqualTo: city)
        .snapshots();
  }

  Future<void> updateService({
    required String serviceId,
    required String title,
    required String description,
    required double price,
  }) async {
    await db.collection("services").doc(serviceId).update({
      "title": title,
      "description": description,
      "price": price,
    });
  }

  Future<void> deleteService(String serviceId) async {
    await db.collection("services").doc(serviceId).delete();
  }
}