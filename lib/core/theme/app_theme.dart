import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

class AppTheme {
  // ─── SHARED TYPOGRAPHY ──────────────────────────────────────
  static const String _fontFamily = 'SF Pro Display';

  // ─── SMOOTH PAGE TRANSITION ─────────────────────────────────
  static PageTransitionsTheme get _pageTransitions => const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      );

  static InputDecorationTheme _inputTheme(Color cardColor, Color primary, Color borderColor) =>
      InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1.8),
        ),
      );

  static BottomNavigationBarThemeData _navTheme(
          Color bg, Color selected) =>
      BottomNavigationBarThemeData(
        backgroundColor: bg,
        selectedItemColor: selected,
        unselectedItemColor: AppColors.textGrey,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
      );

  static DialogThemeData _dialogTheme(Color bgColor) => DialogThemeData(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 16,
      );

  static SnackBarThemeData _snackTheme(Color bg) => SnackBarThemeData(
        backgroundColor: bg,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      );

  // ═══════════════════════════════════════════════════════════
  //  👤 USER — DARK
  // ═══════════════════════════════════════════════════════════
  static ThemeData userDarkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    cardColor: AppColors.cardColor,
    useMaterial3: false,
    pageTransitionsTheme: _pageTransitions,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.userPrimary,
      secondary: AppColors.userSecondary,
      surface: AppColors.surface,
      background: AppColors.background,
      error: AppColors.error,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.userPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),
    inputDecorationTheme:
        _inputTheme(AppColors.cardColor, AppColors.userPrimary, AppColors.border),
    bottomNavigationBarTheme:
        _navTheme(AppColors.surface, AppColors.userPrimary),
    cardTheme: CardThemeData(
      color: AppColors.cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
    ),
    dividerColor: AppColors.border,
    dialogTheme: _dialogTheme(AppColors.cardColor),
    snackBarTheme: _snackTheme(AppColors.cardColor),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
          color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
      headlineMedium: TextStyle(
          color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
      headlineSmall: TextStyle(
          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
      titleLarge: TextStyle(
          color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(
          color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(
          color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: Colors.white, fontSize: 15),
      bodyMedium: TextStyle(color: AppColors.textGrey, fontSize: 14),
      bodySmall: TextStyle(color: AppColors.textGrey, fontSize: 12),
    ),
    iconTheme: const IconThemeData(color: AppColors.textGrey),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.userPrimary,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
    ),
  );

  // ═══════════════════════════════════════════════════════════
  //  👤 USER — LIGHT
  // ═══════════════════════════════════════════════════════════
  static ThemeData userLightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBackground,
    cardColor: AppColors.lightCard,
    useMaterial3: false,
    pageTransitionsTheme: _pageTransitions,
    colorScheme: const ColorScheme.light(
      primary: AppColors.userPrimary,
      secondary: AppColors.userSecondary,
      surface: AppColors.lightSurface,
      background: AppColors.lightBackground,
      error: AppColors.error,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.lightBackground,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: AppColors.textDark),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      titleTextStyle: TextStyle(
        color: AppColors.textDark,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.userPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),
    inputDecorationTheme:
        _inputTheme(AppColors.lightSurface, AppColors.userPrimary, AppColors.borderLight),
    bottomNavigationBarTheme:
        _navTheme(AppColors.lightSurface, AppColors.userPrimary),
    cardTheme: CardThemeData(
      color: AppColors.lightSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.borderLight, width: 1),
      ),
    ),
    dividerColor: AppColors.borderLight,
    dialogTheme: _dialogTheme(AppColors.lightSurface),
    snackBarTheme: _snackTheme(AppColors.textDark),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
          color: AppColors.textDark, fontSize: 28, fontWeight: FontWeight.w800),
      headlineMedium: TextStyle(
          color: AppColors.textDark, fontSize: 24, fontWeight: FontWeight.w700),
      headlineSmall: TextStyle(
          color: AppColors.textDark, fontSize: 20, fontWeight: FontWeight.w700),
      titleLarge: TextStyle(
          color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(
          color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(
          color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: AppColors.textDark, fontSize: 15),
      bodyMedium: TextStyle(color: AppColors.textLight, fontSize: 14),
      bodySmall: TextStyle(color: AppColors.textLight, fontSize: 12),
    ),
    iconTheme: const IconThemeData(color: AppColors.textLight),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.userPrimary,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.textDark,
        borderRadius: BorderRadius.circular(10),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
    ),
  );

  // ═══════════════════════════════════════════════════════════
  //  🛠 PROVIDER — DARK
  // ═══════════════════════════════════════════════════════════
  static ThemeData providerDarkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    cardColor: AppColors.cardColor,
    useMaterial3: false,
    pageTransitionsTheme: _pageTransitions,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.providerPrimary,
      secondary: AppColors.providerSecondary,
      surface: AppColors.surface,
      background: AppColors.background,
      error: AppColors.error,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.providerPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme:
        _inputTheme(AppColors.cardColor, AppColors.providerPrimary, AppColors.border),
    bottomNavigationBarTheme:
        _navTheme(AppColors.surface, AppColors.providerPrimary),
    cardTheme: CardThemeData(
      color: AppColors.cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
    ),
    dividerColor: AppColors.border,
    dialogTheme: _dialogTheme(AppColors.cardColor),
    snackBarTheme: _snackTheme(AppColors.cardColor),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
          color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
      headlineMedium: TextStyle(
          color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
      headlineSmall: TextStyle(
          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
      titleLarge: TextStyle(
          color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(
          color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(
          color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: Colors.white, fontSize: 15),
      bodyMedium: TextStyle(color: AppColors.textGrey, fontSize: 14),
      bodySmall: TextStyle(color: AppColors.textGrey, fontSize: 12),
    ),
    iconTheme: const IconThemeData(color: AppColors.textGrey),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.providerPrimary,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
    ),
  );

  // ═══════════════════════════════════════════════════════════
  //  🛠 PROVIDER — LIGHT
  // ═══════════════════════════════════════════════════════════
  static ThemeData providerLightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBackground,
    cardColor: AppColors.lightCard,
    useMaterial3: false,
    pageTransitionsTheme: _pageTransitions,
    colorScheme: const ColorScheme.light(
      primary: AppColors.providerPrimary,
      secondary: AppColors.providerSecondary,
      error: AppColors.error,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.lightBackground,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: AppColors.textDark),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      titleTextStyle: TextStyle(
        color: AppColors.textDark,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.providerPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    inputDecorationTheme:
        _inputTheme(AppColors.lightSurface, AppColors.providerPrimary, AppColors.borderLight),
    bottomNavigationBarTheme:
        _navTheme(AppColors.lightSurface, AppColors.providerPrimary),
    dialogTheme: _dialogTheme(AppColors.lightSurface),
    snackBarTheme: _snackTheme(AppColors.textDark),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.textDark, fontSize: 15),
      bodyMedium: TextStyle(color: AppColors.textLight, fontSize: 14),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.providerPrimary,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.textDark,
        borderRadius: BorderRadius.circular(10),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
    ),
  );
}
