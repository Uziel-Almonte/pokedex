// Import Flutter material design package
import 'package:flutter/material.dart';
import 'dart:async';
// Import GraphQL Flutter package for GraphQL client and widgets
import 'package:graphql_flutter/graphql_flutter.dart';
// Import the GraphQLService singleton
import '/presentation/app_theme.dart';
import '/data/graphql.dart';
//fonts de google
import 'package:google_fonts/google_fonts.dart';
import '/presentation/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:pie_chart/pie_chart.dart';

// Import the TCG service for Pokémon trading cards
import '/presentation/tcgCards.dart';

import '/domain/home.dart' as home_page;
import '../presentation/pages/DetailPageState.dart';

import 'package:pokedex/data/queries.dart';


const darkMode = false;

// Main entry point for the app
void main() async {
  // Ensure Flutter widget binding is initialized before running async code
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize the GraphQLService singleton
  await GraphQLService().init();
  // Run the Flutter app, providing the GraphQL client to the widget tree
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppThemeState(),
      child: GraphQLProvider(
        client: ValueNotifier(GraphQLService().client),
        child: const MyApp(),
      ),
    ),
  );
}

// Main application widget
class MyApp extends StatelessWidget {
  // Constructor for MyApp
  const MyApp({super.key});

  // Build method returns the widget tree for the app
  @override
  Widget build(BuildContext context) {
    final appThemeState = Provider.of<AppThemeState>(context);
    // Return a MaterialApp widget
    return MaterialApp(

      title: 'Pokedex', // Set the app title
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: appThemeState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const home_page.PokeHomePage(title: 'Pokedex'), // Set the home page
    );
  }
}

// Home page widget, which is stateful
class PokeDetailPage extends StatefulWidget {
  // Constructor for MyHomePage, requires a title
  const PokeDetailPage({super.key, required this.title, this.initialPokemonId});

  // Title field for the home page
  final String title;
  final int? initialPokemonId;

  // Create the state for this widget
  @override
  State<PokeDetailPage> createState() => DetailPageState();
}

