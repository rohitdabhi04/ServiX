import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';
import '../../services/user_service.dart';
import '../user/user_main_screen.dart';
import '../provider/provider_main_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  final bool isSignupFlow;
  const RoleSelectionScreen({super.key, this.isSignupFlow = false});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with TickerProviderStateMixin {
  final userService = UserService();
  bool isLoading = false;
  String? _selectedRole;

  late AnimationController _fadeCtrl;
  late AnimationController _cardCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _card1Anim;
  late Animation<double> _card2Anim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _cardCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));

    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _card1Anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _cardCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    _card2Anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _cardCtrl,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _fadeCtrl.forward();
    _cardCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _cardCtrl.dispose();
    super.dispose();
  }

  Future<void> selectRole(String role) async {
    setState(() {
      _selectedRole = role;
      isLoading = true;
    });

    try {
      await userService.saveUserRole(role);
      final savedRole = await userService.getUserRole();

      if (mounted && savedRole != null) {
        Provider.of<ThemeProvider>(context, listen: false).setRole(savedRole);
      }

      if (!mounted) return;

      if (savedRole == "user") {
        Navigator.pushAndRemoveUntil(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const UserMainScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 400),
          ),
          (route) => false,
        );
      } else if (savedRole == "provider") {
        Navigator.pushAndRemoveUntil(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const ProviderMainScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 400),
          ),
          (route) => false,
        );
      } else {
        throw Exception("Role not saved properly");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          _selectedRole = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Something went wrong. Try again.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          if (isDark) ...[
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    const Color(0xFF6C63FF).withOpacity(0.15),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
          ],
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),

                    Center(
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF48CFE0)],
                          ),
                        ),
                        child: const Icon(Icons.person_pin_rounded,
                            color: Colors.white, size: 36),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Center(
                      child: Text(
                        "Who are you?",
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        "Choose your role to get started",
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 48),

                    // User card
                    AnimatedBuilder(
                      animation: _card1Anim,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(0, 30 * (1 - _card1Anim.value)),
                        child: Opacity(
                          opacity: _card1Anim.value,
                          child: child,
                        ),
                      ),
                      child: _RoleCard(
                        title: "I'm a User",
                        subtitle: "Book services from trusted providers",
                        icon: Icons.person_rounded,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF6C63FF), Color(0xFF48CFE0)],
                        ),
                        isSelected: _selectedRole == 'user',
                        isLoading: isLoading && _selectedRole == 'user',
                        onTap: isLoading ? null : () => selectRole('user'),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Provider card
                    AnimatedBuilder(
                      animation: _card2Anim,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(0, 30 * (1 - _card2Anim.value)),
                        child: Opacity(
                          opacity: _card2Anim.value,
                          child: child,
                        ),
                      ),
                      child: _RoleCard(
                        title: "I'm a Provider",
                        subtitle: "Offer your skills & grow your business",
                        icon: Icons.handyman_rounded,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
                        ),
                        isSelected: _selectedRole == 'provider',
                        isLoading: isLoading && _selectedRole == 'provider',
                        onTap: isLoading ? null : () => selectRole('provider'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final bool isSelected;
  final bool isLoading;
  final VoidCallback? onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.isSelected,
    required this.isLoading,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient:
                widget.isSelected ? widget.gradient : null,
            color: widget.isSelected
                ? null
                : (isDark
                    ? const Color(0xFF1C1D2E)
                    : Colors.white),
            border: Border.all(
              color: widget.isSelected
                  ? Colors.transparent
                  : (isDark
                      ? const Color(0xFF252638)
                      : const Color(0xFFE5E7EB)),
              width: 1.5,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: widget.gradient.colors.first.withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: widget.isSelected
                      ? const LinearGradient(
                          colors: [
                            Color(0x33FFFFFF),
                            Color(0x1AFFFFFF),
                          ],
                        )
                      : widget.gradient,
                ),
                child: widget.isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : Icon(widget.icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: widget.isSelected
                            ? Colors.white
                            : (isDark ? Colors.white : const Color(0xFF1A1B2E)),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        color: widget.isSelected
                            ? Colors.white.withOpacity(0.8)
                            : const Color(0xFF9E9EB0),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                widget.isSelected
                    ? Icons.check_circle_rounded
                    : Icons.arrow_forward_ios_rounded,
                color: widget.isSelected
                    ? Colors.white
                    : const Color(0xFF9E9EB0),
                size: widget.isSelected ? 22 : 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
