import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../widgets/user_avatar.dart';
import 'provider_dashboard.dart';
import 'provider_profile_screen.dart';
import 'provider_bookings_screen.dart';
import 'add_service_screen.dart';
import 'provider_services_screen.dart';
import 'provider_chat_list_screen.dart';
import '../common/notifications_screen.dart';

class ProviderMainScreen extends StatefulWidget {
  const ProviderMainScreen({super.key});

  @override
  State<ProviderMainScreen> createState() => _ProviderMainScreenState();
}

class _ProviderMainScreenState extends State<ProviderMainScreen> {
  int currentIndex = 0;

  final List<String> titles = [
    "Dashboard",
    "Bookings",
    "Services",
    "Chats",
    "Profile",
  ];

  Widget _buildScreen(int index) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();
    switch (index) {
      case 0: return const ProviderDashboard();
      case 1: return const ProviderBookingsScreen();
      case 2: return const ProviderServicesScreen();
      case 3: return const ProviderChatListScreen();
      case 4: return const ProviderProfileScreen();
      default: return const ProviderDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final currentUid = snapshot.data!.uid;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
              ).createShader(bounds),
              child: Text(
                titles[currentIndex],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ),
            elevation: 0,
            backgroundColor: theme.scaffoldBackgroundColor,
            actions: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('notifications')
                        .where('userId', isEqualTo: currentUid)
                        .where('isRead', isEqualTo: false)
                        .snapshots(),
                    builder: (context, snap) {
                      if (snap.hasError) return const SizedBox.shrink();
                      final count = snap.data?.docs.length ?? 0;
                      return Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            child: IconButton(
                              icon: Icon(
                                Icons.notifications_outlined,
                                color: isDark ? Colors.white : const Color(0xFF1A1B2E),
                              ),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const NotificationsScreen()),
                              ),
                            ),
                          ),
                          if (count > 0)
                            Positioned(
                              right: 4,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.colorScheme.primary,
                                      theme.colorScheme.secondary,
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                    minWidth: 16, minHeight: 16),
                                child: Text(
                                  count > 9 ? "9+" : "$count",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => setState(() => currentIndex = 4),
                      child: UserAvatar(userId: currentUid, radius: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),

          body: _buildScreen(currentIndex),

          floatingActionButton: currentIndex == 2
              ? Container(
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
                  color: theme.colorScheme.primary.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AddServiceScreen()),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Icon(Icons.add_rounded,
                      color: Colors.white, size: 26),
                ),
              ),
            ),
          )
              : null,

          // ── Bottom Nav with live badge counts ──────────────────
          bottomNavigationBar: StreamBuilder<QuerySnapshot>(
            // Unread messages for provider
            stream: FirebaseFirestore.instance
                .collection('messages')
                .where('receiverId', isEqualTo: currentUid)
                .where('isRead', isEqualTo: false)
                .snapshots(),
            builder: (context, msgSnap) {
              final unreadMsgs = msgSnap.data?.docs.length ?? 0;

              return StreamBuilder<QuerySnapshot>(
                // Active bookings only — exclude Completed, Rejected & Cancelled
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('providerId', isEqualTo: currentUid)
                    .snapshots(),
                builder: (context, bookSnap) {
                  if (bookSnap.hasError) {
                    debugPrint('❌ Bookings badge error: \${bookSnap.error}');
                  }
                  final pendingBookings = bookSnap.data?.docs.where((doc) {
                    final status = (doc.data() as Map<String, dynamic>)['status'] ?? '';
                    return status != 'Completed' && status != 'Cancelled' && status != 'Rejected';
                  }).length ?? 0;
                  debugPrint('📦 Provider bookings count: \$pendingBookings');

                  return _ProviderNavBar(
                    currentIndex: currentIndex,
                    onTap: (i) => setState(() => currentIndex = i),
                    isDark: isDark,
                    primaryColor: theme.colorScheme.primary,
                    unreadChats: unreadMsgs,
                    pendingBookings: pendingBookings,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _ProviderNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isDark;
  final Color primaryColor;
  final int unreadChats;
  final int pendingBookings;

  const _ProviderNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.isDark,
    required this.primaryColor,
    required this.unreadChats,
    required this.pendingBookings,
  });

  static const _items = [
    (Icons.dashboard_outlined, Icons.dashboard_rounded, "Dashboard"),
    (Icons.calendar_today_outlined, Icons.calendar_today_rounded, "Bookings"),
    (Icons.build_outlined, Icons.build_rounded, "Services"),
    (Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, "Chats"),
    (Icons.person_outline_rounded, Icons.person_rounded, "Profile"),
  ];

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF13141F) : Colors.white;
    final borderColor =
    isDark ? const Color(0xFF252638) : const Color(0xFFE5E7EB);

    // badge count per tab index: 1=Bookings, 3=Chats
    final badges = {1: pendingBookings, 3: unreadChats};

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              _items.length,
                  (i) {
                final item = _items[i];
                final isActive = currentIndex == i;
                final badge = badges[i] ?? 0;

                return GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? primaryColor.withOpacity(0.12)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isActive ? item.$2 : item.$1,
                                color: isActive
                                    ? primaryColor
                                    : const Color(0xFF9E9EB0),
                                size: 22,
                              ),
                            ),
                            // 🔴 Badge
                            if (badge > 0)
                              Positioned(
                                right: -4,
                                top: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                      minWidth: 17, minHeight: 17),
                                  child: Text(
                                    badge > 99 ? '99+' : '$badge',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: isActive
                                ? primaryColor
                                : const Color(0xFF9E9EB0),
                            fontSize: 11,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          child: Text(item.$3),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}