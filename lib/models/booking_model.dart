import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String serviceId;
  final String serviceName;
  final double price;
  final String providerId;
  final String providerName;
  final String status;
  final DateTime? createdAt;

  // ── NEW FIELDS ──────────────────────────────────────────
  final DateTime? scheduledDate;    // user-chosen appointment date
  final String? scheduledTime;      // user-chosen time slot e.g. "10:00 AM"
  final String? cancelledBy;        // "user" | "provider"
  final String? cancellationReason;

  BookingModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.serviceId,
    required this.serviceName,
    required this.price,
    required this.providerId,
    required this.providerName,
    required this.status,
    this.createdAt,
    this.scheduledDate,
    this.scheduledTime,
    this.cancelledBy,
    this.cancellationReason,
  });

  factory BookingModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookingModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      serviceId: data['serviceId'] ?? '',
      serviceName: data['serviceName'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      providerId: data['providerId'] ?? '',
      providerName: data['providerName'] ?? '',
      status: data['status'] ?? 'Pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      scheduledDate: (data['scheduledDate'] as Timestamp?)?.toDate(),
      scheduledTime: data['scheduledTime'],
      cancelledBy: data['cancelledBy'],
      cancellationReason: data['cancellationReason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'price': price,
      'providerId': providerId,
      'providerName': providerName,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      if (scheduledDate != null)
        'scheduledDate': Timestamp.fromDate(scheduledDate!),
      if (scheduledTime != null) 'scheduledTime': scheduledTime,
    };
  }
}