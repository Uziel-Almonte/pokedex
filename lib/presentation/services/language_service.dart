// ============================================================================
/// LANGUAGE SERVICE - Manages app language state and translations
/// ============================================================================
///
/// This service provides centralized language management for the Pokémon Quiz app.
/// Supports English and Spanish with easy switching between languages.
///
/// SUPPORTED LANGUAGES:
/// - English (en) - Default
/// - Spanish (es)
///
/// USAGE:
/// ```dart
/// // Get current language
/// final currentLang = LanguageService.instance.currentLanguage;
///
/// // Change language
/// LanguageService.instance.setLanguage('es');
///
/// // Get translations
/// final translations = LanguageService.instance.translations;
/// ```
///
/// ============================================================================

import 'package:flutter/material.dart';

/// Singleton service that manages language state and provides translations
///
/// HOW IT WORKS:
/// 1. Extends ChangeNotifier to notify widgets when language changes
/// 2. Uses Singleton pattern so there's only ONE instance across the entire app
/// 3. Stores current language and provides translations based on that language
/// 4. When language changes, notifyListeners() triggers UI rebuild automatically
class LanguageService extends ChangeNotifier {
  // ========== SINGLETON PATTERN IMPLEMENTATION ==========
  // This ensures only ONE LanguageService exists throughout the app
  // Benefits: Consistent state, no duplicate services, efficient memory usage

  /// Private static instance - created once and reused forever
  static final LanguageService _instance = LanguageService._internal();

  /// Public getter to access the singleton instance from anywhere
  /// Usage: LanguageService.instance.currentLanguage
  static LanguageService get instance => _instance;

  /// Private constructor prevents external instantiation
  /// Only this class can create instances of itself
  LanguageService._internal();

  // ========== LANGUAGE STATE MANAGEMENT ==========

  /// Current selected language code ('en' for English, 'es' for Spanish)
  /// Private variable with underscore to control access
  String _currentLanguage = 'en'; // Default to English

  /// Public getter to read current language (read-only from outside)
  /// Usage: final lang = LanguageService.instance.currentLanguage;
  String get currentLanguage => _currentLanguage;

  // ========== TRANSLATIONS STORAGE ==========

  /// Map of all available translations, organized by language code
  /// Structure: { 'en': EnglishTranslations, 'es': SpanishTranslations }
  /// This is initialized once and never changes (final)
  final Map<String, QuizTranslations> _translations = {
    'en': QuizTranslations.english(), // Create English translation set
    'es': QuizTranslations.spanish(), // Create Spanish translation set
  };

  /// Get translations for the current language
  /// This dynamically returns the correct translation set based on _currentLanguage
  /// Usage: final text = LanguageService.instance.translations.appTitle;
  /// The '!' tells Dart we're sure the value exists (won't be null)
  QuizTranslations get translations => _translations[_currentLanguage]!;

  // ========== LANGUAGE SWITCHING METHODS ==========

  /// Change the app language to a specific language code
  ///
  /// HOW IT WORKS:
  /// 1. Validates that the language code exists in our translations map
  /// 2. Updates the current language
  /// 3. Calls notifyListeners() which triggers rebuild of all listening widgets
  ///
  /// @param languageCode - The language code to switch to ('en' or 'es')
  /// Usage: LanguageService.instance.setLanguage('es');
  void setLanguage(String languageCode) {
    // Only change if the language code is valid (exists in our translations)
    if (_translations.containsKey(languageCode)) {
      _currentLanguage = languageCode; // Update current language
      notifyListeners(); // 🔔 NOTIFY ALL WIDGETS! Rebuild UI with new language
    }
  }

  /// Toggle between English and Spanish (convenience method)
  ///
  /// HOW IT WORKS:
  /// 1. Checks current language
  /// 2. Switches to the opposite language (en ↔ es)
  /// 3. Notifies listeners to rebuild UI
  ///
  /// Usage: LanguageService.instance.toggleLanguage();
  void toggleLanguage() {
    // Ternary operator: if current is 'en', change to 'es', otherwise change to 'en'
    _currentLanguage = _currentLanguage == 'en' ? 'es' : 'en';
    notifyListeners(); // 🔔 NOTIFY ALL WIDGETS! Rebuild UI with new language
  }
}

/// Contains all translatable strings for the quiz game
///
/// HOW IT WORKS:
/// 1. This is an immutable data class (all fields are final)
/// 2. Each field represents ONE piece of text that appears in the UI
/// 3. Different instances contain different language versions of the same text
/// 4. Factory constructors create pre-configured instances for each language
///
/// STRUCTURE:
/// - All fields are final (can't be changed after creation)
/// - Constructor is const (compile-time constant for efficiency)
/// - Named groups of fields for easy organization
///
/// USAGE IN UI:
/// final translations = LanguageService.instance.translations;
/// Text(translations.appTitle) // Shows "Who's That Pokémon?" or "¿Quién es ese Pokémon?"
class QuizTranslations {
  // ========== APPBAR SECTION ==========
  /// Main title shown in the app bar
  /// EN: "Who's That Pokémon?"
  /// ES: "¿Quién es ese Pokémon?"
  final String appTitle;

  // ========== STATS SECTION ==========
  /// Label for points counter
  /// EN: "Points" | ES: "Puntos"
  final String points;

  /// Label for lives remaining
  /// EN: "Lives" | ES: "Vidas"
  final String lives;

  /// Label for correct answers counter
  /// EN: "Score" | ES: "Aciertos"
  final String score;

  /// Label for total attempts counter
  /// EN: "Attempts" | ES: "Intentos"
  final String attempts;

  // ========== GAME OVER SCREEN ==========
  /// Game over header text
  /// EN: "GAME OVER" | ES: "JUEGO TERMINADO"
  final String gameOver;

  /// Label for final score display
  /// EN: "Final Score" | ES: "Puntuación Final"
  final String finalScore;

  /// Label for correct answers in game over screen
  /// EN: "Correct" | ES: "Correcto"
  final String correct;

  /// Button text to restart the game
  /// EN: "Restart Game" | ES: "Reiniciar Juego"
  final String restartGame;

  // ========== MILESTONES/ACHIEVEMENTS ==========
  /// Congratulations message for achievements
  /// EN: "CONGRATULATIONS!" | ES: "¡FELICITACIONES!"
  final String congratulations;

  /// Prefix text before rank title
  /// EN: "You are now a" | ES: "Ahora eres un"
  final String youAreNowA;

  /// Button to continue after achievement
  /// EN: "Continue" | ES: "Continuar"
  final String continueButton;

  // Achievement Rank Titles (500 points)
  /// EN: "Pokémon Trainer" | ES: "Entrenador Pokémon"
  final String pokemonTrainer;

  // Achievement Rank Titles (1000 points)
  /// EN: "Gym Leader" | ES: "Líder de Gimnasio"
  final String gymLeader;

  // Achievement Rank Titles (2000 points)
  /// EN: "Elite Four Member" | ES: "Miembro del Alto Mando"
  final String eliteFourMember;

  // Achievement Rank Titles (3500 points)
  /// EN: "Champion" | ES: "Campeón"
  final String champion;

  // Achievement Rank Titles (5000 points)
  /// EN: "Legend" | ES: "Leyenda"
  final String legend;

  // ========== INPUT AND BUTTONS ==========
  /// Placeholder text for the guess input field
  /// EN: "Enter Pokémon name..." | ES: "Ingresa el nombre del Pokémon..."
  final String enterPokemonName;

  /// Submit guess button label
  /// EN: "Guess" | ES: "Adivinar"
  final String guessButton;

  /// Reveal answer button label
  /// EN: "Reveal" | ES: "Revelar"
  final String revealButton;

  /// Next Pokémon button label
  /// EN: "Next Pokémon" | ES: "Siguiente Pokémon"
  final String nextPokemon;

  // ========== FEEDBACK MESSAGES ==========
  /// Error message when user tries to submit empty guess
  /// EN: "Please enter a guess!" | ES: "¡Por favor ingresa una respuesta!"
  final String pleaseEnterGuess;

  /// First part of correct answer message
  /// EN: "Correct! It's" | ES: "¡Correcto! Es"
  final String correctPrefix;

  /// Second part of correct answer message (points awarded)
  /// EN: "+100 points" | ES: "+100 puntos"
  final String correctSuffix;

  /// Wrong answer message
  /// EN: "Wrong! Try again or reveal." | ES: "¡Incorrecto! Intenta de nuevo o revela."
  final String wrongTryAgain;

  /// Lives remaining message
  /// EN: "Lives left" | ES: "Vidas restantes"
  final String livesLeft;

  /// Game over message when out of lives
  /// EN: "Game Over! No lives left. Final Score" | ES: "Juego Terminado! Sin vidas. Puntuación Final"
  final String gameOverNoLives;

  /// Reveal message prefix
  /// EN: "The Pokémon is" | ES: "El Pokémon es"
  final String thePokemonIs;

  /// Message when revealing (no points given)
  /// EN: "No points awarded." | ES: "Sin puntos."
  final String noPointsAwarded;

  // ========== CONSTRUCTOR ==========
  /// Creates a QuizTranslations instance with all required text fields
  ///
  /// This is a const constructor which means:
  /// - Instances can be created at compile-time (more efficient)
  /// - All fields must be final
  /// - The object is immutable (can't be changed after creation)
  const QuizTranslations({
    required this.appTitle,
    required this.points,
    required this.lives,
    required this.score,
    required this.attempts,
    required this.gameOver,
    required this.finalScore,
    required this.correct,
    required this.restartGame,
    required this.congratulations,
    required this.youAreNowA,
    required this.continueButton,
    required this.pokemonTrainer,
    required this.gymLeader,
    required this.eliteFourMember,
    required this.champion,
    required this.legend,
    required this.enterPokemonName,
    required this.guessButton,
    required this.revealButton,
    required this.nextPokemon,
    required this.pleaseEnterGuess,
    required this.correctPrefix,
    required this.correctSuffix,
    required this.wrongTryAgain,
    required this.livesLeft,
    required this.gameOverNoLives,
    required this.thePokemonIs,
    required this.noPointsAwarded,
  });

  // ========== FACTORY CONSTRUCTORS FOR EACH LANGUAGE ==========

  /// Factory constructor that returns a QuizTranslations instance with ENGLISH text
  ///
  /// WHAT IS A FACTORY CONSTRUCTOR?
  /// - It's a constructor that doesn't always create a NEW instance
  /// - In this case, it returns a const instance (created at compile time)
  /// - More memory efficient than creating new objects every time
  ///
  /// HOW IT'S USED:
  /// Called by LanguageService when initializing the translations map
  /// QuizTranslations.english() creates the English translation set
  ///
  /// All strings below are the ENGLISH versions of the UI text
  factory QuizTranslations.english() {
    return const QuizTranslations(
      // App Bar
      appTitle: "Who's That Pokémon?", // Classic TV show phrase

      // Stats Labels
      points: 'Points',      // Total points earned
      lives: 'Lives',        // Remaining lives (hearts)
      score: 'Score',        // Correct guesses count
      attempts: 'Attempts',  // Total attempts count

      // Game Over Screen
      gameOver: 'GAME OVER',           // Game over header
      finalScore: 'Final Score',        // Final score label
      correct: 'Correct',               // Correct answers label
      restartGame: 'Restart Game',      // Restart button

      // Achievement Titles
      congratulations: 'CONGRATULATIONS!',  // Achievement dialog header
      youAreNowA: 'You are now a',          // Prefix for rank title
      continueButton: 'Continue',            // Continue button
      pokemonTrainer: 'Pokémon Trainer',     // Rank 1 (500 pts)
      gymLeader: 'Gym Leader',               // Rank 2 (1000 pts)
      eliteFourMember: 'Elite Four Member',  // Rank 3 (2000 pts)
      champion: 'Champion',                  // Rank 4 (3500 pts)
      legend: 'Legend',                      // Rank 5 (5000 pts)

      // Input & Buttons
      enterPokemonName: 'Enter Pokémon name...', // Text field placeholder
      guessButton: 'Guess',                       // Submit guess button
      revealButton: 'Reveal',                     // Show answer button
      nextPokemon: 'Next Pokémon',               // Next question button

      // Feedback Messages
      pleaseEnterGuess: 'Please enter a guess!',                    // Empty input error
      correctPrefix: 'Correct! It\'s',                              // "Correct! It's Pikachu!"
      correctSuffix: '+100 points',                                  // Points awarded
      wrongTryAgain: 'Wrong! Try again or reveal.',                 // Wrong answer message
      livesLeft: 'Lives left',                                      // Lives remaining
      gameOverNoLives: 'Game Over! No lives left. Final Score',     // Out of lives message
      thePokemonIs: 'The Pokémon is',                               // Reveal message
      noPointsAwarded: 'No points awarded.',                        // No points for reveal
    );
  }

  /// Factory constructor that returns a QuizTranslations instance with SPANISH text
  ///
  /// IDENTICAL STRUCTURE TO ENGLISH:
  /// - Same number of fields
  /// - Same field names
  /// - Only the VALUES are different (translated to Spanish)
  ///
  /// HOW IT'S USED:
  /// Called by LanguageService when initializing the translations map
  /// QuizTranslations.spanish() creates the Spanish translation set
  ///
  /// All strings below are the SPANISH versions of the UI text
  factory QuizTranslations.spanish() {
    return const QuizTranslations(
      // App Bar
      appTitle: '¿Quién es ese Pokémon?', // Spanish version of classic phrase

      // Stats Labels
      points: 'Puntos',      // Total points earned
      lives: 'Vidas',        // Remaining lives (hearts)
      score: 'Aciertos',     // Correct guesses count (literally "successes")
      attempts: 'Intentos',  // Total attempts count

      // Game Over Screen
      gameOver: 'JUEGO TERMINADO',     // Game over header
      finalScore: 'Puntuación Final',   // Final score label
      correct: 'Correcto',              // Correct answers label
      restartGame: 'Reiniciar Juego',   // Restart button

      // Achievement Titles
      congratulations: '¡FELICITACIONES!',      // Achievement dialog header
      youAreNowA: 'Ahora eres un',              // Prefix for rank title
      continueButton: 'Continuar',               // Continue button
      pokemonTrainer: 'Entrenador Pokémon',      // Rank 1 (500 pts)
      gymLeader: 'Líder de Gimnasio',           // Rank 2 (1000 pts)
      eliteFourMember: 'Miembro del Alto Mando', // Rank 3 (2000 pts) - "High Command Member"
      champion: 'Campeón',                       // Rank 4 (3500 pts)
      legend: 'Leyenda',                         // Rank 5 (5000 pts)

      // Input & Buttons
      enterPokemonName: 'Ingresa el nombre del Pokémon...', // Text field placeholder
      guessButton: 'Adivinar',                               // Submit guess button (to guess)
      revealButton: 'Revelar',                               // Show answer button (to reveal)
      nextPokemon: 'Siguiente Pokémon',                     // Next question button

      // Feedback Messages
      pleaseEnterGuess: '¡Por favor ingresa una respuesta!',      // Empty input error
      correctPrefix: '¡Correcto! Es',                             // "¡Correcto! Es Pikachu!"
      correctSuffix: '+100 puntos',                               // Points awarded
      wrongTryAgain: '¡Incorrecto! Intenta de nuevo o revela.',  // Wrong answer message
      livesLeft: 'Vidas restantes',                               // Lives remaining
      gameOverNoLives: 'Juego Terminado! Sin vidas. Puntuación Final', // Out of lives
      thePokemonIs: 'El Pokémon es',                              // Reveal message
      noPointsAwarded: 'Sin puntos.',                             // No points for reveal
    );
  }
}

// ============================================================================
// HOW TO ADD A NEW LANGUAGE:
// ============================================================================
// 1. Add a new field to QuizTranslations (e.g., final String newField;)
// 2. Add it to the constructor's required parameters
// 3. Add the English translation in QuizTranslations.english()
// 4. Add the Spanish translation in QuizTranslations.spanish()
// 5. Create a new factory for the new language (e.g., QuizTranslations.french())
// 6. Add the new language to the _translations map in LanguageService
// 7. Update toggleLanguage() if needed, or use setLanguage('fr') directly
// ============================================================================

