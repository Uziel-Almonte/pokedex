# 🎮 Pokédex App - Complete Setup Guide

## 📋 Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Project Structure](#project-structure)
- [Key Features Explained](#key-features-explained)
- [Quiz Game System](#quiz-game-system)
- [Favorites System](#favorites-system)
- [API Usage](#api-usage)

---

## 🌟 Overview

This is a comprehensive Flutter Pokédex application that allows users to browse, search, and learn about Pokémon. The app features a quiz game, favorites management, detailed Pokémon information, and trading card viewing.

---

## ✨ Features

### 🏠 Home Page
- **Browse all Pokémon** (1-1010) with pagination
- **Search by name** with real-time filtering
- **Grid view** with Pokémon sprites and basic info
- **Navigation** to detailed Pokémon pages
- **Favorites indicator** (heart icon on cards)
- **Theme toggle** (light/dark mode)

### 📖 Detail Page
- **Comprehensive Pokémon information**:
  - Official artwork with favorite button overlay
  - Base stats with visual progress bars
  - Abilities with descriptions
  - Move list with levels and methods
  - Evolution chain with sprites
  - Physical stats (height, weight, gender rate, egg groups)
  - Pokédex entry and region information
  - **Pokemon Forms/Variants** - Dropdown selector for regional forms (Alola, Galar), Mega evolutions, and special forms
  - **Shiny toggle** - Switch between normal and shiny sprites
  - **Type matchups** - Shows weaknesses, resistances, and immunities
- **Trading cards viewer** (via TCGDex API)
- **Real-time favorite syncing** across all pages

### ❤️ Favorites Page
- **Dedicated favorites list** with all favorited Pokémon
- **Quick access** to favorite Pokémon details
- **Real-time updates** when favorites are added/removed
- **Empty state** with helpful message when no favorites

### 🎯 Quiz Game - "Who's That Pokémon?"
- **Points System**: Earn 100 points per correct guess
- **Lives System**: Start with 3 lives, lose 1 per wrong answer
- **Achievement Milestones**:
  - 500 points → 🎓 **Pokémon Trainer**
  - 1000 points → 🏆 **Gym Leader**
  - 2000 points → 👑 **Elite Four Member**
  - 3500 points → 🌟 **Champion**
  - 5000+ points → ⭐✨ **Legend**
- **Silhouette effect** for guessing challenge
- **Reveal option** (no points, preserves lives)
- **Game over screen** with restart functionality
- **Real-time stats display** (points, lives, score, attempts)

---

## 🔧 Prerequisites

Before running this project, ensure you have:

1. **Flutter SDK** (3.0.0 or higher)
   - Download from: https://flutter.dev/docs/get-started/install
   
2. **Android Studio** or **VS Code** with Flutter extensions

3. **Android Emulator** or **Physical Device** for testing

4. **Internet Connection** (for API calls and image loading)

---

## 📥 Installation

### Step 1: Clone the Repository
```bash
git clone <repository-url>
cd pokedex
```

### Step 2: Install Dependencies
```bash
flutter pub get
```

This will install all required packages:
- `graphql_flutter` - GraphQL API client
- `hive_flutter` - Local storage for favorites
- `google_fonts` - Retro fonts (Press Start 2P)
- `provider` - State management
- `http` - HTTP requests for TCG API
- `connectivity_plus` - Network status checking

### Step 3: Initialize Hive Database
The app automatically initializes Hive on first launch. No manual setup required.

### Step 4: Run the App
```bash
flutter run
```

---

## 📁 Project Structure

```
lib/
├── data/
│   ├── favorites_service.dart    # Favorites management with Hive
│   ├── graphql.dart               # GraphQL client configuration
│   ├── queries.dart               # GraphQL queries (fetchPokemon, search, etc.)
│   └── tcg_service.dart           # Trading card API service
├── domain/
│   ├── home.dart                  # Home page widget
│   ├── main.dart                  # App entry point
│   └── models/
│       └── Pokemon.dart           # Pokemon data model
└── presentation/
    ├── app_theme.dart             # Theme definitions (light/dark)
    ├── theme_provider.dart        # Theme state management
    ├── pages/
    │   ├── HomePageState.dart     # Home page implementation
    │   ├── DetailPageState.dart   # Detail page implementation
    │   ├── FavoritesPage.dart     # Favorites list page
    │   └── PokemonQuizPage.dart   # Quiz game implementation
    └── page_necessities/
        ├── detail_page/           # Reusable detail page components
        └── home_page/             # Reusable home page components
```

---

## 🎮 Key Features Explained

### 🔍 Search Functionality
- **Debounced search** (500ms delay) to reduce API calls
- **Case-insensitive** matching
- **Real-time results** as you type
- **Clear button** to reset search

### 🎨 Theme System
- **Light Mode**: White backgrounds, dark text
- **Dark Mode**: Dark grey backgrounds, light text
- **Toggle switch** in app bar
- **Persistent theme** across all pages using Provider

### 📡 API Integration
- **GraphQL API**: PokeAPI GraphQL for Pokémon data
  - Endpoint: `https://beta.pokeapi.co/graphql/v1beta`
- **REST API**: TCGDex for trading cards
  - Endpoint: `https://api.tcgdex.net/v2/en`

### 🔄 Pokemon Forms/Variants System

#### What Are Forms?
Pokemon can have different forms/variants such as:
- **Regional Forms**: Alola, Galar, Hisui, Paldea variants
- **Mega Evolutions**: Mega X, Mega Y, etc.
- **Special Forms**: Deoxys forms, Rotom forms, etc.
- **Gigantamax Forms**: Special G-Max variants

#### How It Works
1. **Navigate to a Pokemon** with multiple forms (e.g., Raichu, Charizard, Meowth)
2. **Dropdown appears** below the Pokemon's types
3. **Select a form** from the dropdown
4. **Entire page updates** with the selected form's data:
   - Image changes to the form's sprite
   - Types may change (e.g., Alola Raichu is Electric/Psychic)
   - Stats may differ
   - Abilities may be different
   - Height/weight may vary

#### Examples:
- **Raichu**: Normal (Electric) → Alola Form (Electric/Psychic)
- **Meowth**: Normal → Alola Form (Dark) → Galar Form (Steel)
- **Charizard**: Normal → Mega X (Fire/Dragon) → Mega Y (Fire/Flying)
- **Vulpix**: Normal (Fire) → Alola Form (Ice)
- **Deoxys**: Normal → Attack → Defense → Speed forms

#### Technical Details:
```dart
// Forms are fetched from GraphQL:
fetchPokemonForms(speciesId, client)

// Returns list of forms with:
{
  'id': pokemonId,
  'name': 'raichu-alola',
  'formName': 'Alola Form',
  'isDefault': false,
  'isMega': false,
}

// Dropdown triggers rebuild with new Pokemon ID
setState(() {
  _selectedFormId = newFormId;
});
```

---

## 🎯 Quiz Game System

### How It Works

#### 1. **Points System**
```dart
// Correct guess: +100 points
_points += 100;

// Points determine your rank:
// 0-499: Beginner
// 500-999: Pokémon Trainer
// 1000-1999: Gym Leader
// 2000-3499: Elite Four Member
// 3500-4999: Champion
// 5000+: Legend
```

#### 2. **Lives System**
```dart
// Start with 3 lives
int _lives = 3;

// Wrong guess: -1 life
_lives--;

// Game over when lives = 0
if (_lives <= 0) {
  // Show game over screen
}
```

#### 3. **Achievement Milestones**
When you reach certain point thresholds, a celebration dialog appears:
- Beautiful gradient background (red to orange)
- Large emoji for visual impact
- Rank title in retro font
- "Continue" button to keep playing

The app tracks which milestones you've already achieved to prevent showing the same one multiple times.

#### 4. **Game Flow**
1. Random Pokémon loads as **black silhouette**
2. Player types Pokémon name and clicks **"Guess"**
3. **If correct**:
   - Award 100 points
   - Reveal Pokémon in full color
   - Check for milestone achievements
   - Show "Next Pokémon" button
4. **If wrong**:
   - Lose 1 life
   - Show feedback message
   - Can retry same Pokémon or reveal
5. **If revealed**:
   - Show answer (no points)
   - Lives preserved
   - Show "Next Pokémon" button
6. **If lives = 0**:
   - Game over screen
   - Show final score
   - "Restart Game" button

#### 5. **Strategic Elements**
- **Risk vs Reward**: Guessing earns points but costs lives if wrong
- **Safe Option**: Revealing preserves lives but awards no points
- **Multiple Attempts**: Can retry same Pokémon until correct or out of lives
- **Score Optimization**: Balance between accuracy and speed

---

## ❤️ Favorites System

### How It Works

#### 1. **Storage**
Favorites are stored locally using **Hive**, a fast NoSQL database:
```dart
// Initialize Hive
await Hive.initFlutter();
await Hive.openBox<int>('favorites');

// Add favorite
box.add(pokemonId);

// Remove favorite
box.deleteAt(index);
```

#### 2. **Real-Time Sync**
The app uses **StreamBuilder** to watch for changes:
```dart
StreamBuilder<BoxEvent>(
  stream: _favoritesService.watchFavorites(),
  builder: (context, snapshot) {
    final isFavorite = _favoritesService.isFavorite(pokemonId);
    // Update UI immediately
  },
)
```

#### 3. **Cross-Page Updates**
When you favorite a Pokémon:
1. Hive database updates
2. Stream emits event
3. All StreamBuilders rebuild
4. UI updates across **all pages** simultaneously

#### 4. **UI Indicators**
- **Home Page**: Heart icon on Pokémon cards
- **Detail Page**: Heart button overlay on image
- **Favorites Page**: Full list of favorited Pokémon

---

## 🔌 API Usage

### GraphQL Queries

#### Fetch Single Pokémon
```graphql
query GetPokemon($id: Int!) {
  pokemon_v2_pokemon(where: {id: {_eq: $id}}) {
    id
    name
    height
    weight
    pokemon_v2_pokemonstats {
      base_stat
      pokemon_v2_stat {
        name
      }
    }
    # ... more fields
  }
}
```

#### Search Pokémon by Name
```graphql
query SearchPokemon($name: String!) {
  pokemon_v2_pokemon(where: {name: {_ilike: $name}}, limit: 1) {
    # ... same fields as above
  }
}
```

### TCG API

#### Get Pokémon Cards
```
GET https://api.tcgdex.net/v2/en/cards?name={pokemonName}
```

Returns array of trading cards with images, sets, and details.

---

## 🐛 Troubleshooting

### Common Issues

1. **"BoxEvent isn't a type" error**
   - Make sure `hive_flutter` is imported correctly
   - Run `flutter pub get` to ensure all dependencies are installed

2. **Images not loading**
   - Check internet connection
   - Verify PokeAPI sprites URL is accessible
   - Try clearing Flutter cache: `flutter clean`

3. **GraphQL errors**
   - Ensure GraphQL endpoint is reachable
   - Check query syntax in `queries.dart`
   - Verify Pokemon ID is valid (1-1010)

4. **Favorites not persisting**
   - Hive box may not be initialized
   - Check `FavoritesService.init()` is called in main.dart
   - Clear app data and restart

---

## 🚀 Future Enhancements

Potential features to add:
- [ ] Offline mode with cached data
- [ ] More quiz modes (type guessing, stats comparison)
- [ ] Leaderboard for quiz scores
- [ ] Team builder feature
- [ ] Battle simulator
- [ ] Pokemon comparison tool
- [ ] Advanced search filters (by type, generation, ability)

---

## 📝 License

This project is for educational purposes. Pokémon and related assets are © Nintendo, Game Freak, and The Pokémon Company.

---

## 🤝 Contributing

Feel free to submit issues or pull requests to improve the app!

---

## 📞 Support

If you encounter any issues or have questions, please open an issue on the repository.

---

**Happy Pokémon hunting! 🎉**
