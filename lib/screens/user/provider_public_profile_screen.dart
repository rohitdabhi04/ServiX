import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../widgets/user_avatar.dart';
import '../../widgets/rating_bar.dart';
import '../../services/booking_service.dart';
import '../../widgets/date_time_slot_picker.dart';
import 'chat_screen.dart';
import 'service_detail_screen.dart';

class ProviderPublicProfileScreen extends StatefulWidget {
  final String providerId;
  final String? providerName;

  const ProviderPublicProfileScreen({
    super.key,
    required this.providerId,
    this.providerName,
  });

  @override
  State<ProviderPublicProfileScreen> createState() =>
      _ProviderPublicProfileScreenState();
}

class _ProviderPublicProfileScreenState
    extends State<ProviderPublicProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final bookingService = BookingService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.providerId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final name = data?['name'] ?? widget.providerName ?? 'Provider';
          final image = data?['image'] as String?;
          final business = data?['business'] ?? '';
          final city = data?['city'] ?? '';
          final area = data?['area'] ?? '';
          final phone = data?['phone'] ?? '';
          final about = data?['about'] ?? '';
          final locationStr = area.isNotEmpty && area != city
              ? '$area, $city'
              : city;

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              /// 🔥 SliverAppBar with gradient
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: theme.colorScheme.primary,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded,
                      color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline_rounded,
                        color: Colors.white),
                    tooltip: 'Chat',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ChatScreen(receiverId: widget.providerId),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 50),

                        /// Avatar
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border:
                            Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: UserAvatar(
                            userId: widget.providerId,
                            fallbackName: name,
                            radius: 48,
                          ),
                        ),

                        const SizedBox(height: 12),

                        /// Name
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        if (business.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            business,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14),
                          ),
                        ],

                        const SizedBox(height: 8),

                        /// Location + Phone chips
                        Wrap(
                          spacing: 10,
                          runSpacing: 6,
                          alignment: WrapAlignment.center,
                          children: [
                            if (locationStr.isNotEmpty)
                              _chip(Icons.location_on_rounded, locationStr),
                            if (phone.isNotEmpty)
                              _chip(Icons.phone_rounded, phone),
                          ],
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),

              /// Stats row
              SliverToBoxAdapter(
                child: _StatsRow(providerId: widget.providerId),
              ),

              /// About section
              if (about.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? Colors.white10
                              : Colors.black.withOpacity(0.06),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('About',
                              style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(about,
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 13,
                                  height: 1.5)),
                        ],
                      ),
                    ),
                  ),
                ),

              /// TabBar
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: theme.colorScheme.primary,
                    tabs: const [
                      Tab(text: 'Services'),
                      Tab(text: 'Reviews'),
                    ],
                  ),
                  backgroundColor: theme.scaffoldBackgroundColor,
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                /// Services Tab
                _ServicesTab(
                  providerId: widget.providerId,
                  bookingService: bookingService,
                ),

                /// Reviews Tab
                _ReviewsTab(providerId: widget.providerId),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(label,
              style:
              const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

/// ─── Stats Row ─────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final String providerId;
  const _StatsRow({required this.providerId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('providerId', isEqualTo: providerId)
          .snapshots(),
      builder: (context, revSnap) {
        final reviews = revSnap.data?.docs ?? [];
        final totalReviews = reviews.length;
        final avgRating = totalReviews == 0
            ? 0.0
            : reviews
            .map((d) =>
        (d.data() as Map<String, dynamic>)['rating'] as num? ??
            0)
            .reduce((a, b) => a + b) /
            totalReviews;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('services')
              .where('providerId', isEqualTo: providerId)
              .snapshots(),
          builder: (context, svcSnap) {
            final totalServices = svcSnap.data?.docs.length ?? 0;

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('providerId', isEqualTo: providerId)
                  .where('status', isEqualTo: 'Completed')
                  .snapshots(),
              builder: (context, bookSnap) {
                final completedJobs = bookSnap.data?.docs.length ?? 0;

                return Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _statItem(context, '${avgRating.toStringAsFixed(1)}⭐',
                          'Rating'),
                      _divider(),
                      _statItem(context, '$totalReviews', 'Reviews'),
                      _divider(),
                      _statItem(context, '$totalServices', 'Services'),
                      _divider(),
                      _statItem(context, '$completedJobs', 'Jobs Done'),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _statItem(BuildContext context, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              style:
              const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _divider() => Container(
    width: 1,
    height: 36,
    color: Colors.grey.withOpacity(0.2),
  );
}

/// ─── Services Tab ──────────────────────────────────────────────────────────
class _ServicesTab extends StatelessWidget {
  final String providerId;
  final BookingService bookingService;
  const _ServicesTab(
      {required this.providerId, required this.bookingService});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('services')
          .where('providerId', isEqualTo: providerId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.home_repair_service_outlined,
                    size: 56, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('No services yet',
                    style: TextStyle(color: Colors.grey.shade400)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;
            final title = data['title'] ?? 'Service';
            final desc = data['description'] ?? '';
            final price = (data['price'] as num?)?.toDouble() ?? 0;
            final avgRating =
                (data['avgRating'] as num?)?.toDouble() ?? 0;
            final totalReviews =
                (data['totalReviews'] as num?)?.toInt() ?? 0;

            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ServiceDetailScreen(serviceId: doc.id, data: data),
                ),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withOpacity(0.06),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(title,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(
                                  fontWeight: FontWeight.bold)),
                        ),
                        Text(
                          '₹${price.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(desc,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13)),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        RatingDisplay(
                            rating: avgRating,
                            totalReviews: totalReviews,
                            compact: true),
                        const Spacer(),
                        // ✅ FIX: SizedBox needs width too — without it
                        // ElevatedButton gets w=Infinity and crashes.
                        SizedBox(
                          height: 34,
                          width: 72,
                          child: ElevatedButton(
                            onPressed: () async {
                              final slot = await DateTimeSlotPicker.show(
                                context,
                                serviceName: title,
                              );
                              if (slot == null || !context.mounted) return;
                              final result = await bookingService.bookService(
                                serviceId: doc.id,
                                serviceName: title,
                                price: price.toString(),
                                providerId: providerId,
                                scheduledDate: slot.date,
                                scheduledTime: slot.time,
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result == 'success'
                                      ? '✅ Booked for ${slot.time}'
                                      : result == 'already'
                                      ? 'Already have an active booking'
                                      : 'Booking failed'),
                                  backgroundColor: result == 'success'
                                      ? Colors.green
                                      : null,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(72, 34),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Book',
                                style: TextStyle(fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// ─── Reviews Tab ───────────────────────────────────────────────────────────
class _ReviewsTab extends StatelessWidget {
  final String providerId;
  const _ReviewsTab({required this.providerId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('providerId', isEqualTo: providerId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_border_rounded,
                    size: 56, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('No reviews yet',
                    style: TextStyle(color: Colors.grey.shade400)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final userName = data['userName'] ?? 'User';
            final userId = data['userId'] ?? '';
            final rating = (data['rating'] as num?)?.toDouble() ?? 0;
            final comment = data['comment'] ?? '';
            final createdAt = data['createdAt'];

            String timeAgo = '';
            if (createdAt != null) {
              try {
                final date = createdAt.toDate();
                final diff = DateTime.now().difference(date);
                if (diff.inDays > 30) {
                  timeAgo =
                  '${(diff.inDays / 30).floor()}mo ago';
                } else if (diff.inDays > 0) {
                  timeAgo = '${diff.inDays}d ago';
                } else if (diff.inHours > 0) {
                  timeAgo = '${diff.inHours}h ago';
                } else {
                  timeAgo = 'Just now';
                }
              } catch (_) {}
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? Colors.white10
                      : Colors.black.withOpacity(0.06),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      UserAvatar(
                        userId: userId,
                        fallbackName: userName,
                        radius: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(userName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                            if (timeAgo.isNotEmpty)
                              Text(timeAgo,
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 11)),
                          ],
                        ),
                      ),
                      Row(
                        children: List.generate(
                          5,
                              (index) => Icon(
                            index < rating.round()
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: Colors.amber,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (comment.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(comment,
                        style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                            height: 1.4)),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// ─── SliverPersistentHeader Delegate ───────────────────────────────────────
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _SliverTabBarDelegate(this.tabBar, {required this.backgroundColor});

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}