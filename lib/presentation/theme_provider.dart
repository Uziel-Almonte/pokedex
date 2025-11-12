import 'package:flutter/material.dart';

/**
 * THEME PROVIDER - STATE MANAGEMENT FOR APP THEME
 *
 * This class manages the app's theme state (light/dark mode) using the Provider pattern.
 * It extends ChangeNotifier, which is Flutter's built-in state management solution.
 *
 * WHY CHANGENOTIFIER?
 * - Simple and lightweight
 * - Built into Flutter (no extra dependencies for basic state)
 * - Perfect for global state like themes
 * - Automatically notifies all listening widgets when state changes
 *
 * HOW IT WORKS:
 * 1. AppThemeState is created once at app startup (in main())
 * 2. Provided to widget tree via ChangeNotifierProvider
 * 3. Any widget can access it via Provider.of<AppThemeState>(context)
 * 4. When toggleTheme() is called, notifyListeners() rebuilds all dependent widgets
 *
 * DATA FLOW:
 * User taps theme switch → toggleTheme() → notifyListeners() → All widgets rebuild with new theme
 */

/**
 * AppThemeState - Manages dark/light mode preference
 *
 * EXTENDS ChangeNotifier:
 * - Provides notifyListeners() method
 * - Widgets can listen for changes
 * - Automatically triggers rebuilds when state changes
 */
class AppThemeState extends ChangeNotifier {
  // PRIVATE STATE
  // isDarkMode - Boolean flag for current theme
  // false = light mode (default)
  // true = dark mode
  bool _isDarkMode = false;

  // GETTER
  // Public read-only access to theme state
  bool get isDarkMode => _isDarkMode;

  // TOGGLE METHOD
  // Switches between light and dark mode
  // notifyListeners() tells all widgets to rebuild with new theme
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}
