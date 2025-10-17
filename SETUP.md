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
  - `http: ^1.1.0` for HTTP requests (not used in main logic)
  - `google_fonts: ^6.3.2` for custom Google Fonts styling (Press Start 2P retro font)
  - `cupertino_icons: ^1.0.8` for iOS-style icons
  - `flutter_lints: ^5.0.0` for recommended linting rules

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
  - `main()` function initializes the GraphQLService, and runs the app wrapped in GraphQLProvider.
  - `MyApp` (StatelessWidget): Root widget, sets up Material theme with Pokémon colors and home page.
  - `MyHomePage` (StatefulWidget): Main screen, displays Pokémon info with styled UI and a button to fetch the next Pokémon.
  - `_MyHomePageState`: Handles state, fetching, and UI updates.

## 6. Fetching Pokémon Data
- Function: `fetchPokemon(int id, GraphQLClient client)`
  - Sends a GraphQL query to fetch a Pokémon species by its ID.
  - Returns a map with the Pokémon's `id`, `name`, `types`, and `sprites`.
  - Query structure:
    - `pokemonspecies` filtered by ID
    - Nested `pokemons` → `pokemontypes` → `type` → `name`
    - Nested `pokemons` → `pokemonsprites` → `sprites`
- Uses a `FutureBuilder` in the UI to display loading, error, or Pokémon data.
- The floating action button increments the counter, triggering a new fetch for the next Pokémon.

## 7. UI Design & Styling (Pokémon Theme)
### Theme Configuration
- **App Theme**:
  - Color scheme: Red seed color (Pokémon primary color)
  - Scaffold background: Light blue (`Colors.blue[50]`) for a Pokémon-themed look

### AppBar Styling
- **Background**: Red (`Colors.red`) - iconic Pokémon color
- **Title**: "POKEDEX" styled with:
  - Font: Press Start 2P (retro 8-bit style via Google Fonts)
  - Size: 20 pixels
  - Color: Yellow (`Colors.yellow`) - classic Pokémon branding
  - Shadow: Blue shadow with 2px offset and 4px blur for depth
  - Centered horizontally

### Pokémon Card Display
- **Container with decorations**:
  - White background (`Colors.white`) for clean card appearance
  - Rounded corners: 20px border radius
  - Box shadow: Grey shadow with 50% opacity, 5px spread, 7px blur, 3px vertical offset
  - Padding: 20px on all sides
  - Image: 150x150 pixels (placeholder, to be replaced with actual Pokémon sprites)

### Text Styling
- **Pokémon ID**:
  - Font: Press Start 2P (retro style)
  - Size: 16 pixels
  - Color: Red (`Colors.red`)
  - Weight: Bold

- **Pokémon Name**:
  - Font: Press Start 2P (retro style)
  - Size: 24 pixels (largest, main title)
  - Color: Dark blue (`Colors.blue[900]`)
  - Weight: Bold
  - Transform: Uppercase for impact
  - Shadow: Yellow shadow with 2px offset and 3px blur

- **Pokémon Types**:
  - Font: Roboto (modern, readable)
  - Size: 18 pixels
  - Color: Dark green (`Colors.green[700]`) - nature/type theme
  - Weight: Semi-bold (w600)

### Interactive Elements
- **Floating Action Button**:
  - Background: Red (`Colors.red`) - Pokémon theme
  - Icon: Forward arrow (`Icons.arrow_forward`) in white
  - Action: Increments counter to fetch next Pokémon
  - Tooltip: "Next Pokémon"

### Loading & Error States
- **Loading Indicator**: Red circular progress indicator matching theme
- **Error Message**: Styled with Press Start 2P font in red, 14px size

### Spacing
- Uses `SizedBox` widgets for consistent vertical spacing:
  - 30px between image card and ID
  - 10px between text elements

## 8. Code Comments and Explanations
- Every line in `main.dart` and `graphql.dart` is commented to explain its purpose, including:
  - Imports and their purposes
  - Widget structure and hierarchy
  - State management logic
  - GraphQL query logic
  - UI rendering and layout
  - Singleton pattern implementation
  - **Style properties**: Detailed comments on every style property explaining:
    - What each property does (fontSize, color, shadows, etc.)
    - Why specific values were chosen (e.g., "20 pixels for retro readability")
    - How properties contribute to the Pokémon theme

## 9. Build and Storage Notes
- Each build overwrites previous build outputs; storage does not increase with every build.
- `flutter clean` safely removes old build artifacts without affecting source code or assets.
- Build artifacts are stored in the `build/` directory and are automatically managed by Flutter.

## 10. String Interpolation
- Dart uses `$variable` or `${expression}` for string interpolation, allowing dynamic values in UI text.
- Examples in the app:
  - `Text('ID: ${pokemon['id']}')` displays the Pokémon ID dynamically
  - `pokemon['name'].toString().toUpperCase()` converts name to uppercase

## 11. Architecture Benefits
- **Singleton Pattern**: Ensures only one GraphQL client instance exists throughout the app lifecycle.
- **Separation of Concerns**: GraphQL logic is isolated in `graphql.dart`, making the codebase more maintainable.
- **Reusability**: The `GraphQLService` can be accessed from any part of the app without passing the client as a parameter.
- **Helper Methods**: Built-in `query()` and `mutate()` methods simplify GraphQL operations.
- **Consistent Theming**: Centralized color scheme and Google Fonts integration for uniform styling.

## 12. Google Fonts Integration
- **Package**: `google_fonts: ^6.3.2` installed via pubspec.yaml
- **Primary Font**: Press Start 2P - retro 8-bit style perfect for gaming/Pokémon theme
- **Secondary Font**: Roboto - modern, clean font for secondary information (types)
- **Usage**: 
  - `GoogleFonts.pressStart2p()` for titles, ID, and retro-styled text
  - `GoogleFonts.roboto()` for body text and types
- **Benefits**:
  - No manual font file downloads required
  - Automatic caching and optimization
  - Easy to switch or add new fonts
  - Consistent rendering across platforms

## 13. Design Philosophy
- **Retro Gaming Aesthetic**: Press Start 2P font evokes classic 8-bit Pokémon games
- **Color Psychology**: 
  - Red: Energy, excitement (Pokémon brand)
  - Yellow: Joy, optimism (Pikachu, classic branding)
  - Blue: Trust, stability (balance and contrast)
  - Green: Nature (Pokémon types, natural world)
- **Visual Hierarchy**: Larger font sizes and bold weights for important information (name > types > ID)
- **Depth & Dimension**: Strategic use of shadows on text and containers for modern card-like appearance
- **Accessibility**: High contrast colors (yellow on red, white on red) for readability

## 14. Search Functionality with Debounce
### Overview
- Implemented a search bar that allows users to search for Pokémon by name
- Uses debounce technique to optimize performance and reduce API calls
- Seamlessly switches between two modes: ID navigation and name search

### Components Added
- **TextEditingController** (`_searchController`):
  - Manages the text input state in the search field
  - Allows reading, clearing, and listening to changes
  - Must be disposed of to prevent memory leaks

- **Timer** (`_debounce`):
  - Implements debounce functionality
  - Delays search execution by 500ms after user stops typing
  - Cancels previous timers if user continues typing

- **Search Query State** (`_searchQuery`):
  - Stores the current active search term
  - Empty string = ID navigation mode
  - Non-empty string = search mode

### Debounce Implementation
**Purpose**: Prevent excessive API calls while user is typing

**How it works**:
1. User types a character in the search field
2. `_onSearchChanged()` is called
3. If a timer is already active, cancel it (user is still typing)
4. Create a new 500ms timer
5. If 500ms passes without new input, update `_searchQuery` and trigger search
6. If user types again before 500ms, restart from step 2

**Benefits**:
- Reduces API calls from potentially dozens to just one
- Improves app performance and reduces server load
- Better user experience (no lag from constant queries)
- Network efficiency (especially important on mobile data)

### Search Methods
- **Function**: `searchPokemonByName(String name, GraphQLClient client)`
  - Searches for Pokémon using case-insensitive pattern matching
  - Uses GraphQL `_ilike` operator (PostgreSQL)
  - Pattern: `%$name%` allows partial matching (e.g., "pika" matches "pikachu")
  - Returns first matching result (limit: 1)
  - Query structure identical to `fetchPokemon()` for consistency

### Search Bar UI Design
- **TextField Styling**:
  - Rounded pill shape (30px border radius)
  - White background with colored borders
  - Red border when not focused (2px width)
  - Blue border when focused (2px width)
  - 16px padding on all sides

- **Icons**:
  - **Prefix Icon**: Search icon (magnifying glass) in red
  - **Suffix Icon**: Clear button (X icon) that:
    - Only appears when text is present
    - Clears the search field
    - Resets to ID navigation mode
    - Red color matching theme

- **Placeholder**:
  - Text: "Search Pokémon..."
  - Font: Roboto (readable, modern)
  - Color: Grey[600] for subtle hint

### Smart Mode Switching
- **Implementation**: Conditional `future` in `FutureBuilder`
  ```dart
  future: _searchQuery.isEmpty
      ? fetchPokemon(_counter, client)      // ID Navigation Mode
      : searchPokemonByName(_searchQuery, client)  // Search Mode
  ```

- **ID Navigation Mode** (default):
  - Triggered when search field is empty
  - Uses counter to fetch Pokémon by ID
  - Floating action button increments counter
  - Sequential browsing experience

- **Search Mode**:
  - Triggered when user enters search text
  - Uses debounced query to search by name
  - Floating action button still works (increments counter for when search is cleared)
  - Results update automatically after debounce delay

### Layout Changes
- **Column Structure**:
  - Search bar at the top (Padding with 16px spacing)
  - Pokémon display area below (Expanded widget)
  - Floating action button remains in bottom-right

- **Responsive Design**:
  - Search bar takes fixed space at top
  - Pokémon display expands to fill remaining space
  - Works on various screen sizes

### Memory Management
- **dispose() Method**:
  - Disposes `_searchController` to free resources
  - Cancels any pending debounce timer
  - Prevents memory leaks when widget is removed
  - Critical for app performance

### User Experience Features
1. **Visual Feedback**:
   - Border color changes on focus (red → blue)
   - Clear button appears/disappears dynamically
   - Loading spinner during search
   - "No Pokémon found" message for failed searches

2. **Intuitive Interaction**:
   - Type to search, no search button needed
   - Clear button for quick reset
   - Automatic search after short pause
   - Seamless mode switching

3. **Performance Optimizations**:
   - Debounce reduces server load
   - Case-insensitive search (`toLowerCase()`)
   - Whitespace trimming (`trim()`)
   - Single result limit for faster queries

## 15. Dependencies Update
### Added Dependency
- `dart:async` - Core Dart library for asynchronous programming
  - Required for `Timer` class used in debounce implementation
  - No installation needed (part of Dart SDK)
  - Imported with: `import 'dart:async';`

### Complete Dependencies List
```yaml
dependencies:
  flutter:
    sdk: flutter
  graphql_flutter: ^5.0.1    # GraphQL API integration
  http: ^1.1.0               # HTTP requests
  google_fonts: ^6.3.2       # Custom Google Fonts
  cupertino_icons: ^1.0.8    # iOS-style icons

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0      # Linting rules
```

## 16. Code Documentation Standards
### Comment Structure
All code includes comprehensive inline comments explaining:
- **What**: What each line/block does
- **Why**: Reasoning behind implementation choices
- **How**: Step-by-step process explanations (especially for debounce)

### Special Comment Blocks
- **DEBOUNCE EXPLANATION**: Multi-line comment block explaining the debounce pattern with numbered steps
- **SEARCH BAR SECTION**: Detailed explanation of TextField features and styling
- **SMART SWITCHING**: Explanation of conditional logic for mode switching
- **HOW IT WORKS**: Step-by-step breakdowns for complex logic

### Documentation Style
- Variable declarations include purpose and usage
- Methods have function-level documentation
- Complex logic has inline step-by-step comments
- UI elements explain both technical properties and design choices
- Performance considerations are noted where relevant
