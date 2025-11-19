import 'package:flutter/material.dart';
import 'dart:async';
//fonts de google
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../theme_provider.dart';
import 'package:provider/provider.dart';
import '../page_necessities/home_page/PokeSelect.dart';
import '/domain/main.dart' as main_page;
import '/domain/home.dart' as home_page;
import '/domain/state_management/bloc_state_home.dart';

import '/presentation/page_necessities/home_page/showFilterDialog.dart' as show_filter_dialog;
import 'PokemonQuizPage.dart';



// State class for MyHomePage
class HomePageState extends State<home_page.PokeHomePage> {
  // Counter to keep track of the current Pokémon ID
  // This increments when the user presses the floating action button

  bool get isDarkMode =>
      Provider
          .of<AppThemeState>(context)
          .isDarkMode;

  // Text controller for search bar - manages the text input state
  // Allows us to read, clear, and listen to changes in the search field
  final TextEditingController _searchController = TextEditingController();

  // Scroll controller for the Pokémon list - manages scrolling behavior
  final ScrollController _scrollController = ScrollController();

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

  // Add initState to listen to controller changes so the suffix icon updates immediately
  @override
  void initState() {
    super.initState();
    // When the controller text changes we call setState() so widgets that depend on
    // _searchController.text (like the clear button) rebuild immediately instead of
    // waiting for the debounce to complete.
    _searchController.addListener(() {
      // Only rebuild if mounted to avoid setState after dispose
      if (mounted) setState(() {});
    });
    _scrollController.addListener(_onScroll);
  }

  // Cleanup method called when this widget is removed from the widget tree
  // It's important to dispose of controllers and timers to prevent memory leaks
  @override
  void dispose() {
    _searchController.dispose(); // Release text controller resources
    _scrollController.dispose(); // Release scroll controller resources
    _debounce?.cancel(); // Cancel any active debounce timer
    super.dispose(); // Call parent dispose method
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<HomeBloc>().add(LoadMorePokemon());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildSearchAndFilterBar(context),
          Expanded(child: _buildPokemonList(context)),
        ],
      ),
    );
  }


  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.red,
      centerTitle: true,
      title: Text(
        widget.title,
        style: GoogleFonts.pressStart2p(
          fontSize: 20,
          color: Colors.yellow,
          fontWeight: FontWeight.bold,
          shadows: [
            const Shadow(
              offset: Offset(2, 2),
              blurRadius: 4,
              color: Colors.blue,
            ),
          ],
        ),
      ),
      actions: [
        // Pokemon Quiz button
        IconButton(
          icon: const Icon(Icons.quiz, color: Colors.yellow),
          tooltip: 'Pokemon Quiz',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PokemonQuizPage(),
              ),
            );
          },
        ),
        Consumer<AppThemeState>(
          builder: (context, themeState, _) {
            return Row(
              children: [
                Icon(
                  Icons.light_mode,
                  color: themeState.isDarkMode ? Colors.grey : Colors.yellow,
                  size: 20,
                ),
                Switch(
                  value: themeState.isDarkMode,
                  onChanged: (_) => themeState.toggleTheme(),
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
    );
  }

  Widget _buildSearchAndFilterBar(BuildContext context) {
    final isDarkMode = Provider
        .of<AppThemeState>(context)
        .isDarkMode;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (query) {
                _onSearchChanged(query);
                context.read<HomeBloc>().add(
                    SearchPokemon(query.toLowerCase().trim()));
              },
              maxLength: 100,
              decoration: InputDecoration(
                counterText: '',
                hintText: 'Search Pokémon...',
                hintStyle: GoogleFonts.roboto(color: Colors.grey[600]),
                prefixIcon: const Icon(Icons.search, color: Colors.red),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.red),
                  onPressed: () {
                    _searchController.clear();
                    context.read<HomeBloc>().add(const SearchPokemon(''));
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
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(15),
            ),
            child: BlocBuilder<HomeBloc, HomeState>(
              builder: (context, state) {
                return IconButton(
                  icon: const Icon(Icons.filter_list, color: Colors.white),
                  onPressed: () async {
                    final currentState = state;
                    final result = await show_filter_dialog.showFilterDialog(
                      context,
                      currentState is HomeLoaded ? currentState.selectedType : null,
                      currentState is HomeLoaded ? currentState.selectedGeneration : null,
                      currentState is HomeLoaded ? currentState.selectedAbility : null,
                      currentState is HomeLoaded ? currentState.sortOrder : 'asc',
                    );
                    if (result != null && mounted) {
                      context.read<HomeBloc>().add(UpdateFilters(
                        type: result['type'],
                        generation: result['generation'],
                        ability: result['ability'],
                        sortOrder: result['sortOrder'],
                      ));
                    }
                  },
                  tooltip: 'Filter Pokémon',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPokemonList(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.red),
          );
        }

        if (state is HomeError) {
          return Center(
            child: Text(
              state.message,
              style: GoogleFonts.pressStart2p(fontSize: 14, color: Colors.red),
            ),
          );
        }

        if (state is HomeLoaded) {
          if (state.pokemonList.isEmpty) {
            return Center(
              child: Text(
                'No Pokémon found.',
                style: GoogleFonts.pressStart2p(
                    fontSize: 14, color: Colors.red),
              ),
            );
          }

          return ListView.builder(
            controller: _scrollController,
            itemCount: state.hasReachedMax
                ? state.pokemonList.length
                : state.pokemonList.length + 1,
            itemBuilder: (context, index) {
              if (index >= state.pokemonList.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(color: Colors.red),
                  ),
                );
              }

              final pokemon = state.pokemonList[index];
              final types = (pokemon['pokemon_v2_pokemontypes'] as List<dynamic>?)
                  ?.map((t) => t['pokemon_v2_type']?['name'] as String?)
                  .whereType<String>()
                  .join(', ') ??
                  'Unknown';

              return PokeSelect(
                pokemon: pokemon,
                types: types,
                isDarkMode: Provider
                    .of<AppThemeState>(context)
                    .isDarkMode,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          main_page.PokeDetailPage(
                            title: 'Pokedex',
                            initialPokemonId: pokemon['id'] as int,
                          ),
                    ),
                  );
                },
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

