# Pokedex Flutter App Setup

This document details the setup and implementation steps for the Pokedex app, including all major functions, classes, and features added during development.

## 1. Project Initialization
- Created a new Flutter project named `pokedex`.
- Set up the environment in `pubspec.yaml`:
  - Dart SDK version: ^3.9.2
  - Flutter version: default for project

## 2. Dependencies
- Added the following dependencies in `pubspec.yaml`:
  - `graphql_flutter: ^5.0.1` for GraphQL API integration
  - `http: ^1.1.0` for HTTP requests (TCG card fetching)
  - `google_fonts: ^6.3.2` for custom Google Fonts styling (Press Start 2P retro font)
  - `cupertino_icons: ^1.0.8` for iOS-style icons
  - `flutter_lints: ^5.0.0` for recommended linting rules
  - `provider: ^6.1.5+1` for state management (theme switching)
  - `framework: ^1.0.3` for additional framework utilities

## 3. GraphQL Integration
- Used the PokeAPI GraphQL endpoint: `https://graphql.pokeapi.co/v1beta2`
- Initialized Hive for persistent caching (required by `graphql_flutter`).
- Created a `GraphQLService` singleton class to manage the GraphQL client globally.
- Provided the client to the app using `GraphQLProvider`.

## 4. GraphQL Service Class (graphql.dart)
- **Class**: `GraphQLService` (Singleton pattern)
  - Manages a single instance of `GraphQLClient` accessible throughout the app.
  - **Fields**:
    - `_client`: Private nullable GraphQLClient instance
    - `_instance`: Static singleton instance
  - **Methods**:
    - `init({String uri})`: Initializes Hive and creates the GraphQL client with the specified endpoint URL
    - `get client`: Returns the client instance; throws an exception if not initialized
    - `query(String document, {Map<String, dynamic>? variables})`: Helper method to execute GraphQL queries
    - `mutate(String document, {Map<String, dynamic>? variables})`: Helper method to execute GraphQL mutations
  - **Usage**: Call `await GraphQLService().init()` once at app startup, then access the client anywhere with `GraphQLService().client`

## 5. Main App Structure
- **main.dart** contains all main logic and UI:
  - `main()` function initializes the GraphQLService, and runs the app wrapped in GraphQLProvider and ChangeNotifierProvider (for theme state).
  - `MyApp` (StatelessWidget): Root widget, sets up Material theme with Pokémon colors and home page. Includes light/dark theme support.
  - `MyHomePage` (StatefulWidget): Main screen, displays Pokémon info with styled UI and buttons for navigation and viewing cards.
  - `_MyHomePageState`: Handles state, fetching, and UI updates.

## 6. Fetching Pokémon Data
- Function: `fetchPokemon(int id, GraphQLClient client)`
  - Sends a GraphQL query to fetch a Pokémon species by its ID.
  - Returns a map with the Pokémon's `id`, `name`, `types`, `sprites`, and **base stats** (HP, Attack, Defense, Special Attack, Special Defense, Speed).
  - Query structure:
    - `pokemonspecies` filtered by ID
    - Nested `pokemons` → `pokemontypes` → `type` → `name`
    - Nested `pokemons` → `pokemonsprites` → `sprites`
    - Nested `pokemons` → `pokemonstats` → `base_stat` and `stat` → `name`
  - Uses a `FutureBuilder` in the UI to display loading, error, or Pokémon data.
  - The floating action button increments the counter, triggering a new fetch for the next Pokémon.

- Function: `searchPokemonByName(String name, GraphQLClient client)`
  - Searches for Pokémon by name using case-insensitive matching (PostgreSQL ILIKE operator).
  - Uses `%name%` pattern matching to find Pokémon containing the search term.
  - Returns the first matching Pokémon found.
  - Includes same nested data as `fetchPokemon` (types, sprites, stats).

## 7. Search Functionality with Debounce
- **Search Bar** (TextField):
  - Allows users to search Pokémon by name
  - Features:
    - Search icon prefix
    - Clear button (X icon) that appears when text is entered
    - Rounded pill-shaped design with red/blue borders
    - Theme-aware background color (dark mode support)
  
- **Debounce Implementation**:
  - Uses a `Timer` to delay search queries by 500ms after user stops typing
  - Prevents excessive API calls on every keystroke
  - Controller (`_searchController`) manages text input state
  - `initState` adds listener to controller for immediate UI updates
  - How it works:
    1. User types a character
    2. Cancel any existing timer
    3. Start new 500ms timer
    4. If 500ms passes without input, execute search
    5. If user types again, restart from step 2

## 8. Filter System
- **Filter Button**:
  - Red circular button with filter icon located next to the search bar
  - Opens a dialog with multiple filtering options
  - Filters are applied dynamically to the Pokémon list query

- **Filter Dialog** (`_showFilterDialog()`):
  - **Type Filter**: 
    - 18 filter chips for all Pokémon types (Normal, Fire, Water, Electric, Grass, Ice, Fighting, Poison, Ground, Flying, Psychic, Bug, Rock, Ghost, Dragon, Dark, Steel, Fairy)
    - Single selection - selecting a type filters Pokémon of that type only
    - Uses red selection color with 30% opacity
  - **Generation Filter**:
    - 9 filter chips for Generations 1-9
    - Single selection - filters Pokémon from the selected generation
    - Uses blue selection color with 30% opacity
  - **Ability Filter**:
    - Text input field for searching by ability name
    - Uses case-insensitive pattern matching (ILIKE operator)
    - Clear button (X icon) appears when text is entered
  - **Dialog Actions**:
    - "Clear All" button: Removes all applied filters
    - "Apply" button: Closes dialog and applies filters to the list

- **State Variables**:
  - `_selectedType`: Stores the selected type filter (nullable String)
  - `_selectedGeneration`: Stores the selected generation (nullable int, 1-9)
  - `_selectedAbility`: Stores the ability search term (nullable String)
  - All initialize as null (no filter applied)

- **Filter Implementation** (`_fetchPokemonList()`):
  - Dynamically builds GraphQL WHERE clause based on active filters
  - Type filter: `pokemontypes: {type: {name: {_eq: "$_selectedType"}}}`
  - Generation filter: `pokemonspecy: {generation_id: {_eq: $_selectedGeneration}}`
  - Ability filter: `pokemonabilities: {ability: {name: {_ilike: "%$_selectedAbility%"}}}`
  - Multiple filters can be combined (AND logic)
  - Returns up to 20 results per page with pagination support

## 9. Gradient System for Pokémon Types
- **PokeSelect Widget** (reusable_widgets/PokeSelect.dart):
  - Custom reusable widget for displaying Pokémon cards in the list
  - Features dynamic gradient backgrounds based on Pokémon type(s)

- **Type Color Map**:
  - Defines official Pokémon colors for all 18 types
  - Colors match those used in official games and trading cards
  - Examples:
    - Fire: Orange/Red (#F08030)
    - Water: Blue (#6890F0)
    - Grass: Green (#78C850)
    - Electric: Yellow (#F8D030)
    - Psychic: Pink (#F85888)
    - Dragon: Purple (#7038F8)

- **Gradient Generation** (`_getTypeGradient()`):
  - **Single-type Pokémon**: 
    - Creates gradient of same color with varying opacity (70%, 100%, 90%)
    - Diagonal gradient from top-left to bottom-right
    - Example: Charmander (Fire) → Light orange to darker orange gradient
  - **Dual-type Pokémon**:
    - Creates diagonal gradient transitioning between both type colors
    - Visually represents the dual nature of the Pokémon
    - Example: Bulbasaur (Grass/Poison) → Green to purple gradient
  - **Unknown/Invalid types**:
    - Fallback to neutral grey gradient
    - Ensures UI consistency even with missing data

- **Visual Benefits**:
  - Each Pokémon card has a unique appearance based on its type(s)
  - Provides instant visual recognition of Pokémon types
  - Creates depth and texture without additional images
  - White text with black shadows ensures readability over any gradient

## 10. Navigation and Page Structure
- **Home Page** (home.dart):
  - Displays grid/list of Pokémon with search and filter options
  - Shows Pokémon cards with gradients, sprites, names, and types
  - Pagination with previous/next buttons
  - Tapping a card navigates to detail page

- **Detail Page** (main.dart - PokeDetailPage):
  - Shows comprehensive information for a single Pokémon
  - Includes base stats, TCG cards, and detailed information
  - Accepts `initialPokemonId` parameter for navigation
  - Previous/next buttons for browsing adjacent Pokémon

## 11. Theme System
- **Theme Provider** (theme_provider.dart):
  - `AppThemeState` class extends `ChangeNotifier` for state management
  - Manages dark/light mode preference
  - `toggleTheme()` method switches between modes
  - Notifies listeners when theme changes

- **App Theme** (app_theme.dart):
  - `AppTheme` class provides static light and dark themes
  - Light theme: White background, red primary color
  - Dark theme: Dark grey background, red accent color
  - Both themes use Pokémon-inspired color palette

- **Theme Toggle Switch**:
  - Located in AppBar actions
  - Shows sun/moon icons indicating current mode
  - Switch component toggles between light/dark themes
  - Persists across app sessions

## 12. UI Design & Styling (Pokémon Theme)
### Theme Configuration
- **App Theme**:
  - Color scheme: Red seed color (Pokémon primary color)
  - Light mode: Light background with red accents
  - Dark mode: Dark grey background with red/yellow accents

### AppBar Styling
- **Background**: Red (`Colors.red`) - iconic Pokémon color
- **Title**: "POKEDEX" styled with:
  - Font: Press Start 2P (retro 8-bit style via Google Fonts)
  - Size: 20 pixels
  - Color: Yellow (`Colors.yellow`) - classic Pokémon branding
  - Shadow: Blue shadow with 2px offset and 4px blur for depth
  - Centered horizontally
- **Actions**: Theme toggle switch with light/dark mode icons

### Pokémon Card Display
- **Container with decorations**:
  - Theme-aware background (white in light mode, dark grey in dark mode)
  - Rounded corners: 20px border radius
  - Box shadow: Grey shadow with opacity, spread, blur, and vertical offset
  - Padding: 20px on all sides
  - Image: 150x150 pixels official Pokémon artwork from PokeAPI

### Text Styling
- **Pokémon ID**:
  - Font: Press Start 2P (retro style)
  - Size: 16 pixels
  - Color: Red (`Colors.red`)
  - Weight: Bold

- **Pokémon Name**:
  - Font: Press Start 2P (retro style)
  - Size: 24 pixels (largest, main title)
  - Color: Dark blue in light mode, red in dark mode
  - Weight: Bold
  - Transform: Uppercase for impact
  - Shadow: Yellow shadow with 2px offset and 3px blur

- **Pokémon Types**:
  - Font: Roboto (modern, readable)
  - Size: 18 pixels
  - Color: Dark green (`Colors.green[700]`) - nature/type theme
  - Weight: Semi-bold (w600)

## 13. Base Stats Display
- **Stats Section**:
  - Shows all 6 Pokémon base statistics in a card container
  - Stats displayed: HP, Attack, Defense, Special Attack, Special Defense, Speed
  - Each stat row includes:
    - Abbreviated name (HP, ATK, DEF, SpA, SpD, SPE)
    - Numeric value (0-255 range)
    - Visual progress bar with color coding
  - Total stats row shows sum of all base stats
  
- **Stats Visualization**:
  - Color-coded progress bars:
    - HP: Red (health/vitality)
    - Attack: Orange (physical power)
    - Defense: Yellow (protection)
    - Special Attack: Blue (special power)
    - Special Defense: Green (resistance)
    - Speed: Pink (agility)
  - Bar width calculated as: `statValue / 255` (255 is max Pokémon stat)
  - Progress bars show relative strength at a glance

- **Helper Method**: `_buildStatRow(String statName, int statValue, Color color)`
  - Reusable widget builder for stat rows
  - Creates consistent layout for all stats
  - Parameters: stat name, value, and color for visual coding

## 14. Trading Card Game (TCG) Integration
### TCG Service Class (tcgCards.dart)
- **Class**: `TCGService` (Static methods)
  - Provides access to Pokémon Trading Card Game data via TCGDex API
  - API Base URL: `https://api.tcgdex.net/v2/en`
  - Documentation: https://api.tcgdex.net/v2/docs

- **Architecture**:
  - Acts as data layer between UI and TCGDex REST API
  - Uses static methods (no instantiation needed)
  - Handles HTTP requests, JSON parsing, and error handling
  - Returns structured Dart Maps consumable by UI

- **Method**: `searchCardsByPokemon(String pokemonName)`
  - Searches for all trading cards of a specific Pokémon
  - Returns: `List<Map<String, dynamic>>` of card objects
  - Card properties include: id, name, image URL, set info, rarity, HP, types
  
  - **Algorithm**:
    1. Fetch complete list of all TCG sets from API
    2. Iterate through each set and fetch its card list
    3. Filter cards by exact name match (case-insensitive)
    4. Aggregate all matching cards into single list
    5. Return comprehensive list across all sets
  
  - **Performance**:
    - Makes ~150+ API calls (1 for sets + 1 per set)
    - Takes 10-30 seconds depending on network
    - Shows loading spinner during search
    - Progress logged every 10 sets
    - All calls are async/non-blocking
  
  - **Why This Approach**:
    - TCGDex API lacks direct "search by Pokémon name" endpoint
    - `/search`, `/pokemon/{name}` endpoints return 404
    - `/cards/{name}` returns only ONE card variant
    - Solution: Iterate through all sets for comprehensive results
  
  - **Trade-offs**:
    - Slower initial load BUT finds cards from ANY generation
    - User only waits when clicking "VIEW CARDS" button
    - Could be optimized with caching in future

- **Method**: `getCardById(String cardId)`
  - Fetches detailed card information by unique ID
  - Returns: `Map<String, dynamic>?` or null if not found
  - Currently unused but available for future features
  - Example usage: Show attack info, weaknesses, pricing when tapping card

### TCG Cards Display (main.dart)
- **Method**: `_showPokemonCards(String pokemonName)`
  - Opens modal bottom sheet showing trading cards
  - Uses `FutureBuilder` to handle async card fetching
  - Shows loading spinner while fetching
  - Displays error message if fetch fails
  - Shows "No cards found" if Pokémon has no cards
  
- **UI Components**:
  - **DraggableScrollableSheet**: Resizable bottom sheet (40%-95% screen height)
  - **Drag Handle**: Visual indicator at top for dragging
  - **Title**: Shows Pokémon name and card count
  - **GridView**: 2-column grid of card images
  - **Card Items**:
    - High-quality card images (appends `/high.png` to base URL)
    - Card name and set name below image
    - Tap to view full-size in dialog with zoom (InteractiveViewer)
    - Loading spinner while image loads
    - Error icon if image fails to load

- **"VIEW CARDS" Button**:
  - Elevated button with icon (playing card icon)
  - Press Start 2P font for retro style
  - Red background matching Pokémon theme
  - Located below stats section
  - Triggers `_showPokemonCards()` on press

## 15. Image Assets
- **Pokémon Sprites**:
  - Source: PokeAPI official artwork
  - URL pattern: `https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/{id}.png`
  - High-quality official artwork for each Pokémon
  - Dynamically loaded based on Pokémon ID

- **Trading Card Images**:
  - Source: TCGDex asset CDN
  - Base URL from API response, appended with `/high.png` for quality
  - Example: `https://assets.tcgdex.net/en/swsh/swsh3/136/high.png`
  - Shows actual physical card designs from various TCG sets

## 16. Error Handling
- **GraphQL Errors**:
  - Network issues handled with try-catch blocks
  - Display "No Pokémon found" message on failure
  - Logs errors to console for debugging

- **TCG API Errors**:
  - Individual set fetch failures don't break entire search
  - Continues to next set on error
  - Logs detailed error messages and stack traces
  - Returns empty list if major error occurs

- **Image Loading Errors**:
  - Shows error icon if card image fails to load
  - Loading indicator while images download
  - Fallback UI for missing images

## 17. Development Notes
- **State Management**: Uses Provider for theme state, local state for UI updates and filters
- **Performance**: Debounced search prevents excessive API calls
- **Responsiveness**: UI updates smoothly with async operations
- **Accessibility**: Theme support for user preferences
- **Scalability**: Service classes separate concerns (data fetching vs UI)
- **Visual Design**: Type-based gradients provide intuitive visual feedback

## 18. Future Enhancements
- **Caching**: Store TCG card search results to avoid repeated API calls
- **Favorites**: Allow users to save favorite Pokémon
- **Advanced Filters**: 
  - Filter by stat ranges (HP > 100, Speed < 50)
  - Multiple type selection (AND/OR logic)
  - Filter by name length, evolution stage
- **Filter Persistence**: Remember applied filters between sessions
- **Card Details**: Show attack info, weaknesses, pricing when tapping cards
- **Offline Mode**: Cache Pokémon data for offline browsing
- **Animations**: Add transitions and loading animations
- **Search History**: Remember recent searches
- **Filter Presets**: Save and load custom filter combinations

## 19. File Structure
```
lib/
├── main.dart                    # Main app entry, detail page UI
├── home.dart                    # Home page with list, search, filters
├── graphql.dart                 # GraphQL service singleton
├── tcgCards.dart                # TCG API service for trading cards
├── app_theme.dart               # Light/dark theme definitions
├── theme_provider.dart          # Theme state management
└── reusable_widgets/
    └── PokeSelect.dart          # Reusable Pokémon card widget with gradients
```

## 20. Running the App
1. Ensure Flutter SDK is installed
2. Run `flutter pub get` to install dependencies
3. Connect a device or start an emulator
4. Run `flutter run` to launch the app
5. Search for Pokémon by name or browse by ID
6. Click "VIEW CARDS" to see trading card collection
7. Toggle light/dark mode with switch in AppBar

## 21. API Documentation
- **PokeAPI GraphQL**: https://beta.pokeapi.co/graphql/console/
- **TCGDex API**: https://api.tcgdex.net/v2/docs
- **PokeAPI Sprites**: https://github.com/PokeAPI/sprites
