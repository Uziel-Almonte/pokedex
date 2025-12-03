// ============================================================================
/// POKÉMON QUIZ PAGE - "WHO'S THAT POKÉMON?" GAME
/// ============================================================================
///
/// This interactive quiz game challenges players to identify Pokémon from their
/// silhouettes, featuring a complete scoring system with lives and achievements.
///
/// KEY FEATURES:
/// - **Points System**: Earn 100 points for each correct guess
/// - **Lives System**: Start with 3 lives, lose 1 per wrong answer (game over at 0)
/// - **Achievement Milestones**: Unlock titles as you progress:
///   * 500 points → Pokémon Trainer
///   * 1000 points → Gym Leader
///   * 2000 points → Elite Four Member
///   * 3500 points → Champion
///   * 5000+ points → Legend
/// - **Real-time Feedback**: Visual and text feedback for correct/wrong answers
/// - **Silhouette Effect**: Pokémon appear as black silhouettes until revealed
///
/// SCORING MECHANICS:
/// - Correct guess: +100 points, advance to next Pokémon
/// - Wrong guess: -1 life, can retry same Pokémon
/// - Reveal button: Shows answer but no points awarded
/// - Game over: When lives reach 0, can restart to try again
///
/// GAME FLOW:
/// 1. Random Pokémon loads as silhouette
/// 2. Player types guess and submits
/// 3. If correct: award points, check for milestone, show next Pokémon
/// 4. If wrong: lose life, show feedback, allow retry or reveal
/// 5. If lives = 0: game over screen with final score
/// 6. Restart button resets everything to initial state
///
/// ============================================================================

// Import Flutter's Material Design components for UI building
import 'package:flutter/material.dart';
// Import GraphQL Flutter package for API queries (currently imported but not actively used in favor of queries.dart)
import 'package:graphql_flutter/graphql_flutter.dart';
// Import Google Fonts package to use the retro "Press Start 2P" font for Pokémon theme
import 'package:google_fonts/google_fonts.dart';
import 'package:pokedex/domain/models/Pokemon.dart';
// Import Dart's math library to generate random numbers for selecting random Pokémon
import 'dart:math';
// Import custom queries file that contains the fetchPokemon function for GraphQL data fetching
import '../../data/queries.dart';
// Import GraphQL service singleton to access the configured GraphQL client
import '../../data/graphql.dart';
// Import language service for multilingual support (Spanish/English)
import '../services/language_service.dart';

/// PokemonQuizPage is a StatefulWidget that implements the "Who's That Pokémon?" quiz game
/// This is the main quiz page where users guess Pokémon based on their silhouette
class PokemonQuizPage extends StatefulWidget {
  const PokemonQuizPage({super.key});

  @override
  State<PokemonQuizPage> createState() => _PokemonQuizPageState();
}

/// State class for PokemonQuizPage that manages the quiz game logic and UI state
class _PokemonQuizPageState extends State<PokemonQuizPage> {
  // ============================================================================
  // POKÉMON DATA STATE VARIABLES
  // ============================================================================

  /// Stores the randomly generated Pokémon ID (1-1010) for the current quiz question
  /// Nullable because it's not set until _loadNewPokemon() is called
  int? _randomPokemonId;

  /// Stores the fetched Pokémon data (name, types, sprites, etc.) as a Map
  /// Nullable because data is fetched asynchronously after the widget initializes
  Pokemon? _currentPokemon;

  // ============================================================================
  // UI STATE VARIABLES
  // ============================================================================

  /// Tracks whether the Pokémon has been revealed (either by guessing correctly or clicking "Reveal")
  /// When true, the silhouette becomes the full-color image
  bool _isRevealed = false;

  /// Tracks whether the user's last guess was correct
  /// Used to determine the color of the feedback message (green for correct, orange for wrong)
  bool _isCorrect = false;

  /// Text controller for the guess input field
  /// Manages the text the user types and allows clearing/reading the input
  final TextEditingController _guessController = TextEditingController();

  /// Stores the feedback message shown to the user after guessing or revealing
  /// Examples: "Correct! It's Pikachu!", "Wrong! Try again or reveal the answer."
  String _feedbackMessage = '';

  /// Tracks whether data is currently being loaded from the API
  /// When true, shows a loading spinner instead of the quiz UI
  bool _isLoading = false;

  // ============================================================================
  // SCORING SYSTEM STATE VARIABLES
  // ============================================================================

  /// **POINTS SYSTEM**: Total points earned throughout the game
  ///
  /// EARNING POINTS:
  /// - Each correct guess awards 100 points
  /// - Points accumulate across all Pokémon guessed correctly
  /// - Revealing without guessing awards 0 points
  ///
  /// MILESTONE SYSTEM:
  /// Points determine your trainer rank:
  /// - 0-499: Beginner
  /// - 500-999: Pokémon Trainer 🎓
  /// - 1000-1999: Gym Leader 🏆
  /// - 2000-3499: Elite Four Member 👑
  /// - 3500-4999: Champion 🌟
  /// - 5000+: Legend ⭐✨
  int _points = 0;

  /// **LIVES SYSTEM**: Number of remaining chances before game over
  ///
  /// MECHANICS:
  /// - Start with 3 lives
  /// - Lose 1 life for each wrong guess
  /// - Lives do NOT regenerate during a game session
  /// - When lives reach 0, game ends and shows final score
  /// - Restart button resets lives back to 3
  ///
  /// STRATEGIC ELEMENT:
  /// - Players must balance risk (guessing) vs safety (revealing)
  /// - Revealing doesn't cost a life, but awards no points
  /// - Wrong guesses can be retried on same Pokémon (costs 1 life per wrong attempt)
  int _lives = 3;

  /// **ACHIEVEMENT TRACKING**: Set of milestone points already celebrated
  ///
  /// PURPOSE:
  /// Prevents showing the same achievement message multiple times.
  ///
  /// HOW IT WORKS:
  /// - When player reaches 500 points, show "Pokémon Trainer!" celebration
  /// - Add 500 to this set so we don't show it again at 600, 700, etc.
  /// - Each milestone (500, 1000, 2000, 3500, 5000) is tracked separately
  ///
  /// EXAMPLE:
  /// Player at 450 points → guesses correctly → now 550 points
  /// → Check if 500 is in _celebratedMilestones → Not found
  /// → Show achievement dialog → Add 500 to set
  /// → At 600 points, 500 is in set, so no dialog shown again
  final Set<int> _celebratedMilestones = {};

  /// Legacy score counter (kept for backward compatibility, but _points is now primary)
  /// Tracks the number of correct guesses (increments by 1 per correct answer)
  int _score = 0;

  /// Legacy attempts counter (kept for backward compatibility)
  /// Tracks the total number of attempts (guesses + reveals) across all Pokémon
  int _attempts = 0;

  // ============================================================================
  // LIFECYCLE METHODS
  // ============================================================================

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

  // ============================================================================
  // GAME LOGIC METHODS
  // ============================================================================

  /// **RESTART GAME**: Resets all game state to initial values
  ///
  /// WHAT GETS RESET:
  /// - Points back to 0
  /// - Lives back to 3
  /// - Score and attempts back to 0
  /// - Clears all celebrated milestones
  /// - Loads a new random Pokémon
  ///
  /// WHEN CALLED:
  /// - Player clicks "Restart Game" button after game over
  /// - Allows players to try for a higher score without closing the app
  void _restartGame() {
    setState(() {
      _points = 0;
      _lives = 3;
      _score = 0;
      _attempts = 0;
      _celebratedMilestones.clear();
    });
    _loadNewPokemon();
  }

  /// **CHECK MILESTONE ACHIEVEMENTS**: Displays celebration dialog for new ranks
  ///
  /// MILESTONE THRESHOLDS:
  /// - 500 points: Pokémon Trainer
  /// - 1000 points: Gym Leader
  /// - 2000 points: Elite Four Member
  /// - 3500 points: Champion
  /// - 5000 points: Legend
  ///
  /// ALGORITHM:
  /// 1. Define all milestone points in order (lowest to highest)
  /// 2. Loop through each milestone
  /// 3. If player's points >= milestone AND milestone not yet celebrated
  /// 4. Show celebration dialog with rank title
  /// 5. Mark milestone as celebrated to prevent repeats
  ///
  /// DESIGN:
  /// - Colorful gradient background (red to orange)
  /// - Large emoji for visual impact
  /// - Rank title in retro font
  /// - "Continue" button to dismiss and keep playing
  void _checkForMilestone() {
    // Get translations for current language
    final translations = LanguageService.instance.translations;

    // Define all achievement milestones in ascending order
    final milestones = [
      {'points': 500, 'title': translations.pokemonTrainer, 'emoji': '🎓'},
      {'points': 1000, 'title': translations.gymLeader, 'emoji': '🏆'},
      {'points': 2000, 'title': translations.eliteFourMember, 'emoji': '👑'},
      {'points': 3500, 'title': translations.champion, 'emoji': '🌟'},
      {'points': 5000, 'title': translations.legend, 'emoji': '⭐✨'},
    ];

    // Loop through each milestone to check if player just reached it
    for (var milestone in milestones) {
      final points = milestone['points'] as int;
      final title = milestone['title'] as String;
      final emoji = milestone['emoji'] as String;

      // Check if player has enough points AND hasn't been celebrated yet
      if (_points >= points && !_celebratedMilestones.contains(points)) {
        // Mark this milestone as celebrated
        _celebratedMilestones.add(points);

        // Show celebration dialog (non-blocking, player can continue playing)
        showDialog(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              // Beautiful gradient background (red to orange)
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.red, Colors.orange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Only take up necessary space
                children: [
                  // "CONGRATULATIONS!" header text
                  Text(
                    translations.congratulations,
                    style: GoogleFonts.pressStart2p(
                      fontSize: 16,
                      color: Colors.yellow,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Large emoji for visual celebration
                  Text(
                    emoji,
                    style: const TextStyle(fontSize: 64),
                  ),
                  const SizedBox(height: 16),
                  // "You are now a..." text
                  Text(
                    translations.youAreNowA,
                    style: GoogleFonts.pressStart2p(
                      fontSize: 10,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // Rank title (e.g., "Pokémon Trainer")
                  Text(
                    title,
                    style: GoogleFonts.pressStart2p(
                      fontSize: 14,
                      color: Colors.yellow,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // "Continue" button to close dialog
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow,
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      translations.continueButton,
                      style: GoogleFonts.pressStart2p(fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        // Only show one milestone at a time, exit loop after showing first match
        break;
      }
    }
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

  /// **VALIDATE AND CHECK GUESS**: Core game logic for processing user's answer
  ///
  /// VALIDATION:
  /// 1. Check if input is not empty (show error if empty)
  /// 2. Normalize both guess and correct answer (lowercase, trim whitespace)
  /// 3. Compare normalized strings for exact match
  ///
  /// IF CORRECT:
  /// - Award 100 points
  /// - Increment score counter
  /// - Reveal the Pokémon
  /// - Show success message (green background)
  /// - Check if player reached a new milestone
  ///
  /// IF WRONG:
  /// - Deduct 1 life
  /// - Show error message (orange background)
  /// - Check if game is over (lives = 0)
  /// - Allow retry on same Pokémon
  ///
  /// EDGE CASES:
  /// - Empty input: Show "Please enter a guess!" message
  /// - Missing data: Use empty string as fallback (null coalescing)
  void _checkGuess() {
    // Get translations for current language
    final translations = LanguageService.instance.translations;

    // Validate that the user entered something
    if (_guessController.text.trim().isEmpty) {
      setState(() {
        _feedbackMessage = translations.pleaseEnterGuess;
      });
      return; // Exit early if input is empty
    }

    // Normalize the user's guess: remove whitespace and convert to lowercase for case-insensitive comparison
    final guess = _guessController.text.trim().toLowerCase();
    // Get the correct Pokémon name from the fetched data and normalize it the same way
    // Use null-aware operators (?.) and null coalescing (??) to handle missing data gracefully
    final correctName = _currentPokemon?.name.toLowerCase() ?? '';

    // Update state based on whether the guess is correct
    setState(() {
      _attempts++; // Increment total attempts counter (legacy)

      if (guess == correctName) {
        // ✅ CORRECT ANSWER PATH
        _isCorrect = true; // Set correct flag for green feedback styling
        _isRevealed = true; // Reveal the Pokémon (remove silhouette effect)
        _score++; // Increment the score (legacy)
        _points += 100; // Award 100 points for correct guess
        _feedbackMessage = '${translations.correctPrefix} ${_currentPokemon?.name}! ${translations.correctSuffix}'; // Show success message with points

        // Check if this achievement unlocked a new milestone rank
        _checkForMilestone();
      } else {
        // ❌ WRONG ANSWER PATH
        _lives--; // Deduct 1 life for wrong guess

        // Check if player ran out of lives (game over condition)
        if (_lives <= 0) {
          _feedbackMessage = '${translations.gameOverNoLives}: $_points ${translations.points}';
        } else {
          // Player still has lives, can try again
          _feedbackMessage = '${translations.wrongTryAgain} ${translations.livesLeft}: $_lives';
        }
      }
    });
  }

  /// **REVEAL POKÉMON**: Shows the answer without costing a life
  ///
  /// BEHAVIOR:
  /// - User can click this if they give up or want to skip the current Pokémon
  /// - Reveals the full-color image and shows the Pokémon's name
  /// - Increments attempts counter (legacy stat tracking)
  /// - Does NOT award points (only correct guesses earn points)
  /// - Does NOT cost a life (safe option for difficult Pokémon)
  ///
  /// STRATEGIC USE:
  /// - Preserves lives when unsure of answer
  /// - Allows progression without penalty (except no points)
  /// - Good for learning unfamiliar Pokémon
  void _revealPokemon() {
    // Get translations for current language
    final translations = LanguageService.instance.translations;

    setState(() {
      _isRevealed = true; // Remove silhouette and show full-color image
      _attempts++; // Count this as an attempt (legacy)
      _feedbackMessage = '${translations.thePokemonIs} ${_currentPokemon?.name}! ${translations.noPointsAwarded}'; // Show the answer with no points message
    });
  }

  /// **LOAD NEXT POKÉMON**: Advances to a new random Pokémon question
  ///
  /// WHEN CALLED:
  /// - After correctly guessing a Pokémon
  /// - After revealing a Pokémon and clicking "Next Pokémon" button
  ///
  /// BEHAVIOR:
  /// - Calls _loadNewPokemon() which handles:
  ///   * Resetting UI state (feedback, revealed status, input field)
  ///   * Generating new random ID
  ///   * Fetching new Pokémon data
  ///   * Showing loading spinner during fetch
  ///
  /// NOTE: Does NOT reset points, lives, or achievements (those persist across questions)
  void _nextPokemon() {
    _loadNewPokemon();
  }

  // ============================================================================
  // UI BUILD METHOD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    // Get translations for current language
    final translations = LanguageService.instance.translations;
    final currentLang = LanguageService.instance.currentLanguage;

    return Scaffold(
      // AppBar with Pokémon-themed styling
      appBar: AppBar(
        backgroundColor: Colors.red, // Classic Pokémon red color
        centerTitle: true, // Center the title text
        title: Text(
          translations.appTitle, // Quiz title referencing the classic TV show segment
          style: GoogleFonts.pressStart2p( // Retro 8-bit font for nostalgic feel
            fontSize: 14,
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
        actions: [
          // Language toggle button
          IconButton(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.yellow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: Text(
                currentLang.toUpperCase(),
                style: GoogleFonts.pressStart2p(
                  fontSize: 10,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onPressed: () {
              setState(() {
                LanguageService.instance.toggleLanguage();
              });
            },
            tooltip: currentLang == 'en' ? 'Cambiar a Español' : 'Switch to English',
          ),
        ],
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
                  // ============================================================
                  // 📊 STATS DISPLAY SECTION - Points, Lives, Score, Attempts
                  // ============================================================
                  //
                  // This section shows the player's current game statistics in
                  // a visually appealing card with retro Pokémon styling.
                  //
                  // DISPLAYED STATS:
                  // - Points: Total points earned (100 per correct guess)
                  // - Lives: Remaining chances (3 at start, -1 per wrong guess)
                  // - Score: Number of correct guesses (legacy counter)
                  // - Attempts: Total guesses + reveals (legacy counter)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100, // Light red background
                      borderRadius: BorderRadius.circular(12), // Rounded corners
                      border: Border.all(color: Colors.red, width: 2), // Red border
                    ),
                    child: Column(
                      children: [
                        // Top row: Points and Lives (most important stats)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            // Points display with trophy icon
                            Column(
                              children: [
                                const Icon(Icons.stars, color: Colors.amber, size: 32),
                                const SizedBox(height: 4),
                                Text(
                                  translations.points,
                                  style: GoogleFonts.pressStart2p(
                                    fontSize: 10,
                                    color: Colors.red.shade900,
                                  ),
                                ),
                                Text(
                                  '$_points',
                                  style: GoogleFonts.pressStart2p(
                                    fontSize: 18,
                                    color: Colors.red.shade900,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            // Lives display with heart icons
                            Column(
                              children: [
                                Row(
                                  children: List.generate(
                                    3,
                                    (index) => Icon(
                                      Icons.favorite,
                                      color: index < _lives ? Colors.red : Colors.grey.shade300,
                                      size: 24,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  translations.lives,
                                  style: GoogleFonts.pressStart2p(
                                    fontSize: 10,
                                    color: Colors.red.shade900,
                                  ),
                                ),
                                Text(
                                  '$_lives',
                                  style: GoogleFonts.pressStart2p(
                                    fontSize: 18,
                                    color: Colors.red.shade900,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.red),
                        const SizedBox(height: 8),
                        // Bottom row: Score and Attempts (secondary stats)
                          Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround, // Space items evenly
                          children: [
                            // Score text (number of correct guesses)
                            Text(
                              '${translations.score}: $_score',
                              style: GoogleFonts.pressStart2p(
                                fontSize: 10,
                                color: Colors.red.shade900,
                              ),
                            ),
                            // Attempts text (total guesses + reveals)
                            Text(
                              '${translations.attempts}: $_attempts',
                              style: GoogleFonts.pressStart2p(
                                fontSize: 10,
                                color: Colors.red.shade900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24), // Vertical spacing

                  // ============================================================
                  // 💀 GAME OVER SCREEN - Shown when lives reach 0
                  // ============================================================
                  //
                  // DISPLAYED INFO:
                  // - "GAME OVER" title in retro font
                  // - Final score and points earned
                  // - Encouraging message to try again
                  // - "Restart Game" button to reset and play again
                  //
                  // LOGIC:
                  // - Only shows when _lives <= 0
                  // - Hides the Pokémon image and guess interface
                  // - Restart button calls _restartGame() to reset all stats
                  if (_lives <= 0) ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red, width: 3),
                      ),
                      child: Column(
                        children: [
                          Text(
                            translations.gameOver,
                            style: GoogleFonts.pressStart2p(
                              fontSize: 24,
                              color: Colors.red.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          const Icon(Icons.cancel, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            translations.finalScore,
                            style: GoogleFonts.pressStart2p(
                              fontSize: 12,
                              color: Colors.red.shade900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$_points ${translations.points}',
                            style: GoogleFonts.pressStart2p(
                              fontSize: 20,
                              color: Colors.amber.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${translations.correct}: $_score',
                            style: GoogleFonts.pressStart2p(
                              fontSize: 10,
                              color: Colors.red.shade900,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _restartGame,
                            icon: const Icon(Icons.refresh),
                            label: Text(translations.restartGame),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // ============================================================
                    // 🎮 ACTIVE GAME SCREEN - Normal quiz interface
                    // ============================================================
                    // Only show if Pokémon data has been loaded and game is not over
                    if (_currentPokemon != null) ...[
                      // ============ POKEMON IMAGE SECTION ============
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
                            hintText: translations.enterPokemonName, // Placeholder text
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
                              label: Text(translations.guessButton),
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
                              label: Text(translations.revealButton),
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
                                  _currentPokemon?.name ?? 'Unknown',
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
                          label: Text(translations.nextPokemon),
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
                ],
              ),
            ),
    );
  }
}

