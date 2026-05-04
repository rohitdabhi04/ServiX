import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/social_button.dart';
import 'login_screen.dart';
import 'role_selection_screen.dart';
import 'email_verification_screen.dart';
import 'phone_login_screen.dart';
import '../common/privacy_policy_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
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

  void signup() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => errorMessage = 'Please fill in all fields.');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final result = await _auth.signUpWithoutRole(email, password);

    if (!mounted) return;
    setState(() => isLoading = false);

    final error = result['error'];

    if (error != null) {
      if (error == 'email-already-in-use') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("This email is already registered. Please login."),
            backgroundColor: Color(0xFFF59E0B),
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } else {
        setState(() => errorMessage = error.toString());
      }
    } else {
      // Send verification email
      try {
        await result['user']?.sendEmailVerification();
      } catch (_) {}

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const EmailVerificationScreen(),
        ),
        (route) => false,
      );
    }
  }

  void googleSignup() async {
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
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (_) =>
                const RoleSelectionScreen(isSignupFlow: false)),
        (route) => false,
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          if (isDark) ...[
            Positioned(
              top: -100,
              left: -80,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    theme.colorScheme.secondary.withOpacity(0.15),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    theme.colorScheme.primary.withOpacity(0.12),
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

                      // Back button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1C1D2E)
                                : Colors.white,
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

                      const SizedBox(height: 28),

                      Text(
                        "Create account ✨",
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Join Servix and get started",
                        style: theme.textTheme.bodyMedium,
                      ),

                      const SizedBox(height: 36),

                      CustomTextField(
                        hint: "Email address",
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                      ),

                      const SizedBox(height: 14),

                      CustomTextField(
                        hint: "Password",
                        controller: passwordController,
                        isPassword: true,
                        prefixIcon: Icons.lock_outline_rounded,
                      ),

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

                      CustomButton(
                        text: "Create Account",
                        onPressed: isLoading ? null : signup,
                        isLoading: isLoading,
                      ),

                      const SizedBox(height: 20),

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
                              "or sign up with",
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

                      SocialButton(
                        text: "Continue with Google",
                        icon: Icons.g_mobiledata_rounded,
                        onPressed: isLoading ? null : googleSignup,
                      ),

                      const SizedBox(height: 12),

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

                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                            (route) => false,
                          ),
                          child: RichText(
                            text: TextSpan(
                              text: "Already have an account?  ",
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

                      const SizedBox(height: 20),

                      // Terms & Privacy
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            children: [
                              Text(
                                "By signing up, you agree to our ",
                                style: theme.textTheme.bodySmall,
                              ),
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
                                " and ",
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
