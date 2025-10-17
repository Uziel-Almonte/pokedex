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
  - `MyApp` (StatelessWidget): Root widget, sets up Material theme and home page.
  - `MyHomePage` (StatefulWidget): Main screen, displays Pokémon info and a button to fetch the next Pokémon.
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

## 7. UI Logic
- Displays the current Pokémon's ID, name, and types.
- Shows a placeholder image (currently using picsum for testing).
- Shows a loading spinner while fetching data.
- Shows a message if no Pokémon is found for the given ID.
- Button labeled with a plus icon fetches the next Pokémon.

## 8. Code Comments and Explanations
- Every line in `main.dart` and `graphql.dart` is commented to explain its purpose, including:
  - Imports
  - Widget structure
  - State management
  - GraphQL query logic
  - UI rendering
  - Singleton pattern implementation

## 9. Build and Storage Notes
- Each build overwrites previous build outputs; storage does not increase with every build.
- `flutter clean` safely removes old build artifacts without affecting source code or assets.

## 10. String Interpolation
- Dart uses `$variable` or `${expression}` for string interpolation, allowing dynamic values in UI text.
- Example: `Text('ID: ${pokemon['id']}')` displays the Pokémon ID dynamically.

## 11. Architecture Benefits
- **Singleton Pattern**: Ensures only one GraphQL client instance exists throughout the app lifecycle.
- **Separation of Concerns**: GraphQL logic is isolated in `graphql.dart`, making the codebase more maintainable.
- **Reusability**: The `GraphQLService` can be accessed from any part of the app without passing the client as a parameter.
- **Helper Methods**: Built-in `query()` and `mutate()` methods simplify GraphQL operations.

---
