import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/favorites_service.dart';
import '../../data/queries.dart';
import '../../domain/models/Pokemon.dart';
import '../theme_provider.dart';
import '/domain/main.dart' as main_page;

/// ============================================================================
/// FAVORITES PAGE - DISPLAYS ALL FAVORITED POKÉMON
/// ============================================================================
///
/// This page shows a dedicated view of all Pokémon that the user has marked
/// as favorites. It provides a beautiful grid layout with real-time updates
/// whenever favorites are added or removed.
///
/// KEY FEATURES:
/// - **2-Column Grid Layout**: Displays Pokémon cards in a responsive grid
/// - **Real-Time Updates**: Uses StreamBuilder to auto-refresh when favorites change
/// - **Empty State**: Shows friendly message when no favorites exist
/// - **Quick Navigation**: Tap any card to view full Pokémon details
/// - **Quick Remove**: Tap heart icon to remove from favorites
/// - **Theme Support**: Adapts to light/dark mode automatically
///
/// ARCHITECTURE:
/// - StatefulWidget for managing local UI state
/// - Uses FavoritesService singleton for data access
/// - GraphQL client for fetching Pokémon details
/// - Provider for theme state
///
/// DATA FLOW:
/// 1. FavoritesService provides list of favorite Pokémon IDs
/// 2. StreamBuilder watches for changes in favorites
/// 3. For each ID, FutureBuilder fetches Pokémon data from GraphQL
/// 4. Cards display Pokémon info with remove button
/// 5. Tapping card navigates to detail page
/// 6. Tapping heart removes from favorites
///
/// NAVIGATION:
/// - Accessed from home page AppBar (heart icon)
/// - Can navigate to detail page for any favorite
/// - Detail page can navigate back here
///
/// ============================================================================

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  // ============================================================================
  // STATE VARIABLES
  // ============================================================================

  /// Singleton instance of FavoritesService for accessing favorites data
  ///
  /// This service manages all favorites operations (add, remove, check, list).
  /// Using the singleton pattern ensures we're always working with the same
  /// data source across the entire app.
  final FavoritesService _favoritesService = FavoritesService();

  /// Getter for current theme mode (light/dark)
  ///
  /// Uses Provider to access AppThemeState without rebuilding on changes.
  /// The `listen: false` parameter prevents unnecessary rebuilds since we
  /// only need the current value, not continuous updates.
  ///
  /// USAGE:
  /// - Used to determine card colors, text colors, backgrounds
  /// - Ensures UI adapts to current theme setting
  bool get isDarkMode => Provider.of<AppThemeState>(context, listen: false).isDarkMode;

  // ============================================================================
  // BUILD METHOD - MAIN UI CONSTRUCTION
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    // Get GraphQL client from provider for fetching Pokémon data
    // This client is configured with caching and is shared across the app
    final client = GraphQLProvider.of(context).value;

    // Get current list of favorite Pokémon IDs
    // This is called once on build - StreamBuilder handles updates
    final favoriteIds = _favoritesService.getAllFavorites();

    return Scaffold(
      // ========================================================================
      // APP BAR - NAVIGATION AND THEME CONTROLS
      // ========================================================================
      appBar: AppBar(
        backgroundColor: Colors.red, // Pokémon brand color
        centerTitle: true, // Center the "FAVORITES" title
        title: Text(
          'FAVORITES',
          style: GoogleFonts.pressStart2p( // Retro 8-bit font style
            fontSize: 18,
            color: Colors.yellow, // High contrast yellow on red
            fontWeight: FontWeight.bold,
            shadows: [
              const Shadow(
                offset: Offset(2, 2), // Shadow positioned bottom-right
                blurRadius: 4, // Soft shadow edge
                color: Colors.blue, // Blue shadow for depth
              ),
            ],
          ),
        ),
        actions: [
          // Theme toggle switch - allows switching between light/dark mode
          // Uses Consumer to rebuild only this widget when theme changes
          Consumer<AppThemeState>(
            builder: (context, themeState, _) {
              return Row(
                children: [
                  // Sun icon - indicates light mode
                  Icon(
                    Icons.light_mode,
                    color: themeState.isDarkMode ? Colors.grey : Colors.yellow,
                    size: 20,
                  ),
                  // Toggle switch
                  Switch(
                    value: themeState.isDarkMode,
                    onChanged: (_) => themeState.toggleTheme(),
                    thumbColor: WidgetStateProperty.all(Colors.white),
                    trackColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.yellow; // Yellow track when dark mode
                      }
                      return Colors.grey; // Grey track when light mode
                    }),
                  ),
                  // Moon icon - indicates dark mode
                  Icon(
                    Icons.dark_mode,
                    color: themeState.isDarkMode ? Colors.yellow : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 8), // Spacing from edge
                ],
              );
            },
          ),
        ],
      ),

      // ========================================================================
      // BODY - FAVORITES GRID OR EMPTY STATE
      // ========================================================================
      body: favoriteIds.isEmpty
          // ====================================================================
          // EMPTY STATE - SHOWN WHEN NO FAVORITES EXIST
          // ====================================================================
          // Displays a friendly message encouraging users to add favorites
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Large heart outline icon
                  Icon(
                    Icons.favorite_border,
                    size: 100,
                    color: Colors.grey[400], // Muted grey
                  ),
                  const SizedBox(height: 20),
                  // "No favorites yet!" message
                  Text(
                    'No favorites yet!',
                    style: GoogleFonts.pressStart2p(
                      fontSize: 16,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Instructional text
                  Text(
                    'Add Pokémon to your\nfavorites to see them here',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          // ====================================================================
          // FAVORITES GRID - SHOWN WHEN FAVORITES EXIST
          // ====================================================================
          // Uses StreamBuilder for real-time updates when favorites change
          : StreamBuilder<BoxEvent>(
              stream: _favoritesService.watchFavorites(),
              builder: (context, snapshot) {
                // Get fresh list of favorites
                // This ensures the grid updates immediately when favorites change
                final currentFavorites = _favoritesService.getAllFavorites();

                // 2-column grid with responsive spacing
                return GridView.builder(
                  padding: const EdgeInsets.all(16), // Padding around grid
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 cards per row
                    childAspectRatio: 0.75, // Cards are taller than wide (3:4 ratio)
                    crossAxisSpacing: 16, // Horizontal space between cards
                    mainAxisSpacing: 16, // Vertical space between cards
                  ),
                  itemCount: currentFavorites.length,
                  itemBuilder: (context, index) {
                    final pokemonId = currentFavorites[index];
                    // Build individual Pokémon card
                    return _buildPokemonCard(pokemonId, client);
                  },
                );
              },
            ),
    );
  }

  // ============================================================================
  // POKÉMON CARD BUILDER - INDIVIDUAL FAVORITE CARD
  // ============================================================================

  /// Builds a single Pokémon card for the favorites grid
  ///
  /// WHAT IT DOES:
  /// 1. Fetches Pokémon data from GraphQL API using the ID
  /// 2. Displays loading state while fetching
  /// 3. Shows error state if fetch fails
  /// 4. Renders beautiful card with image, name, types, and remove button
  ///
  /// PARAMETERS:
  /// - pokemonId: The ID of the Pokémon to display
  /// - client: GraphQL client for API queries
  ///
  /// STATES:
  /// - Loading: Shows card with spinner
  /// - Error: Shows card with error message
  /// - Success: Shows full Pokémon card with data
  ///
  /// INTERACTIONS:
  /// - Tap card → Navigate to detail page
  /// - Tap heart → Remove from favorites
  ///
  /// UI FEATURES:
  /// - Rounded corners (16px)
  /// - Shadow for depth (elevation 4)
  /// - Theme-aware colors
  /// - Official artwork image
  /// - Formatted Pokédex number (#001)
  /// - Uppercase name (Press Start 2P font)
  /// - Color-coded types
  Widget _buildPokemonCard(int pokemonId, GraphQLClient client) {
    return FutureBuilder<Map<String, dynamic>?>(
      // Fetch Pokémon data from GraphQL API
      future: fetchPokemon(pokemonId, client),
      builder: (context, snapshot) {
        // ====================================================================
        // LOADING STATE - SHOW SPINNER WHILE FETCHING DATA
        // ====================================================================
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            elevation: 4, // Shadow depth
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16), // Rounded corners
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.red),
            ),
          );
        }

        // ====================================================================
        // ERROR STATE - SHOW ERROR MESSAGE IF FETCH FAILED
        // ====================================================================
        if (!snapshot.hasData) {
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                'Error loading\nPokémon',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: Colors.red,
                ),
              ),
            ),
          );
        }

        // ====================================================================
        // SUCCESS STATE - DISPLAY POKÉMON CARD
        // ====================================================================

        // Convert GraphQL data to Pokemon object
        final pokemon = Pokemon.fromGraphQL(snapshot.data!);

        // GestureDetector wraps card to make entire card tappable
        return GestureDetector(
          onTap: () {
            // Navigate to detail page when card is tapped
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => main_page.PokeDetailPage(
                  title: 'Pokédex',
                  initialPokemonId: pokemon.id,
                ),
              ),
            );
          },
          child: Card(
            elevation: 4, // Shadow for 3D effect
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16), // Rounded corners
            ),
            // Theme-aware background color
            color: isDarkMode ? Colors.grey[850] : Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ============================================================
                // HEART ICON - REMOVE FROM FAVORITES BUTTON
                // ============================================================
                // Positioned at top-right corner of card
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(
                      Icons.favorite, // Filled heart (always favorited here)
                      color: Colors.red,
                      size: 24,
                    ),
                    onPressed: () async {
                      // Remove this Pokémon from favorites
                      await _favoritesService.removeFavorite(pokemon.id);
                      // Refresh UI to remove card from grid
                      // Note: StreamBuilder will also trigger rebuild
                      setState(() {});
                    },
                  ),
                ),

                // ============================================================
                // POKÉMON IMAGE - OFFICIAL ARTWORK
                // ============================================================
                Expanded(
                  child: Image.network(
                    // Official artwork from PokeAPI GitHub
                    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${pokemon.id}.png',
                    fit: BoxFit.contain, // Scale to fit without cropping
                    // Error handler if image fails to load
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.error,
                        size: 50,
                        color: Colors.grey,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),

                // ============================================================
                // POKÉMON ID - FORMATTED POKÉDEX NUMBER
                // ============================================================
                Text(
                  '#${pokemon.id.toString().padLeft(3, '0')}', // #001, #025, #150
                  style: GoogleFonts.pressStart2p(
                    fontSize: 10,
                    color: Colors.grey[600], // Muted grey
                  ),
                ),
                const SizedBox(height: 4),

                // ============================================================
                // POKÉMON NAME - UPPERCASE WITH RETRO FONT
                // ============================================================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    pokemon.name.toUpperCase(), // PIKACHU, CHARIZARD, etc.
                    textAlign: TextAlign.center,
                    maxLines: 2, // Allow wrapping for long names
                    overflow: TextOverflow.ellipsis, // ... if name too long
                    style: GoogleFonts.pressStart2p(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white : Colors.blue[900],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // ============================================================
                // POKÉMON TYPES - COLOR-CODED TYPE NAMES
                // ============================================================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    pokemon.typesString, // "fire, flying" or "electric"
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.roboto(
                      fontSize: 10,
                      color: Colors.green[700], // Green for nature/type theme
                    ),
                  ),
                ),
                const SizedBox(height: 8), // Bottom padding
              ],
            ),
          ),
        );
      },
    );
  }
}
