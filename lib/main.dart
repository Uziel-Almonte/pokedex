// Import Flutter material design package
import 'package:flutter/material.dart';
import 'dart:async';
// Import GraphQL Flutter package for GraphQL client and widgets
import 'package:graphql_flutter/graphql_flutter.dart';
// Import the GraphQLService singleton
import 'graphql.dart';
//fonts de google
import 'package:google_fonts/google_fonts.dart';

// Main entry point for the app
void main() async {
  // Ensure Flutter widget binding is initialized before running async code
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize the GraphQLService singleton
  await GraphQLService().init();
  // Run the Flutter app, providing the GraphQL client to the widget tree
  runApp(
    GraphQLProvider(
      client: ValueNotifier(GraphQLService().client), // Use the singleton client
      child: const MyApp(), // Set MyApp as the root widget
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
    // Return a MaterialApp widget
    return MaterialApp(
      title: 'Pokedex', // Set the app title
      theme: ThemeData(
        // Set the color scheme for the app with Pokémon red theme
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        // Set scaffold background to light blue (Pokémon theme)
        scaffoldBackgroundColor: Colors.blue[50],
      ),
      home: const MyHomePage(title: 'Pokedex'), // Set the home page
    );
  }
}

// Home page widget, which is stateful
class MyHomePage extends StatefulWidget {
  // Constructor for MyHomePage, requires a title
  const MyHomePage({super.key, required this.title});

  // Title field for the home page
  final String title;

  // Create the state for this widget
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// State class for MyHomePage
class _MyHomePageState extends State<MyHomePage> {
  // Counter to keep track of the current Pokémon ID
  // This increments when the user presses the floating action button
  int _counter = 1;

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

  // Function to fetch Pokémon data from the API by ID
  Future<Map<String, dynamic>?> fetchPokemon(int id, GraphQLClient client) async {
    // Define the GraphQL query to get Pokémon species by ID
    final query = '''
      query GetPokemonById {
        pokemonspecies(where: {id: {_eq: $id}}) {
          id
          name
          pokemons{
            pokemontypes{
              type{
                 name
              }
           }
           pokemonsprites{
             sprites
          }
        }
      }
      }
    ''';
    // Execute the query using the GraphQL client
    final result = await client.query(QueryOptions(document: gql(query)));
    // Extract the species data from the result
    final species = result.data?['pokemonspecies'];
    // Return the first species if available, otherwise null
    return (species != null && species.isNotEmpty) ? species[0] : null;
  }

  // Function to search Pokémon by name using GraphQL
  // Uses case-insensitive matching with ILIKE operator
  // Returns the first matching Pokémon found (limit: 1)
  Future<Map<String, dynamic>?> searchPokemonByName(String name, GraphQLClient client) async {
    // GraphQL query with WHERE clause for name matching
    // _ilike: case-insensitive pattern matching (PostgreSQL operator)
    // %$name%: matches any string containing the search term
    // Example: searching "pika" will match "pikachu"
    final query = '''
      query SearchPokemonByName {
        pokemonspecies(where: {name: {_ilike: "%$name%"}}, limit: 1) {
          id
          name
          pokemons{
            pokemontypes{
              type{
                 name
              }
           }
           pokemonsprites{
             sprites
          }
        }
      }
      }
    ''';
    // Execute the query using the GraphQL client
    final result = await client.query(QueryOptions(document: gql(query)));
    // Extract the species data from the result
    final species = result.data?['pokemonspecies'];
    // Return the first species if available, otherwise null
    return (species != null && species.isNotEmpty) ? species[0] : null;
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
        title: Text(
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
        ), // Set app bar title with Pokémon style
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
                fillColor: Colors.white, // White background

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
                    : searchPokemonByName(_searchQuery, client), // Search by name (search mode)
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
                        fontSize: 14, // Set font size to 14 pixels for readability
                        color: Colors.red, // Use red color to indicate error/warning
                      ),
                    );
                  }


                  // Get the Pokémon data from the snapshot
                  final pokemon = snapshot.data!;

                  // Extract types from the nested structure
                  final pokemons = (pokemon['pokemons'] as List<dynamic>?) ?? [];

                  final types = pokemons.isNotEmpty
                      ? (pokemons[0]['pokemontypes'] as List<dynamic>?)
                      ?.map((t) => t['type']?['name'] as String?).whereType<String>().join(', ') ?? 'Unknown'
                      : 'Unknown';
                  // Display the Pokémon ID and name
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center, // Center all children vertically
                    children: <Widget>[
                      // Container with decoration for the Pokémon image
                      Container(
                        padding: const EdgeInsets.all(20), // Add 20 pixels of padding inside the container on all sides
                        decoration: BoxDecoration(
                          color: Colors.white, // Set container background to white for a clean card look
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
                          'https://picsum.photos/250?image=9',
                          height: 150, // Set image height to 150 pixels
                          width: 150, // Set image width to 150 pixels (square image)
                        ),
                      ),
                      const SizedBox(height: 30), // Add 30 pixels of vertical spacing between elements
                      // Pokémon ID with styled text
                      Text(
                        'ID: ${pokemon['id']}',
                        style: GoogleFonts.pressStart2p( // Use retro 8-bit font style
                          fontSize: 16, // Set font size to 16 pixels
                          color: Colors.red, // Use red color to match Pokémon brand
                          fontWeight: FontWeight.bold, // Make text bold for emphasis and readability
                        ),
                      ),
                      const SizedBox(height: 10), // Add 10 pixels of vertical spacing
                      // Pokémon name with styled text
                      Text(
                        pokemon['name'].toString().toUpperCase(), // Convert name to uppercase for impact
                        style: GoogleFonts.pressStart2p( // Use retro 8-bit font style
                          fontSize: 24, // Set larger font size (24 pixels) since this is the main title
                          color: Colors.blue[900], // Use dark blue color (shade 900 is darkest)
                          fontWeight: FontWeight.bold, // Make text bold for strong emphasis
                          shadows: [ // Add shadow effects to text for depth and visibility
                            const Shadow(
                              offset: Offset(2, 2), // Move shadow 2 pixels right and 2 pixels down
                              blurRadius: 3, // Blur shadow edges by 3 pixels for subtle effect
                              color: Colors.yellow, // Use yellow shadow for Pokémon theme contrast
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10), // Add 10 pixels of vertical spacing
                      // Pokémon types with styled text
                      Text(
                        'Types: $types',
                        style: GoogleFonts.roboto( // Use Roboto font (modern, clean sans-serif)
                          fontSize: 18, // Set font size to 18 pixels for good readability
                          color: Colors.green[700], // Use medium-dark green (shade 700) for nature/type theme
                          fontWeight: FontWeight.w600, // Use semi-bold weight (600) for moderate emphasis
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
      // Floating action button to increment the counter
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter, // Call increment function on press
        backgroundColor: Colors.red, // Set button background to Pokémon red color
        tooltip: 'Next Pokémon', // Tooltip text shown when user long-presses button
        child: const Icon(
          Icons.arrow_forward, // Use forward arrow icon to indicate "next" action
          color: Colors.white, // Set icon color to white for contrast against red background
        ),
      ),
    );
  }
}
