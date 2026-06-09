import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _isBigText = false;
  
  bool get isDarkMode => _isDarkMode;
  bool get isBigText => _isBigText;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('darkMode') ?? false;
    _isBigText = prefs.getBool('bigText') ?? false;
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _isDarkMode);
    notifyListeners();
  }

  Future<void> toggleBigText() async {
    _isBigText = !_isBigText;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bigText', _isBigText);
    notifyListeners();
  }

  double get textScaleFactor {
    return _isBigText ? 1.5 : 1.0;
  }
}
