import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final AuthService _auth = AuthService();

  bool isLoading = false;
  bool emailSent = false;
  String? errorMessage;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    emailController.dispose();
    super.dispose();
  }

  void _sendResetLink() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      setState(() => errorMessage = 'Please enter your email address.');
      return;
    }

    if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(email)) {
      setState(() => errorMessage = 'Please enter a valid email address.');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final res = await _auth.resetPassword(email);

    if (!mounted) return;

    setState(() => isLoading = false);

    if (res['success'] == true) {
      setState(() => emailSent = true);
    } else {
      setState(() => errorMessage = res['error'] ?? 'Something went wrong.');
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
          // Background glow
          if (isDark) ...[
            Positioned(
              top: -100,
              left: -60,
              child: Container(
                width: 250,
                height: 250,
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
              right: -60,
              child: Container(
                width: 200,
                height: 200,
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // Back button
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1C1D2E)
                              : const Color(0xFFF0F1FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF252638)
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                          color: isDark ? Colors.white : const Color(0xFF1A1B2E),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Icon
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withOpacity(0.15),
                            theme.colorScheme.secondary.withOpacity(0.10),
                          ],
                        ),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Icon(
                        emailSent
                            ? Icons.mark_email_read_rounded
                            : Icons.lock_reset_rounded,
                        color: theme.colorScheme.primary,
                        size: 30,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Title
                    Text(
                      emailSent ? "Check your email" : "Forgot Password?",
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      emailSent
                          ? "We've sent a password reset link to\n${emailController.text.trim()}"
                          : "No worries! Enter your registered email and we'll send you a reset link.",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── SUCCESS STATE ──
                    if (emailSent) ...[
                      // Success card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFF10B981).withOpacity(0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFF10B981).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF10B981),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Email sent successfully!",
                                    style: TextStyle(
                                      color: const Color(0xFF10B981),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Check your inbox and spam folder.",
                                    style: TextStyle(
                                      color: const Color(0xFF10B981)
                                          .withOpacity(0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Steps
                      _stepTile(
                        theme,
                        icon: Icons.email_outlined,
                        step: "1",
                        title: "Open your email",
                        subtitle: "Look for an email from Firebase",
                      ),
                      const SizedBox(height: 12),
                      _stepTile(
                        theme,
                        icon: Icons.link_rounded,
                        step: "2",
                        title: "Click the reset link",
                        subtitle: "You'll be taken to a password reset page",
                      ),
                      const SizedBox(height: 12),
                      _stepTile(
                        theme,
                        icon: Icons.lock_open_rounded,
                        step: "3",
                        title: "Set a new password",
                        subtitle: "Then login with your new password",
                      ),

                      const SizedBox(height: 32),

                      // Resend
                      CustomButton(
                        text: "Resend Email",
                        onPressed: isLoading
                            ? null
                            : () {
                                setState(() => emailSent = false);
                                _sendResetLink();
                              },
                        isLoading: isLoading,
                      ),

                      const SizedBox(height: 14),

                      // Back to login
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "← Back to Login",
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],

                    // ── INPUT STATE ──
                    if (!emailSent) ...[
                      // Email input
                      CustomTextField(
                        hint: "Enter your email",
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                      ),

                      // Error message
                      if (errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFFEF4444)
                                    .withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Color(0xFFEF4444), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  errorMessage!,
                                  style: const TextStyle(
                                      color: Color(0xFFEF4444), fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Send button
                      CustomButton(
                        text: "Send Reset Link",
                        onPressed: isLoading ? null : _sendResetLink,
                        isLoading: isLoading,
                      ),

                      const SizedBox(height: 20),

                      // Back to login
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: RichText(
                            text: TextSpan(
                              text: "Remember your password?  ",
                              style: theme.textTheme.bodyMedium,
                              children: [
                                TextSpan(
                                  text: "Sign in",
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Step tile for success state
  Widget _stepTile(
    ThemeData theme, {
    required IconData icon,
    required String step,
    required String title,
    required String subtitle,
  }) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1D2E) : const Color(0xFFF5F6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF252638) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF1A1B2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF9E9EB0)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Icon(icon,
              size: 20,
              color: isDark
                  ? const Color(0xFF9E9EB0)
                  : const Color(0xFF6B7280)),
        ],
      ),
    );
  }
}
