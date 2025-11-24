import 'package:hive_flutter/hive_flutter.dart';

/// ============================================================================
/// FAVORITES SERVICE - LOCAL STORAGE FOR FAVORITE POKÉMON
/// ============================================================================
///
/// This service manages favorite Pokémon using Hive, a lightweight and fast
/// NoSQL database for Flutter. It uses the Singleton pattern to ensure only
/// one instance exists throughout the app lifecycle.
///
/// KEY FEATURES:
/// - Persistent storage (favorites survive app restarts)
/// - Fast read/write operations (optimized for mobile)
/// - Reactive updates with streams (UI updates automatically)
/// - Type-safe storage (only stores integers - Pokémon IDs)
///
/// ARCHITECTURE:
/// - Singleton Pattern: Only one instance exists globally
/// - Lazy Initialization: Initializes only when first needed
/// - Error Handling: Graceful fallbacks for uninitialized state
///
/// USAGE:
/// 1. Call FavoritesService().init() in main() before runApp()
/// 2. Use FavoritesService() anywhere in the app to access favorites
/// 3. Methods automatically handle initialization if needed
///
/// ============================================================================

class FavoritesService {
  // ============================================================================
  // SINGLETON PATTERN IMPLEMENTATION
  // ============================================================================
  // This ensures only ONE instance of FavoritesService exists in the entire app.
  // No matter how many times you call FavoritesService(), you get the same instance.
  // This is crucial for maintaining a single source of truth for favorites data.

  /// Private static instance - the single instance that will be reused
  static final FavoritesService _instance = FavoritesService._internal();

  /// Factory constructor - returns the existing instance instead of creating new ones
  /// When you call FavoritesService(), this returns _instance
  factory FavoritesService() => _instance;

  /// Private named constructor - prevents external instantiation
  /// Only this class can create instances using FavoritesService._internal()
  FavoritesService._internal();

  // ============================================================================
  // STORAGE CONFIGURATION
  // ============================================================================

  /// Box name for Hive storage
  /// Think of a "box" as a table in a traditional database
  /// This box will store integers (Pokémon IDs)
  static const String _boxName = 'favorites';

  /// Cached reference to the opened Hive box
  /// Once opened, we keep it in memory for fast access
  /// null until init() is called
  Box<int>? _favoritesBox;

  /// Flag to track if the service has been initialized
  /// Prevents re-initialization and handles hot-reload gracefully
  bool _isInitialized = false;

  // ============================================================================
  // INITIALIZATION METHODS
  // ============================================================================

  /// Initialize Hive and open the favorites box
  ///
  /// WHAT IT DOES:
  /// 1. Checks if already initialized (prevents duplicate initialization)
  /// 2. Initializes Hive with Flutter-specific paths (for file storage)
  /// 3. Opens the 'favorites' box (creates it if it doesn't exist)
  /// 4. Marks service as initialized
  ///
  /// WHEN TO CALL:
  /// - Must be called in main() before runApp()
  /// - Async methods will auto-call if forgotten
  ///
  /// WHY IT'S ASYNC:
  /// - File I/O operations (reading from disk) are asynchronous
  /// - Must use 'await' when calling this method
  Future<void> init() async {
    if (_isInitialized) return; // Already initialized - skip

    // Initialize Hive with Flutter-specific configuration
    // This sets up the storage directory path
    await Hive.initFlutter();

    // Open (or create) the favorites box
    // Box<int> means this box only stores integers
    _favoritesBox = await Hive.openBox<int>(_boxName);

    // Mark as initialized to prevent re-initialization
    _isInitialized = true;
  }

  /// Get the favorites box asynchronously, initializing if necessary
  ///
  /// This is a private getter that ensures the box is always ready to use.
  /// If not initialized, it initializes first, then returns the box.
  ///
  /// ASYNC PATTERN:
  /// - Returns Future<Box<int>> instead of Box<int>
  /// - Must use 'await' when calling: await _box
  /// - Guarantees the box is initialized before returning
  Future<Box<int>> get _box async {
    if (_favoritesBox == null || !_isInitialized) {
      await init(); // Initialize if needed
    }
    return _favoritesBox!; // Safe to use ! because we just initialized
  }

  /// Get the favorites box synchronously (only safe after init)
  ///
  /// This is for methods that need immediate access without async/await.
  /// Throws an exception if not initialized.
  ///
  /// WHEN TO USE:
  /// - In synchronous methods like isFavorite(), count, getAllFavorites()
  /// - Only after confirming initialization
  ///
  /// ERROR HANDLING:
  /// - Wrapped in try-catch blocks to return safe defaults
  /// - Prevents crashes during hot reload
  Box<int> get _boxSync {
    if (_favoritesBox == null || !_isInitialized) {
      throw Exception('FavoritesService not initialized. Call init() first or use async methods.');
    }
    return _favoritesBox!;
  }

  // ============================================================================
  // CORE FUNCTIONALITY - ADD, REMOVE, TOGGLE FAVORITES
  // ============================================================================

  /// Add a Pokémon to favorites by ID
  ///
  /// PARAMETERS:
  /// - pokemonId: The unique ID of the Pokémon (e.g., 1 for Bulbasaur)
  ///
  /// RETURNS:
  /// - true: Successfully added (was not already a favorite)
  /// - false: Already in favorites (no action taken)
  ///
  /// EXAMPLE:
  /// bool added = await FavoritesService().addFavorite(25); // Pikachu
  /// if (added) print('Added to favorites!');
  Future<bool> addFavorite(int pokemonId) async {
    final box = await _box; // Ensure box is initialized

    // Check if already exists to avoid duplicates
    if (!box.values.contains(pokemonId)) {
      await box.add(pokemonId); // Add to storage
      return true; // Successfully added
    }
    return false; // Already exists
  }

  /// Remove a Pokémon from favorites by ID
  ///
  /// PARAMETERS:
  /// - pokemonId: The ID of the Pokémon to remove
  ///
  /// RETURNS:
  /// - true: Successfully removed (was in favorites)
  /// - false: Not found in favorites (no action taken)
  ///
  /// HOW IT WORKS:
  /// 1. Converts box values to a list
  /// 2. Finds the index of the Pokémon ID
  /// 3. Deletes at that index
  ///
  /// EXAMPLE:
  /// bool removed = await FavoritesService().removeFavorite(25);
  /// if (removed) print('Removed from favorites!');
  Future<bool> removeFavorite(int pokemonId) async {
    final box = await _box;

    // Find the index of this Pokémon ID in the box
    final index = box.values.toList().indexOf(pokemonId);

    if (index != -1) { // -1 means not found
      await box.deleteAt(index); // Delete at the found index
      return true; // Successfully removed
    }
    return false; // Not found
  }

  /// Toggle favorite status - add if not favorite, remove if favorite
  ///
  /// This is a convenience method for the heart button.
  /// One tap adds, another tap removes - perfect for UI interactions.
  ///
  /// PARAMETERS:
  /// - pokemonId: The ID of the Pokémon to toggle
  ///
  /// RETURNS:
  /// - true: Now a favorite (just added)
  /// - false: No longer a favorite (just removed)
  ///
  /// EXAMPLE:
  /// bool isFav = await FavoritesService().toggleFavorite(25);
  /// print(isFav ? 'Now favorite' : 'Removed from favorites');
  Future<bool> toggleFavorite(int pokemonId) async {
    final box = await _box;

    if (box.values.contains(pokemonId)) {
      // Already a favorite - remove it
      await removeFavorite(pokemonId);
      return false; // No longer favorite
    } else {
      // Not a favorite - add it
      await addFavorite(pokemonId);
      return true; // Now favorite
    }
  }

  // ============================================================================
  // QUERY METHODS - CHECK AND RETRIEVE FAVORITES
  // ============================================================================

  /// Check if a Pokémon is in favorites
  ///
  /// This is a synchronous method for immediate UI updates.
  /// Used to show/hide the heart icon, change colors, etc.
  ///
  /// PARAMETERS:
  /// - pokemonId: The ID to check
  ///
  /// RETURNS:
  /// - true: Is a favorite
  /// - false: Not a favorite (or service not initialized)
  ///
  /// ERROR HANDLING:
  /// - Catches exceptions and returns false instead of crashing
  /// - Handles hot-reload scenarios gracefully
  ///
  /// EXAMPLE:
  /// bool isFav = FavoritesService().isFavorite(25);
  /// Icon icon = isFav ? Icons.favorite : Icons.favorite_border;
  bool isFavorite(int pokemonId) {
    try {
      return _boxSync.values.contains(pokemonId);
    } catch (e) {
      // If not initialized, return false instead of throwing error
      // This prevents crashes during hot reload
      return false;
    }
  }

  /// Get all favorite Pokémon IDs as a list
  ///
  /// Returns a list of all stored Pokémon IDs.
  /// Used to display the favorites page grid.
  ///
  /// RETURNS:
  /// - List<int>: All favorite Pokémon IDs
  /// - Empty list if no favorites or not initialized
  ///
  /// ORDER:
  /// - Order is based on when they were added (first added = first in list)
  ///
  /// EXAMPLE:
  /// List<int> favIds = FavoritesService().getAllFavorites();
  /// print('You have ${favIds.length} favorites');
  /// // Output: [1, 25, 150] (Bulbasaur, Pikachu, Mewtwo)
  List<int> getAllFavorites() {
    try {
      return _boxSync.values.toList();
    } catch (e) {
      return []; // Return empty list if not initialized
    }
  }

  /// Get the number of favorite Pokémon
  ///
  /// Quick count of favorites without creating a list.
  /// Used for the badge counter in the AppBar.
  ///
  /// RETURNS:
  /// - int: Number of favorites (0 if none or not initialized)
  ///
  /// PERFORMANCE:
  /// - O(1) operation - very fast
  /// - Doesn't iterate through items
  ///
  /// EXAMPLE:
  /// int count = FavoritesService().count;
  /// if (count > 0) showBadge(count);
  int get count {
    try {
      return _boxSync.length;
    } catch (e) {
      return 0; // Return 0 if not initialized
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Clear all favorites
  ///
  /// Removes all Pokémon from favorites at once.
  /// Useful for a "Clear All" button or reset functionality.
  ///
  /// WARNING:
  /// - This is permanent and cannot be undone
  /// - Consider showing a confirmation dialog before calling
  ///
  /// EXAMPLE:
  /// await FavoritesService().clearAll();
  /// print('All favorites cleared!');
  Future<void> clearAll() async {
    final box = await _box;
    await box.clear(); // Remove all items from the box
  }

  /// Get a stream to listen for changes in favorites
  ///
  /// REACTIVE PROGRAMMING:
  /// This stream emits events whenever favorites change (add/remove/clear).
  /// Perfect for updating UI automatically without manual refreshes.
  ///
  /// RETURNS:
  /// - Stream<BoxEvent>: Stream of change events
  /// - Empty stream if not initialized
  ///
  /// STREAM EVENTS:
  /// - BoxEvent.put: Item added
  /// - BoxEvent.delete: Item removed
  ///
  /// USAGE WITH STREAMBUILDER:
  /// StreamBuilder<BoxEvent>(
  ///   stream: FavoritesService().watchFavorites(),
  ///   builder: (context, snapshot) {
  ///     // Rebuild when favorites change
  ///     return MyWidget();
  ///   },
  /// )
  ///
  /// EXAMPLE:
  /// FavoritesService().watchFavorites().listen((event) {
  ///   print('Favorites changed! Event: ${event.key}');
  /// });
  Stream<BoxEvent> watchFavorites() {
    try {
      return _boxSync.watch();
    } catch (e) {
      // Return an empty stream if not initialized
      // Prevents errors during hot reload
      return Stream.empty();
    }
  }
}
