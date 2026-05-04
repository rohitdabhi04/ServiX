import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'notification_service.dart';

class BookingService {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  User? get user => FirebaseAuth.instance.currentUser;

  /// Book a service with optional date & time slot
  Future<String> bookService({
    required String serviceId,
    required String serviceName,
    required String price,
    required String providerId,
    DateTime? scheduledDate,
    String? scheduledTime,
  }) async {
    try {
      final u = user;
      if (u == null) return "error";

      final alreadyBooked = await checkAlreadyBooked(serviceId);
      if (alreadyBooked) return "already";

      final providerDoc = await db.collection("users").doc(providerId).get();
      final providerName = providerDoc.data()?['name'] ?? "Provider";

      final userDoc = await db.collection("users").doc(u.uid).get();
      final userName = userDoc.data()?['name'] ?? u.email ?? "User";

      final Map<String, dynamic> bookingData = {
        "userId": u.uid,
        "userName": userName,
        "userEmail": u.email,
        "serviceId": serviceId,
        "serviceName": serviceName,
        "price": double.tryParse(price) ?? 0,
        "providerId": providerId,
        "providerName": providerName,
        "status": "Pending",
        "createdAt": FieldValue.serverTimestamp(),
      };

      if (scheduledDate != null) {
        bookingData["scheduledDate"] = Timestamp.fromDate(scheduledDate);
      }
      if (scheduledTime != null) {
        bookingData["scheduledTime"] = scheduledTime;
      }

      final bookingRef = await db.collection("bookings").add(bookingData);

      final slotInfo = (scheduledDate != null && scheduledTime != null)
          ? " for $scheduledTime"
          : "";
      await NotificationService.sendNotificationToUser(
        userId: providerId,
        title: "📅 New Booking Request",
        body: "$userName booked \"$serviceName\"$slotInfo.",
        bookingId: bookingRef.id,
      );

      return "success";
    } catch (e) {
      print("❌ Booking Error: $e");
      return "error";
    }
  }

  /// Reschedule a booking (user or provider)
  Future<void> rescheduleBooking({
    required String bookingId,
    required DateTime newDate,
    required String newTime,
    required String rescheduledBy, // "user" | "provider"
  }) async {
    await db.collection("bookings").doc(bookingId).update({
      "scheduledDate": Timestamp.fromDate(newDate),
      "scheduledTime": newTime,
      "rescheduledBy": rescheduledBy,
      "rescheduledAt": FieldValue.serverTimestamp(),
      "status": "Pending",
    });
  }

  /// Cancel a booking with reason (user or provider)
  Future<void> cancelBooking({
    required String bookingId,
    required String cancelledBy, // "user" | "provider"
    required String reason,
  }) async {
    await db.collection("bookings").doc(bookingId).update({
      "status": "Cancelled",
      "cancelledBy": cancelledBy,
      "cancellationReason": reason,
    });

    try {
      final doc = await db.collection("bookings").doc(bookingId).get();
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return;

      final serviceName = data['serviceName'] ?? "Service";
      final userId = data['userId'] as String?;
      final providerId = data['providerId'] as String?;
      final providerName = data['providerName'] ?? "Provider";
      final userName = data['userName'] ?? "User";

      if (cancelledBy == "user" && providerId != null) {
        await NotificationService.sendNotificationToUser(
          userId: providerId,
          title: "🚫 Booking Cancelled by User",
          body: "$userName cancelled \"$serviceName\". Reason: $reason",
          bookingId: bookingId,
        );
      } else if (cancelledBy == "provider" && userId != null) {
        await NotificationService.sendNotificationToUser(
          userId: userId,
          title: "🚫 Booking Cancelled by Provider",
          body: "$providerName cancelled your \"$serviceName\" booking. Reason: $reason",
          bookingId: bookingId,
        );
      }
    } catch (e) {
      print("❌ Cancel Notification Error: $e");
    }
  }

  /// Check if already booked
  /// Returns true only if an ACTIVE booking (Pending/Accepted) exists.
  /// Completed or Cancelled bookings are ignored → user can re-book.
  Future<bool> checkAlreadyBooked(String serviceId) async {
    try {
      final u = user;
      if (u == null) return false;
      final res = await db
          .collection("bookings")
          .where("userId", isEqualTo: u.uid)
          .where("serviceId", isEqualTo: serviceId)
          .get();

      return res.docs.any((doc) {
        final status =
            (doc.data() as Map<String, dynamic>)['status'] ?? '';
        return status == 'Pending' || status == 'Accepted';
      });
    } catch (e) {
      return false;
    }
  }

  /// Get user bookings stream
  Stream<QuerySnapshot> getUserBookings() {
    final u = user;
    if (u == null) return const Stream.empty();
    return db
        .collection("bookings")
        .where("userId", isEqualTo: u.uid)
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  /// Get provider bookings stream
  Stream<QuerySnapshot> getProviderBookings() {
    final u = user;
    if (u == null) return const Stream.empty();
    return db
        .collection("bookings")
        .where("providerId", isEqualTo: u.uid)
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  /// Update booking status and notify user
  Future<void> updateBookingStatus({
    required String bookingId,
    required String status,
  }) async {
    await db.collection("bookings").doc(bookingId).update({"status": status});

    try {
      final doc = await db.collection("bookings").doc(bookingId).get();
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return;

      final userId = data['userId'] as String?;
      final serviceName = data['serviceName'] ?? "Service";
      final providerName = data['providerName'] ?? "Provider";

      if (userId == null) return;

      String notifTitle;
      String notifBody;

      switch (status) {
        case "Accepted":
          notifTitle = "✅ Booking Accepted!";
          notifBody = "$providerName accepted your \"$serviceName\" booking.";
          break;
        case "Rejected":
          notifTitle = "❌ Booking Rejected";
          notifBody = "$providerName rejected your \"$serviceName\" booking.";
          break;
        case "Completed":
          notifTitle = "🎉 Booking Completed!";
          notifBody = "\"$serviceName\" has been completed successfully.";
          break;
        case "Cancelled":
          notifTitle = "🚫 Booking Cancelled";
          notifBody = "Your \"$serviceName\" booking has been cancelled.";
          break;
        default:
          notifTitle = "📋 Booking Update";
          notifBody = "Your \"$serviceName\" booking status: $status";
      }

      await NotificationService.sendNotificationToUser(
        userId: userId,
        title: notifTitle,
        body: notifBody,
        bookingId: bookingId,
      );
    } catch (e) {
      print("❌ Notification Error: $e");
    }
  }

  /// Mark booking as completed
  Future<void> completeBooking(String bookingId) async {
    await updateBookingStatus(bookingId: bookingId, status: "Completed");
  }
}