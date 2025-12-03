# 🌍 Multilanguage Support Guide - Pokémon Quiz

## 📋 Overview

The Pokémon Quiz app now supports **multiple languages** (English and Spanish), allowing users to switch between languages in real-time while playing the game.

## 🏗️ Architecture

### Key Components

1. **LanguageService** (`lib/presentation/services/language_service.dart`)
   - Singleton service that manages the current language state
   - Extends `ChangeNotifier` to notify widgets when language changes
   - Provides access to translations based on current language

2. **QuizTranslations** (in same file)
   - Immutable data class containing all translatable strings
   - Factory constructors for each language (English, Spanish)
   - Organized by UI sections (AppBar, Stats, Game Over, etc.)

3. **PokemonQuizPage** (`lib/presentation/pages/PokemonQuizPage.dart`)
   - Main quiz screen that uses translations
   - Language toggle button in the AppBar
   - Updates UI automatically when language changes

## 🔄 How It Works

### 1. Singleton Pattern

```dart
// Only ONE instance exists throughout the app
LanguageService.instance
```

**Benefits:**
- Consistent state across all screens
- No duplicate services in memory
- Easy access from anywhere in the app

### 2. ChangeNotifier Pattern

```dart
class LanguageService extends ChangeNotifier {
  void toggleLanguage() {
    _currentLanguage = _currentLanguage == 'en' ? 'es' : 'en';
    notifyListeners(); // 🔔 Triggers UI rebuild!
  }
}
```

**How it works:**
1. When language changes, `notifyListeners()` is called
2. All widgets listening to LanguageService are notified
3. Widgets rebuild with new translations automatically
4. User sees updated text instantly

### 3. Translation Retrieval

```dart
// In any widget:
final translations = LanguageService.instance.translations;

// Use in UI:
Text(translations.appTitle) // Shows correct language automatically
```

**Flow:**
1. `translations` getter returns the QuizTranslations object for current language
2. Access any field (e.g., `appTitle`, `guessButton`, etc.)
3. Correct language string is displayed

## 🎯 Usage Examples

### Getting Translations in a Widget

```dart
@override
Widget build(BuildContext context) {
  // Get translations for current language
  final translations = LanguageService.instance.translations;
  
  return Text(
    translations.appTitle,  // "Who's That Pokémon?" or "¿Quién es ese Pokémon?"
    style: TextStyle(fontSize: 20),
  );
}
```

### Switching Languages

```dart
// Toggle between English and Spanish
LanguageService.instance.toggleLanguage();

// Or set specific language
LanguageService.instance.setLanguage('es'); // Spanish
LanguageService.instance.setLanguage('en'); // English
```

### Getting Current Language

```dart
final currentLang = LanguageService.instance.currentLanguage;
// Returns: 'en' or 'es'

if (currentLang == 'en') {
  print('Currently in English');
}
```

## 📦 Translation Structure

All translations are organized into logical sections:

### AppBar Section
- `appTitle` - Main app title

### Stats Section
- `points` - Points label
- `lives` - Lives label
- `score` - Score label
- `attempts` - Attempts label

### Game Over Screen
- `gameOver` - Game over header
- `finalScore` - Final score label
- `correct` - Correct answers label
- `restartGame` - Restart button text

### Milestones/Achievements
- `congratulations` - Achievement dialog header
- `youAreNowA` - Prefix before rank title
- `continueButton` - Continue button
- `pokemonTrainer` - Rank 1 (500 pts)
- `gymLeader` - Rank 2 (1000 pts)
- `eliteFourMember` - Rank 3 (2000 pts)
- `champion` - Rank 4 (3500 pts)
- `legend` - Rank 5 (5000 pts)

### Input and Buttons
- `enterPokemonName` - Text field placeholder
- `guessButton` - Guess button label
- `revealButton` - Reveal button label
- `nextPokemon` - Next Pokémon button label

### Feedback Messages
- `pleaseEnterGuess` - Empty input error
- `correctPrefix` - First part of correct message
- `correctSuffix` - Points awarded text
- `wrongTryAgain` - Wrong answer message
- `livesLeft` - Lives remaining message
- `gameOverNoLives` - Out of lives message
- `thePokemonIs` - Reveal message prefix
- `noPointsAwarded` - No points message

## ➕ Adding a New Language

To add a new language (e.g., French), follow these steps:

### Step 1: Create Factory Constructor

```dart
factory QuizTranslations.french() {
  return const QuizTranslations(
    appTitle: 'Qui est ce Pokémon?',
    points: 'Points',
    lives: 'Vies',
    score: 'Score',
    attempts: 'Tentatives',
    // ... add all other fields
  );
}
```

### Step 2: Add to LanguageService

```dart
final Map<String, QuizTranslations> _translations = {
  'en': QuizTranslations.english(),
  'es': QuizTranslations.spanish(),
  'fr': QuizTranslations.french(), // Add this line
};
```

### Step 3: Update Toggle Logic (Optional)

If you want to support more than 2 languages, replace `toggleLanguage()`:

```dart
void nextLanguage() {
  final languages = ['en', 'es', 'fr'];
  final currentIndex = languages.indexOf(_currentLanguage);
  final nextIndex = (currentIndex + 1) % languages.length;
  _currentLanguage = languages[nextIndex];
  notifyListeners();
}
```

### Step 4: Update Language Toggle Button

```dart
IconButton(
  icon: Text(currentLang.toUpperCase()),
  onPressed: () {
    setState(() {
      LanguageService.instance.nextLanguage(); // Use new method
    });
  },
)
```

## 🎨 Language Toggle Button

The language toggle button in the AppBar shows the current language code and allows users to switch languages:

```dart
IconButton(
  icon: Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.yellow,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.blue, width: 2),
    ),
    child: Text(
      currentLang.toUpperCase(), // Shows "EN" or "ES"
      style: GoogleFonts.pressStart2p(
        fontSize: 10,
        color: Colors.red,
      ),
    ),
  ),
  onPressed: () {
    setState(() {
      LanguageService.instance.toggleLanguage();
    });
  },
)
```

## 🔍 How Translation Lookup Works

### Under the Hood

```
User clicks toggle button
         ↓
toggleLanguage() is called
         ↓
_currentLanguage changes ('en' → 'es')
         ↓
notifyListeners() is called
         ↓
All listening widgets are notified
         ↓
Widgets call build() method again
         ↓
translations getter returns new language set
         ↓
UI displays new language strings
```

### Example Flow

```dart
// Initial state
_currentLanguage = 'en'
translations.appTitle → "Who's That Pokémon?"

// User clicks toggle button
toggleLanguage()

// New state
_currentLanguage = 'es'
translations.appTitle → "¿Quién es ese Pokémon?"

// UI automatically updates! ✨
```

## 🎯 Best Practices

### 1. Always Use Translations
❌ **Bad:**
```dart
Text('Guess') // Hardcoded string
```

✅ **Good:**
```dart
Text(translations.guessButton) // Translatable
```

### 2. Get Translations Once Per Build
❌ **Bad:**
```dart
Text(LanguageService.instance.translations.appTitle)
Text(LanguageService.instance.translations.points)
Text(LanguageService.instance.translations.lives)
```

✅ **Good:**
```dart
final translations = LanguageService.instance.translations;
Text(translations.appTitle)
Text(translations.points)
Text(translations.lives)
```

### 3. Wrap setState When Changing Language
❌ **Bad:**
```dart
onPressed: () {
  LanguageService.instance.toggleLanguage();
}
```

✅ **Good:**
```dart
onPressed: () {
  setState(() {
    LanguageService.instance.toggleLanguage();
  });
}
```

### 4. Keep Translations Organized
- Group related strings together
- Add comments explaining context
- Use descriptive field names

## 🧪 Testing Translations

To test that all translations are working:

1. **Visual Test:** Click through all screens in both languages
2. **Check for missing translations:** All text should change
3. **Verify special characters:** Spanish uses ¿ ¡ á é í ó ú ñ
4. **Test dynamic text:** Check that variables are inserted correctly

## 📝 Translation Checklist

When adding new UI text:

- [ ] Add field to `QuizTranslations` class
- [ ] Add to constructor's required parameters
- [ ] Add English translation in `QuizTranslations.english()`
- [ ] Add Spanish translation in `QuizTranslations.spanish()`
- [ ] Add comment explaining the field
- [ ] Test in both languages
- [ ] Verify text fits in UI layout

## 🌟 Supported Languages

| Language | Code | Status |
|----------|------|--------|
| English  | `en` | ✅ Fully supported |
| Spanish  | `es` | ✅ Fully supported |
| French   | `fr` | ⏳ Not yet implemented |
| German   | `de` | ⏳ Not yet implemented |
| Japanese | `ja` | ⏳ Not yet implemented |

## 🔧 Troubleshooting

### Translations not updating?
1. Make sure you're calling `setState()` when toggling
2. Verify `notifyListeners()` is called in LanguageService
3. Check that you're using `translations.field` not hardcoded strings

### Missing translation error?
1. Ensure the field exists in QuizTranslations
2. Verify it's added to all factory constructors
3. Check for typos in field names

### Language not persisting?
- Currently, language resets on app restart
- To persist: Add SharedPreferences integration
- Save language on change, load on app startup

## 🚀 Future Enhancements

Potential improvements to the multilanguage system:

1. **Persistent Language Selection**
   - Save user's preferred language using SharedPreferences
   - Load saved language on app startup

2. **System Language Detection**
   - Auto-detect device language
   - Default to system language if supported

3. **More Languages**
   - French, German, Japanese, Portuguese, etc.
   - Community translations

4. **RTL Support**
   - Right-to-left languages (Arabic, Hebrew)
   - Adjust layout direction

5. **Language-Specific Fonts**
   - Different fonts for different languages
   - Better character support

## 📚 Resources

- [Flutter Internationalization](https://flutter.dev/docs/development/accessibility-and-localization/internationalization)
- [ChangeNotifier Documentation](https://api.flutter.dev/flutter/foundation/ChangeNotifier-class.html)
- [Singleton Pattern](https://dart.dev/guides/language/language-tour#factory-constructors)

---

**Made with ❤️ for the Pokémon Quiz App**

