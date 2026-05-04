import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../../widgets/custom_button.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  Timer? _checkTimer;
  Timer? _cooldownTimer;
  bool _isVerified = false;
  bool _canResend = false;
  int _cooldownSeconds = 0;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    // Send verification email immediately
    _sendVerificationEmail();

    // Auto-check every 3 seconds
    _checkTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkEmailVerified();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _checkTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        print('✅ Verification email sent to: ${user.email}');
      }
    } catch (e) {
      print('❌ Send verification email error: $e');
    }

    // Start 60s cooldown
    setState(() {
      _canResend = false;
      _cooldownSeconds = 60;
    });

    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _cooldownSeconds--;
        if (_cooldownSeconds <= 0) {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _checkEmailVerified() async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser != null && refreshedUser.emailVerified) {
        _checkTimer?.cancel();
        if (!mounted) return;

        setState(() => _isVerified = true);

        // Wait a moment for the animation, then navigate
        await Future.delayed(const Duration(milliseconds: 1200));

        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
            context, '/login', (route) => false);
      }
    } catch (e) {
      print('❌ Check verification error: $e');
    } finally {
      _isChecking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background glow
          if (isDark) ...[
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    theme.colorScheme.primary.withOpacity(0.12),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              left: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    theme.colorScheme.secondary.withOpacity(0.10),
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
                  children: [
                    const Spacer(flex: 2),

                    // Animated icon
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: _isVerified
                          ? Container(
                              key: const ValueKey('verified'),
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF10B981),
                                    const Color(0xFF059669),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF10B981)
                                        .withOpacity(0.4),
                                    blurRadius: 24,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 50,
                              ),
                            )
                          : Container(
                              key: const ValueKey('unverified'),
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary.withOpacity(0.15),
                                    theme.colorScheme.secondary
                                        .withOpacity(0.10),
                                  ],
                                ),
                                border: Border.all(
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.2),
                                ),
                              ),
                              child: Icon(
                                Icons.mark_email_unread_rounded,
                                color: theme.colorScheme.primary,
                                size: 44,
                              ),
                            ),
                    ),

                    const SizedBox(height: 28),

                    // Title
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        _isVerified
                            ? "Email Verified! ✅"
                            : "Verify your email",
                        key: ValueKey(_isVerified),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Subtitle
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        _isVerified
                            ? "Redirecting to login..."
                            : "We've sent a verification link to",
                        key: ValueKey('sub_$_isVerified'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    if (!_isVerified) ...[
                      const SizedBox(height: 6),
                      Text(
                        email,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    const SizedBox(height: 32),

                    if (!_isVerified) ...[
                      // Waiting indicator
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1C1D2E)
                              : const Color(0xFFF5F6FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF252638)
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                "Waiting for verification...\nThis page will auto-redirect once verified.",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? const Color(0xFF9E9EB0)
                                      : const Color(0xFF6B7280),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Steps
                      _stepRow(theme, "1", "Open your email inbox"),
                      const SizedBox(height: 8),
                      _stepRow(theme, "2", "Click the verification link"),
                      const SizedBox(height: 8),
                      _stepRow(theme, "3", "Come back here — it auto-detects!"),

                      const SizedBox(height: 28),

                      // Resend button
                      CustomButton(
                        text: _canResend
                            ? "Resend Verification Email"
                            : "Resend in ${_cooldownSeconds}s",
                        onPressed: _canResend ? _sendVerificationEmail : null,
                      ),

                      const SizedBox(height: 12),

                      // Check spam note
                      Text(
                        "Don't see it? Check your spam folder.",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF9E9EB0)
                              : const Color(0xFF6B7280),
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      // Back to login
                      TextButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          if (!mounted) return;
                          Navigator.pushNamedAndRemoveUntil(
                              context, '/login', (route) => false);
                        },
                        child: Text(
                          "← Back to Login",
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],

                    const Spacer(flex: 3),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepRow(ThemeData theme, String step, String text) {
    final isDark = theme.brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white : const Color(0xFF1A1B2E),
          ),
        ),
      ],
    );
  }
}
