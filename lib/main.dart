import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'providers/theme_provider.dart';
import 'providers/location_provider.dart';
import 'providers/auth_provider.dart' as app;
import 'providers/booking_provider.dart';
import 'services/notification_service.dart';
import 'routes/app_routes.dart';

import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/auth/email_verification_screen.dart';
import 'screens/user/user_main_screen.dart';
import 'screens/provider/provider_main_screen.dart';

/// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // FCM + Local Notifications init
  await NotificationService().init();

  // Location
  final locationProvider = LocationProvider();
  await locationProvider.loadSavedLocation();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: locationProvider),
        ChangeNotifierProvider(create: (_) => app.AuthProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
      ],
      child: const ServixApp(),
    ),
  );
}

class ServixApp extends StatelessWidget {
  const ServixApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: themeProvider.theme,
      navigatorKey: navigatorKey,
      home: const SplashScreen(),
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        if (!authSnap.hasData || authSnap.data == null) {
          return const LoginScreen();
        }

        final uid = authSnap.data!.uid;

        // 🔒 Email verification check (skip for Google & Phone users)
        if (!authSnap.data!.emailVerified) {
          final isExternalProvider = authSnap.data!.providerData
              .any((p) => p.providerId == 'google.com' || p.providerId == 'phone');
          if (!isExternalProvider) {
            return const EmailVerificationScreen();
          }
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          NotificationService().saveTokenToFirestore();
          context.read<LocationProvider>().loadSavedLocation();
        });

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection("users")
              .doc(uid)
              .snapshots(),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }

            if (!userSnap.hasData || !userSnap.data!.exists) {
              return const RoleSelectionScreen(isSignupFlow: false);
            }

            final data = userSnap.data!.data() as Map<String, dynamic>?;
            final role = data?['role'] as String?;

            if (role == null || role.isEmpty) {
              return const RoleSelectionScreen(isSignupFlow: false);
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              Provider.of<ThemeProvider>(context, listen: false).setRole(role);
            });

            if (role == "user") return const UserMainScreen();
            if (role == "provider") return const ProviderMainScreen();

            return const RoleSelectionScreen(isSignupFlow: false);
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
