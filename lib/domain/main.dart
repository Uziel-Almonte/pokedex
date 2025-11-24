/// ============================================================================
/// MAIN.DART - APPLICATION ENTRY POINT
/// ============================================================================
///
/// This file serves as the entry point for the entire Pokédex application.
/// It initializes all core services, sets up the app-wide state management,
/// and defines the root widget tree.
///
/// KEY RESPONSIBILITIES:
/// 1. **Service Initialization**: Initializes GraphQL and Hive (Favorites)
/// 2. **State Management Setup**: Provides theme and GraphQL state to entire app
/// 3. **App Configuration**: Sets up themes, routes, and initial page
///
/// INITIALIZATION ORDER (CRITICAL):
/// 1. WidgetsFlutterBinding.ensureInitialized() - Prepares Flutter engine
/// 2. GraphQLService().init() - Sets up GraphQL client with caching
/// 3. FavoritesService().init() - Opens Hive database for favorites
/// 4. runApp() - Launches the Flutter application
///
/// IMPORTANT: These must be initialized BEFORE runApp() because they need
/// to access platform-specific resources (file system for Hive, network for GraphQL).
///
/// STATE PROVIDERS:
/// - ChangeNotifierProvider<AppThemeState>: Theme switching (light/dark mode)
/// - GraphQLProvider: GraphQL client for all API queries
///
/// ============================================================================

// Import Flutter material design package
import 'package:flutter/material.dart';
// Import GraphQL Flutter package for GraphQL client and widgets
import 'package:graphql_flutter/graphql_flutter.dart';
// Import services and configuration
import '/presentation/app_theme.dart';
import '/data/graphql.dart';
import '/data/favorites_service.dart';
import '/presentation/theme_provider.dart';
import 'package:provider/provider.dart';

// Import pages
import '/domain/home.dart' as home_page;
import '../presentation/pages/DetailPageState.dart';

// ============================================================================
// MAIN FUNCTION - APPLICATION ENTRY POINT
// ============================================================================

/// Main entry point for the Pokédex Flutter application
///
/// WHAT IT DOES:
/// 1. Ensures Flutter framework is ready for async operations
/// 2. Initializes GraphQL service (API communication + caching)
/// 3. Initializes Favorites service (Hive local database)
/// 4. Wraps app in Provider widgets for state management
/// 5. Launches the application
///
/// WHY IT'S ASYNC:
/// - GraphQL initialization requires network setup
/// - Hive initialization requires file I/O operations
/// - Both operations must complete before app starts
///
/// ERROR HANDLING:
/// - If initialization fails, app won't start (intentional)
/// - Errors will be displayed in console during development
/// - In production, consider adding try-catch with error screens
void main() async {
  // Ensure Flutter widget binding is initialized before running async code
  // This is REQUIRED before any async operations in main()
  // It sets up the connection between Flutter framework and platform
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the GraphQL service singleton
  // Sets up HTTP link, cache policies, and Hive persistent cache
  // Must complete before app runs to ensure API is ready
  await GraphQLService().init();

  // Initialize the Favorites service (Hive local storage)
  // Opens the favorites box and makes it ready for read/write operations
  // Must complete before app runs to prevent "not initialized" errors
  await FavoritesService().init();

  // Run the Flutter app with state management providers
  runApp(
    // ChangeNotifierProvider wraps app to provide theme state management
    // This allows any widget to access and modify the current theme (light/dark)
    ChangeNotifierProvider<AppThemeState>(
      create: (_) => AppThemeState(), // Creates the theme state instance
      child: GraphQLProvider(
        // Provides GraphQL client to entire widget tree
        // ValueNotifier allows widgets to react to client changes
        client: ValueNotifier(GraphQLService().client),
        child: const MyApp(), // Root application widget
      ),
    ),
  );
}

// ============================================================================
// ROOT APPLICATION WIDGET
// ============================================================================

/// Root application widget that configures app-wide settings
///
/// RESPONSIBILITIES:
/// - Defines MaterialApp configuration
/// - Sets up light and dark themes
/// - Configures app title and home page
/// - Listens to theme changes and applies them
///
/// THEME MANAGEMENT:
/// - Uses AppTheme.lightTheme and AppTheme.darkTheme
/// - Switches based on AppThemeState.isDarkMode
/// - Changes apply immediately when user toggles theme switch
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Get current theme state from Provider
    // This will rebuild when theme changes (listen: true by default)
    final appThemeState = Provider.of<AppThemeState>(context);

    // MaterialApp is the root of the material design widget hierarchy
    return MaterialApp(
      title: 'Pokedex', // App title (shown in task switcher)

      // Theme configuration for light and dark modes
      theme: AppTheme.lightTheme,       // Light theme (white background)
      darkTheme: AppTheme.darkTheme,   // Dark theme (dark grey background)

      // Current theme mode based on user preference
      // When user toggles switch, this rebuilds and switches themes
      themeMode: appThemeState.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // Initial page shown when app launches
      home: const home_page.PokeHomePage(title: 'Pokedex'),
    );
  }
}

// ============================================================================
// DETAIL PAGE WIDGET DEFINITION
// ============================================================================

/// Detail page widget for displaying individual Pokémon information
///
/// This StatefulWidget shows comprehensive information about a single Pokémon
/// including stats, abilities, moves, evolution chain, and TCG cards.
///
/// PARAMETERS:
/// - title: AppBar title (usually "Pokédex")
/// - initialPokemonId: Optional starting Pokémon ID (defaults to 1)
///
/// NAVIGATION:
/// - Accessed from HomePageState (tap Pokémon card)
/// - Accessed from FavoritesPage (tap favorite card)
/// - Accessed from EvolutionChainCard (tap evolution sprite)
///
/// STATE MANAGEMENT:
/// - Uses DetailPageState for UI state and logic
/// - See DetailPageState.dart for implementation
class PokeDetailPage extends StatefulWidget {
  const PokeDetailPage({super.key, required this.title, this.initialPokemonId});

  // Title displayed in the AppBar
  final String title;

  // Optional Pokémon ID to display (defaults to 1 if not provided)
  // Allows deep linking and navigation from other pages
  final int? initialPokemonId;

  @override
  State<PokeDetailPage> createState() => DetailPageState();
}
