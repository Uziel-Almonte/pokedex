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
│   └── tcg_service.dart            # ✨ NEW: TCG API service (TCGDex integration)
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
│   │   └── PokemonQuizPage.dart    # ✨ NEW: "Who's That Pokémon?" quiz game
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
- ⚠️ **lib/presentation/page_necessities/detail_page/tcgCards.dart**: Now deprecated/empty (can be deleted)
- ✅ **lib/presentation/theme_provider.dart**: Fixed and completed implementation
- ✅ **lib/data/queries.dart**: Rebuilt and all functions working

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

### 🔧 Architecture Fixes Completed
- ✅ **theme_provider.dart**: Completed missing implementation with proper ChangeNotifier
- ✅ **queries.dart**: Rebuilt from corrupted state with all functions working
- ✅ **Provider fix**: Added `listen: false` to prevent event handler errors
- ✅ **TCGService**: Moved from presentation to data layer (proper architecture)

### 🎮 New Features Added
1. **TCG Cards System**
   - Service in data layer: `lib/data/tcg_service.dart`
   - Searches ~150 TCG sets comprehensively
   - High-quality card images with zoom
   - Loading states and error handling
   
2. **Pokemon Quiz Game**
   - Random Pokémon selection (1-1010)
   - Silhouette effect with ColorFiltered matrix
   - Score and attempts tracking
   - Case-insensitive validation
   - Retro Press Start 2P styling

3. **Pokédex Entry and Region Information** ✨ NEW
   - Displays official Pokédex flavor text from games
   - Shows region of origin (Kanto, Johto, Hoenn, etc.)
   - Shows generation introduced (Gen I-IX with Roman numerals)
   - Text cleaning (removes \n, \f, normalizes whitespace)
   - GraphQL query filters for English only (language_id: 9)
   - Fetches most recent game version's entry
   - Beautiful card layout with book icon
   - Blue region card with globe icon
   - Purple generation card with history icon
   - Full dark/light mode theming
   - Graceful handling of missing data
