import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../widgets/user_avatar.dart';
import 'home_screen.dart';
import 'my_bookings_screen.dart';
import 'profile_screen.dart';
import 'user_chat_list_screen.dart';
import 'search_screen.dart';
import '../common/notifications_screen.dart';

class UserMainScreen extends StatefulWidget {
  const UserMainScreen({super.key});

  @override
  State<UserMainScreen> createState() => _UserMainScreenState();
}

class _UserMainScreenState extends State<UserMainScreen>
    with TickerProviderStateMixin {
  int currentIndex = 0;

  final List<Widget> screens = const [
    HomeScreen(),
    SearchScreen(),
    MyBookingsScreen(),
    UserChatListScreen(),
    ProfileScreen(),
  ];

  late AnimationController _navCtrl;

  @override
  void initState() {
    super.initState();
    _navCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _navCtrl.forward();
  }

  @override
  void dispose() {
    _navCtrl.dispose();
    super.dispose();
  }

  void _onTabTap(int index) {
    if (currentIndex == index) return;
    setState(() => currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: currentIndex == 0
          ? AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
            ],
          ).createShader(bounds),
          child: const Text(
            "Servix",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 22,
              letterSpacing: 0.5,
            ),
          ),
        ),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, authSnap) {
              final currentUid = authSnap.data?.uid;
              if (currentUid == null) return const SizedBox.shrink();

              return Row(
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
                      child: UserAvatar(
                        userId: currentUid,
                        radius: 16,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      )
          : null,

      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),

      // ── Bottom Nav with live badge counts ──────────────────────
      bottomNavigationBar: currentUid == null
          ? null
          : StreamBuilder<QuerySnapshot>(
        // Unread messages stream
        stream: FirebaseFirestore.instance
            .collection('messages')
            .where('receiverId', isEqualTo: currentUid)
            .where('isRead', isEqualTo: false)
            .snapshots(),
        builder: (context, msgSnap) {
          final unreadMsgs = msgSnap.data?.docs.length ?? 0;

          return StreamBuilder<QuerySnapshot>(
            // Active bookings only — exclude Completed & Cancelled
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .where('userId', isEqualTo: currentUid)
                .snapshots(),
            builder: (context, bookSnap) {
              final pendingBookings = bookSnap.data?.docs.where((doc) {
                final status = (doc.data() as Map<String, dynamic>)['status'] ?? '';
                return status != 'Completed' && status != 'Cancelled';
              }).length ?? 0;

              return _PremiumNavBar(
                currentIndex: currentIndex,
                onTap: _onTabTap,
                isDark: isDark,
                primaryColor: theme.colorScheme.primary,
                items: [
                  const _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: "Home"),
                  const _NavItem(icon: Icons.search_outlined, activeIcon: Icons.search_rounded, label: "Search"),
                  _NavItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today_rounded, label: "Bookings", badgeCount: pendingBookings),
                  _NavItem(icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded, label: "Chats", badgeCount: unreadMsgs),
                  const _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: "Profile"),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badgeCount;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount = 0,
  });
}

class _PremiumNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isDark;
  final Color primaryColor;
  final List<_NavItem> items;

  const _PremiumNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.isDark,
    required this.primaryColor,
    required this.items,
  });

  @override
  State<_PremiumNavBar> createState() => _PremiumNavBarState();
}

class _PremiumNavBarState extends State<_PremiumNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _indicatorCtrl;

  @override
  void initState() {
    super.initState();
    _indicatorCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _indicatorCtrl.forward();
  }

  @override
  void dispose() {
    _indicatorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? const Color(0xFF13141F) : Colors.white;
    final borderColor = widget.isDark
        ? const Color(0xFF252638)
        : const Color(0xFFE5E7EB);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          top: BorderSide(color: borderColor, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(widget.isDark ? 0.4 : 0.06),
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
              widget.items.length,
                  (i) => _NavBarItem(
                item: widget.items[i],
                isActive: widget.currentIndex == i,
                primaryColor: widget.primaryColor,
                isDark: widget.isDark,
                onTap: () => widget.onTap(i),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatefulWidget {
  final _NavItem item;
  final bool isActive;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.isActive,
    required this.primaryColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _scaleAnim = Tween(begin: 1.0, end: 1.15).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    if (widget.isActive) _ctrl.forward();
  }

  @override
  void didUpdateWidget(_NavBarItem old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      _ctrl.forward();
    } else if (!widget.isActive && old.isActive) {
      _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badge = widget.item.badgeCount;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                      color: widget.isActive
                          ? widget.primaryColor.withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.isActive ? widget.item.activeIcon : widget.item.icon,
                      color: widget.isActive
                          ? widget.primaryColor
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
                        constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
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
                  color: widget.isActive
                      ? widget.primaryColor
                      : const Color(0xFF9E9EB0),
                  fontSize: 11,
                  fontWeight: widget.isActive
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
                child: Text(widget.item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}