# Pokedex Flutter App Setup

This document details the setup and implementation steps for the Pokedex app, including all major functions, classes, and features added during development.

## 1. Project Initialization
- Created a new Flutter project named `pokedex`.
- Set up the environment in `pubspec.yaml`:
  - Dart SDK version: ^3.9.2
  - Flutter version: default for project

## 2. Dependencies
- Added the following dependencies in `pubspec.yaml`:
  - `graphql_flutter: ^5.0.1` for GraphQL API integration with Hive caching
  - `http: ^1.1.0` for HTTP requests (TCG card fetching)
  - `google_fonts: ^6.3.2` for custom Google Fonts styling (Press Start 2P retro font)
  - `pie_chart: ^5.4.0` for gender ratio pie chart visualizations
  - `flutter_bloc: ^9.1.1` for BLoC state management pattern
  - `equatable: ^2.0.0` for value equality in BLoC states
  - `cupertino_icons: ^1.0.8` for iOS-style icons
  - `flutter_lints: ^5.0.0` for recommended linting rules
  - `provider: ^6.1.5+1` for theme state management
  - `framework: ^1.0.3` for additional framework utilities
  - `hive: ^2.2.3` for lightweight NoSQL database
  - `hive_flutter: ^1.1.0` for Flutter-specific Hive integration
  - `path_provider: ^2.1.1` for finding storage directory paths

## 3. Project Architecture (3-Layer Pattern)

The app follows a clean architecture with three distinct layers:

### Data Layer (`lib/data/`)
Handles all external data sources and API communication.

- **graphql.dart**: `GraphQLService` singleton class
  - Manages GraphQL client lifecycle
  - Initializes Hive for persistent caching
  - Provides global access to GraphQL client
  - Methods: `init()`, `query()`, `mutate()`

- **queries.dart**: Contains all GraphQL query functions
  - `fetchPokemonList()`: Fetches paginated list with filters (type, generation, ability)
  - `fetchPokemon()`: Fetches single Pokémon with complete details (stats, abilities, moves, evolution chain)
  - `fetchEvolutionChain()`: Fetches evolution chain data for a species
  - All functions return structured Maps ready for model conversion

- **tcg_service.dart**: ✨ New service for TCG card fetching (proper data layer)
  - `TCGService` class with static methods
  - Base URL: `https://api.tcgdex.net/v2/en`
  - `searchCardsByPokemon()`: Fetches all cards for a Pokémon
  - Iterates through all TCG sets (~150+ API calls)
  - Returns comprehensive list of card objects
  - Error handling for individual set failures

- **favorites_service.dart**: ❤️ New service for managing favorite Pokémon
  - `FavoritesService` singleton class
  - Manages favorites using Hive local storage
  - Methods: `init()`, `addFavorite()`, `removeFavorite()`, `toggleFavorite()`, `isFavorite()`, `getAllFavorites()`, `count`, `clearAll()`, `watchFavorites()`

### Domain Layer (`lib/domain/`)
Contains business logic, models, and state management.

- **models/Pokemon.dart**: Core data model
  - `Pokemon` class with all Pokémon properties
  - Factory constructor `fromGraphQL()` for API data mapping
  - Computed properties: `formattedHeight`, `formattedWeight`, `typesString`
  - Handles stats aggregation and total calculation

- **state_management/**:
  - **bloc_state_home.dart**: BLoC pattern for home page
    - Events: `LoadPokemonList`, `LoadMorePokemon`, `SearchPokemon`, `UpdateFilters`
    - States: `HomeInitial`, `HomeLoading`, `HomeLoaded`, `HomeError`
    - `HomeBloc`: Manages Pokémon list, search, filters, and pagination
  - **bloc_state_main.dart**: BLoC pattern for main/detail page (if needed)

- **main.dart**: Main app entry point
  - Initializes GraphQLService
  - Provides GraphQL and theme state to widget tree
  - Defines `MyApp` root widget with theme configuration

- **home.dart**: Home page setup and routing
  - `PokeHomePage` widget definition
  - Entry point setup alternative

### Presentation Layer (`lib/presentation/`)
Contains all UI components, pages, and styling.

- **app_theme.dart**: Theme definitions
  - `AppTheme` class with static `lightTheme` and `darkTheme`
  - Red color scheme (Pokémon branding)
  - Material 3 design principles

- **theme_provider.dart**: Theme state management
  - `AppThemeState` extends `ChangeNotifier`
  - `toggleTheme()` method for light/dark mode switching
  - Persists theme preference

- **pages/**:
  - **HomePageState.dart**: Home page implementation
    - Displays Pokémon grid/list
    - Search bar with 500ms debounce
    - Filter dialog (type, generation, ability)
    - Pagination controls (prev/next buttons)
    - Uses BLoC for state management
    - Navigation to detail page on card tap
  
  - **DetailPageState.dart**: Detail page implementation
    - Displays comprehensive Pokémon information
    - All detail cards integration
    - Previous/next navigation buttons
    - TCG cards viewer integration
    - Official artwork display

  - **PokemonQuizPage.dart**: ✨ NEW: "Who's That Pokémon?" quiz game
    - Random Pokémon selection (1-1010)
    - Silhouette effect with ColorFiltered matrix
    - Score and attempts tracking
    - Case-insensitive validation
    - Retro Press Start 2P styling

  - **FavoritesPage.dart**: ❤️ NEW: Favorites page
    - Displays all favorited Pokémon in a grid
    - Real-time updates when favorites change
    - Empty state message when no favorites
    - Navigation to detail page on card tap
    - Quick remove from favorites

- **page_necessities/**:
  - **home_page/**:
    - **PokeSelect.dart**: Reusable Pokémon card widget
      - Dynamic type-based gradient backgrounds
      - Shows sprite, name, types, and Pokédex number
      - Official type color palette (18 types)
      - Handles single-type and dual-type gradients

    - **showFilterDialog.dart**: Filter dialog component
      - Type filter chips (18 types, single selection)
      - Generation filter chips (Gen 1-9, single selection)
      - Ability search text field
      - Clear all and apply buttons

  - **detail_page/**:
    - **StatsCard.dart**: Base stats visualization
      - Shows HP, Attack, Defense, Special Attack, Special Defense, Speed
      - Color-coded progress bars for each stat
      - Displays total stats
      - Retro Press Start 2P font styling

    - **PokedexEntryCard.dart**: ✨ NEW: Pokédex entry and region information
      - Displays official Pokédex flavor text (game description)
      - Shows region of origin (Kanto, Johto, Hoenn, Sinnoh, etc.)
      - Shows generation introduced (Generation I-IX)
      - Formats region names (capitalize first letter)
      - Formats generation names ("generation-i" → "Generation I")
      - Blue color scheme for region (globe icon)
      - Purple color scheme for generation (history icon)
      - Gracefully handles missing data with placeholder text
      - Full dark/light mode support

    - **AbilitiesCard.dart**: Abilities display
      - Lists all abilities (normal and hidden)
      - Highlights hidden abilities with orange background
      - Shows ability name and isHidden flag

    - **MovesCard.dart**: Moves list
      - Groups moves by level learned
      - Shows move name, power, accuracy, PP, and type
      - Sortable and filterable (level-up moves currently)

    - **EvolutionChainCard.dart**: Evolution chain viewer
      - Displays complete evolution tree
      - Shows evolution triggers (level, stone, trade, friendship, time of day)
      - Pre-evolution → Stage 1 → Stage 2 visualization
      - Handles branching evolutions
      - Clickable evolution sprites to navigate
      - Shows "No evoluciona" message for single-stage Pokémon

    - **PhysicalStatsCard.dart**: Physical characteristics
      - Height (converted to feet/inches)
      - Weight (converted to pounds)
      - Gender ratio pie chart (using pie_chart package)
      - Egg groups display
      - Color-coded male/female/genderless visualization

    - **showPokemonCards.dart**: TCG cards UI
      - Modal bottom sheet with draggable scroll
      - 2-column grid of card images
      - High-quality card image display
      - Tap to view full-size with zoom (InteractiveViewer)
      - Shows card name, set name
      - Loading and error states

## 4. GraphQL Integration
- **Endpoint**: `https://beta.pokeapi.co/graphql/v1beta`
- **Client Setup**: Initialized with Hive cache in `GraphQLService`
- **Provider Pattern**: `GraphQLProvider` wraps app to provide client globally
- **Queries**: All queries defined in `data/queries.dart`
- **Caching**: Hive provides persistent cache (survives app restarts)

## 5. State Management (BLoC Pattern)

### Home Page BLoC
- **Events**:
  - `LoadPokemonList`: Loads initial list with optional filters
  - `LoadMorePokemon`: Pagination event
  - `SearchPokemon`: Debounced search by name
  - `UpdateFilters`: Apply type/generation/ability filters

- **States**:
  - `HomeInitial`: Initial state before loading
  - `HomeLoading`: Loading indicator during fetch
  - `HomeLoaded`: Successfully loaded with Pokémon list
  - `HomeError`: Error state with message

### Theme State Management
- Uses `Provider` with `ChangeNotifier`
- `AppThemeState` manages dark/light mode preference
- Theme toggle switch in AppBar
- Persists across app lifecycle

## 6. Search Functionality
- **Search Bar** (TextField):
  - Search icon prefix
  - Clear button (X icon) when text entered
  - Rounded pill-shaped design with red/blue borders
  - Theme-aware background

- **Debounce Implementation**:
  - 500ms delay after user stops typing
  - Prevents excessive API calls
  - Uses `Timer` to manage delay
  - Cancels previous timer on new input

## 7. Filter System
- **Filter Button**: Red circular button with filter icon
- **Filter Dialog** (`showFilterDialog()`):
  - **Type Filter**: 18 chips for all Pokémon types (single selection)
  - **Generation Filter**: 9 chips for Gen 1-9 (single selection)
  - **Ability Filter**: Text input with case-insensitive search
  - **Actions**: "Clear All" removes filters, "Apply" closes dialog

- **State Variables**:
  - `_selectedType`: Currently selected type filter
  - `_selectedGeneration`: Currently selected generation (1-9)
  - `_selectedAbility`: Ability search term

- **Implementation**:
  - Dynamically builds GraphQL WHERE clause
  - Combines multiple filters with AND logic
  - Returns up to 50 results per page

## 8. Gradient System for Pokémon Types
- **Type Color Map** (18 official colors):
  - Fire: Orange/Red, Water: Blue, Grass: Green, Electric: Yellow
  - Psychic: Pink, Dragon: Purple, Ghost: Dark Purple, etc.

- **Gradient Generation** (`_getTypeGradient()`):
  - **Single-type**: Same color gradient with opacity variation (70%-100%-90%)
  - **Dual-type**: Diagonal gradient transitioning between both colors
  - **Fallback**: Neutral grey for unknown types
  - Diagonal direction: top-left to bottom-right

## 9. Navigation Structure
- **Home Page → Detail Page**: Tap Pokémon card to navigate
- **Detail Page Navigation**:
  - Previous/Next buttons to browse adjacent Pokémon
  - Back button returns to list
  - Accepts `initialPokemonId` parameter

## 10. Theme System
- **Light Theme**:
  - White background
  - Red primary color (Pokémon brand)
  - Dark text for readability

- **Dark Theme**:
  - Dark grey background (#212121)
  - Red accent color
  - Light text for contrast
  - Card backgrounds: Grey[800]

- **Toggle Switch**:
  - Located in AppBar actions
  - Sun/moon icons for current mode
  - Switches between themes instantly

## 11. UI Design & Styling

### Typography
- **Press Start 2P** (Google Fonts): Retro 8-bit style for titles and headers
- **Roboto**: Modern readable font for body text

### AppBar
- Red background (`Colors.red`)
- "POKEDEX" title in Press Start 2P (20px, yellow with blue shadow)
- Theme toggle switch in actions

### Pokémon Cards (List)
- Type-based gradient backgrounds
- Rounded corners (15px radius)
- Box shadows for depth
- White text with black shadows for readability
- Shows sprite, name, types, Pokédex number

### Detail Page Cards
- Consistent styling across all cards
- 16px margins, 16px padding
- 15px border radius
- Theme-aware backgrounds (white/grey[800])
- Subtle box shadows

## 12. Trading Card Game (TCG) Integration

### TCGService
- Static methods for TCG data fetching
- API: `https://api.tcgdex.net/v2/en`
- `searchCardsByPokemon()`: Comprehensive card search
- Iterates through all sets (10-30 seconds)
- Returns card objects with image URLs, rarity, HP, types

### TCG Cards Display
- "VIEW CARDS" button below stats
- Modal bottom sheet with draggable scroll
- 2-column grid of high-quality card images
- Tap card → Full-screen view with zoom
- Shows card count and loading states

## 13. Data Models

### Pokemon Class
- Properties: id, name, types, height, weight, stats, abilities, moves, etc.
- `fromGraphQL()` factory constructor for API mapping
- Computed properties for formatted values
- Stats aggregation and total calculation

## 14. Error Handling
- **GraphQL Errors**: Try-catch blocks, console logging
- **TCG API Errors**: Individual failure handling, continues on error
- **Image Loading**: Error icons for failed loads, loading indicators
- **Empty States**: "No Pokémon found", "No cards found" messages

## 15. Performance Considerations
- **Debounced Search**: Reduces API calls
- **Pagination**: 50 items per page with offset
- **Lazy Loading**: Images loaded on demand
- **Async Operations**: Non-blocking UI updates
- **Caching**: Hive cache for GraphQL responses

## 16. File Structure (Updated November 2025)
```
lib/
├── data/                           # Data Layer
│   ├── graphql.dart                # GraphQL service singleton
│   ├── queries.dart                # All GraphQL query functions
│   ├── tcg_service.dart            # ✨ NEW: TCG API service (TCGDex integration)
│   └── favorites_service.dart      # ❤️ NEW: Favorites service (Hive integration)
│
├── domain/                         # Domain Layer
│   ├── main.dart                   # Main app entry point
│   ├── home.dart                   # Home page setup
│   ├── models/
│   │   └── Pokemon.dart            # Pokemon data model
│   └── state_management/
│       ├── bloc_state_home.dart    # Home page BLoC
│       └── bloc_state_main.dart    # Main/detail page BLoC
│
├── presentation/                   # Presentation Layer
│   ├── app_theme.dart              # Theme definitions
│   ├── theme_provider.dart         # Theme state management (ChangeNotifier)
│   ├── pages/
│   │   ├── HomePageState.dart      # Home page implementation
│   │   ├── DetailPageState.dart    # Detail page implementation
│   │   ├── PokemonQuizPage.dart    # ✨ NEW: "Who's That Pokémon?" quiz game
│   │   └── FavoritesPage.dart      # ❤️ NEW: Favorites page
│   └── page_necessities/
│       ├── home_page/
│       │   ├── PokeSelect.dart          # Pokémon card widget
│       │   └── showFilterDialog.dart    # Filter dialog
│       └── detail_page/
│           ├── StatsCard.dart           # Base stats card
│           ├── PokedexEntryCard.dart      # Pokédex entry and region information
│           ├── AbilitiesCard.dart       # Abilities card
│           ├── MovesCard.dart           # Moves card
│           ├── EvolutionChainCard.dart  # Evolution chain card
│           ├── PhysicalStatsCard.dart   # Physical stats & gender
│           ├── tcgCards.dart            # ⚠️ DEPRECATED: Empty file (TCGService moved to data/)
│           └── showPokemonCards.dart    # TCG cards UI modal
│
├── images/                         # Image assets
│   └── empty_pokeball.png
│
└── test/                           # Test files
    └── widget_test.dart
```

### Key Changes in File Structure:
- ✨ **lib/data/tcg_service.dart**: New service for TCG card fetching (proper data layer)
- ✨ **lib/presentation/pages/PokemonQuizPage.dart**: New quiz game page
- ❤️ **lib/presentation/pages/FavoritesPage.dart**: New favorites page
- ⚠️ **lib/presentation/page_necessities/detail_page/tcgCards.dart**: Now deprecated/empty (can be deleted)
- ✅ **lib/presentation/theme_provider.dart**: Fixed and completed implementation
- ✅ **lib/data/queries.dart**: Rebuilt and all functions working
- ✅ **lib/data/favorites_service.dart**: New service for managing favorites with Hive

## 17. Future Enhancements
- **Cursor-based Pagination**: Switch from offset to cursor for better performance
- **Favorites System**: Local storage with Hive/Isar for favorite Pokémon
- **Offline Mode**: Cache Pokémon data for offline browsing
- **Type Matchups**: Show weaknesses, resistances, immunities (x4, x2, x0.5, x0.25, x0)
- **Shiny Toggle**: Display shiny sprites if available
- **Form Variants**: Dropdown for Alola, Galar, Mega forms
- **Move Filters**: Filter by TM, Tutor, Egg moves
- **Advanced Sort**: Sort by stats, name, type
- **Filter Persistence**: Remember filters between sessions
- **Hero Animations**: Smooth transitions between pages
- **Accessibility**: Semantics labels, screen reader support
- **Internationalization**: Multi-language support (ES/EN)
- **Interactive Game**: "Who's That Pokémon?" quiz with scoring
- **Region Maps**: Interactive maps showing Pokémon locations
- **Share Feature**: Export Pokémon card as image

## 18. Development Progress (Updated November 2025)

### ✅ Completed Features
- ✅ 3-layer architecture implemented and fixed
- ✅ BLoC pattern for state management
- ✅ GraphQL integration with caching
- ✅ Home page with search and filters
- ✅ Detail page with comprehensive information
- ✅ **TCG cards integration** (lib/data/tcg_service.dart)
- ✅ **"VIEW CARDS" button** with modal bottom sheet
- ✅ Theme system (light/dark) with proper Provider implementation
- ✅ Type-based gradients
- ✅ Evolution chains
- ✅ Stats visualization
- ✅ **Pokemon Quiz Game** ("Who's That Pokémon?")
- ✅ **Quiz button in AppBar** for easy access
- ✅ **Pokédex Entry Card** with flavor text, region, and generation
- ✅ Infinite scroll pagination
- ✅ Debounced search (500ms)
- ✅ Multiple filters working together
- ✅ **Favorites System** ❤️
  - Local storage with Hive
  - Heart button on detail pages
  - Dedicated favorites page with grid
  - Real-time badge counter
  - Persistent across sessions

### 🔧 Technical Improvements
- ✅ **theme_provider.dart**: Completed missing implementation with proper ChangeNotifier
- ✅ **queries.dart**: Rebuilt from corrupted state with all functions working
- ✅ **Provider fix**: Added `listen: false` to prevent event handler errors
- ✅ **TCGService**: Moved from presentation to data layer (proper architecture)
- ✅ **Favorites Service**: Singleton pattern with error handling
- ✅ **Stream-Based Updates**: Real-time UI synchronization
- ✅ **Hot-Reload Safety**: Graceful fallbacks for development

---

## 19. ❤️ Favorites System (Added November 2025)

### Overview
A complete favorites feature that allows users to save their favorite Pokémon locally using Hive database. Favorites persist across app sessions and sync in real-time across all screens.

### Dependencies Added
```yaml
hive: ^2.2.3              # Lightweight NoSQL database for Flutter
hive_flutter: ^1.1.0      # Flutter-specific Hive integration
path_provider: ^2.1.1     # For finding storage directory paths
```

### Architecture & Files

#### 1. FavoritesService (`lib/data/favorites_service.dart`)
**Purpose**: Singleton service managing all favorites operations with Hive local storage.

**Key Features**:
- **Singleton Pattern**: Only one instance exists globally (`_instance`)
- **Persistent Storage**: Data survives app restarts (stored on device)
- **Type-Safe**: Only stores integers (Pokémon IDs)
- **Reactive**: Stream-based updates for real-time UI synchronization
- **Error Handling**: Graceful fallbacks for hot-reload scenarios

**Core Methods**:
```dart
// Initialization (called in main.dart before runApp)
await FavoritesService().init();

// Add/Remove/Toggle
await addFavorite(pokemonId)      // Returns true if added, false if already exists
await removeFavorite(pokemonId)   // Returns true if removed, false if not found
await toggleFavorite(pokemonId)   // Returns true if now favorite, false if removed

// Query Methods (synchronous)
bool isFavorite(pokemonId)        // Check if Pokémon is favorited
List<int> getAllFavorites()       // Get all favorite Pokémon IDs
int count                         // Get number of favorites

// Utility
await clearAll()                  // Remove all favorites (permanent)
Stream<BoxEvent> watchFavorites() // Stream for reactive UI updates
```

**Implementation Details**:
- **Hive Box**: Named "favorites", stores `List<int>` of Pokémon IDs
- **Lazy Initialization**: Auto-initializes on first async method call if needed
- **Hot-Reload Safety**: Try-catch blocks prevent crashes during hot reload
- **O(1) Count**: Very fast count operation, no iteration

#### 2. FavoritesPage (`lib/presentation/pages/FavoritesPage.dart`)
**Purpose**: Dedicated page displaying all favorite Pokémon in a grid layout.

**Features**:
- **2-Column Grid**: Beautiful card layout with proper spacing
- **Real-Time Updates**: Uses `StreamBuilder<BoxEvent>` to auto-refresh when favorites change
- **Empty State**: Shows friendly message with heart icon when no favorites
- **Navigation**: Tap any card to view full Pokémon details
- **Quick Remove**: Tap heart icon on card to remove from favorites
- **Theme Support**: Adapts to light/dark mode

**UI Components**:
- AppBar with "FAVORITES" title (Press Start 2P font)
- Theme toggle switch
- Grid with 2 columns, 0.75 aspect ratio
- Each card shows:
  - Pokémon image (official artwork)
  - Pokémon ID (#001 format)
  - Name (uppercase, Press Start 2P)
  - Types (color-coded)
  - Heart icon (remove button)

**Implementation**:
```dart
// Fetches Pokémon data for each favorite ID
FutureBuilder<Map<String, dynamic>?>(
  future: fetchPokemon(pokemonId, client),
  // Displays card or loading/error state
)

// Watches for changes and rebuilds
StreamBuilder<BoxEvent>(
  stream: _favoritesService.watchFavorites(),
  // Rebuilds grid when favorites change
)
```

#### 3. Detail Page Enhancement (`lib/presentation/pages/DetailPageState.dart`)
**Purpose**: Added heart button to Pokemon image container for quick favoriting.

**UI Enhancement**:
- **Heart Button**: Positioned in top-right corner of Pokémon image
- **Visual States**:
  - Filled red heart (❤️): Currently favorited
  - Outlined grey heart (🤍): Not favorited
- **White Circle Background**: 90% opacity for visibility over any image
- **Box Shadow**: Subtle depth effect
- **Feedback**: SnackBar notification when toggling (green for add, orange for remove)

**Implementation**:
```dart
Stack(
  children: [
    Container(...Pokémon image...),
    Positioned(
      top: 8, right: 8,
      child: StreamBuilder<BoxEvent>( // Real-time updates
        stream: _favoritesService.watchFavorites(),
        builder: (context, snapshot) {
          final isFavorite = _favoritesService.isFavorite(pokemon.id);
          return IconButton(
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: () async {
              await _favoritesService.toggleFavorite(pokemon.id);
              // Shows SnackBar with confirmation message
            },
          );
        },
      ),
    ),
  ],
)
```

#### 4. Home Page Navigation (`lib/presentation/pages/HomePageState.dart`)
**Purpose**: Added favorites button to AppBar for easy access.

**UI Components**:
- **Heart Icon**: Yellow heart icon in AppBar actions
- **Badge Counter**: Red circular badge showing number of favorites
- **Real-Time Counter**: Updates automatically using `StreamBuilder`
- **Navigation**: Tap to open FavoritesPage

**Implementation**:
```dart
StreamBuilder<BoxEvent>(
  stream: FavoritesService().watchFavorites(),
  builder: (context, snapshot) {
    final favCount = FavoritesService().count;
    return Stack(
      children: [
        IconButton(icon: Icon(Icons.favorite), ...),
        if (favCount > 0)
          Positioned(
            // Badge with count
            child: Text('$favCount'),
          ),
      ],
    );
  },
)
```

#### 5. Main Entry Point (`lib/domain/main.dart`)
**Purpose**: Initialize Hive before app starts.

**Changes**:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GraphQLService().init();
  await FavoritesService().init(); // ✨ NEW: Initialize Hive
  runApp(...);
}
```

### User Flow

1. **Adding Favorites**:
   - User views any Pokémon detail page
   - Taps heart icon in top-right of image
   - Heart fills with red color
   - SnackBar confirms: "PIKACHU added to favorites!"
   - Badge counter in home page updates immediately

2. **Viewing Favorites**:
   - User taps heart icon in home page AppBar
   - Navigates to FavoritesPage
   - Sees grid of all favorite Pokémon
   - Can tap any card to view details

3. **Removing Favorites**:
   - From detail page: Tap filled heart (toggles off)
   - From favorites page: Tap heart on card
   - SnackBar confirms removal
   - Card disappears from favorites grid
   - Badge counter decreases

### Data Persistence

**Storage Location**:
- Android: `/data/data/com.example.pokedex/app_flutter/`
- iOS: `Application Documents Directory`
- Desktop: User's application data directory

**File Format**:
- Hive binary format (optimized for speed)
- File: `favorites.hive`
- Type-safe: Only integers allowed

**Persistence**:
- Survives app restarts ✅
- Survives app updates ✅
- Survives hot reload ✅ (with error handling)
- Does NOT sync across devices (local only)

### Performance

**Speed**:
- Add/Remove: ~1ms (O(n) for indexOf, but small dataset)
- Check if favorite: <1ms (O(n), typically <100 items)
- Count: <1ms (O(1))
- Stream updates: Instant (event-driven)

**Memory**:
- Each favorite: 8 bytes (int64)
- 100 favorites: ~800 bytes
- Negligible impact on app performance

### Error Handling

**Hot Reload Issue**:
- Problem: Hot reload doesn't re-run `main()`, so Hive isn't reinitialized
- Solution: Full restart (Stop + Run) required after adding feature
- Graceful fallback: Methods return safe defaults (false, [], 0) instead of crashing

**Uninitialized State**:
- Async methods: Auto-initialize if needed
- Sync methods: Try-catch with safe defaults
- Stream: Returns `Stream.empty()` if not initialized

### Testing Scenarios

✅ **Test Cases Covered**:
1. Add favorite → Badge appears with "1"
2. Add multiple → Badge shows correct count
3. Remove favorite → Badge decreases
4. Toggle on detail page → Updates favorites page
5. Navigate from favorites → Shows correct Pokémon
6. Empty favorites → Shows empty state message
7. App restart → Favorites persist
8. Hot reload → Graceful handling (no crash)
9. Theme toggle → UI updates correctly

### Future Enhancements

**Potential Improvements**:
- **Cloud Sync**: Firebase/Supabase integration for cross-device sync
- **Collections**: Multiple favorite lists (Team, Shinies, Legendaries)
- **Export/Import**: Share favorites via JSON file
- **Sort Options**: Sort by ID, name, type, date added
- **Search in Favorites**: Filter favorites by name/type
- **Bulk Operations**: Select multiple → Remove all
- **Undo**: Temporary undo for accidental removals

---

## 20. Development Progress (Updated November 2025)

### ✅ Completed Features
- ✅ 3-layer architecture implemented and fixed
- ✅ BLoC pattern for state management
- ✅ GraphQL integration with caching
- ✅ Home page with search and filters
- ✅ Detail page with comprehensive information
- ✅ **TCG cards integration** (lib/data/tcg_service.dart)
- ✅ **"VIEW CARDS" button** with modal bottom sheet
- ✅ Theme system (light/dark) with proper Provider implementation
- ✅ Type-based gradients
- ✅ Evolution chains
- ✅ Stats visualization
- ✅ **Pokemon Quiz Game** ("Who's That Pokémon?")
- ✅ **Quiz button in AppBar** for easy access
- ✅ **Pokédex Entry Card** with flavor text, region, and generation
- ✅ Infinite scroll pagination
- ✅ Debounced search (500ms)
- ✅ Multiple filters working together
- ✅ **Favorites System** ❤️
  - Local storage with Hive
  - Heart button on detail pages
  - Dedicated favorites page with grid
  - Real-time badge counter
  - Persistent across sessions

### 🔧 Technical Improvements
- ✅ **theme_provider.dart**: Completed missing implementation with proper ChangeNotifier
- ✅ **queries.dart**: Rebuilt from corrupted state with all functions working
- ✅ **Provider fix**: Added `listen: false` to prevent event handler errors
- ✅ **TCGService**: Moved from presentation to data layer (proper architecture)
- ✅ **Favorites Service**: Singleton pattern with error handling
- ✅ **Stream-Based Updates**: Real-time UI synchronization
- ✅ **Hot-Reload Safety**: Graceful fallbacks for development

---

## 21. Running the Application

### First Time Setup
```bash
# Install dependencies
flutter pub get

# Run on device/emulator
flutter run

# For hot reload issues (after adding new features)
# Press 'q' to quit, then run again
flutter run
```

### Important Notes
- **Hot Reload Limitation**: After adding Hive-based features, use full restart (Stop + Run)
- **Favorites Persistence**: Data stored locally, survives app restarts
- **Theme Persistence**: Theme preference saved automatically

### Troubleshooting

**"FavoritesService not initialized" Error**:
- Solution: Do a full restart (Stop the app, then Run again)
- Why: Hot reload (R) doesn't re-run `main()`, so Hive doesn't initialize
- Prevention: Code now has graceful fallbacks to prevent crashes

**Badge Counter Not Updating**:
- Check: Ensure app is fully restarted
- Verify: `StreamBuilder` should wrap the favorites button
- Test: Add a favorite and check if stream emits events

**Favorites Not Persisting**:
- Verify: `FavoritesService().init()` called in `main()`
- Check: Storage permissions (usually automatic on modern Flutter)
- Debug: Print `getAllFavorites()` after restart to confirm persistence

---

