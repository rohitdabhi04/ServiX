import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Reusable avatar widget — Firestore se image auto-fetch karta hai
/// [userId] — jis user ka avatar dikhana hai
/// [radius] — avatar size (default 22)
/// [imageUrl] — agar already url pata ho toh seedha pass karo (Firestore call skip)
class UserAvatar extends StatelessWidget {
  final String? userId;
  final double radius;
  final String? imageUrl;   // optional override
  final String? fallbackName; // initials ke liye

  const UserAvatar({
    super.key,
    this.userId,
    this.radius = 22,
    this.imageUrl,
    this.fallbackName,
  });

  @override
  Widget build(BuildContext context) {
    // Agar imageUrl directly diya hai toh Firestore call mat karo
    if (imageUrl != null) {
      return _avatar(context, imageUrl, fallbackName);
    }

    // userId se Firestore se fetch karo
    if (userId == null) {
      return _avatar(context, null, fallbackName);
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        final url = data?['image'] as String?;
        final name = fallbackName ?? (data?['name'] as String?) ?? '';
        return _avatar(context, url, name);
      },
    );
  }

  Widget _avatar(BuildContext context, String? url, String? name) {
    final theme = Theme.of(context);
    final initial = (name != null && name.isNotEmpty)
        ? name[0].toUpperCase()
        : '?';

    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
      backgroundImage: url != null && url.isNotEmpty
          ? NetworkImage(url)
          : null,
      child: url == null || url.isEmpty
          ? Text(
        initial,
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.75,
        ),
      )
          : null,
    );
  }
}