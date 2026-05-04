import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../services/service_service.dart';
import '../../services/booking_service.dart';
import '../../providers/location_provider.dart';
import '../../widgets/rating_bar.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/location_picker_sheet.dart';
import 'chat_screen.dart';
import 'service_detail_screen.dart';
import 'provider_public_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final serviceService = ServiceService();
  final bookingService = BookingService();

  String searchQuery = '';
  String selectedCategory = 'All';

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> categories = [
    {'label': 'All',         'icon': Icons.apps},
    {'label': 'AC',          'icon': Icons.ac_unit},
    {'label': 'Plumber',     'icon': Icons.plumbing},
    {'label': 'Electrician', 'icon': Icons.electrical_services},
    {'label': 'Cleaning',    'icon': Icons.cleaning_services},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();

    // Saved location load karo
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

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [

            /// 🔥 PREMIUM HEADER
            SliverToBoxAdapter(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  final data =
                      snapshot.data?.data() as Map<String, dynamic>?;
                  final userName = data?['name'] ?? 'User';
                  final userImage = data?['image'] as String?;

                  return Container(
                    padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
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
                              const Text('Welcome 👋',
                                  style: TextStyle(color: Colors.white70)),
                              const SizedBox(height: 4),
                              Text(
                                userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
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
                              const SizedBox(height: 2),
                              const Text(
                                'Find Best Services',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white24,
                          backgroundImage: userImage != null
                              ? NetworkImage(userImage)
                              : null,
                          child: userImage == null
                              ? Text(
                                  userName.isNotEmpty
                                      ? userName[0].toUpperCase()
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

            /// 🔍 SEARCH BAR
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 6)
                    ],
                  ),
                  child: TextField(
                    onChanged: (value) =>
                        setState(() => searchQuery = value.toLowerCase()),
                    decoration: const InputDecoration(
                      hintText: 'Search services...',
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),

            /// 🏷 CATEGORY CHIPS
            SliverToBoxAdapter(
              child: SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = selectedCategory == cat['label'];

                    return GestureDetector(
                      onTap: () =>
                          setState(() => selectedCategory = cat['label']),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.deepPurple
                              : theme.cardColor,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 5)
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(cat['icon'],
                                color: isSelected
                                    ? Colors.white
                                    : Colors.deepPurple),
                            const SizedBox(height: 5),
                            Text(
                              cat['label'],
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : theme.textTheme.bodyLarge?.color,
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            /// 🔥 SERVICES LIST
            StreamBuilder<QuerySnapshot>(
              stream: serviceService.getServices(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final loc = context.watch<LocationProvider>();
                final userCity = loc.city.toLowerCase().trim();

                final allServices = snapshot.data!.docs;
                final services = allServices.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title =
                      (data['title'] ?? '').toString().toLowerCase();
                  final category = data['category'] ?? '';
                  final serviceCity =
                      (data['providerCity'] ?? data['city'] ?? '').toString().toLowerCase().trim();
                  final matchesSearch = title.contains(searchQuery);
                  final matchesCategory = selectedCategory == 'All' ||
                      category == selectedCategory;
                  // Filter by city only if user has set location
                  final matchesCity = userCity.isEmpty ||
                      serviceCity.isEmpty ||
                      serviceCity == userCity;
                  return matchesSearch && matchesCategory && matchesCity;
                }).toList();

                if (services.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(child: Text('No Services Found')),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final doc = services[index];
                      final data = doc.data() as Map<String, dynamic>;

                      final providerId = data['providerId'] ?? '';
                      final providerName = data['providerName'] ?? 'Provider';
                      final providerCity = data['providerCity'] ?? '';
                      final title = data['title'] ?? '';
                      final desc = data['description'] ?? '';
                      final price = data['price'];
                      final finalPrice = price is num
                          ? price.toDouble()
                          : double.tryParse(price.toString()) ?? 0;
                      final avgRating =
                          (data['avgRating'] as num?)?.toDouble() ?? 0;
                      final totalReviews =
                          (data['totalReviews'] as num?)?.toInt() ?? 0;

                      return TweenAnimationBuilder(
                        duration:
                            Duration(milliseconds: 400 + (index * 100)),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, double value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 30 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: GestureDetector(
                          /// 🔗 Tap → Service Detail Page
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ServiceDetailScreen(
                                serviceId: doc.id,
                                data: data,
                              ),
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.black12, blurRadius: 6)
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                Row(
                                  children: [
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
                                      child: UserAvatar(
                                        userId: providerId,
                                        fallbackName: providerName,
                                        radius: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(providerName,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          if (providerCity.isNotEmpty)
                                            Row(
                                              children: [
                                                const Icon(Icons.location_on_rounded,
                                                    size: 11, color: Colors.grey),
                                                const SizedBox(width: 2),
                                                Text(providerCity,
                                                    style: const TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.grey)),
                                              ],
                                            ),
                                          const SizedBox(height: 2),
                                          Text(title,
                                              style: const TextStyle(
                                                  fontSize: 16)),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '₹${finalPrice.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        RatingDisplay(
                                          rating: avgRating,
                                          totalReviews: totalReviews,
                                          compact: true,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                if (desc.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    desc,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 13),
                                  ),
                                ],

                                const SizedBox(height: 12),

                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ServiceDetailScreen(
                                              serviceId: doc.id,
                                              data: data,
                                            ),
                                          ),
                                        ),
                                        child: const Text('Book'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    IconButton(
                                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ChatScreen(
                                              receiverId: providerId),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 16),
                                      tooltip: 'View Details',
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ServiceDetailScreen(
                                              serviceId: doc.id, data: data),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: services.length,
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }
}
