import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/social_button.dart';
import 'signup_screen.dart';
import 'role_selection_screen.dart';
import 'forgot_password_screen.dart';
import 'email_verification_screen.dart';
import 'phone_login_screen.dart';
import '../common/privacy_policy_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthService _auth = AuthService();

  bool isLoading = false;
  String? errorMessage;

  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));

    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));

    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void login() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final res = await _auth.login(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => isLoading = false);

    if (res != null) {
      // Check email verification (skip for Google and Phone users)
      final user = res['user'];
      if (user != null && !user.emailVerified) {
        final isExternalProvider = user.providerData
            .any((p) => p.providerId == 'google.com' || p.providerId == 'phone');
        if (!isExternalProvider) {
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (_) => const EmailVerificationScreen()),
            (route) => false,
          );
          return;
        }
      }

      final String role = res['role'] ?? 'user';
      if (role == 'user') {
        Navigator.pushNamedAndRemoveUntil(
            context, '/userHome', (route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(
            context, '/providerHome', (route) => false);
      }
    } else {
      setState(() => errorMessage = 'Invalid email or password.');
    }
  }

  void googleLogin() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final res = await _auth.signInWithGoogle();

    if (!mounted) return;
    setState(() => isLoading = false);

    if (res == null) {
      setState(() => errorMessage = 'Google sign-in failed. Try again.');
      return;
    }

    final bool isNewUser = res['isNewUser'] == true;
    if (isNewUser) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      );
    } else {
      final String role = res['role'] ?? 'user';
      if (role == 'user') {
        Navigator.pushNamedAndRemoveUntil(
            context, '/userHome', (route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(
            context, '/providerHome', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background glow
          if (isDark) ...[
            Positioned(
              top: -100,
              right: -80,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    theme.colorScheme.primary.withOpacity(0.15),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    theme.colorScheme.secondary.withOpacity(0.12),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
          ],

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 48),

                      // App icon
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.secondary,
                            ],
                          ),
                        ),
                        child: const Icon(Icons.bolt_rounded,
                            color: Colors.white, size: 30),
                      ),

                      const SizedBox(height: 28),

                      Text(
                        "Welcome back 👋",
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Sign in to continue to Servix",
                        style: theme.textTheme.bodyMedium,
                      ),

                      const SizedBox(height: 36),

                      // Email field
                      CustomTextField(
                        hint: "Email address",
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                      ),

                      const SizedBox(height: 14),

                      // Password field
                      CustomTextField(
                        hint: "Password",
                        controller: passwordController,
                        isPassword: true,
                        prefixIcon: Icons.lock_outline_rounded,
                      ),

                      const SizedBox(height: 10),

                      // Forgot Password link
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const ForgotPasswordScreen()),
                          ),
                          child: Text(
                            "Forgot Password?",
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),

                      // Error message
                      if (errorMessage != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color:
                                    const Color(0xFFEF4444).withOpacity(0.3)),
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

                      // Login button
                      CustomButton(
                        text: "Sign In",
                        onPressed: isLoading ? null : login,
                        isLoading: isLoading,
                      ),

                      const SizedBox(height: 20),

                      // Divider
                      Row(
                        children: [
                          Expanded(
                              child: Divider(
                                  color: isDark
                                      ? const Color(0xFF252638)
                                      : const Color(0xFFE5E7EB))),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              "or continue with",
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          Expanded(
                              child: Divider(
                                  color: isDark
                                      ? const Color(0xFF252638)
                                      : const Color(0xFFE5E7EB))),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Google button
                      SocialButton(
                        text: "Continue with Google",
                        icon: Icons.g_mobiledata_rounded,
                        onPressed: isLoading ? null : googleLogin,
                      ),

                      const SizedBox(height: 12),

                      // Phone button
                      SocialButton(
                        text: "Continue with Phone",
                        icon: Icons.phone_android_rounded,
                        onPressed: isLoading
                            ? null
                            : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const PhoneLoginScreen()),
                                ),
                      ),

                      const SizedBox(height: 32),

                      // Sign up nav
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SignupScreen()),
                          ),
                          child: RichText(
                            text: TextSpan(
                              text: "Don't have an account?  ",
                              style: theme.textTheme.bodyMedium,
                              children: [
                                TextSpan(
                                  text: "Sign up",
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

                      const SizedBox(height: 20),

                      // Terms & Privacy
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const TermsOfServiceScreen()),
                              ),
                              child: Text(
                                "Terms of Service",
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Text(
                              "  •  ",
                              style: theme.textTheme.bodySmall,
                            ),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const PrivacyPolicyScreen()),
                              ),
                              child: Text(
                                "Privacy Policy",
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
