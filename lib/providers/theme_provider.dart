import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  String _role = "user";
  bool isDark = true;

  ThemeData _theme = AppTheme.userDarkTheme;

  ThemeData get theme => _theme;

  /// 🔥 SET ROLE
  void setRole(String role) {
    _role = role;
    _applyTheme();
  }

  /// 🌙 TOGGLE DARK/LIGHT
  void toggleTheme(bool value) {
    isDark = value;
    _applyTheme();
  }

  /// 🎨 APPLY THEME (FINAL LOGIC)
  void _applyTheme() {
    if (_role == "provider") {
      _theme = isDark
          ? AppTheme.providerDarkTheme
          : AppTheme.providerLightTheme;
    } else {
      _theme = isDark
          ? AppTheme.userDarkTheme
          : AppTheme.userLightTheme;
    }

    notifyListeners();
  }
}