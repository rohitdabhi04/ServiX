import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/booking_service.dart';
import 'date_time_slot_screen.dart';
import '../../services/review_service.dart';
import '../../widgets/rating_bar.dart';
import '../../widgets/user_avatar.dart';
import 'chat_screen.dart';
import 'provider_public_profile_screen.dart';
import '../provider/service_portfolio_screen.dart';

class ServiceDetailScreen extends StatefulWidget {
  final String serviceId;
  final Map<String, dynamic> data;

  const ServiceDetailScreen({
    super.key,
    required this.serviceId,
    required this.data,
  });

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen>
    with TickerProviderStateMixin {

  final bookingService = BookingService();
  final reviewService = ReviewService();

  bool _isBooking = false;

  late AnimationController _heroController;
  late Animation<double> _heroFade;
  late Animation<Offset> _contentSlide;
  late AnimationController _contentController;

  @override
  void initState() {
    super.initState();

    _heroController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _heroFade = CurvedAnimation(parent: _heroController, curve: Curves.easeOut);

    _contentController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _contentSlide = Tween<Offset>(
        begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _contentController, curve: Curves.easeOut));

    _heroController.forward();
    Future.delayed(const Duration(milliseconds: 200),
            () => _contentController.forward());
  }

  @override
  void dispose() {
    _heroController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _bookService() async {
    final title = widget.data['title'] ?? '';
    final providerId = widget.data['providerId'] ?? '';
    final price = widget.data['price'];
    final finalPrice = price is num
        ? price.toDouble()
        : double.tryParse(price.toString()) ?? 0;

    final slot = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => DateTimeSlotScreen(serviceName: title),
      ),
    );

    if (slot == null) return;

    setState(() => _isBooking = true);

    final result = await bookingService.bookService(
      serviceId: widget.serviceId,
      serviceName: title,
      price: finalPrice.toString(),
      providerId: providerId,
      scheduledDate: slot['date'] as DateTime?,
      scheduledTime: slot['time'] as String?,
    );

    if (!mounted) return;
    setState(() => _isBooking = false);

    if (result == 'success') {
      _showBookingSuccess();
    } else if (result == 'already') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already booked this service'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking failed. Try again.'),
            backgroundColor: Colors.red),
      );
    }
  }

  void _showBookingSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: Colors.green, size: 44),
            ),
            const SizedBox(height: 16),
            const Text('Booking Confirmed!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Your booking request has been sent to the provider.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Great!'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final title = widget.data['title'] ?? 'Service';
    final description = widget.data['description'] ?? '';
    final price = widget.data['price'];
    final finalPrice = price is num
        ? price.toDouble()
        : double.tryParse(price.toString()) ?? 0;
    final providerName = widget.data['providerName'] ?? 'Provider';
    final providerId = widget.data['providerId'] ?? '';
    final category = widget.data['category'] ?? '';
    final avgRating = (widget.data['avgRating'] as num?)?.toDouble() ?? 0;
    final totalReviews = (widget.data['totalReviews'] as num?)?.toInt() ?? 0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [

          /// 🔥 HERO HEADER
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black45
                        : Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: isDark ? Colors.white : Colors.black87),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: FadeTransition(
                opacity: _heroFade,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -40,
                        top: -40,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.06),
                          ),
                        ),
                      ),
                      Positioned(
                        left: -30,
                        bottom: -30,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 50),
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.home_repair_service_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 14),
                            if (category.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  category,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          /// 📋 CONTENT — single SliverToBoxAdapter with ONE Column
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _contentSlide,
              child: FadeTransition(
                opacity: _contentController,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// Title + Price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${finalPrice.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              Text(
                                'per visit',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      /// Rating Row
                      Row(
                        children: [
                          RatingDisplay(
                            rating: avgRating,
                            totalReviews: totalReviews,
                          ),
                          const SizedBox(width: 12),
                          if (totalReviews > 0)
                            Text(
                              '$totalReviews review${totalReviews > 1 ? 's' : ''}',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 12),
                            ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      /// Provider card
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProviderPublicProfileScreen(
                              providerId: providerId,
                              providerName: providerName,
                            ),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: isDark
                                    ? Colors.white10
                                    : Colors.black.withOpacity(0.06)),
                          ),
                          child: Row(
                            children: [
                              UserAvatar(
                                userId: providerId,
                                fallbackName: providerName,
                                radius: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      providerName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                    ),
                                    Text(
                                      'Tap to view profile & all services',
                                      style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              if (providerId.isNotEmpty)
                                GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ChatScreen(receiverId: providerId),
                                    ),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.chat_bubble_outline_rounded,
                                        color: theme.colorScheme.primary,
                                        size: 20),
                                  ),
                                ),
                              const SizedBox(width: 6),
                              Icon(Icons.arrow_forward_ios_rounded,
                                  size: 14, color: Colors.grey.shade400),
                            ],
                          ),
                        ),
                      ),

                      // ✅ FIX: Provider card ke baad Column mein hi continue —
                      //         pehle yahan galti se ], ), ), aa gaya tha
                      //         jisse baaki content Column ke bahar chala gaya tha

                      const SizedBox(height: 20),

                      /// Description
                      Text('About this service',
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        description.isEmpty
                            ? 'No description provided.'
                            : description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.6, fontSize: 14),
                      ),

                      const SizedBox(height: 24),

                      /// Portfolio Gallery
                      PortfolioGalleryWidget(serviceId: widget.serviceId),

                      const SizedBox(height: 16),

                      /// Info Cards
                      Row(
                        children: [
                          _infoChip(
                              theme,
                              Icons.verified_rounded,
                              'Verified',
                              Colors.green),
                          const SizedBox(width: 10),
                          _infoChip(
                              theme,
                              Icons.flash_on_rounded,
                              'Fast Response',
                              Colors.orange),
                          const SizedBox(width: 10),
                          _infoChip(
                              theme,
                              Icons.shield_rounded,
                              'Safe',
                              Colors.blue),
                        ],
                      ),

                      const SizedBox(height: 28),

                      /// ⭐ REVIEWS SECTION
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Reviews',
                              style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold)),
                          if (totalReviews > 0)
                            Text('$totalReviews total',
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 12),

                      StreamBuilder<QuerySnapshot>(
                        stream: reviewService.getServiceReviews(widget.serviceId),
                        builder: (context, snap) {
                          if (!snap.hasData || snap.data!.docs.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.rate_review_outlined,
                                        size: 40,
                                        color: Colors.grey.shade400),
                                    const SizedBox(height: 8),
                                    Text('No reviews yet',
                                        style: TextStyle(
                                            color: Colors.grey.shade500)),
                                  ],
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: snap.data!.docs.map((doc) {
                              final d = doc.data() as Map<String, dynamic>;
                              return _reviewCard(theme, d);
                            }).toList(),
                          );
                        },
                      ),

                      const SizedBox(height: 100),

                    ], // ✅ Column children end
                  ),   // ✅ Column end
                ),     // ✅ Padding end
              ),       // ✅ FadeTransition end
            ),         // ✅ SlideTransition end
          ),           // ✅ SliverToBoxAdapter end

        ],
      ),

      /// 🔘 BOTTOM BOOK BUTTON
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (providerId.isNotEmpty) ...[
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(receiverId: providerId),
                  ),
                ),
                child: Container(
                  height: 54,
                  width: 54,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: isDark ? Colors.white12 : Colors.black12),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],

            Expanded(
              child: GestureDetector(
                onTap: _isBooking ? null : _bookService,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isBooking
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      'Book Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(ThemeData theme, IconData icon, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _reviewCard(ThemeData theme, Map<String, dynamic> data) {
    final rating = (data['rating'] as num?)?.toDouble() ?? 0;
    final comment = data['comment'] ?? '';
    final userName = data['userName'] ?? 'User';
    final userId = data['userId'] as String?;
    final ts = data['createdAt'] as Timestamp?;
    final dateStr = ts != null ? _formatDate(ts.toDate()) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: theme.brightness == Brightness.dark
                ? Colors.white10
                : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                userId: userId,
                fallbackName: userName,
                radius: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(userName,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              Text(dateStr,
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          RatingBar(
            initialRating: rating,
            readOnly: true,
            itemSize: 16,
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              comment,
              style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color,
                  fontSize: 13,
                  height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}