// Import Flutter material design package
import 'package:flutter/material.dart';
import 'dart:async';
// Import GraphQL Flutter package for GraphQL client and widgets
import 'package:graphql_flutter/graphql_flutter.dart';
// Import the GraphQLService singleton
import '../../domain/main.dart';
import '/presentation/app_theme.dart';
import '/data/graphql.dart';
//fonts de google
import 'package:google_fonts/google_fonts.dart';
import '/presentation/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:pie_chart/pie_chart.dart';

// Import the TCG service for Pokémon trading cards
import '../page_necessities/detail_page/tcgCards.dart';

import 'package:pokedex/data/queries.dart';
import '../page_necessities/detail_page/showPokemonCards.dart' as show_pokemon_cards;
import '/domain/models/Pokemon.dart';




Map<String, double> _buildGenderMap(int? genderRate) {
  if (genderRate == null || genderRate == -1) {
    // Genderless or unknown
    return {"Genderless": 1.0};
  } else if (genderRate == 0) {
    // All male
    return {"Male": 1.0};
  } else if (genderRate == 8) {
    // All female
    return {"Female": 1.0};
  } else {
    // Mixed gender ratio
    return {
      "Male": (8 - genderRate) / 8.0,
      "Female": genderRate / 8.0,
    };
  }
}

// State class for MyHomePage
class DetailPageState extends State<PokeDetailPage> {
  // Counter to keep track of the current Pokémon ID
  // This increments when the user presses the floating action button
  int _counter = 1;

  bool get isDarkMode => Provider.of<AppThemeState>(context).isDarkMode;

  // Text controller for search bar - manages the text input state
  // Allows us to read, clear, and listen to changes in the search field
  final TextEditingController _searchController = TextEditingController();

  // Timer for debounce functionality - prevents excessive API calls
  // Debounce waits for the user to stop typing before triggering the search
  // This improves performance by avoiding a query on every keystroke
  Timer? _debounce;

  // Current search query string - stores the active search term
  // When empty, the app shows Pokémon by ID; when filled, it searches by name
  String _searchQuery = '';

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

  // Add initState to listen to controller changes so the suffix icon updates immediately
  @override
  void initState() {
    super.initState();
    _counter = widget.initialPokemonId ?? 1;
    // When the controller text changes we call setState() so widgets that depend on
    // _searchController.text (like the clear button) rebuild immediately instead of
    // waiting for the debounce to complete.
    _searchController.addListener(() {
      // Only rebuild if mounted to avoid setState after dispose
      if (mounted) setState(() {});
    });
  }

  // Cleanup method called when this widget is removed from the widget tree
  // It's important to dispose of controllers and timers to prevent memory leaks
  @override
  void dispose() {
    _searchController.dispose(); // Release text controller resources
    _debounce?.cancel(); // Cancel any pending debounce timer
    super.dispose(); // Call parent dispose method
  }

  // Function to increment the counter when the button is pressed
  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  // Function to handle search input changes with debounce
  // DEBOUNCE EXPLANATION:
  // Instead of searching immediately on every keystroke, we wait 500ms after
  // the user stops typing. This reduces API calls from dozens to just one.
  //
  // HOW IT WORKS:
  // 1. User types a character
  // 2. Cancel any existing timer (if user is still typing)
  // 3. Start a new 500ms timer
  // 4. If 500ms passes without new input, execute the search
  // 5. If user types again, restart from step 2
  void _onSearchChanged(String query) {
    // Check if there's an active debounce timer and cancel it
    // This happens when the user types before the previous timer finishes
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Create a new timer that waits 500 milliseconds (half a second)
    // Only after this delay will the search query be updated
    _debounce = Timer(const Duration(milliseconds: 500), () {
      // Update the state with the new search query
      // toLowerCase() makes the search case-insensitive
      // trim() removes leading/trailing whitespace
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
          Padding(
            padding: const EdgeInsets.all(16.0), // Add spacing around the search bar
            child: TextField(
              controller: _searchController, // Connect the text controller
              onChanged: _onSearchChanged, // Trigger debounce on every text change
              decoration: InputDecoration(
                // Placeholder text shown when the field is empty
                hintText: 'Search Pokémon...',
                hintStyle: GoogleFonts.roboto(color: Colors.grey[600]),

                // Search icon on the left side of the input field
                prefixIcon: const Icon(Icons.search, color: Colors.red),

                // Clear button (X icon) appears only when there's text
                // Dynamically shows/hides based on text presence
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.red),
                  onPressed: () {
                    _searchController.clear(); // Clear the text field
                    setState(() {
                      _searchQuery = ''; // Reset search query to show ID-based navigation
                    });
                  },
                )
                    : null, // No icon when field is empty

                // Background styling for the search field
                filled: true, // Enable background fill
                fillColor: isDarkMode ? Colors.grey[800] : Colors.white, // White background

                // Default border (no visible border, just rounded corners)
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30), // Rounded pill shape
                  borderSide: BorderSide.none, // No border line
                ),

                // Border when the field is enabled but not focused
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.red, width: 2), // Red border
                ),

                // Border when the field is focused (user is typing)
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.blue, width: 2), // Blue border
                ),
              ),
            ),
          ),

          // POKÉMON DISPLAY AREA
          // This section shows the Pokémon information below the search bar
          Expanded(
            child: Center(
              // Use FutureBuilder to fetch and display Pokémon data
              // SMART SWITCHING: Uses search when query exists, otherwise uses ID counter
              child: FutureBuilder<Map<String, dynamic>?>(
                // Conditional future: if search query is empty, fetch by ID
                // Otherwise, search by name with debounced query
                future: _searchQuery.isEmpty
                    ? fetchPokemon(_counter, client) // Fetch by ID (navigation mode)
                    : searchSinglePokemonByName(_searchQuery, client), // Search by name (search mode)
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
                  final pokemon = Pokemon.fromGraphQL(snapshot.data!);

                  // Display the Pokémon ID and name
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, // Center all children vertically
                      children: <Widget>[
                        const SizedBox(height: 20), // Add top spacing
                        // Container with decoration for the Pokémon image
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

                        // BASE STATS SECTION
                        // This section displays all 6 base statistics plus the total
                        // Each stat is shown with: name, numeric value, and visual progress bar
                        // Design: White card with shadow, similar to Pokémon games style
                        const SizedBox(height: 20), // Spacing before stats section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0), // Add horizontal padding (16px left & right)
                          child: Container(
                            padding: const EdgeInsets.all(16.0), // Internal padding for the stats card (all sides)
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.grey[800] : Colors.white, // White background for stats card (clean, readable)
                              borderRadius: BorderRadius.circular(15), // Rounded corners (15px radius for modern look)
                              boxShadow: [ // Add shadow for depth and elevation effect
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3), // Light grey shadow (30% opacity for subtle effect)
                                  spreadRadius: 2, // Shadow spread (2px outward)
                                  blurRadius: 5, // Shadow blur (5px for soft edges)
                                  offset: const Offset(0, 2), // Shadow position (2px down, 0px horizontal)
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // STATS TITLE
                                // "BASE STATS" header in retro gaming font
                                Text(
                                  'BASE STATS',
                                  style: GoogleFonts.pressStart2p(
                                    fontSize: 14, // Medium size for section header
                                    color: Colors.red, // Pokémon red theme
                                    fontWeight: FontWeight.bold, // Bold for emphasis
                                  ),
                                ),
                                const SizedBox(height: 15), // Spacing after title

                                // HP STAT (Health Points)
                                // Red color represents health/vitality
                                _buildStatRow('HP', pokemon.stats['hp'] ?? 0, Colors.red),
                                const SizedBox(height: 8), // Spacing between stats

                                // ATTACK STAT
                                // Orange color represents physical power
                                _buildStatRow('ATK', pokemon.stats['attack'] ?? 0, Colors.orange),
                                const SizedBox(height: 8),

                                // DEFENSE STAT
                                // Yellow color represents protection/armor
                                _buildStatRow('DEF', pokemon.stats['defense'] ?? 0, Colors.yellow[700]!),
                                const SizedBox(height: 8),

                                // SPECIAL ATTACK STAT
                                // Blue color represents special/magical power
                                _buildStatRow('SpA', pokemon.stats['special-attack'] ?? 0, Colors.blue),
                                const SizedBox(height: 8),

                                // SPECIAL DEFENSE STAT
                                // Green color represents special resistance/nature
                                _buildStatRow('SpD', pokemon.stats['special-defense'] ?? 0, Colors.green),
                                const SizedBox(height: 8),

                                // SPEED STAT
                                // Pink color represents agility/quickness
                                _buildStatRow('SPE', pokemon.stats['speed'] ?? 0, Colors.pink),
                                const SizedBox(height: 12), // Extra spacing before divider

                                // DIVIDER LINE
                                // Separates individual stats from the total
                                const Divider(thickness: 2, color: Colors.grey),
                                const SizedBox(height: 8),

                                // TOTAL STATS ROW
                                // Shows the sum of all base stats (power level indicator)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between label and value
                                  children: [
                                    Text(
                                      'TOTAL',
                                      style: GoogleFonts.pressStart2p(
                                        fontSize: 12, // Slightly smaller than title
                                        color: isDarkMode ? Colors.white : Colors.black, // Black for contrast
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      pokemon.totalStats.toString(), // Display calculated total
                                      style: GoogleFonts.pressStart2p(
                                        fontSize: 14, // Larger to emphasize the total
                                        color: Colors.purple, // Purple for special emphasis
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0), // Add horizontal padding (16px left & right)
                          child: Container(
                            padding: const EdgeInsets.all(20.0), // Internal padding for the stats card (all sides)
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.grey[800] : Colors.white, // White background for stats card (clean, readable)
                              borderRadius: BorderRadius.circular(15), // Rounded corners (15px radius for modern look)
                              boxShadow: [ // Add shadow for depth and elevation effect
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3), // Light grey shadow (30% opacity for subtle effect)
                                  spreadRadius: 2, // Shadow spread (2px outward)
                                  blurRadius: 5, // Shadow blur (5px for soft edges)
                                  offset: const Offset(0, 2), // Shadow position (2px down, 0px horizontal)
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Height: ${pokemon.formattedHeight}""',
                                  style: GoogleFonts.roboto( // Use retro 8-bit font style
                                    fontSize: 16, // Set font size to 16 pixels
                                    color: isDarkMode ? Colors.white : Colors.black, // Use red color to match Pokémon brand
                                    fontWeight: FontWeight.bold, // Make text bold for emphasis and readability
                                  ),
                                ),
                                Text(
                                  'Weight: ${pokemon.formattedWeight} lbs',
                                  style: GoogleFonts.roboto( // Use retro 8-bit font style
                                    fontSize: 16, // Set font size to 16 pixels
                                    color: isDarkMode ? Colors.white : Colors.black, // Use red color to match Pokémon brand
                                    fontWeight: FontWeight.normal, // Make text bold for emphasis and readability
                                  ),
                                ),
                                const SizedBox(height: 20),
                                PieChart(
                                  dataMap: _buildGenderMap(pokemon.genderRate),
                                  chartLegendSpacing: 32,
                                  chartRadius: MediaQuery.of(context).size.width / 3.2,
                                  gradientList: gradientList,
                                  chartType: ChartType.ring,
                                  ringStrokeWidth: 32,
                                  centerText: "Gender",
                                  chartValuesOptions: ChartValuesOptions(
                                    showChartValuesInPercentage: true,
                                    decimalPlaces: 1,
                                  ),
                                  legendOptions: LegendOptions(
                                    legendTextStyle: GoogleFonts.roboto(
                                      fontSize: 14,
                                      color: isDarkMode ? Colors.white : Colors.black,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Egg Groups: ${pokemon.eggGroups}',
                                  style: GoogleFonts.roboto(
                                    fontSize: 16,
                                    color: isDarkMode ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
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

  // HELPER METHOD: Build a stat row widget
  // This reusable method creates a single row displaying a Pokémon stat
  //
  // PARAMETERS:
  // - statName: The display name of the stat (e.g., "HP", "ATK", "DEF")
  // - statValue: The numeric value of the stat (0-255 typically)
  // - color: The color for the progress bar (visual coding by stat type)
  //
  // LAYOUT: [Stat Name] [Numeric Value] [Colored Progress Bar]
  // Example: HP          45           [████████░░░░░░░░░░]
  //
  // RETURNS: A Row widget containing the stat display
  Widget _buildStatRow(String statName, int statValue, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribute space evenly
      children: [
        // STAT NAME LABEL
        // Displays the abbreviated stat name (HP, ATK, DEF, etc.)
        Expanded(
          child: Text(
            statName, // The stat label passed as parameter
            style: GoogleFonts.roboto(
              fontSize: 16, // Readable size for stat names
              color: isDarkMode ? Colors.white : Colors.black, // Black for high contrast
              fontWeight: FontWeight.w500, // Medium weight (not too bold, not too light)
            ),
          ),
        ),
        const SizedBox(width: 10), // Spacing between name and value

        // STAT VALUE NUMBER
        // Displays the numeric stat value (e.g., 45, 120, 255)
        Text(
          statValue.toString(), // Convert integer to string for display
          style: GoogleFonts.roboto(
            fontSize: 16, // Same size as name for consistency
            color: isDarkMode ? Colors.white : Colors.black, // Black for readability
            fontWeight: FontWeight.bold, // Bold to emphasize the number
          ),
        ),
        const SizedBox(width: 10), // Spacing between value and progress bar

        // VISUAL PROGRESS BAR
        // Shows the stat value as a colored bar (like in Pokémon games)
        // Higher values = longer bar, easier to compare stats visually
        Container(
          height: 8, // Thin horizontal bar (8px height)
          width: 100, // Fixed width (100px) - all bars same length for comparison
          decoration: BoxDecoration(
            color: Colors.grey[300], // Light grey background (unfilled portion)
            borderRadius: BorderRadius.circular(4), // Rounded corners (4px radius)
          ),

          // FRACTIONALLY SIZED BOX - Creates the filled portion
          // This widget fills a fraction of the parent container based on widthFactor
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft, // Align filled part to the left side

            // CALCULATE FILL PERCENTAGE
            // widthFactor: 0.0 to 1.0 (0% to 100%)
            // Formula: statValue / 255
            // Why 255? It's the maximum value for any Pokémon stat
            // Examples:
            //   - HP 45 / 255 = 0.176 (17.6% filled)
            //   - Attack 120 / 255 = 0.470 (47% filled)
            //   - Speed 255 / 255 = 1.0 (100% filled - rare!)
            widthFactor: statValue / 255, // Dynamic width based on stat value

            // COLORED FILL CONTAINER
            // This is the actual colored bar that represents the stat value
            child: Container(
              decoration: BoxDecoration(
                color: color, // Dynamic color based on stat type (passed as parameter)
                // Color meanings: Red=HP, Orange=ATK, Yellow=DEF, Blue=SpA, Green=SpD, Pink=SPE
                borderRadius: BorderRadius.circular(4), // Match parent corners
              ),
            ),
          ),
        ),
      ],
    );
  }
}