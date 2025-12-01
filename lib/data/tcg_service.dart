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
      print('Error searching for cards: $e');
      print('Stack trace: $stackTrace');
      return []; // Return empty list on error
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

  /// **PAGINATED CARD SEARCH - WITH BACKGROUND FETCHING**: Fetch first 3 fast, continue searching in background
  ///
  /// This method implements a two-phase loading strategy:
  /// PHASE 1: Quick initial load (search until we find 3 cards, ~1-3 seconds)
  /// PHASE 2: Background completion (continue searching all sets, cache all cards)
  ///
  /// PARAMETERS:
  /// - pokemonName: The name of the Pokémon to search for (case-insensitive)
  /// - limit: Maximum number of cards to return (default: 3)
  /// - offset: Number of cards to skip before starting (default: 0)
  /// - onBackgroundComplete: Optional callback when background search finishes
  ///
  /// RETURNS:
  /// - Map with keys:
  ///   * 'cards': List of card objects (up to 'limit' cards)
  ///   * 'hasMore': Boolean indicating if more cards exist or are being searched
  ///   * 'totalCount': Total number of cards found so far (updates as search continues)
  ///   * 'isComplete': Boolean indicating if background search has finished
  ///
  /// CACHING STRATEGY:
  /// - Static Map stores all found cards per Pokémon name
  /// - First call (offset=0): Searches until 3 cards found, returns immediately, continues in background
  /// - Subsequent calls: Returns from cache (either partial or complete)
  /// - Cache grows as background search finds more cards
  ///
  /// PERFORMANCE:
  /// - First 3 cards: 1-5 seconds (stops after finding 3, very fast)
  /// - Show More (while searching): Returns next available cards from cache
  /// - Show More (after complete): Instant from full cache
  /// - Background search: Continues until all sets searched (10-30 seconds total)
  static final Map<String, List<Map<String, dynamic>>> _cardsCache = {};
  static final Map<String, bool> _searchComplete = {}; // Track if background search is done

  static Future<Map<String, dynamic>> searchCardsPaginated(
    String pokemonName, {
    int limit = 3,
    int offset = 0,
    Function(int totalFound)? onBackgroundComplete,
  }) async {
    try {
      final cacheKey = pokemonName.toLowerCase();

      // Check if we already have a cache (partial or complete)
      if (_cardsCache.containsKey(cacheKey)) {
        // Return from cache (might be partial if background still searching)
        final allCards = _cardsCache[cacheKey]!;
        final paginatedCards = allCards.skip(offset).take(limit).toList();
        final hasMore = offset + limit < allCards.length || !(_searchComplete[cacheKey] ?? false);
        final isComplete = _searchComplete[cacheKey] ?? false;

        print(' Cache: ${paginatedCards.length} cards (offset: $offset, total: ${allCards.length}, complete: $isComplete)');

        return {
          'cards': paginatedCards,
          'hasMore': hasMore,
          'totalCount': allCards.length,
          'isComplete': isComplete,
        };
      }

      // FIRST TIME - Quick initial search for first 3 cards
      print(' First fetch for "$pokemonName" - finding first $limit cards quickly...');

      final setsUrl = Uri.parse('$_baseUrl/sets');
      final setsResponse = await http.get(setsUrl);

      if (setsResponse.statusCode != 200) {
        return {'cards': [], 'hasMore': false, 'totalCount': 0, 'isComplete': true};
      }

      final dynamic setsData = json.decode(setsResponse.body);
      final List<dynamic> sets = setsData is List ? setsData : [];

      final List<Map<String, dynamic>> quickCards = [];
      int setsSearched = 0;

      // PHASE 1: Quick search - stop after finding 'limit' cards (usually 3)
      for (var set in sets) {
        final setId = set['id'] as String?;
        if (setId == null) continue;

        final setCardsUrl = Uri.parse('$_baseUrl/sets/$setId');
        final setCardsResponse = await http.get(setCardsUrl);

        if (setCardsResponse.statusCode == 200) {
          final dynamic setData = json.decode(setCardsResponse.body);

          if (setData is Map && setData.containsKey('cards')) {
            final List<dynamic> cards = setData['cards'] as List<dynamic>;

            for (var card in cards) {
              if (card is Map<String, dynamic>) {
                final cardName = (card['name'] as String?)?.toLowerCase() ?? '';
                final searchName = pokemonName.toLowerCase();

                if (cardName == searchName) {
                  quickCards.add(card);

                  // EARLY EXIT: Stop searching once we have enough cards for initial display
                  if (quickCards.length >= limit) {
                    // Initialize cache with what we found so far
                    _cardsCache[cacheKey] = List.from(quickCards);
                    _searchComplete[cacheKey] = false; // Not done yet

                    print('⚡ Found first $limit cards quickly! Starting background search...');

                    // Start background search to find remaining cards
                    _continueSearchInBackground(
                      pokemonName,
                      sets,
                      setsSearched,
                      quickCards.length,
                      onBackgroundComplete,
                    );

                    // Return first batch immediately
                    return {
                      'cards': quickCards,
                      'hasMore': true, // Assume more exist (background will confirm)
                      'totalCount': quickCards.length,
                      'isComplete': false,
                    };
                  }
                }
              }
            }
          }
        }

        setsSearched++;
      }

      // If we get here, we searched all sets and found fewer than 'limit' cards
      _cardsCache[cacheKey] = quickCards;
      _searchComplete[cacheKey] = true;

      print(' Search complete! Found ${quickCards.length} total cards (all sets searched)');

      if (onBackgroundComplete != null) {
        onBackgroundComplete(quickCards.length);
      }

      return {
        'cards': quickCards,
        'hasMore': false,
        'totalCount': quickCards.length,
        'isComplete': true,
      };

    } catch (e) {
      print('Error in paginated search: $e');
      return {'cards': [], 'hasMore': false, 'totalCount': 0, 'isComplete': true};
    }
  }

  /// **BACKGROUND SEARCH CONTINUATION**: Continues searching remaining sets in background
  ///
  /// This method runs asynchronously (fire-and-forget) to find all remaining cards
  /// while the user views the first batch. Updates the cache as it finds more cards.
  ///
  /// PARAMETERS:
  /// - pokemonName: Name to search for
  /// - allSets: Full list of sets to search
  /// - startIndex: Which set index to start from (where quick search left off)
  /// - alreadyFound: Number of cards already found in quick search
  /// - onComplete: Callback when background search finishes
  static void _continueSearchInBackground(
    String pokemonName,
    List<dynamic> allSets,
    int startIndex,
    int alreadyFound,
    Function(int totalFound)? onComplete,
  ) async {
    final cacheKey = pokemonName.toLowerCase();
    final searchName = pokemonName.toLowerCase();

    try {
      print(' Background search started from set $startIndex/${allSets.length}...');

      // Continue from where quick search left off
      for (int i = startIndex; i < allSets.length; i++) {
        final set = allSets[i];
        final setId = set['id'] as String?;
        if (setId == null) continue;

        final setCardsUrl = Uri.parse('$_baseUrl/sets/$setId');
        final setCardsResponse = await http.get(setCardsUrl);

        if (setCardsResponse.statusCode == 200) {
          final dynamic setData = json.decode(setCardsResponse.body);

          if (setData is Map && setData.containsKey('cards')) {
            final List<dynamic> cards = setData['cards'] as List<dynamic>;

            for (var card in cards) {
              if (card is Map<String, dynamic>) {
                final cardName = (card['name'] as String?)?.toLowerCase() ?? '';

                if (cardName == searchName) {
                  // Add to cache (thread-safe append)
                  if (_cardsCache.containsKey(cacheKey)) {
                    _cardsCache[cacheKey]!.add(card);
                  }
                }
              }
            }
          }
        }

        // Progress logging every 20 sets
        if ((i - startIndex) % 20 == 0 && i > startIndex) {
          final totalFound = _cardsCache[cacheKey]?.length ?? alreadyFound;
          print('   Background: Searched ${i + 1}/${allSets.length} sets, ${totalFound} cards total...');
        }
      }

      // Background search complete!
      _searchComplete[cacheKey] = true;
      final totalFound = _cardsCache[cacheKey]?.length ?? alreadyFound;

      print(' Background search complete! Found ${totalFound} total cards for "$pokemonName"');

      if (onComplete != null) {
        onComplete(totalFound);
      }

    } catch (e) {
      print('Error in background search: $e');
      _searchComplete[cacheKey] = true; // Mark as complete to prevent infinite searching
    }
  }

  /// Clear the cards cache (useful for memory management or forced refresh)
  static void clearCardsCache() {
    _cardsCache.clear();
    _searchComplete.clear();
    print('Cards cache cleared');
  }
}
