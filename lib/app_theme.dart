import 'package:flutter/material.dart';

class AppTheme{ // simple class to hold theme data, reusable/expandable for other classes

  static final lightTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.red), // Pokémon theme color
    // Set scaffold background to light blue (Pokémon theme)
    scaffoldBackgroundColor: Colors.blue[50],
  );
  static final darkTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
    // Set scaffold background to dark grey (Pokémon theme)
    scaffoldBackgroundColor: Colors.grey[900],
  );
}