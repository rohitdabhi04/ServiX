import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../providers/theme_provider.dart';
import '../../providers/location_provider.dart';
import '../../services/auth_service.dart';
import 'provider_edit_profile_screen.dart';
import 'package:share_plus/share_plus.dart';

import 'provider_services_screen.dart';
import 'provider_bookings_screen.dart';
import 'provider_reviews_screen.dart';
import '../common/privacy_policy_screen.dart';
import 'earnings_dashboard_screen.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 🔥 UPDATED LOGOUT DIALOG
  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) => Dialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              const Icon(Icons.logout, size: 40, color: Colors.redAccent),

              const SizedBox(height: 10),

              const Text(
                "Logout",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "Are you sure you want to logout?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade400,
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text("Cancel"),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        "Logout",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _isLoggingOut = true);

    try {
      await AuthService().logout();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoggingOut = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Logout failed")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [

            /// 🔥 HEADER + PROFILE
            SliverToBoxAdapter(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("users")
                    .doc(user.uid)
                    .snapshots(),
                builder: (context, snapshot) {

                  if (!snapshot.hasData) {
                    return const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final data =
                  snapshot.data!.data() as Map<String, dynamic>?;

                  final name = data?['name'] ?? "Provider";
                  final image = data?['image'];
                  final business = data?['business'] ?? "";

                  return Container(
                    padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xff3ea2ac), Color(0xff4d64dd)],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(25),
                        bottomRight: Radius.circular(25),
                      ),
                    ),
                    child: Column(
                      children: [

                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          backgroundImage:
                          image != null ? NetworkImage(image) : null,
                          child: image == null
                              ? const Icon(Icons.person,
                              size: 40, color: Colors.black)
                              : null,
                        ),

                        const SizedBox(height: 10),

                        Text(name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),

                        if (business.isNotEmpty)
                          Text(business,
                              style:
                              const TextStyle(color: Colors.white70)),

                        const SizedBox(height: 6),

                        Consumer<LocationProvider>(
                          builder: (context, loc, _) {
                            if (!loc.hasLocation) return const SizedBox.shrink();
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on_rounded,
                                    color: Colors.white60, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  loc.displayLocation,
                                  style: const TextStyle(
                                      color: Colors.white60, fontSize: 12),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            /// 🔧 OPTIONS
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [

                    _tile(Icons.edit, "Edit Profile", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const ProviderEditProfileScreen(),
                        ),
                      );
                    }),

                    _tile(Icons.work, "My Services", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Scaffold(
                            appBar:
                            AppBar(title: const Text('My Services')),
                            body: const ProviderServicesScreen(),
                          ),
                        ),
                      );
                    }),

                    _tile(Icons.receipt, "Bookings", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Scaffold(
                            appBar:
                            AppBar(title: const Text('Bookings')),
                            body: const ProviderBookingsScreen(),
                          ),
                        ),
                      );
                    }),

                    _tile(Icons.star_rounded, "My Reviews", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                            const ProviderReviewsScreen()),
                      );
                    }),

                    _tile(Icons.bar_chart, "Earnings", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EarningsDashboardScreen(),
                        ),
                      );
                    }),

                    _tile(Icons.shield_outlined, "Privacy Policy", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyScreen(),
                        ),
                      );
                    }),

                    _tile(Icons.description_outlined, "Terms of Service", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TermsOfServiceScreen(),
                        ),
                      );
                    }),

                    Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: SwitchListTile(
                        title: const Text("Dark Mode"),
                        value: themeProvider.isDark,
                        onChanged: themeProvider.toggleTheme,
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                        _isLoggingOut ? null : _handleLogout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding:
                          const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: _isLoggingOut
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(Icons.logout,
                            color: Colors.white),
                        label: Text(
                          _isLoggingOut
                              ? "Logging out..."
                              : "Logout",
                          style:
                          const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    _tile(Icons.share_rounded, "Share App", () {
                      Share.share(
                        'Check out Servix — find trusted services near you! Download now: https://play.google.com/store/apps/details?id=com.servix.app',
                      );
                    }),

                    _tile(Icons.delete_forever_rounded, "Delete Account", () {
                      _showDeleteDialog();
                    }),

                    const SizedBox(height: 16),

                    Center(
                      child: Text(
                        "Servix v1.0.0",
                        style: theme.textTheme.bodySmall,
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_rounded, size: 40, color: Colors.redAccent),
              const SizedBox(height: 10),
              const Text("Delete Account", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text("This will permanently delete your account and all data.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade400)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel"))),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        if (!mounted) return;
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                        try {
                          await AuthService().deleteAccount();
                          if (!mounted) return;
                          Navigator.of(context).pop(); // dismiss loading
                          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                        } catch (e) {
                          if (!mounted) return;
                          Navigator.of(context).pop(); // dismiss loading
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(e.toString().contains('requires-recent-login')
                                ? 'Please logout and login again before deleting.'
                                : 'Failed to delete account.'),
                          ));
                        }
                      },
                      child: const Text("Delete", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(IconData icon, String title, VoidCallback onTap) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 5)
          ],
        ),
        child: ListTile(
          leading: Icon(icon, color: Colors.deepPurple),
          title: Text(title),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onTap,
        ),
      ),
    );
  }
}
