/// ============================================================================
/// DETAIL PAGE STATE - COMPREHENSIVE POKÉMON INFORMATION DISPLAY
/// ============================================================================
///
/// This StatefulWidget displays detailed information about a single Pokémon,
/// including stats, abilities, moves, evolution chain, TCG cards, and more.
///
/// KEY FEATURES:
/// - **Favorites Integration**: Heart button to add/remove from favorites ❤️
/// - **Real-Time Updates**: StreamBuilder syncs favorite status across app
/// - **Navigation**: Previous/Next buttons to browse Pokémon
/// - **Search**: Search bar to jump to specific Pokémon by name
/// - **Comprehensive Data**: Stats, abilities, moves, evolutions, physical stats
/// - **TCG Cards**: View trading cards for this Pokémon
/// - **Theme Support**: Adapts to light/dark mode
///
/// FAVORITES FUNCTIONALITY:
/// - Heart icon positioned on top-right of Pokémon image
/// - Filled red heart = favorited, outline grey heart = not favorited
/// - Tap to toggle favorite status
/// - Shows SnackBar confirmation (green for add, orange for remove)
/// - Updates in real-time using StreamBuilder
///
/// DATA FLOW:
/// 1. Receives Pokémon ID from navigation or defaults to 1
/// 2. Fetches Pokémon data from GraphQL API
/// 3. Displays all information in scrollable cards
/// 4. User can toggle favorite, which updates Hive storage
/// 5. StreamBuilder detects change and updates UI immediately
///
/// ============================================================================

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../domain/main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '/presentation/theme_provider.dart';
import 'package:provider/provider.dart';

import 'package:pokedex/data/queries.dart';
import 'package:pokedex/data/favorites_service.dart';
import '../page_necessities/detail_page/showPokemonCards.dart' as show_pokemon_cards;
import '/domain/models/Pokemon.dart';

import '../page_necessities/detail_page/AbilitiesCard.dart' as abilities_card;
import '../page_necessities/detail_page/MovesCard.dart' as moves_card;
import '../page_necessities/detail_page/EvolutionChainCard.dart' as evolutions_card;
import '../page_necessities/detail_page/StatsCard.dart' as stats_card;
import '../page_necessities/detail_page/PhysicalStatsCard.dart' as physical_stats_card;
import '../page_necessities/detail_page/PokedexEntryCard.dart' as pokedex_entry_card;

/// ============================================================================
/// DETAIL PAGE STATE CLASS
/// ============================================================================

/// State class for PokeDetailPage
///
/// Manages the UI state and logic for displaying detailed Pokémon information.
/// Handles navigation, search, favorites, and data fetching.
class DetailPageState extends State<PokeDetailPage> {
  // ============================================================================
  // STATE VARIABLES
  // ============================================================================

  /// Current Pokémon ID being displayed
  ///
  /// Starts at the initialPokemonId passed from navigation, or defaults to 1.
  /// Changes when user navigates with previous/next buttons or searches.
  int _counter = 1;

  /// Singleton instance of FavoritesService for managing favorites
  ///
  /// Used to check if current Pokémon is favorited and to toggle favorite status.
  /// The singleton pattern ensures we're always working with the same Hive database.
  final FavoritesService _favoritesService = FavoritesService();

  /// Getter for current theme mode (light/dark)
  ///
  /// Uses Provider to access theme state without causing unnecessary rebuilds.
  /// The `listen: false` parameter is crucial - we only need the current value,
  /// not continuous updates (which would cause excessive rebuilds).
  bool get isDarkMode => Provider.of<AppThemeState>(context, listen: false).isDarkMode;

  /// Text controller for the search bar
  ///
  /// Manages the text input state for searching Pokémon by name.
  /// Allows us to read, clear, and listen to changes in the search field.
  final TextEditingController _searchController = TextEditingController();

  /// Timer for debounce functionality
  ///
  /// Prevents excessive API calls by waiting 500ms after user stops typing
  /// before triggering the search. This improves performance significantly.
  Timer? _debounce;

  /// Current search query string
  ///
  /// Stores the active search term. When empty, displays Pokémon by ID.
  /// When filled, searches for Pokémon by name.
  String _searchQuery = '';

  /// Gradient list for UI styling (currently unused, can be removed)
  final gradientList = <List<Color>>[
    [
      Color.fromRGBO(92, 100, 250, 1.0),
      Color.fromRGBO(0, 15, 188, 1.0),
    ],
    [
      Color.fromRGBO(255, 0, 194, 1.0),
      Color.fromRGBO(255, 75, 189, 1.0),
    ],
  ];

  // ============================================================================
  // LIFECYCLE METHODS
  // ============================================================================

  /// Initialize state when widget is first created
  ///
  /// WHAT IT DOES:
  /// 1. Sets initial Pokémon ID from widget parameter or defaults to 1
  /// 2. Adds listener to search controller for immediate UI updates
  ///
  /// WHY THE LISTENER:
  /// - Without it, the clear button wouldn't appear immediately when typing
  /// - With it, any change to search text triggers a rebuild
  /// - Checks `mounted` to avoid setState after widget disposal
  @override
  void initState() {
    super.initState();

    // Set initial Pokémon ID from navigation parameter or default to 1 (Bulbasaur)
    _counter = widget.initialPokemonId ?? 1;

    // Add listener to search controller for immediate UI updates
    // This ensures the clear button appears/disappears instantly
    _searchController.addListener(() {
      if (mounted) setState(() {}); // Only rebuild if widget still exists
    });
  }

  /// Cleanup when widget is removed from the widget tree
  ///
  /// CRITICAL FOR MEMORY MANAGEMENT:
  /// - Dispose of text controller to prevent memory leaks
  /// - Cancel any pending debounce timer
  /// - Always call super.dispose() last
  @override
  void dispose() {
    _searchController.dispose(); // Release text controller resources
    _debounce?.cancel(); // Cancel any pending debounce timer
    super.dispose(); // Call parent dispose method
  }

  // ============================================================================
  // SEARCH FUNCTIONALITY
  // ============================================================================

  /// Handle search input changes with debounce
  ///
  /// DEBOUNCE PATTERN:
  /// Instead of searching on every keystroke, we wait 500ms after the user
  /// stops typing. This reduces API calls from potentially dozens to just one.
  ///
  /// HOW IT WORKS:
  /// 1. User types a character
  /// 2. If timer exists, cancel it (user is still typing)
  /// 3. Start a new 500ms timer
  /// 4. If 500ms passes without new input, execute the search
  /// 5. If user types again before 500ms, restart from step 2
  ///
  /// EXAMPLE:
  /// User types "pikachu" (7 characters)
  /// Without debounce: 7 API calls
  /// With debounce: 1 API call (after user stops typing)
  void _onSearchChanged(String query) {
    // Cancel existing timer if user is still typing
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Start new 500ms timer
    _debounce = Timer(const Duration(milliseconds: 500), () {
      // After 500ms of no typing, update search query
      setState(() {
        _searchQuery = query.toLowerCase().trim();
      });
    });
  }


  // Build method returns the widget tree for the home page
  @override
  Widget build(BuildContext context) {
    // Get the GraphQL client from the provider
    final client = GraphQLProvider.of(context).value;
    // Return a Scaffold widget for the page layout
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red, // Set Pokémon red color for app bar background
        centerTitle: true, // Center the title horizontally in the app bar
        title: Text( // Set app bar title with Pokémon style
          widget.title,
          style: GoogleFonts.pressStart2p( // Apply Press Start 2P font (retro 8-bit style)
            fontSize: 20, // Set font size to 20 pixels
            color: Colors.yellow, // Set text color to yellow (iconic Pokémon color)
            fontWeight: FontWeight.bold, // Make the text bold for emphasis
            shadows: [ // Add shadow effects to the text for depth
              const Shadow(
                offset: Offset(2, 2), // Move shadow 2 pixels right and 2 pixels down
                blurRadius: 4, // Blur the shadow edges for a soft effect (4 pixels)
                color: Colors.blue, // Set shadow color to blue for contrast
              ),
            ],
          ),
        ),
        actions: [ // Adds the theme toggle switch to the app bar
          Consumer<AppThemeState>( // Listen to theme state changes
            builder: (context, themeState, _) {
              return Row(
                children: [
                  Icon( // Light mode icon
                    Icons.light_mode,
                    color: themeState.isDarkMode ? Colors.grey : Colors.yellow,
                    size: 20,
                  ),
                  Switch( // Actual Toggle Switch
                    value: themeState.isDarkMode,
                    onChanged: (_) => themeState.toggleTheme(), // uses an arrow function to toggle theme
                    activeColor: Colors.yellow,
                  ),
                  Icon(
                    Icons.dark_mode,
                    color: themeState.isDarkMode ? Colors.yellow : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // SEARCH BAR SECTION
          // This TextField allows users to search for Pokémon by name
          // Features: debounce, clear button, themed styling, rounded borders

          // POKÉMON DISPLAY AREA
          // This section shows the Pokémon information below the search bar
          Expanded(
            child: Center(
              // Use FutureBuilder to fetch and display Pokémon data
              // SMART SWITCHING: Uses search when query exists, otherwise uses ID counter
              child: FutureBuilder<Pokemon?>(
                // Conditional future: if search query is empty, fetch by ID
                // Otherwise, search by name with debounced query
                future: _searchQuery.isEmpty
                    ? fetchPokemon(_counter, client) // Fetch by ID (navigation mode)
                    : searchPokemonByNameFull(_searchQuery, client), // Search by name (search mode)
                builder: (context, snapshot) {
                  // Show loading indicator while waiting for data
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator(
                      color: Colors.red, // Set loading spinner color to red (Pokémon theme)
                    );
                  }
                  // Show message if no data is found
                  if (!snapshot.hasData) {
                    return Text(
                      'No Pokémon found.',
                      style: GoogleFonts.pressStart2p( // Use retro font for error message
                        fontSize: 14, // Set font size to 14 pixels
                        color: Colors.red, // Use red color to indicate error/warning
                      ),
                    );
                  }


                  // Get the Pokémon data from the snapshot
                  final pokemon = snapshot.data!;

                  // Display the Pokémon ID and name
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, // Center all children vertically
                      children: <Widget>[
                        const SizedBox(height: 20), // Add top spacing
                        // Container with decoration for the Pokémon image
                        Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20), // Add 20 pixels of padding inside the container on all sides
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.grey[800] : Colors.white, // Set container background to white for a clean card look
                                borderRadius: BorderRadius.circular(20), // Round the corners with 20 pixel radius for modern look
                                boxShadow: [ // Add shadow effects to the container for depth and elevation
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5), // Use semi-transparent grey (50% opacity) for shadow
                                    spreadRadius: 5, // Spread the shadow 5 pixels outward from the container
                                    blurRadius: 7, // Blur the shadow edges by 7 pixels for soft effect
                                    offset: const Offset(0, 3), // Move shadow 3 pixels down (0 horizontal, 3 vertical)
                                  ),
                                ],
                              ),
                              child: Image.network(
                                'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${pokemon.id}.png',
                                height: 150, // Set image height to 150 pixels
                                width: 150, // Set image width to 150 pixels (square image)
                              ),
                            ),
                            // ========================================================
                            // ❤️ FAVORITE BUTTON - HEART ICON OVERLAY
                            // ========================================================
                            //
                            // This is the main favorites feature UI component!
                            // Positioned absolutely on top-right of Pokémon image.
                            //
                            // REAL-TIME UPDATES:
                            // - Uses StreamBuilder to watch for changes in favorites
                            // - Automatically updates when favorites are added/removed
                            // - Works across all pages (home, detail, favorites)
                            //
                            // VISUAL STATES:
                            // - Filled red heart (❤️): Currently favorited
                            // - Outlined grey heart (🤍): Not favorited
                            //
                            // USER INTERACTION:
                            // 1. User taps heart icon
                            // 2. toggleFavorite() is called (async operation)
                            // 3. Hive database is updated
                            // 4. StreamBuilder detects change
                            // 5. UI rebuilds with new state
                            // 6. SnackBar shows confirmation message
                            //
                            // DESIGN:
                            // - White circular background (90% opacity)
                            // - Subtle shadow for depth
                            // - 28px icon size for easy tapping
                            // - Positioned 8px from top and right edges
                            //
                            Positioned(
                              top: 8,
                              right: 8,
                              child: StreamBuilder<BoxEvent>(
                                // Watch favorites stream for real-time updates
                                // When any favorite is added/removed, this rebuilds
                                stream: _favoritesService.watchFavorites(),
                                builder: (context, snapshot) {
                                  // Check if current Pokémon is favorited
                                  // This is a synchronous call - very fast (O(n) but small dataset)
                                  final isFavorite = _favoritesService.isFavorite(pokemon.id);

                                  return Container(
                                    // White circular background for visibility over any image
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      // Dynamic icon based on favorite status
                                      icon: Icon(
                                        isFavorite ? Icons.favorite : Icons.favorite_border,
                                        color: isFavorite ? Colors.red : Colors.grey[600],
                                        size: 28,
                                      ),
                                      onPressed: () async {
                                        // Toggle favorite status (add if not favorite, remove if favorite)
                                        await _favoritesService.toggleFavorite(pokemon.id);

                                        // Trigger rebuild to update UI immediately
                                        setState(() {});

                                        // Show confirmation SnackBar with appropriate message and color
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                // Check current state after toggle
                                                _favoritesService.isFavorite(pokemon.id)
                                                    ? '${pokemon.name.toUpperCase()} added to favorites!'
                                                    : '${pokemon.name.toUpperCase()} removed from favorites',
                                                style: GoogleFonts.pressStart2p(fontSize: 10),
                                              ),
                                              duration: const Duration(seconds: 2),
                                              // Green for add, orange for remove
                                              backgroundColor: _favoritesService.isFavorite(pokemon.id)
                                                  ? Colors.green
                                                  : Colors.orange,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30), // Add 30 pixels of vertical spacing between elements
                        // Pokémon ID with styled text
                        Text(
                          'ID: ${pokemon.id}',
                          style: GoogleFonts.pressStart2p( // Use retro 8-bit font style
                            fontSize: 16, // Set font size to 16 pixels
                            color: Colors.red, // Use red color to match Pokémon brand
                            fontWeight: FontWeight.bold, // Make text bold for emphasis and readability
                          ),
                        ),
                        const SizedBox(height: 10), // Add 10 pixels of vertical spacing
                        // Pokémon name with styled text
                        Text(
                          pokemon.name.toUpperCase(), // Convert name to uppercase for impact
                          style: GoogleFonts.pressStart2p( // Use retro 8-bit font style
                            fontSize: 24, // Set larger font size (24 pixels) since this is the main title
                            color: isDarkMode ? Colors.red : Colors.blue[900], // Use dark blue color (shade 900 is darkest)
                            fontWeight: FontWeight.bold, // Make text bold for strong emphasis
                            shadows: [ // Add shadow effects to text for depth and visibility
                              Shadow(
                                offset: const Offset(2, 2), // Move shadow 2 pixels right and 2 pixels down
                                blurRadius: 3, // Blur shadow edges by 3 pixels for subtle effect
                                color: isDarkMode ? Colors.white : Colors.yellow, // Use yellow shadow for Pokémon theme contrast
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10), // Add 10 pixels of vertical spacing
                        // Pokémon types with styled text
                        Text(
                          'Types: ${pokemon.typesString}',
                          style: GoogleFonts.roboto( // Use Roboto font (modern, clean sans-serif)
                            fontSize: 18, // Set font size to 18 pixels for good readability
                            color: Colors.green[700], // Use medium-dark green (shade 700) for nature/type theme
                            fontWeight: FontWeight.w600, // Use semi-bold weight (600) for moderate emphasis
                          ),
                        ),

                        // POKÉDEX ENTRY AND REGION
                        // This section displays the Pokédex entry description and region information
                        const SizedBox(height: 20),
                        pokedex_entry_card.PokedexEntryCard(
                          pokedexEntry: pokemon.pokedexEntry,
                          region: pokemon.region,
                          generation: pokemon.generation,
                          isDarkMode: isDarkMode,
                        ),

                        // BASE STATS SECTION
                        // This section displays all 6 base statistics plus the total
                        // Each stat is shown with: name, numeric value, and visual progress bar
                        // Design: White card with shadow, similar to Pokémon games style
                        const SizedBox(height: 20), // Spacing before stats section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: stats_card.StatsCard(
                            stats: pokemon.stats,
                            totalStats: pokemon.totalStats,
                            isDarkMode: isDarkMode,
                          ),
                        ),

                        // TRADING CARDS BUTTON
                        // This button opens a bottom sheet showing all trading cards for the current Pokémon
                        // Uses the TCGDex API to fetch real card images from various TCG sets
                        const SizedBox(height: 20), // Spacing before button
                        ElevatedButton.icon(
                          onPressed: () => show_pokemon_cards.showPokemonCards(pokemon.name, context, isDarkMode), // Open cards modal with Pokémon name
                          icon: const Icon(Icons.style, color: Colors.white), // Playing card icon
                          label: Text(
                            'VIEW CARDS',
                            style: GoogleFonts.pressStart2p(fontSize: 12, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red, // Pokémon red theme
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20), // Rounded pill-shaped button
                            ),
                            elevation: 4, // Add shadow for depth
                          ),
                        ),
                        const SizedBox(height: 20), // Add bottom spacing for scrolling comfort

                        // PHYSICAL STATS
                        // This section shows various physical statistics of the pokemon
                        // Design: White card with shadow, similar to Pokémon games style
                        const SizedBox(height: 20), // Spacing before stats section
                        physical_stats_card.PhysicalStatsCard(
                          height: double.parse(pokemon.formattedHeight),
                          weight: double.parse(pokemon.formattedWeight),
                          genderRate: pokemon.genderRate,
                          eggGroups: pokemon.eggGroups,
                          isDarkMode: isDarkMode,
                        ),
                        const SizedBox(height: 20),
                        if (pokemon.speciesId != null)
                          evolutions_card.EvolutionChainCard(
                            pokemonId: pokemon.id,
                            speciesId: pokemon.speciesId!,
                            isDarkMode: isDarkMode,
                          ),
                        const SizedBox(height: 20),
                        // show abilities card
                        abilities_card.AbilitiesCard(abilities: pokemon.abilities, isDarkMode: isDarkMode),
                        const SizedBox(height: 12),
                        // show moves card
                        moves_card.MovesCard(moves: pokemon.moves, isDarkMode: isDarkMode),
                        const SizedBox(height: 60),
                        const SizedBox(height: 60),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

}
