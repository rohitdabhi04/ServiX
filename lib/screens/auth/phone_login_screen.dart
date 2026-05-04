import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import 'role_selection_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen>
    with SingleTickerProviderStateMixin {
  final phoneController = TextEditingController();
  final otpControllers = List.generate(6, (_) => TextEditingController());
  final otpFocusNodes = List.generate(6, (_) => FocusNode());
  final AuthService _auth = AuthService();

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  bool isLoading = false;
  bool otpSent = false;
  String? errorMessage;
  String? _verificationId;
  int? _resendToken;

  // Cooldown timer
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;
  bool _canResend = true;

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
    phoneController.dispose();
    _cooldownTimer?.cancel();
    for (final c in otpControllers) {
      c.dispose();
    }
    for (final f in otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _fullPhoneNumber {
    final phone = phoneController.text.trim();
    if (phone.startsWith('+')) return phone;
    return '+91$phone'; // Default to India
  }

  void _sendOTP() async {
    final phone = phoneController.text.trim();

    if (phone.isEmpty) {
      setState(() => errorMessage = 'Please enter your phone number.');
      return;
    }

    if (phone.replaceAll(RegExp(r'[^0-9]'), '').length < 10) {
      setState(() => errorMessage = 'Please enter a valid phone number.');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    await _auth.verifyPhoneNumber(
      phoneNumber: _fullPhoneNumber,
      forceResendingToken: _resendToken,
      onCodeSent: (verificationId, resendToken) {
        if (!mounted) return;
        setState(() {
          isLoading = false;
          otpSent = true;
          _verificationId = verificationId;
          _resendToken = resendToken;
        });
        _startCooldown();
        // Focus first OTP field
        otpFocusNodes[0].requestFocus();
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          isLoading = false;
          errorMessage = error;
        });
      },
      onAutoVerified: (credential) async {
        // Auto-verification on Android
        if (!mounted) return;
        setState(() => isLoading = true);
        await _handlePhoneCredential(credential);
      },
    );
  }

  void _verifyOTP() async {
    final otp = otpControllers.map((c) => c.text).join();

    if (otp.length != 6) {
      setState(() => errorMessage = 'Please enter the complete 6-digit OTP.');
      return;
    }

    if (_verificationId == null) {
      setState(() => errorMessage = 'Session expired. Please resend OTP.');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final res = await _auth.signInWithOTP(
      verificationId: _verificationId!,
      otp: otp,
    );

    if (!mounted) return;

    if (res == null) {
      setState(() {
        isLoading = false;
        errorMessage = 'Verification failed. Please try again.';
      });
      return;
    }

    if (res['error'] != null) {
      setState(() {
        isLoading = false;
        errorMessage = res['error'];
      });
      return;
    }

    _handleSignInResult(res);
  }

  Future<void> _handlePhoneCredential(PhoneAuthCredential credential) async {
    final res = await _auth.signInWithPhoneCredential(credential);
    if (!mounted) return;

    if (res == null || res['error'] != null) {
      setState(() {
        isLoading = false;
        errorMessage = res?['error'] ?? 'Auto-verification failed.';
      });
      return;
    }

    _handleSignInResult(res);
  }

  void _handleSignInResult(Map<String, dynamic> res) {
    setState(() => isLoading = false);

    final bool isNewUser = res['isNewUser'] == true;

    if (isNewUser) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (_) => const RoleSelectionScreen(isSignupFlow: false)),
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

  void _startCooldown() {
    _canResend = false;
    _cooldownSeconds = 60;
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

  void _clearOTP() {
    for (final c in otpControllers) {
      c.clear();
    }
    otpFocusNodes[0].requestFocus();
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
              right: -60,
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
              left: -40,
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
                      onPressed: () {
                        if (otpSent) {
                          setState(() {
                            otpSent = false;
                            errorMessage = null;
                            _clearOTP();
                          });
                        } else {
                          Navigator.pop(context);
                        }
                      },
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
                          color:
                              isDark ? Colors.white : const Color(0xFF1A1B2E),
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
                        otpSent
                            ? Icons.sms_rounded
                            : Icons.phone_android_rounded,
                        color: theme.colorScheme.primary,
                        size: 30,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Title
                    Text(
                      otpSent ? "Enter OTP" : "Phone Login",
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      otpSent
                          ? "We've sent a 6-digit code to\n$_fullPhoneNumber"
                          : "Enter your phone number to receive a verification code.",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── PHONE INPUT STATE ──
                    if (!otpSent) ...[
                      // Phone number input with country code
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1C1D2E)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF252638)
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Country code
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                border: Border(
                                  right: BorderSide(
                                    color: isDark
                                        ? const Color(0xFF252638)
                                        : const Color(0xFFE5E7EB),
                                  ),
                                ),
                              ),
                              child: Text(
                                "+91",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1A1B2E),
                                ),
                              ),
                            ),
                            // Phone input
                            Expanded(
                              child: TextField(
                                controller: phoneController,
                                keyboardType: TextInputType.phone,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1A1B2E),
                                ),
                                decoration: InputDecoration(
                                  hintText: "Enter phone number",
                                  hintStyle: TextStyle(
                                    color: isDark
                                        ? const Color(0xFF9E9EB0)
                                        : const Color(0xFF6B7280),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // ── OTP INPUT STATE ──
                    if (otpSent) ...[
                      // OTP input fields
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) {
                          return SizedBox(
                            width: 48,
                            height: 56,
                            child: TextField(
                              controller: otpControllers[index],
                              focusNode: otpFocusNodes[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A1B2E),
                              ),
                              decoration: InputDecoration(
                                counterText: "",
                                filled: true,
                                fillColor: isDark
                                    ? const Color(0xFF1C1D2E)
                                    : const Color(0xFFF5F6FF),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? const Color(0xFF252638)
                                        : const Color(0xFFE5E7EB),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? const Color(0xFF252638)
                                        : const Color(0xFFE5E7EB),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onChanged: (value) {
                                if (value.isNotEmpty && index < 5) {
                                  otpFocusNodes[index + 1].requestFocus();
                                } else if (value.isEmpty && index > 0) {
                                  otpFocusNodes[index - 1].requestFocus();
                                }
                                // Auto-verify when all 6 digits entered
                                if (index == 5 && value.isNotEmpty) {
                                  final otp = otpControllers
                                      .map((c) => c.text)
                                      .join();
                                  if (otp.length == 6) {
                                    _verifyOTP();
                                  }
                                }
                              },
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 20),

                      // Resend OTP
                      Center(
                        child: _canResend
                            ? GestureDetector(
                                onTap: () {
                                  _clearOTP();
                                  _sendOTP();
                                },
                                child: Text(
                                  "Resend OTP",
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              )
                            : Text(
                                "Resend OTP in ${_cooldownSeconds}s",
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFF9E9EB0)
                                      : const Color(0xFF6B7280),
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ],

                    // Error message
                    if (errorMessage != null) ...[
                      const SizedBox(height: 16),
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

                    // Action button
                    CustomButton(
                      text: otpSent ? "Verify OTP" : "Send OTP",
                      onPressed: isLoading
                          ? null
                          : (otpSent ? _verifyOTP : _sendOTP),
                      isLoading: isLoading,
                    ),

                    const SizedBox(height: 24),

                    // Back to login
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: RichText(
                          text: TextSpan(
                            text: "Use email instead?  ",
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
}
