// Import Flutter's Material Design components for UI building
import 'package:flutter/material.dart';
// Import GraphQL Flutter package for API queries (currently imported but not actively used in favor of queries.dart)
import 'package:graphql_flutter/graphql_flutter.dart';
// Import Google Fonts package to use the retro "Press Start 2P" font for Pokémon theme
import 'package:google_fonts/google_fonts.dart';
// Import Dart's math library to generate random numbers for selecting random Pokémon
import 'dart:math';
// Import custom queries file that contains the fetchPokemon function for GraphQL data fetching
import 'package:pokedex/queries.dart';
// Import GraphQL service singleton to access the configured GraphQL client
import 'graphql.dart';

/// PokemonQuizPage is a StatefulWidget that implements the "Who's That Pokémon?" quiz game
/// This is the main quiz page where users guess Pokémon based on their silhouette
class PokemonQuizPage extends StatefulWidget {
  const PokemonQuizPage({super.key});

  @override
  State<PokemonQuizPage> createState() => _PokemonQuizPageState();
}

/// State class for PokemonQuizPage that manages the quiz game logic and UI state
class _PokemonQuizPageState extends State<PokemonQuizPage> {
  // Stores the randomly generated Pokémon ID (1-1010) for the current quiz question
  // Nullable because it's not set until _loadNewPokemon() is called
  int? _randomPokemonId;

  // Stores the fetched Pokémon data (name, types, sprites, etc.) as a Map
  // Nullable because data is fetched asynchronously after the widget initializes
  Map<String, dynamic>? _currentPokemon;

  // Tracks whether the Pokémon has been revealed (either by guessing correctly or clicking "Reveal")
  // When true, the silhouette becomes the full-color image
  bool _isRevealed = false;

  // Tracks whether the user's last guess was correct
  // Used to determine the color of the feedback message (green for correct, orange for wrong)
  bool _isCorrect = false;

  // Text controller for the guess input field
  // Manages the text the user types and allows clearing/reading the input
  final TextEditingController _guessController = TextEditingController();

  // Stores the feedback message shown to the user after guessing or revealing
  // Examples: "Correct! It's Pikachu!", "Wrong! Try again or reveal the answer."
  String _feedbackMessage = '';

  // Tracks the number of correct guesses the user has made in the current session
  // Increments by 1 each time the user guesses correctly
  int _score = 0;

  // Tracks the total number of attempts (guesses + reveals) across all Pokémon
  // Increments with each guess or reveal action
  int _attempts = 0;

  // Tracks whether data is currently being loaded from the API
  // When true, shows a loading spinner instead of the quiz UI
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load the first random Pokémon when the page is initialized
    _loadNewPokemon();
  }

  @override
  void dispose() {
    // Clean up the text controller when the widget is disposed to prevent memory leaks
    _guessController.dispose();
    super.dispose();
  }

  /// Generates a random Pokémon ID and fetches its data from the API
  /// This method resets the quiz state for a new question
  ///
  /// Process:
  /// 1. Reset all state variables (_isRevealed, _isCorrect, _feedbackMessage, input field)
  /// 2. Generate random ID between 1-1010 (covering all existing Pokémon generations)
  /// 3. Fetch Pokémon data from GraphQL API using the random ID
  /// 4. Update state with the fetched data and stop loading indicator
  void _loadNewPokemon() async {
    // Set loading state and reset quiz-specific states
    setState(() {
      _isLoading = true; // Show loading spinner
      _isRevealed = false; // Hide the Pokémon (show silhouette)
      _isCorrect = false; // Reset correct status
      _feedbackMessage = ''; // Clear any previous feedback
      _guessController.clear(); // Clear the text input field
    });

    // Create Random instance and generate a number between 1 and 1010
    final random = Random();
    final randomId = random.nextInt(1010) + 1; // nextInt(1010) gives 0-1009, +1 makes it 1-1010

    // Update state with the random ID so the image URL can use it
    setState(() {
      _randomPokemonId = randomId;
    });

    // Fetch the Pokémon data from the GraphQL API
    // Uses the GraphQL service singleton to get the client instance
    final client = GraphQLService().client;
    // Call the fetchPokemon function from queries.dart to get Pokémon details
    final pokemonData = await fetchPokemon(randomId, client);

    // Update state with the fetched data and stop loading
    setState(() {
      _currentPokemon = pokemonData; // Store the Pokémon data (name, types, etc.)
      _isLoading = false; // Hide loading spinner and show quiz UI
    });
  }

  /// Validates and checks the user's guess against the correct Pokémon name
  ///
  /// Process:
  /// 1. Validate that the input is not empty
  /// 2. Normalize both the guess and correct name (trim whitespace, lowercase)
  /// 3. Compare the guess with the correct name
  /// 4. If correct: increment score, reveal Pokémon, show success message
  /// 5. If wrong: show error message, allow user to try again or reveal
  void _checkGuess() {
    // Validate that the user entered something
    if (_guessController.text.trim().isEmpty) {
      setState(() {
        _feedbackMessage = 'Please enter a guess!';
      });
      return; // Exit early if input is empty
    }

    // Normalize the user's guess: remove whitespace and convert to lowercase for case-insensitive comparison
    final guess = _guessController.text.trim().toLowerCase();
    // Get the correct Pokémon name from the fetched data and normalize it the same way
    // Use null-aware operators (?.) and null coalescing (??) to handle missing data gracefully
    final correctName = _currentPokemon?['name']?.toString().toLowerCase() ?? '';

    // Update state based on whether the guess is correct
    setState(() {
      _attempts++; // Increment total attempts counter
      if (guess == correctName) {
        // User guessed correctly!
        _isCorrect = true; // Set correct flag for green feedback styling
        _isRevealed = true; // Reveal the Pokémon (remove silhouette effect)
        _score++; // Increment the score
        _feedbackMessage = 'Correct! It\'s ${_currentPokemon?['name']}!'; // Show success message
      } else {
        // User guessed incorrectly
        _feedbackMessage = 'Wrong! Try again or reveal the answer.'; // Show error message, user can try again
      }
    });
  }

  /// Reveals the Pokémon without requiring a correct guess
  /// Users can click this if they give up or want to skip the current Pokémon
  ///
  /// Note: This increments attempts but does NOT increment score
  void _revealPokemon() {
    setState(() {
      _isRevealed = true; // Remove silhouette and show full-color image
      _attempts++; // Count this as an attempt
      _feedbackMessage = 'The Pokémon is ${_currentPokemon?['name']}!'; // Show the answer
    });
  }

  /// Loads the next random Pokémon for a new quiz question
  /// Simply calls _loadNewPokemon() which handles all the reset and fetch logic
  void _nextPokemon() {
    _loadNewPokemon();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar with Pokémon-themed styling
      appBar: AppBar(
        backgroundColor: Colors.red, // Classic Pokémon red color
        centerTitle: true, // Center the title text
        title: Text(
          'Who\'s That Pokémon?', // Quiz title referencing the classic TV show segment
          style: GoogleFonts.pressStart2p( // Retro 8-bit font for nostalgic feel
            fontSize: 16,
            color: Colors.yellow, // Yellow text on red background (Pokémon branding)
            fontWeight: FontWeight.bold,
            shadows: [
              // Add blue shadow for depth and classic Pokémon aesthetic
              const Shadow(
                offset: Offset(2, 2), // Shadow positioned 2px down and right
                blurRadius: 4, // Soft shadow blur
                color: Colors.blue,
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          // Show loading spinner while fetching Pokémon data
          ? const Center(child: CircularProgressIndicator())
          // Show quiz UI once data is loaded
          : SingleChildScrollView( // Allow scrolling if content exceeds screen height
              padding: const EdgeInsets.all(16.0), // Padding around all edges
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center, // Center all children horizontally
                children: [
                  // ============ SCORE DISPLAY SECTION ============
                  // Container showing current score and total attempts
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100, // Light red background
                      borderRadius: BorderRadius.circular(12), // Rounded corners
                      border: Border.all(color: Colors.red, width: 2), // Red border
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround, // Space items evenly
                      children: [
                        // Score text (number of correct guesses)
                        Text(
                          'Score: $_score',
                          style: GoogleFonts.pressStart2p(
                            fontSize: 14,
                            color: Colors.red.shade900, // Dark red text
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Attempts text (total guesses + reveals)
                        Text(
                          'Attempts: $_attempts',
                          style: GoogleFonts.pressStart2p(
                            fontSize: 14,
                            color: Colors.red.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24), // Vertical spacing

                  // ============ POKEMON IMAGE SECTION ============
                  // Only show if Pokémon data has been loaded
                  if (_currentPokemon != null) ...[
                    // Container for the Pokémon image with silhouette effect
                    Container(
                      height: 300,
                      width: 300,
                      decoration: BoxDecoration(
                        color: Colors.white, // White background for image
                        borderRadius: BorderRadius.circular(16), // Rounded corners
                        border: Border.all(color: Colors.red, width: 3), // Red border for Pokémon theme
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13), // Match parent border radius (minus border width)
                        // ColorFiltered widget applies a color filter to create the silhouette effect
                        child: ColorFiltered(
                          colorFilter: _isRevealed
                              // If revealed, show normal colors (transparent filter does nothing)
                              ? const ColorFilter.mode(
                                  Colors.transparent,
                                  BlendMode.multiply,
                                )
                              // If not revealed, create black silhouette using a color matrix
                              // This matrix zeros out all RGB channels, keeping only the alpha (opacity)
                              // Result: Pokémon appears as a solid black shape
                              : const ColorFilter.matrix([
                                  0, 0, 0, 0, 0, // Red channel: all zeros = no red
                                  0, 0, 0, 0, 0, // Green channel: all zeros = no green
                                  0, 0, 0, 0, 0, // Blue channel: all zeros = no blue
                                  0, 0, 0, 1, 0, // Alpha channel: 1 = keep original opacity
                                ]),
                          // Load Pokémon image from PokeAPI sprites repository
                          child: Image.network(
                            'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${_randomPokemonId}.png',
                            fit: BoxFit.contain, // Scale image to fit container while maintaining aspect ratio
                            // Error builder shows an error icon if image fails to load
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(Icons.error, size: 50),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ============ FEEDBACK MESSAGE SECTION ============
                    // Only show if there's a feedback message to display
                    if (_feedbackMessage.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          // Background color changes based on correctness:
                          // Green for correct, orange for wrong/revealed
                          color: _isCorrect ? Colors.green.shade100 : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isCorrect ? Colors.green : Colors.orange,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          _feedbackMessage,
                          style: GoogleFonts.pressStart2p(
                            fontSize: 12,
                            // Text color matches border: dark green for correct, dark orange otherwise
                            color: _isCorrect ? Colors.green.shade900 : Colors.orange.shade900,
                          ),
                          textAlign: TextAlign.center, // Center the feedback text
                        ),
                      ),
                    const SizedBox(height: 24),

                    // ============ INPUT AND BUTTONS SECTION ============
                    // Show input field and guess/reveal buttons ONLY if Pokémon is not yet revealed
                    if (!_isRevealed) ...[
                      // Text field for user to type their guess
                      TextField(
                        controller: _guessController, // Controller to read/manage the text
                        decoration: InputDecoration(
                          hintText: 'Enter Pokémon name...', // Placeholder text
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12), // Rounded corners
                            borderSide: const BorderSide(color: Colors.red, width: 2), // Red border
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.blue, width: 2), // Blue border when focused
                          ),
                        ),
                        // Allow user to submit guess by pressing Enter/Return on keyboard
                        onSubmitted: (_) => _checkGuess(),
                      ),
                      const SizedBox(height: 16),

                      // Row containing the Guess and Reveal buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Space buttons evenly
                        children: [
                          // "Guess" button - checks the user's answer
                          ElevatedButton.icon(
                            onPressed: _checkGuess, // Call checkGuess when pressed
                            icon: const Icon(Icons.check), // Checkmark icon
                            label: const Text('Guess'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green, // Green for "submit/confirm" action
                              foregroundColor: Colors.white, // White text and icon
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                          // "Reveal" button - shows the answer without guessing
                          ElevatedButton.icon(
                            onPressed: _revealPokemon, // Call revealPokemon when pressed
                            icon: const Icon(Icons.visibility), // Eye icon (visibility)
                            label: const Text('Reveal'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange, // Orange for "secondary/skip" action
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // ============ REVEALED POKEMON DETAILS SECTION ============
                      // Show Pokémon details ONLY after it's been revealed
                      // Displayed after correct guess or clicking "Reveal"
                      Card(
                        elevation: 4, // Shadow depth for card
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.red, width: 2), // Red border
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              // Display Pokémon name in retro font
                              Text(
                                _currentPokemon?['name'] ?? 'Unknown',
                                style: GoogleFonts.pressStart2p(
                                  fontSize: 18,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Display Pokémon ID number
                              Text(
                                'ID: #${_randomPokemonId}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // "Next Pokémon" button - loads a new random Pokémon
                      ElevatedButton.icon(
                        onPressed: _nextPokemon, // Call nextPokemon to load new question
                        icon: const Icon(Icons.skip_next), // Skip/next icon
                        label: const Text('Next Pokémon'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue, // Blue for "continue/next" action
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
    );
  }
}
