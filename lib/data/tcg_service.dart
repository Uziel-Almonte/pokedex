import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service class for fetching Pokémon Trading Card Game data
/// Uses the TCGDex API (https://api.tcgdex.net)
///
/// ARCHITECTURE:
/// - This service acts as a data layer between the UI and the TCGDex REST API
/// - Provides static methods to avoid unnecessary instantiation
/// - Handles all HTTP requests, JSON parsing, and error handling
/// - Returns structured Dart objects (Maps) that the UI can easily consume
class TCGService {
  /// Base URL for TCGDex API v2
  /// TCGDex is a comprehensive Pokémon TCG database with free API access
  /// Documentation: https://api.tcgdex.net/v2/docs
  static const String _baseUrl = 'https://api.tcgdex.net/v2/en';

  /// Fetches all cards for a specific Pokémon by name
  /// Returns a list of card data maps, or empty list if none found
  ///
  /// PARAMETERS:
  /// - pokemonName: The name of the Pokémon to search for (case-insensitive)
  ///
  /// RETURNS:
  /// - List<Map<String, dynamic>>: List of card objects with properties like:
  ///   - id: Unique card identifier (e.g., "sv03.5-007")
  ///   - name: Card name (e.g., "Pikachu")
  ///   - image: Base URL for card images
  ///   - set: Set information (name, logo, symbol)
  ///   - rarity: Card rarity (Common, Uncommon, Rare, etc.)
  ///   - hp: Pokémon's HP value
  ///   - types: Array of Pokémon types
  ///
  /// Example: searchCardsByPokemon('pikachu') returns all Pikachu cards
  ///
  /// HOW IT WORKS:
  /// 1. Fetches the complete list of ALL TCG sets from the API
  /// 2. Iterates through each set and fetches its card list
  /// 3. Filters cards by exact name match (case-insensitive)
  /// 4. Aggregates all matching cards into a single list
  /// 5. Returns the complete list of cards across all sets
  ///
  /// PERFORMANCE CONSIDERATIONS:
  /// - Makes multiple API calls (1 for sets list + 1 per set = ~150+ calls)
  /// - Takes 10-30 seconds depending on network speed
  /// - Shows loading spinner in UI during search
  /// - Progress logged to console every 10 sets
  /// - All calls are async/non-blocking
  ///
  /// WHY THIS APPROACH:
  /// - TCGDex API doesn't have a direct "search by Pokémon name" endpoint
  /// - The /search endpoint returns 404 (not available)
  /// - The /pokemon/{name} endpoint returns 404 (not available)
  /// - The /cards/{name} endpoint returns only ONE card, not all variants
  /// - Solution: Iterate through all sets to find all card variants
  ///
  /// TRADE-OFFS:
  /// - Slower initial load BUT comprehensive results
  /// - Finds cards from ANY generation/set (Gen 1 to current)
  /// - User only waits when they explicitly click "VIEW CARDS"
  /// - Could be optimized with caching in future iterations
  static Future<List<Map<String, dynamic>>> searchCardsByPokemon(String pokemonName) async {
    try {
      // ============================================================
      // STEP 1: Fetch the list of ALL TCG sets
      // ============================================================
      // TCGDex organizes cards into "sets" (e.g., Base Set, Jungle, etc.)
      // Each set has an ID (e.g., "base1", "sv03.5") and contains multiple cards
      // We need the full list to search through all of them

      final setsUrl = Uri.parse('$_baseUrl/sets');
      print('Fetching all sets from TCGDex...'); // Debug log for monitoring

      // Make HTTP GET request to fetch all sets
      final setsResponse = await http.get(setsUrl);
      print('Sets response status: ${setsResponse.statusCode}'); // Log response status

      // Check if the request was successful (HTTP 200 OK)
      if (setsResponse.statusCode != 200) {
        print('Failed to fetch sets');
        return []; // Return empty list if we can't get the sets
      }

      // ============================================================
      // STEP 2: Parse the JSON response
      // ============================================================
      // The API returns a JSON array of set objects
      // Example: [{"id": "base1", "name": "Base Set"}, {"id": "base2", ...}]

      final dynamic setsData = json.decode(setsResponse.body);
      final List<dynamic> sets = setsData is List ? setsData : [];
      print('Found ${sets.length} total sets to search'); // Typically ~150 sets

      // ============================================================
      // STEP 3: Initialize search variables
      // ============================================================
      // We'll accumulate all matching cards in this list
      final List<Map<String, dynamic>> allCards = [];

      // Track progress for logging purposes
      int setsSearched = 0;  // Counter for how many sets we've checked
      int cardsFound = 0;     // Counter for how many matching cards we've found

      // ============================================================
      // STEP 4: Search through ALL sets
      // ============================================================
      // This is the main loop that searches every TCG set
      // For each set, we fetch its cards and filter by name

      for (var set in sets) {
        try {
          // Extract the set ID from the set object
          // Example: set = {"id": "base1", "name": "Base Set", ...}
          final setId = set['id'] as String?;
          if (setId == null) continue; // Skip if set has no ID (shouldn't happen)

          setsSearched++; // Increment our progress counter

          // ============================================================
          // STEP 4a: Fetch all cards in this specific set
          // ============================================================
          // API endpoint: GET /sets/{setId}
          // Returns: Set object with 'cards' array containing all cards in that set

          final setCardsUrl = Uri.parse('$_baseUrl/sets/$setId');
          final setCardsResponse = await http.get(setCardsUrl);

          // Only process if we successfully fetched the set data
          if (setCardsResponse.statusCode == 200) {
            final dynamic setData = json.decode(setCardsResponse.body);

            // ============================================================
            // STEP 4b: Extract the 'cards' array from the set data
            // ============================================================
            // Set response structure:
            // {
            //   "id": "base1",
            //   "name": "Base Set",
            //   "cards": [
            //     {"id": "base1-1", "name": "Alakazam", ...},
            //     {"id": "base1-25", "name": "Pikachu", ...},
            //     ...
            //   ]
            // }

            if (setData is Map && setData.containsKey('cards')) {
              final List<dynamic> cards = setData['cards'] as List<dynamic>;

              // ============================================================
              // STEP 4c: Filter cards by name
              // ============================================================
              // Check each card in this set to see if it matches our search

              for (var card in cards) {
                if (card is Map<String, dynamic>) {
                  // Get the card name and convert to lowercase for comparison
                  final cardName = (card['name'] as String?)?.toLowerCase() ?? '';
                  final searchName = pokemonName.toLowerCase();

                  // EXACT NAME MATCH (case-insensitive)
                  // This ensures we match "Pikachu" but not "Pikachu EX" or "Raichu"
                  // Uses == operator for exact equality after lowercasing both strings
                  if (cardName == searchName) {
                    allCards.add(card); // Add matching card to our results
                    cardsFound++;        // Increment found counter
                  }
                }
              }
            }
          }

          // ============================================================
          // STEP 4d: Progress logging
          // ============================================================
          // Log progress every 10 sets so users can see activity in console
          // Helps with debugging and shows the search is actively running

          if (setsSearched % 10 == 0) {
            print('Searched $setsSearched sets, found $cardsFound cards so far...');
          }

        } catch (e) {
          // If a specific set fails to load, log the error but continue
          // This ensures one bad set doesn't break the entire search
          print('Error fetching set: $e');
          continue; // Skip to next set
        }
      }

      // ============================================================
      // STEP 5: Return results
      // ============================================================
      // Log final summary and return the complete list of cards
      print('Search complete! Found ${allCards.length} cards for "$pokemonName" across $setsSearched sets');
      return allCards;

    } catch (e, stackTrace) {
      // ============================================================
      // ERROR HANDLING
      // ============================================================
      // Catch any unexpected errors (network issues, parsing errors, etc.)
      // Log detailed error information for debugging
      // Return empty list so UI can display "No cards found" message

      print('Error fetching TCG cards: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Fetches detailed information for a specific card by its ID
  /// Returns card data map, or null if not found
  ///
  /// PARAMETERS:
  /// - cardId: Unique card identifier (e.g., "sv03.5-007", "base1-25")
  ///
  /// RETURNS:
  /// - Map<String, dynamic>?: Card object with full details, or null if not found
  ///
  /// USAGE:
  /// This method is currently unused but available for future features like:
  /// - Showing detailed card stats when user taps a card
  /// - Displaying attack information, weaknesses, resistances
  /// - Showing market pricing data
  ///
  /// Example: getCardById('sv03.5-007') returns detailed Squirtle card info
  static Future<Map<String, dynamic>?> getCardById(String cardId) async {
    try {
      // Build the API endpoint URL with the card ID
      final url = Uri.parse('$_baseUrl/cards/$cardId');

      // Make HTTP GET request to fetch card details
      final response = await http.get(url);

      // If successful, parse and return the card data
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }

      // Return null if card not found (404) or other error
      return null;

    } catch (e) {
      // Log error and return null on failure
      print('Error fetching card details: $e');
      return null;
    }
  }
}

