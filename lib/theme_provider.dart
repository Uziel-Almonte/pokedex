import 'package:flutter/material.dart';

class AppThemeState extends ChangeNotifier { // extends ChangeNotifier to manage theme state
  var isDarkMode = false;

  void toggleTheme() {
    isDarkMode = !isDarkMode;
    notifyListeners(); // notify listeners about the change, reloads all widgets that depend on this state
  }

  void setLightTheme() {
    isDarkMode = false;
    notifyListeners();
  }

  void setDarkTheme() {
    isDarkMode = true;
    notifyListeners();
  }
}