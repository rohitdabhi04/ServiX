import 'package:flutter/material.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/role_selection_screen.dart';
import '../screens/auth/email_verification_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/phone_login_screen.dart';
import '../screens/common/privacy_policy_screen.dart';
import '../screens/user/user_main_screen.dart';
import '../screens/provider/provider_main_screen.dart';

class AppRoutes {
  // ── Route Names ────────────────────────────────────────────
  static const String login            = '/login';
  static const String signup           = '/signup';
  static const String roleSelection    = '/role-selection';
  static const String emailVerify      = '/email-verify';
  static const String forgotPassword   = '/forgot-password';
  static const String phoneLogin       = '/phone-login';
  static const String privacyPolicy    = '/privacy-policy';
  static const String termsOfService   = '/terms-of-service';
  static const String userHome         = '/userHome';
  static const String providerHome     = '/providerHome';

  // ── Route Generator ───────────────────────────────────────
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    Widget page;

    switch (settings.name) {
      case login:
        page = const LoginScreen();
        break;
      case signup:
        page = const SignupScreen();
        break;
      case roleSelection:
        final args = settings.arguments as Map<String, dynamic>?;
        final isSignupFlow = args?['isSignupFlow'] as bool? ?? false;
        page = RoleSelectionScreen(isSignupFlow: isSignupFlow);
        break;
      case emailVerify:
        page = const EmailVerificationScreen();
        break;
      case forgotPassword:
        page = const ForgotPasswordScreen();
        break;
      case phoneLogin:
        page = const PhoneLoginScreen();
        break;
      case privacyPolicy:
        page = const PrivacyPolicyScreen();
        break;
      case termsOfService:
        page = const TermsOfServiceScreen();
        break;
      case userHome:
        page = const UserMainScreen();
        break;
      case providerHome:
        page = const ProviderMainScreen();
        break;
      default:
        page = const LoginScreen();
    }

    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 350),
    );
  }
}
