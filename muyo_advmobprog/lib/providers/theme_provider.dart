import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDark = false;

  bool get isDark => _isDark;

  void setDarkMode(bool value) {
    // Enhancement 3: Settings uses this setter to control dark/light mode.
    _isDark = value;
    notifyListeners();
  }

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}
