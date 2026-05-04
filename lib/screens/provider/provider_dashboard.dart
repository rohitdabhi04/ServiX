import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../widgets/user_avatar.dart';
import '../../widgets/location_picker_sheet.dart';
import '../../providers/location_provider.dart';
import 'earnings_dashboard_screen.dart';

class ProviderDashboard extends StatefulWidget {
  const ProviderDashboard({super.key});

  @override
  State<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends State<ProviderDashboard>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.forward();

    // Load saved location
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().loadSavedLocation();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _fade,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [

          /// 🔥 HEADER
          SliverToBoxAdapter(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .snapshots(),
              builder: (context, snapshot) {
                final data =
                    snapshot.data?.data() as Map<String, dynamic>?;
                final providerName = data?['name'] ?? 'Provider';
                final providerImage = data?['image'] as String?;

                return Container(
                  padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1C53CB), Color(0xFF1AB1AD)],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(25),
                      bottomRight: Radius.circular(25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Dashboard",
                                style: TextStyle(color: Colors.white70)),
                            const SizedBox(height: 4),
                            Text(
                              providerName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            // 📍 Location Row
                            GestureDetector(
                              onTap: () => showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => ChangeNotifierProvider.value(
                                  value: context.read<LocationProvider>(),
                                  child: const LocationPickerSheet(),
                                ),
                              ),
                              child: Consumer<LocationProvider>(
                                builder: (context, loc, _) {
                                  return Row(
                                    children: [
                                      const Icon(Icons.location_on_rounded,
                                          color: Colors.white70, size: 14),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          loc.isLoading
                                              ? 'Detecting...'
                                              : loc.displayLocation,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: Colors.white70,
                                          size: 16),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white24,
                        backgroundImage: providerImage != null
                            ? NetworkImage(providerImage)
                            : null,
                        child: providerImage == null
                            ? Text(
                                providerName.isNotEmpty
                                    ? providerName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20),
                              )
                            : null,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          /// 📊 DATA
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("bookings")
                .where("providerId", isEqualTo: uid)
                .snapshots(),
            builder: (context, bookingSnapshot) {

              int totalBookings = 0;
              int pending = 0;
              int accepted = 0;
              double earnings = 0;

              if (bookingSnapshot.hasData) {
                final docs = bookingSnapshot.data!.docs;
                totalBookings = docs.length;

                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status'] ?? '';

                  if (status == "Pending") pending++;
                  if (status == "Accepted") accepted++;

                  if (status == "Completed") {
                    final price = data['price'];
                    if (price is num) {
                      earnings += price.toDouble();
                    } else if (price is String) {
                      earnings += double.tryParse(price) ?? 0;
                    }
                  }
                }
              }

              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const SizedBox(height: 10),

                      Text("Overview",
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),

                      const SizedBox(height: 15),

                      /// GRID CARDS
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.2,
                        children: [

                          _animatedCard(
                              "Total Bookings",
                              totalBookings.toString(),
                              Icons.calendar_today,
                              Colors.blue,
                              0),

                          _animatedCard(
                              "Pending",
                              pending.toString(),
                              Icons.pending_actions,
                              Colors.orange,
                              1),

                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EarningsDashboardScreen())),
                            child: _animatedCard(
                                "Earnings",
                                "₹${earnings.toStringAsFixed(0)}",
                                Icons.bar_chart_rounded,
                                Colors.green,
                                2),
                          ),

                          _servicesCard(uid, 3),

                          _animatedCard(
                              "Accepted",
                              accepted.toString(),
                              Icons.check_circle_outline,
                              Colors.teal,
                              4),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 🔥 ANIMATED CARD
  Widget _animatedCard(
      String title, String value, IconData icon, Color color, int index) {

    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, double valueAnim, child) {
        return Opacity(
          opacity: valueAnim,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - valueAnim)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 4),
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  /// 🔧 SERVICES COUNT CARD
  Widget _servicesCard(String uid, int index) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("services")
          .where("providerId", isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;

        return _animatedCard(
            "Services", count.toString(), Icons.build, Colors.purple, index);
      },
    );
  }
}