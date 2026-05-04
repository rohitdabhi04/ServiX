import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceModel {
  final String id;
  final String title;
  final String description;
  final String price;
  final String providerId;
  final Timestamp? createdAt;

  ServiceModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.providerId,
    this.createdAt,
  });

  /// 🔥 TO MAP (FIRESTORE SAVE)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'providerId': providerId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// 🔥 FROM MAP (FIRESTORE READ)
  factory ServiceModel.fromMap(String id, Map<String, dynamic> data) {
    return ServiceModel(
      id: id,
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      price: data['price']?.toString() ?? '',
      providerId: data['providerId']?.toString() ?? '',
      createdAt: data['createdAt'],
    );
  }

  /// 🔥 COPY WITH (UPDATE SUPPORT)
  ServiceModel copyWith({
    String? title,
    String? description,
    String? price,
    String? providerId,
    Timestamp? createdAt,
  }) {
    return ServiceModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      providerId: providerId ?? this.providerId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'ServiceModel(title: $title, price: $price)';
  }
}