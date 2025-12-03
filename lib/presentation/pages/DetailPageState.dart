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
import '../page_necessities/detail_page/TypeMatchupsCard.dart';

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

  /// Toggle state for showing shiny sprite
  ///
  /// When true, displays the shiny (alternate color) version of the Pokémon.
  /// When false, displays the normal version.
  /// The shiny sprites are fetched from the same PokeAPI sprites repository
  /// but from the 'shiny' subfolder instead of the normal one.
  bool _isShiny = false;

  /// Available forms/variants for the current Pokemon species
  ///
  /// WHAT IT STORES:
  /// List of all available forms (e.g., Normal, Alola, Galar, Mega, etc.)
  ///
  /// DATA STRUCTURE:
  /// Each form is a Map with:
  /// - 'id' (int): Pokemon ID for this form (used to fetch full data)
  /// - 'name' (String): Internal pokemon name (e.g., "raichu-alola")
  /// - 'formName' (String): Human-readable name for display (e.g., "Alola Form")
  /// - 'isDefault' (bool): Whether this is the default/normal form
  /// - 'isMega' (bool): Whether this is a Mega evolution (for special icon)
  ///
  /// WHEN IT'S POPULATED:
  /// - Populated by fetchPokemonForms() when a Pokemon is loaded
  /// - Cleared when navigating to a different Pokemon
  /// - Empty list means: Either no forms loaded yet, OR Pokemon has only 1 form
  ///
  /// EXAMPLE FOR RAICHU:
  /// [
  ///   {'id': 26, 'name': 'raichu', 'formName': 'Normal', 'isDefault': true, 'isMega': false},
  ///   {'id': 10100, 'name': 'raichu-alola', 'formName': 'Alola Form', 'isDefault': false, 'isMega': false}
  /// ]
  List<Map<String, dynamic>> _availableForms = [];

  /// Currently selected form Pokemon ID
  ///
  /// WHAT IT TRACKS:
  /// The Pokemon ID of the currently displayed form variant
  ///
  /// VALUES:
  /// - null: Show default form (uses _counter ID)
  /// - Non-null: Show specific form (uses this ID instead of _counter)
  ///
  /// WHEN IT CHANGES:
  /// - User selects a form from the dropdown
  /// - Reset to null when navigating to a different Pokemon
  /// - Reset to null when forms are loaded for a new species
  ///
  /// HOW IT WORKS:
  /// The FutureBuilder uses: fetchPokemon(_selectedFormId ?? _counter, client)
  /// This means: "Use selected form ID if available, otherwise use counter"
  ///
  /// EXAMPLE FLOW:
  /// 1. User navigates to Raichu (id=26) → _selectedFormId = null → Shows Raichu #26
  /// 2. User selects "Alola Form" → _selectedFormId = 10100 → Shows Raichu-Alola #10100
  /// 3. User navigates to Pikachu → _selectedFormId = null → Shows Pikachu #25
  int? _selectedFormId;

  /// Track which species ID has forms loaded
  ///
  /// WHAT IT PREVENTS:
  /// Infinite loop of loading forms on every rebuild
  ///
  /// WHY IT'S NEEDED:
  /// Without this, every time the widget rebuilds (which happens often),
  /// it would trigger _loadAvailableForms() again, causing:
  /// 1. Unnecessary API calls
  /// 2. UI flashing/flickering
  /// 3. Potential infinite loops
  ///
  /// HOW IT WORKS:
  /// - Before loading forms, check if _loadedFormsForSpeciesId == currentSpeciesId
  /// - If yes: Skip loading (already loaded for this species)
  /// - If no: Load forms and set _loadedFormsForSpeciesId = currentSpeciesId
  ///
  /// WHEN IT'S RESET:
  /// - Set to null when navigating to a different Pokemon
  /// - This allows forms to be loaded for the new Pokemon
  ///
  /// EXAMPLE:
  /// 1. Navigate to Raichu (speciesId=26) → _loadedFormsForSpeciesId = null → Load forms → Set to 26
  /// 2. Widget rebuilds (theme change, etc.) → _loadedFormsForSpeciesId = 26 → Skip loading
  /// 3. Navigate to Meowth (speciesId=52) → Reset to null → Load forms → Set to 52
  int? _loadedFormsForSpeciesId;

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

  /// Load available forms for a Pokemon species
  ///
  /// WHAT IT DOES:
  /// 1. Checks if forms are already loaded for this species (prevents duplicates)
  /// 2. Fetches all available forms/variants from GraphQL API
  /// 3. Updates _availableForms list with form data
  /// 4. Resets _selectedFormId to show default form
  /// 5. Marks species as loaded to prevent re-loading
  ///
  /// WHEN IT'S CALLED:
  /// - After a Pokemon is successfully loaded in the FutureBuilder
  /// - Only called once per species (tracked by _loadedFormsForSpeciesId)
  /// - NOT called when user navigates to different Pokemon (reset happens first)
  ///
  /// PARAMETERS:
  /// @param speciesId - The species ID from pokemon.speciesId
  /// @param client - GraphQL client for making the API call
  ///
  /// FLOW DIAGRAM:
  /// ```
  /// Pokemon Loaded → Check _loadedFormsForSpeciesId
  ///                         ↓
  ///                  Already loaded? → YES → Return early (skip)
  ///                         ↓ NO
  ///                  Call fetchPokemonForms(speciesId)
  ///                         ↓
  ///                  Get list of forms from API
  ///                         ↓
  ///                  setState({
  ///                    _availableForms = forms,
  ///                    _selectedFormId = null,
  ///                    _loadedFormsForSpeciesId = speciesId
  ///                  })
  ///                         ↓
  ///                  Dropdown appears (if forms.length > 1)
  /// ```
  ///
  /// EXAMPLE RESULTS:
  /// For Raichu (speciesId=26):
  ///   _availableForms = [
  ///     {'id': 26, 'formName': 'Normal', ...},
  ///     {'id': 10100, 'formName': 'Alola Form', ...}
  ///   ]
  ///
  /// For Pikachu (speciesId=25):
  ///   _availableForms = [
  ///     {'id': 25, 'formName': 'Normal', ...}
  ///   ]
  ///   (Dropdown won't appear because length = 1)
  ///
  /// ERROR HANDLING:
  /// - If forms fail to load (network error, etc.), shows default form
  /// - Catches exceptions and sets empty list
  /// - Still marks as loaded to prevent retry loops
  Future<void> _loadAvailableForms(int speciesId, GraphQLClient client) async {
    // GUARD: Only load if we haven't already loaded for this species
    // This prevents infinite loops and unnecessary API calls
    if (_loadedFormsForSpeciesId == speciesId) {
      return; // Already loaded, skip
    }

    try {
      // Fetch all available forms from GraphQL API
      // This calls the fetchPokemonForms() function in queries.dart
      // Returns list of maps with form data (id, name, formName, isDefault, isMega)
      final forms = await fetchPokemonForms(speciesId, client);

      // Update UI with loaded forms
      // Only update if widget is still mounted (not disposed)
      if (mounted) {
        setState(() {
          _availableForms = forms;           // Store the forms list
          _selectedFormId = null;             // Reset to default form
          _loadedFormsForSpeciesId = speciesId; // Mark as loaded for this species
        });
      }
    } catch (e) {
      // ERROR HANDLING: If forms fail to load, just show default form
      // This could happen due to:
      // - Network errors
      // - GraphQL query errors
      // - Invalid species ID
      //
      // Instead of crashing, we gracefully degrade to showing just the default form
      if (mounted) {
        setState(() {
          _availableForms = [];                 // Empty list = no dropdown
          _selectedFormId = null;               // Reset to default
          _loadedFormsForSpeciesId = speciesId; // Mark as attempted (prevent retry loop)
        });
      }
    }
  }

  /// Reset forms when navigating to a different Pokemon
  ///
  /// WHAT IT DOES:
  /// Clears all form-related state to prepare for a new Pokemon
  ///
  /// WHEN TO CALL:
  /// - Before navigating to a different Pokemon
  /// - When user clicks previous/next buttons
  /// - When user searches for a different Pokemon
  ///
  /// WHAT IT RESETS:
  /// - _availableForms: Clear the forms list
  /// - _selectedFormId: Reset to null (show default form)
  /// - _loadedFormsForSpeciesId: Clear the tracking (allow new forms to load)
  /// - _isShiny: Reset shiny toggle to normal
  ///
  /// WHY IT'S NEEDED:
  /// Without resetting, navigating from Raichu (with forms) to Pikachu (no extra forms)
  /// would still show Raichu's forms in the dropdown, which would be incorrect.
  ///
  /// USAGE:
  /// Currently unused, but available for manual navigation reset
  /// Could be called in navigation buttons or search handlers
  void _resetForms() {
    if (mounted) {
      setState(() {
        _availableForms = [];           // Clear forms list
        _selectedFormId = null;         // Reset selected form
        _loadedFormsForSpeciesId = null; // Clear loaded tracker
        _isShiny = false;               // Reset shiny toggle
      });
    }
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
                // ========================================================
                // FUTURE PARAMETER - POKEMON DATA FETCHING LOGIC
                // ========================================================
                //
                // This determines which Pokemon to fetch and display.
                // It uses CONDITIONAL LOGIC to handle 3 different scenarios:
                //
                // SCENARIO 1: User is searching by name
                // - Condition: _searchQuery.isEmpty == false
                // - Action: searchPokemonByNameFull(_searchQuery, client)
                // - Example: User types "pikachu" → Fetches Pikachu by name
                //
                // SCENARIO 2: User has selected a form from dropdown
                // - Condition: _searchQuery.isEmpty == true AND _selectedFormId != null
                // - Action: fetchPokemon(_selectedFormId, client)
                // - Example: User selects "Alola Form" → _selectedFormId = 10100 → Fetches Alola Raichu
                //
                // SCENARIO 3: Normal navigation (default)
                // - Condition: _searchQuery.isEmpty == true AND _selectedFormId == null
                // - Action: fetchPokemon(_counter, client)
                // - Example: User navigates to Pokemon #26 → Fetches normal Raichu
                //
                // THE KEY LINE: fetchPokemon(_selectedFormId ?? _counter, client)
                // Explanation: The ?? operator means "use left if not null, otherwise use right"
                // - If _selectedFormId is NOT null → Use _selectedFormId (selected form)
                // - If _selectedFormId IS null → Use _counter (default form)
                //
                // FLOW EXAMPLE (Raichu):
                // 1. Navigate to Raichu → _counter=26, _selectedFormId=null → Fetches #26 (Normal Raichu)
                // 2. Forms load → Dropdown appears with "Normal" and "Alola Form"
                // 3. User selects "Alola Form" → _selectedFormId=10100 → Triggers rebuild
                // 4. FutureBuilder runs again → fetchPokemon(10100, client) → Fetches #10100 (Alola Raichu)
                // 5. Page updates with Alola Raichu data (new image, types, stats, etc.)
                //
                future: _searchQuery.isEmpty
                    ? fetchPokemon(_selectedFormId ?? _counter, client) // Fetch by ID (navigation mode or form selection)
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


                  // ========================================================
                  // POKEMON DATA RECEIVED - START PROCESSING
                  // ========================================================

                  // Get the Pokémon data from the snapshot
                  final pokemon = snapshot.data!;

                  // ========================================================
                  // AUTO-LOAD AVAILABLE FORMS
                  // ========================================================
                  //
                  // WHAT THIS DOES:
                  // Automatically fetches all available forms for this Pokemon species
                  // when new Pokemon data is loaded.
                  //
                  // WHEN THIS RUNS:
                  // - After Pokemon data is successfully fetched
                  // - Only runs ONCE per species (prevented by _loadedFormsForSpeciesId check)
                  // - Runs asynchronously (doesn't block UI rendering)
                  //
                  // CONDITIONS:
                  // 1. pokemon.speciesId != null
                  //    - Ensures we have a valid species ID to query
                  //    - Some Pokemon might not have species data
                  //
                  // 2. _loadedFormsForSpeciesId != pokemon.speciesId
                  //    - Prevents loading forms multiple times for same species
                  //    - Example: If forms already loaded for Raichu (id=26), skip
                  //
                  // FLOW EXAMPLE (Raichu):
                  // 1. User navigates to Raichu → Pokemon data loads → speciesId = 26
                  // 2. Check: _loadedFormsForSpeciesId (null) != 26? YES → Load forms
                  // 3. _loadAvailableForms(26, client) is called asynchronously
                  // 4. Forms load in background: [Normal, Alola Form]
                  // 5. When forms load, setState() triggers rebuild
                  // 6. Dropdown appears with both forms
                  // 7. _loadedFormsForSpeciesId = 26 (prevent re-loading)
                  // 8. User rebuilds widget (theme change) → Check: 26 != 26? NO → Skip
                  //
                  // WHY ASYNC?
                  // _loadAvailableForms() is async but we don't await it here.
                  // This allows the Pokemon to display immediately while forms load
                  // in the background. The dropdown appears after forms finish loading.
                  //
                  if (pokemon.speciesId != null && _loadedFormsForSpeciesId != pokemon.speciesId) {
                    _loadAvailableForms(pokemon.speciesId!, client);
                  }

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
                                // ========================================================
                                // DYNAMIC SPRITE URL - NORMAL vs SHINY
                                // ========================================================
                                //
                                // URL changes based on _isShiny state variable:
                                // - Normal: .../official-artwork/{id}.png
                                // - Shiny: .../official-artwork/shiny/{id}.png
                                //
                                // The PokeAPI sprites repository provides both versions
                                // for all Pokémon. Shiny sprites have alternate colors
                                // and are highly sought after by collectors!
                                _isShiny
                                    ? 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/shiny/${pokemon.id}.png'
                                    : 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${pokemon.id}.png',
                                height: 150, // Set image height to 150 pixels
                                width: 150, // Set image width to 150 pixels (square image)
                              ),
                            ),
                            // ========================================================
                            // SHINY TOGGLE BUTTON - SPARKLE ICON OVERLAY
                            // ========================================================
                            //
                            // Allows users to toggle between normal and shiny sprites!
                            // Positioned on top-left of Pokémon image.
                            //
                            // WHAT IS SHINY:
                            // - Shiny Pokémon are rare alternate color variants
                            // - In games, they have a 1/4096 chance of appearing
                            // - They're highly prized by collectors
                            // - Same stats, just different colors
                            //
                            // VISUAL STATES:
                            // - Active (shiny): Gold sparkles icon
                            // - Inactive (normal): Grey stars outline icon
                            //
                            // USER INTERACTION:
                            // 1. User taps sparkle icon
                            // 2. _isShiny boolean toggles
                            // 3. setState() rebuilds the widget
                            // 4. Image URL changes to shiny/normal version
                            // 5. SnackBar shows confirmation
                            //
                            // DESIGN:
                            // - White circular background (90% opacity)
                            // - Subtle shadow for depth
                            // - 28px icon size for easy tapping
                            // - Positioned 8px from top and left edges
                            //
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
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
                                  // Dynamic icon based on shiny status
                                  // sparkles = shiny active (gold color)
                                  // stars_outlined = normal (grey color)
                                  icon: Icon(
                                    _isShiny ? Icons.auto_awesome : Icons.stars_outlined,
                                    color: _isShiny ? Colors.amber[600] : Colors.grey[600],
                                    size: 28,
                                  ),
                                  onPressed: () {
                                    // Toggle shiny state
                                    setState(() {
                                      _isShiny = !_isShiny;
                                    });

                                    // Show confirmation SnackBar
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            _isShiny
                                                ? ' Shiny ${pokemon.name.toUpperCase()} appeared!'
                                                : 'Showing normal ${pokemon.name.toUpperCase()}',
                                            style: GoogleFonts.pressStart2p(fontSize: 10),
                                          ),
                                          duration: const Duration(seconds: 2),
                                          // Gold for shiny, blue for normal
                                          backgroundColor: _isShiny
                                              ? Colors.amber[700]
                                              : Colors.blue[700],
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ),
                            // ========================================================
                            //  FAVORITE BUTTON - HEART ICON OVERLAY
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
                            // - Filled red heart (): Currently favorited
                            // - Outlined grey heart (): Not favorited
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

                        // ========================================================
                        // FORMS/VARIANTS DROPDOWN SELECTOR
                        // ========================================================
                        //
                        // WHAT IT DOES:
                        // Displays a dropdown menu allowing users to switch between different
                        // forms/variants of the same Pokemon species (e.g., Alola, Galar, Mega, etc.)
                        //
                        // WHEN IT APPEARS:
                        // Only shows if _availableForms.length > 1
                        // - If Pokemon has only 1 form (default): Dropdown hidden
                        // - If Pokemon has multiple forms: Dropdown visible
                        //
                        // EXAMPLES:
                        // - Pikachu: Only 1 form → No dropdown
                        // - Raichu: 2 forms (Normal, Alola) → Dropdown shows
                        // - Meowth: 3 forms (Normal, Alola, Galar) → Dropdown shows
                        // - Charizard: 4 forms (Normal, Mega X, Mega Y, Gmax) → Dropdown shows
                        //
                        // HOW IT WORKS:
                        // 1. User sees dropdown with all available forms
                        // 2. Current form is pre-selected (highlighted)
                        // 3. User taps dropdown → List of forms appears
                        // 4. User selects a form → onChanged() is called
                        // 5. setState() updates _selectedFormId
                        // 6. FutureBuilder detects change and rebuilds
                        // 7. New Pokemon data is fetched for selected form
                        // 8. Entire page updates (image, stats, types, abilities, etc.)
                        //
                        // UI DESIGN:
                        // - White card (light mode) or dark grey card (dark mode)
                        // - Rounded corners (15px radius)
                        // - Drop shadow for elevation
                        // - Icons: ⚡ for Mega evolutions, ✨ for other forms
                        // - Full width with padding
                        //
                        if (_availableForms.length > 1) ...[
                          const SizedBox(height: 20),
                          // Container provides styling and shadow for the dropdown
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.grey[800] : Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            // Remove the default underline from the dropdown
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                // ========================================================
                                // DROPDOWN VALUE - Currently selected form
                                // ========================================================
                                //
                                // Uses: _selectedFormId ?? pokemon.id
                                // - If form selected: Show that form's ID
                                // - If no form selected (null): Show current pokemon ID (default)
                                //
                                // Example for Raichu:
                                // - Initial load: _selectedFormId=null, pokemon.id=26 → Shows Normal (26)
                                // - User selects Alola: _selectedFormId=10100 → Shows Alola Form (10100)
                                //
                                value: _selectedFormId ?? pokemon.id,

                                // Make dropdown take full width of container
                                isExpanded: true,

                                // Dropdown arrow icon (adapts to theme)
                                icon: Icon(
                                  Icons.arrow_drop_down,
                                  color: isDarkMode ? Colors.white : Colors.black,
                                ),

                                // Text style for selected item (adapts to theme)
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),

                                // Dropdown menu background color (adapts to theme)
                                dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,

                                // ========================================================
                                // DROPDOWN ITEMS - List of all available forms
                                // ========================================================
                                //
                                // Maps each form in _availableForms to a DropdownMenuItem
                                // Each item shows:
                                // - Icon (⚡ for Mega, ✨ for others)
                                // - Form name (e.g., "Normal", "Alola Form", "Mega X")
                                //
                                items: _availableForms.map<DropdownMenuItem<int>>((form) {
                                  return DropdownMenuItem<int>(
                                    // Value is the Pokemon ID for this form
                                    // When user selects this item, onChanged receives this ID
                                    value: form['id'] as int,
                                    // Each dropdown item is a Row with icon + text
                                    child: Row(
                                      children: [
                                        // ========================================================
                                        // FORM ICON - Visual indicator of form type
                                        // ========================================================
                                        //
                                        // MEGA EVOLUTIONS (isMega == true):
                                        // - Icon: ⚡ electric_bolt (power/energy symbol)
                                        // - Color: Purple (indicates special/powerful form)
                                        //
                                        // OTHER FORMS (Regional, Special, etc.):
                                        // - Icon: ✨ auto_awesome (sparkles/star symbol)
                                        // - Color: Blue (indicates variant/alternative)
                                        //
                                        Icon(
                                          form['isMega'] == true
                                              ? Icons.electric_bolt  // Mega evolutions
                                              : Icons.auto_awesome,  // Other forms
                                          size: 20,
                                          color: form['isMega'] == true
                                              ? Colors.purple  // Mega = purple
                                              : Colors.blue,   // Other = blue
                                        ),
                                        const SizedBox(width: 10),
                                        // ========================================================
                                        // FORM NAME - Human-readable form name
                                        // ========================================================
                                        //
                                        // Displays the form name extracted by fetchPokemonForms()
                                        // Examples: "Normal", "Alola Form", "Mega X", "Galar Form"
                                        //
                                        // Expanded widget ensures text takes available space
                                        // TextOverflow.ellipsis adds "..." if name is too long
                                        //
                                        Expanded(
                                          child: Text(
                                            form['formName'] as String,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                // ========================================================
                                // ON CHANGED - Form selection handler
                                // ========================================================
                                //
                                // WHEN THIS FIRES:
                                // User taps the dropdown and selects a different form
                                //
                                // PARAMETERS:
                                // @param newFormId - The Pokemon ID of the selected form
                                //                    (comes from DropdownMenuItem.value)
                                //
                                // WHAT IT DOES:
                                // 1. Validates the selection (not null, different from current)
                                // 2. Updates _selectedFormId to the new form's Pokemon ID
                                // 3. Resets _isShiny to false (prevents showing wrong shiny sprite)
                                // 4. Triggers rebuild via setState()
                                //
                                // REBUILD CHAIN:
                                // setState() → build() → FutureBuilder.future updates
                                // → fetchPokemon(_selectedFormId, client) called
                                // → New Pokemon data loaded for selected form
                                // → Entire page updates with new data
                                //
                                // EXAMPLE FLOW (Raichu):
                                // 1. User has Normal Raichu displayed (id=26)
                                // 2. User opens dropdown, sees: Normal, Alola Form
                                // 3. User taps "Alola Form"
                                // 4. onChanged fires with newFormId = 10100
                                // 5. Check: 10100 != null? YES, 10100 != 26? YES
                                // 6. setState: _selectedFormId = 10100, _isShiny = false
                                // 7. Widget rebuilds
                                // 8. FutureBuilder future = fetchPokemon(10100, client)
                                // 9. Alola Raichu data loads (Electric/Psychic type)
                                // 10. Page displays Alola Raichu image, stats, types
                                //
                                // WHY RESET SHINY?
                                // When switching forms, we want to show the normal sprite first.
                                // Otherwise, if user had shiny Normal Raichu, switching to Alola
                                // would try to show shiny Alola sprite immediately, which might
                                // not exist or load incorrectly. Better UX to reset to normal.
                                //
                                onChanged: (int? newFormId) {
                                  // Validate: form ID must be non-null and different from current
                                  if (newFormId != null && newFormId != _selectedFormId) {
                                    setState(() {
                                      _selectedFormId = newFormId;  // Update selected form
                                      _isShiny = false;              // Reset shiny toggle
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],

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

                        // TYPE MATCHUPS SECTION
                        // ========================================================
                        //  DEFENSIVE TYPE EFFECTIVENESS DISPLAY
                        // ========================================================
                        //
                        // Shows how this Pokémon's type combination affects
                        // damage taken from different attacking types.
                        //
                        // CATEGORIES DISPLAYED:
                        // - WEAKNESSES: Types that deal 2x or 4x damage (red)
                        // - RESISTANCES: Types that deal 0.5x or 0.25x damage (green)
                        // - IMMUNITIES: Types that deal 0x damage (blue)
                        //
                        // EXAMPLES:
                        // - Charizard (Fire/Flying): x4 weak to Rock, immune to Ground
                        // - Magnezone (Electric/Steel): x4 weak to Ground, many resistances
                        // - Spiritomb (Ghost/Dark): No weaknesses (before Fairy type existed)
                        //
                        // This helps players understand battle strategy and team building.
                        const SizedBox(height: 20),
                        TypeMatchupsCard(
                          types: pokemon.types,
                          isDarkMode: isDarkMode,
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
