// Import Flutter material design package
import 'package:flutter/material.dart';
// Import GraphQL Flutter package for GraphQL client and widgets
import 'package:graphql_flutter/graphql_flutter.dart';

// Main entry point for the app
void main() async {
  // Ensure Flutter widget binding is initialized before running async code
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Hive for persistent cache storage (required by graphql_flutter)
  await initHiveForFlutter();
  // Create an HTTP link to the PokeAPI GraphQL endpoint
  final HttpLink httpLink = HttpLink('https://graphql.pokeapi.co/v1beta2');
  // Create a ValueNotifier holding the GraphQL client instance
  final ValueNotifier<GraphQLClient> client = ValueNotifier(
    GraphQLClient(
      // Set the HTTP link for the client
      link: httpLink,
      // Set up the cache using HiveStore
      cache: GraphQLCache(store: HiveStore()),
    ),
  );
  // Run the Flutter app, providing the GraphQL client to the widget tree
  runApp(
    GraphQLProvider(
      client: client, // Pass the client to GraphQLProvider
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
        // Set the color scheme for the app
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Gotta Catch \'Em All'), // Set the home page
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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary, // Set app bar color
        title: Text(widget.title), // Set app bar title
      ),
      body: Center(
        // Use FutureBuilder to fetch and display Pokémon data
        child: FutureBuilder<Map<String, dynamic>?>(
          future: fetchPokemon(_counter, client), // Fetch Pokémon with current counter
          builder: (context, snapshot) {
            // Show loading indicator while waiting for data
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            // Show message if no data is found
            if (!snapshot.hasData) {
              return const Text('No Pokémon found.');
            }
            // Get the Pokémon data from the snapshot
            final pokemon = snapshot.data!;
            // Display the Pokémon ID and name
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text('ID: ${pokemon['id']}'), // Show Pokémon ID
                Text('Name: ${pokemon['name']}'), // Show Pokémon name
              ],
            );
          },
        ),
      ),
      // Floating action button to increment the counter
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter, // Call increment function on press
        tooltip: 'Next Pokémon', // Tooltip for the button
        child: const Icon(Icons.add), // Plus icon for the button
      ),
    );
  }
}
