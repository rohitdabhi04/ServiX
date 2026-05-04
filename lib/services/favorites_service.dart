import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Reference to the user's favorites sub-collection
  CollectionReference get _favRef =>
      _db.collection('users').doc(_uid).collection('favorites');

  /// Add a provider to favorites
  Future<void> addFavorite(String providerId) async {
    if (_uid == null) return;
    await _favRef.doc(providerId).set({
      'providerId': providerId,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Remove a provider from favorites
  Future<void> removeFavorite(String providerId) async {
    if (_uid == null) return;
    await _favRef.doc(providerId).delete();
  }

  /// Toggle favorite status
  Future<bool> toggleFavorite(String providerId) async {
    final isFav = await isFavorite(providerId);
    if (isFav) {
      await removeFavorite(providerId);
      return false;
    } else {
      await addFavorite(providerId);
      return true;
    }
  }

  /// Check if a provider is in favorites
  Future<bool> isFavorite(String providerId) async {
    if (_uid == null) return false;
    final doc = await _favRef.doc(providerId).get();
    return doc.exists;
  }

  /// Stream of favorite provider IDs (real-time)
  Stream<List<String>> getFavoriteIds() {
    if (_uid == null) return Stream.value([]);
    return _favRef.snapshots().map(
        (snap) => snap.docs.map((doc) => doc.id).toList());
  }

  /// Stream of favorite providers with full user data
  Stream<QuerySnapshot> getFavorites() {
    if (_uid == null) return const Stream.empty();
    return _favRef.orderBy('addedAt', descending: true).snapshots();
  }
}
