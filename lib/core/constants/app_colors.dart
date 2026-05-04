import 'package:flutter/material.dart';

class AppColors {
  // ─── USER THEME ───────────────────────────────────────────
  static const Color userPrimary = Color(0xFF6C63FF);
  static const Color userSecondary = Color(0xFF48CFE0);

  // ─── PROVIDER THEME ───────────────────────────────────────
  static const Color providerPrimary = Color(0xFF7C3AED);
  static const Color providerSecondary = Color(0xFF06B6D4);

  // ─── DARK BACKGROUND ──────────────────────────────────────
  static const Color background = Color(0xFF0A0B14);
  static const Color surface = Color(0xFF13141F);
  static const Color cardColor = Color(0xFF1C1D2E);
  static const Color cardDark = Color(0xFF151622);

  // ─── LIGHT BACKGROUND ─────────────────────────────────────
  static const Color lightBackground = Color(0xFFF5F6FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF0F1FF);

  // ─── TEXT ─────────────────────────────────────────────────
  static const Color textWhite = Colors.white;
  static const Color textGrey = Color(0xFF9E9EB0);
  static const Color textDark = Color(0xFF1A1B2E);
  static const Color textLight = Color(0xFF6B7280);

  // ─── BORDER / DIVIDER ─────────────────────────────────────
  static const Color border = Color(0xFF252638);
  static const Color borderLight = Color(0xFFE5E7EB);

  // ─── STATUS COLORS ────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ─── GRADIENTS ────────────────────────────────────────────
  static const LinearGradient userGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C63FF), Color(0xFF48CFE0)],
  );

  static const LinearGradient providerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
  );

  static const LinearGradient darkHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C63FF), Color(0xFF48CFE0)],
  );

  // ─── GLASSMORPHISM ────────────────────────────────────────
  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
}
