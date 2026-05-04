import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'notification_service.dart';

class ReviewService {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  User? get user => FirebaseAuth.instance.currentUser;

  /// Submit a review for a service (after booking is Completed)
  Future<String> submitReview({
    required String serviceId,
    required String providerId,
    required String bookingId,
    required double rating,
    required String comment,
    required String serviceName,
    required String providerName,
  }) async {
    final u = user;
    if (u == null) return 'error';

    try {
      // Check if already reviewed
      final existing = await db
          .collection('reviews')
          .where('bookingId', isEqualTo: bookingId)
          .where('userId', isEqualTo: u.uid)
          .get();

      if (existing.docs.isNotEmpty) return 'already';

      final userDoc = await db.collection('users').doc(u.uid).get();
      final userName = userDoc.data()?['name'] ?? u.email ?? 'User';

      // Save review
      await db.collection('reviews').add({
        'serviceId': serviceId,
        'providerId': providerId,
        'bookingId': bookingId,
        'userId': u.uid,
        'userName': userName,
        'serviceName': serviceName,
        'providerName': providerName,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Mark booking as reviewed
      await db.collection('bookings').doc(bookingId).update({'isReviewed': true});

      // Notify provider about new review
      await NotificationService.sendNotificationToUser(
        userId: providerId,
        title: '⭐ New Review Received',
        body: '$userName rated "$serviceName" ${rating.toStringAsFixed(1)}/5.',
        bookingId: bookingId,
      );

      // Update service avg rating
      await _updateServiceRating(serviceId);

      return 'success';
    } catch (e) {
      print('Review Error: $e');
      return 'error';
    }
  }

  /// Recalculate and update service average rating
  Future<void> _updateServiceRating(String serviceId) async {
    final snap = await db
        .collection('reviews')
        .where('serviceId', isEqualTo: serviceId)
        .get();

    if (snap.docs.isEmpty) return;

    final ratings = snap.docs
        .map((d) => (d.data()['rating'] as num?)?.toDouble() ?? 0)
        .toList();

    final avg = ratings.reduce((a, b) => a + b) / ratings.length;

    await db.collection('services').doc(serviceId).update({
      'avgRating': double.parse(avg.toStringAsFixed(1)),
      'totalReviews': ratings.length,
    });
  }

  /// Get all reviews for a service
  Stream<QuerySnapshot> getServiceReviews(String serviceId) {
    return db
        .collection('reviews')
        .where('serviceId', isEqualTo: serviceId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get reviews written by a user
  Stream<QuerySnapshot> getUserReviews() {
    final u = user;
    if (u == null) return const Stream.empty();
    return db
        .collection('reviews')
        .where('userId', isEqualTo: u.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Check if booking is already reviewed
  Future<bool> isBookingReviewed(String bookingId) async {
    final u = user;
    if (u == null) return false;
    final snap = await db
        .collection('reviews')
        .where('bookingId', isEqualTo: bookingId)
        .where('userId', isEqualTo: u.uid)
        .get();
    return snap.docs.isNotEmpty;
  }
}