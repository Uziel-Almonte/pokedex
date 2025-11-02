import 'package:flutter/material.dart';
import 'dart:async';
// Import GraphQL Flutter package for GraphQL client and widgets
import 'package:graphql_flutter/graphql_flutter.dart';
// Import the GraphQLService singleton
import 'app_theme.dart';
import 'graphql.dart';
//fonts de google
import 'package:google_fonts/google_fonts.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart';
import 'reusable_widgets/PokeSelect.dart';
import 'main.dart' as main_page;
import 'package:pokedex/queries.dart';

class PokeHomePage extends StatefulWidget {
  // Constructor for MyHomePage, requires a title
  const PokeHomePage({super.key, required this.title, this.initialPokemonId});

  // Title field for the home page
  final String title;
  final int? initialPokemonId;

  // Create the state for this widget
  @override
  State<PokeHomePage> createState() => _MyHomePageState();
}
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
      home: const PokeHomePage(title: 'Pokedex'), // Set the home page
    );
  }
}


// State class for MyHomePage
class _MyHomePageState extends State<PokeHomePage> {
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

  // ============================================================================
  // VARIABLES DE ESTADO PARA EL SISTEMA DE FILTROS
  // ============================================================================
  // Estas variables almacenan los criterios de filtrado seleccionados por el usuario.
  // Se inicializan como null, lo que significa "sin filtro aplicado".
  //
  // Cuando el usuario selecciona un filtro en el diálogo, estas variables se actualizan
  // y se usa setState() para reconstruir la interfaz con los resultados filtrados.
  String? _selectedType;        // Tipo de Pokémon seleccionado (fire, water, grass, etc.)
  int? _selectedGeneration;     // Generación seleccionada (1-9)
  String? _selectedAbility;     // Nombre de habilidad para buscar (ej: "overgrow")

  // Add initState to listen to controller changes so the suffix icon updates immediately
  @override
  void initState() {
    super.initState();
    // When the controller text changes we call setState() so widgets that depend on
    // _searchController.text (like the clear button) rebuild immediately instead of
    // waiting for the debounce to complete.
    _counter = widget.initialPokemonId ?? 1;
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

  void _decrementCounter() {
    setState(() {
      if (_counter > 1) {
        _counter--;
      }
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
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Search TextField
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    maxLength: 100,
                    decoration: InputDecoration(
                      counterText: '', // Hide character counter
                      hintText: 'Search Pokémon...',
                      hintStyle: GoogleFonts.roboto(color: Colors.grey[600]),
                      prefixIcon: const Icon(Icons.search, color: Colors.red),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.red),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                          : null,
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.blue, width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8), // Spacing between search and filter button
                // Filter Button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.filter_list, color: Colors.white),
                    onPressed: () {
                      // Add your filter logic here
                      // For example, show a dialog with filter options
                      _showFilterDialog();
                    },
                    tooltip: 'Filter Pokémon',
                  ),
                ),
              ],
            ),
          ),


          // POKÉMON DISPLAY AREA
          // This section shows the Pokémon information below the search bar
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _searchQuery.isEmpty // si esta vacio, carga las listas normales
                  ? fetchPokemonList(client, _selectedType, _selectedGeneration, _selectedAbility, _counter)
                  : searchPokemonByName(_searchQuery, client), // si no esta vacia, carga por nombre
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.red),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'No Pokémon found.',
                      style: GoogleFonts.pressStart2p(fontSize: 14, color: Colors.red),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final pokemon = snapshot.data![index];
                    final types = (pokemon['pokemontypes'] as List<dynamic>?)
                        ?.map((t) => t['type']?['name'] as String?)
                        .whereType<String>()
                        .join(', ') ?? 'Unknown';

                    return PokeSelect(
                      pokemon: pokemon,
                      types: types,
                      isDarkMode: isDarkMode,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => main_page.PokeDetailPage(
                              title: 'Pokedex',
                              initialPokemonId: pokemon['id'] as int, // Pasa el ID del Pokémon
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

        ],
      ),
      // Floating action button to increment the counter
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botón de retroceso (izquierda)
          Padding(
            padding: const EdgeInsets.only(left: 30), // Espaciado desde el borde
            child: FloatingActionButton(
              onPressed: _decrementCounter,
              backgroundColor: Colors.blue,
              tooltip: 'Previous Pokémon',
              heroTag: 'decrementButton', // Necesario cuando hay múltiples FABs
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
            ),
          ),
          // Botón de avance (derecha)
          FloatingActionButton(
            onPressed: _incrementCounter,
            backgroundColor: Colors.red,
            tooltip: 'Next Pokémon',
            heroTag: 'incrementButton', // Necesario cuando hay múltiples FABs
            child: const Icon(
              Icons.arrow_forward,
              color: Colors.white,
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
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Filter Options',
                style: GoogleFonts.pressStart2p(fontSize: 12),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // FILTRO POR TIPO
                    Text('Type:', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'normal', 'fire', 'water', 'electric', 'grass', 'ice',
                        'fighting', 'poison', 'ground', 'flying', 'psychic',
                        'bug', 'rock', 'ghost', 'dragon', 'dark', 'steel', 'fairy'
                      ].map((type) {
                        final isSelected = _selectedType == type;
                        return FilterChip(
                          label: Text(type.toUpperCase(), style: const TextStyle(fontSize: 10)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setDialogState(() {
                              _selectedType = selected ? type : null;
                            });
                          },
                          selectedColor: Colors.red.withOpacity(0.3),
                        );
                      }).toList(),
                    ),
                    const Divider(height: 32),

                    // FILTRO POR GENERACIÓN
                    Text('Generation:', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(9, (index) {
                        final gen = index + 1;
                        final isSelected = _selectedGeneration == gen;
                        return FilterChip(
                          label: Text('Gen $gen'),
                          selected: isSelected,
                          onSelected: (selected) {
                            setDialogState(() {
                              _selectedGeneration = selected ? gen : null;
                            });
                          },
                          selectedColor: Colors.blue.withOpacity(0.3),
                        );
                      }),
                    ),
                    const Divider(height: 32),

                    // FILTRO POR HABILIDAD
                    Text('Ability:', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Enter ability name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        suffixIcon: _selectedAbility != null
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  setDialogState(() {
                                    _selectedAbility = null;
                                  });
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          _selectedAbility = value.isEmpty ? null : value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                // Botón para limpiar todos los filtros
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      _selectedType = null;
                      _selectedGeneration = null;
                      _selectedAbility = null;
                    });
                  },
                  child: const Text('Clear All'),
                ),
                // Botón para aplicar filtros
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      // Triggers rebuild with new filters
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

}