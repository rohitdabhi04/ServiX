import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // "user" | "provider"
  final String? image;
  final String? phone;
  final String? location;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Provider-specific fields
  final String? bio;
  final List<String>? categories;
  final double? avgRating;
  final int? totalReviews;
  final bool? isAvailable;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.image,
    this.phone,
    this.location,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
    this.bio,
    this.categories,
    this.avgRating,
    this.totalReviews,
    this.isAvailable,
  });

  factory UserModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'user',
      image: data['image'],
      phone: data['phone'],
      location: data['location'],
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      bio: data['bio'],
      categories: (data['categories'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      avgRating: (data['avgRating'] as num?)?.toDouble(),
      totalReviews: (data['totalReviews'] as num?)?.toInt(),
      isAvailable: data['isAvailable'] as bool?,
    );
  }

  factory UserModel.fromMap(String uid, Map<String, dynamic> data) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'user',
      image: data['image'],
      phone: data['phone'],
      location: data['location'],
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      bio: data['bio'],
      categories: (data['categories'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      avgRating: (data['avgRating'] as num?)?.toDouble(),
      totalReviews: (data['totalReviews'] as num?)?.toInt(),
      isAvailable: data['isAvailable'] as bool?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
      if (image != null) 'image': image,
      if (phone != null) 'phone': phone,
      if (location != null) 'location': location,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'updatedAt': FieldValue.serverTimestamp(),
      if (bio != null) 'bio': bio,
      if (categories != null) 'categories': categories,
      if (isAvailable != null) 'isAvailable': isAvailable,
    };
  }

  UserModel copyWith({
    String? name,
    String? image,
    String? phone,
    String? location,
    double? latitude,
    double? longitude,
    String? bio,
    List<String>? categories,
    double? avgRating,
    int? totalReviews,
    bool? isAvailable,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      name: name ?? this.name,
      role: role,
      image: image ?? this.image,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt,
      updatedAt: updatedAt,
      bio: bio ?? this.bio,
      categories: categories ?? this.categories,
      avgRating: avgRating ?? this.avgRating,
      totalReviews: totalReviews ?? this.totalReviews,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  bool get isProvider => role == 'provider';
  bool get isUser => role == 'user';

  @override
  String toString() => 'UserModel(uid: $uid, name: $name, role: $role)';
}
