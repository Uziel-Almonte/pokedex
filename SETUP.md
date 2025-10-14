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
- Created a `GraphQLClient` and provided it to the app using `GraphQLProvider`.

## 4. Main App Structure
- **main.dart** contains all main logic and UI:
  - `main()` function initializes Hive, sets up the GraphQL client, and runs the app.
  - `MyApp` (StatelessWidget): Root widget, sets up Material theme and home page.
  - `MyHomePage` (StatefulWidget): Main screen, displays Pokémon info and a button to fetch the next Pokémon.
  - `_MyHomePageState`: Handles state, fetching, and UI updates.

## 5. Fetching Pokémon Data
- Function: `fetchPokemon(int id, GraphQLClient client)`
  - Sends a GraphQL query to fetch a Pokémon species by its ID.
  - Returns a map with the Pokémon's `id` and `name`.
- Uses a `FutureBuilder` in the UI to display loading, error, or Pokémon data.
- The floating action button increments the counter, triggering a new fetch for the next Pokémon.

## 6. UI Logic
- Displays the current Pokémon's ID and name.
- Shows a loading spinner while fetching data.
- Shows a message if no Pokémon is found for the given ID.
- Button labeled with a plus icon fetches the next Pokémon.

## 7. Code Comments and Explanations
- Every line in `main.dart` is commented to explain its purpose, including:
  - Imports
  - Widget structure
  - State management
  - GraphQL query logic
  - UI rendering

## 8. Build and Storage Notes
- Each build overwrites previous build outputs; storage does not increase with every build.
- `flutter clean` safely removes old build artifacts without affecting source code or assets.

## 9. String Interpolation
- Dart uses `$variable` or `${expression}` for string interpolation, allowing dynamic values in UI text.

---

