import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../services/favorites_service.dart';
import '../user/provider_public_profile_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  final FavoritesService _favService = FavoritesService();
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Favorites"),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: StreamBuilder<List<String>>(
          stream: _favService.getFavoriteIds(),
          builder: (context, favSnap) {
            if (favSnap.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                    color: theme.colorScheme.primary),
              );
            }

            final favIds = favSnap.data ?? [];

            if (favIds.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_border_rounded,
                        size: 64,
                        color: isDark
                            ? const Color(0xFF252638)
                            : const Color(0xFFE5E7EB)),
                    const SizedBox(height: 16),
                    Text("No favorites yet",
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      "Tap the heart icon on any provider\nto save them here.",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              itemCount: favIds.length,
              itemBuilder: (context, index) {
                return _FavProviderTile(
                  providerId: favIds[index],
                  index: index,
                  onRemove: () async {
                    await _favService.removeFavorite(favIds[index]);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Removed from favorites")),
                      );
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _FavProviderTile extends StatelessWidget {
  final String providerId;
  final int index;
  final VoidCallback onRemove;

  const _FavProviderTile({
    required this.providerId,
    required this.index,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(providerId)
          .get(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) {
          return const SizedBox.shrink();
        }

        final data = snap.data!.data() as Map<String, dynamic>;
        final name = data['name'] ?? 'Provider';
        final image = data['image'];
        final business = data['business'] ?? '';

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 400 + (index * 80)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
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
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF252638)
                    : const Color(0xFFE5E7EB),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                radius: 26,
                backgroundColor:
                    theme.colorScheme.primary.withOpacity(0.1),
                backgroundImage:
                    image != null ? CachedNetworkImageProvider(image) : null,
                child: image == null
                    ? Icon(Icons.person,
                        color: theme.colorScheme.primary)
                    : null,
              ),
              title: Text(
                name,
                style: theme.textTheme.titleSmall,
              ),
              subtitle: business.isNotEmpty
                  ? Text(business, style: theme.textTheme.bodySmall)
                  : null,
              trailing: IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.favorite_rounded,
                    color: Colors.redAccent, size: 24),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProviderPublicProfileScreen(
                        providerId: providerId),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
