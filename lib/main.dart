// Import Flutter material design package
import 'package:flutter/material.dart';
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
  int _counter = 1;

  // Function to increment the counter when the button is pressed
  void _incrementCounter() {
    setState(() {
      _counter++;
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
      body: Center(
        // Use FutureBuilder to fetch and display Pokémon data
        child: FutureBuilder<Map<String, dynamic>?>(
          future: fetchPokemon(_counter, client), // Fetch Pokémon with current counter
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
