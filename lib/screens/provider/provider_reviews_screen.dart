import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../widgets/rating_bar.dart';
import '../../widgets/user_avatar.dart';

class ProviderReviewsScreen extends StatelessWidget {
  const ProviderReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reviews'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .where('providerId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_outline_rounded,
                      size: 72, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    'No reviews yet',
                    style: TextStyle(
                        fontSize: 16, color: theme.colorScheme.outline),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Complete bookings to receive reviews',
                    style: TextStyle(
                        fontSize: 13, color: theme.colorScheme.outline),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          // Client-side sort by createdAt descending
          docs.sort((a, b) {
            final aTime = (a.data() as Map)['createdAt'] as Timestamp?;
            final bTime = (b.data() as Map)['createdAt'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });

          // Calculate average rating
          final ratings = docs
              .map((d) =>
          ((d.data() as Map)['rating'] as num?)?.toDouble() ?? 0)
              .toList();
          final avgRating =
              ratings.reduce((a, b) => a + b) / ratings.length;

          return Column(
            children: [
              // Summary Card
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statItem(
                      label: 'Avg Rating',
                      value: avgRating.toStringAsFixed(1),
                      icon: Icons.star_rounded,
                    ),
                    Container(
                        width: 1,
                        height: 40,
                        color: Colors.white24),
                    _statItem(
                      label: 'Total Reviews',
                      value: '${docs.length}',
                      icon: Icons.rate_review_outlined,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Review List
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final data =
                    docs[index].data() as Map<String, dynamic>;
                    return _ReviewCard(data: data, theme: theme);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statItem(
      {required String label,
        required String value,
        required IconData icon}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(
                color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final ThemeData theme;

  const _ReviewCard({required this.data, required this.theme});

  @override
  Widget build(BuildContext context) {
    final userName = data['userName'] ?? 'User';
    final userId = data['userId'] as String?;
    final serviceName = data['serviceName'] ?? '';
    final rating = (data['rating'] as num?)?.toDouble() ?? 0;
    final comment = (data['comment'] as String?)?.trim() ?? '';
    final createdAt = data['createdAt'] as Timestamp?;

    String timeStr = '';
    if (createdAt != null) {
      final dt = createdAt.toDate();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) {
        timeStr = 'Just now';
      } else if (diff.inMinutes < 60) {
        timeStr = '${diff.inMinutes} min ago';
      } else if (diff.inHours < 24) {
        timeStr = '${diff.inHours} hr ago';
      } else {
        timeStr = DateFormat('d MMM yyyy').format(dt);
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              UserAvatar(
                userId: userId,
                fallbackName: userName,
                radius: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    if (serviceName.isNotEmpty)
                      Text(serviceName,
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500)),
                  ],
                ),
              ),
              Text(timeStr,
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade500)),
            ],
          ),
          const SizedBox(height: 10),
          RatingBar(
            initialRating: rating,
            itemSize: 20,
            readOnly: true,
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              comment,
              style:
              TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ],
        ],
      ),
    );
  }
}