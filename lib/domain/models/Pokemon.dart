class Pokemon {
  final int id;
  final String name;
  final List<String> types;
  final int? height;
  final int? weight;
  final Map<String, int> stats;
  final int totalStats;
  final int? genderRate;
  final String eggGroups;
  final List<Map<String, dynamic>> abilities;
  final List<Map<String, dynamic>> moves;
  final int? speciesId;

  // ✨ NEW: Pokédex entry (flavor text)
  // This is the official description text from the Pokémon games
  // Example: "A strange seed was planted on its back at birth. The plant sprouts and grows with this Pokémon."
  // Extracted from pokemon_v2_pokemonspeciesflavortexts (language_id: 9 = English)
  final String? pokedexEntry;

  // ✨ NEW: Region of origin
  // The region where this Pokémon was first discovered
  // Examples: "kanto", "johto", "hoenn", "sinnoh", "unova", "kalos", "alola", "galar", "paldea"
  // Extracted from pokemon_v2_generation -> pokemon_v2_region -> name
  final String? region;

  // ✨ NEW: Generation introduced
  // The generation when this Pokémon was first added to the franchise
  // Format: "generation-i", "generation-ii", etc.
  // Extracted from pokemon_v2_generation -> name
  final String? generation;

  Pokemon({
    required this.id,
    required this.name,
    required this.types,
    this.height,
    this.weight,
    required this.stats,
    required this.totalStats,
    this.genderRate,
    required this.eggGroups,
    this.abilities = const [],
    this.moves = const [],
    this.speciesId,
    this.pokedexEntry,
    this.region,
    this.generation,
  });

  factory Pokemon.fromGraphQL(Map<String, dynamic> data) {
    // Extract types
    final types = (data['pokemon_v2_pokemontypes'] as List<dynamic>?)
        ?.map((t) => t['pokemon_v2_type']?['name'] as String?)
        .whereType<String>()
        .toList() ?? ['Unknown'];

    // Extract stats
    final statsData = (data['pokemon_v2_pokemonstats'] as List<dynamic>?) ?? [];

    // CREATE A MAP TO ORGANIZE STATS BY NAME
    // This map allows us to access stats by their name (e.g., 'hp', 'attack')
    // instead of iterating through the list every time we need a specific stat
    // Example: statsMap['hp'] = 45, statsMap['attack'] = 60
    final Map<String, int> statsMap = {};

    // CALCULATE TOTAL STATS
    // Variable to accumulate the sum of all base stats
    // This gives us the overall power level of the Pokémon
    // Typical range: 180-780 (Shedinja has lowest, Eternamax has highest)
    int total = 0;


    // LOOP THROUGH ALL STATS AND ORGANIZE THEM
    // The API returns stats with structure: {base_stat: 45, stat: {name: "hp"}}
    // We extract both the name and value, then store in our map
    for (var stat in statsData) {
      final statName = stat['pokemon_v2_stat']?['name'] as String?;
      final baseStat = stat['base_stat'] as int?;
      if (statName != null && baseStat != null) {
        statsMap[statName] = baseStat;
        total += baseStat;
      }
    }

    // Extract egg groups
    final eggGroups = (data['pokemon_v2_pokemonspecy']?['pokemon_v2_pokemonegggroups'] as List<dynamic>?)
        ?.map((eg) => eg['pokemon_v2_egggroup']?['name'] as String?)
        .whereType<String>()
        .join(', ') ?? 'Unknown';

    // abilities - handle multiple possible key names
    final rawAbilities = data['pokemon_v2_pokemonabilities'] ?? data['abilities'] ?? [];
    final abilities = (rawAbilities is List) ? rawAbilities.cast<Map<String, dynamic>>() : <Map<String, dynamic>>[];

    final rawMoves = data['pokemon_v2_pokemonmoves'] ?? data['moves'] ?? [];
    final moves = (rawMoves is List) ? rawMoves.cast<Map<String, dynamic>>() : <Map<String, dynamic>>[];

    // ✨ NEW: Extract Pokedex entry (flavor text)
    // WHAT IT DOES:
    // 1. Fetches flavor text entries from the API (filtered for English, language_id: 9)
    // 2. Takes the most recent version's entry (order_by: version_id desc, limit: 1)
    // 3. Cleans up the text by removing special characters and normalizing whitespace
    //
    // WHY WE CLEAN IT:
    // - API returns text with newline characters (\n) and form feed characters (\f)
    // - These come from the original game's text formatting
    // - We replace them with spaces for better display in the UI
    // - We also collapse multiple spaces into single spaces with RegExp(r'\s+')
    //
    // EXAMPLE TRANSFORMATION:
    // Input:  "A strange seed was\nplanted on its\fback at birth."
    // Output: "A strange seed was planted on its back at birth."
    final flavorTexts = (data['pokemon_v2_pokemonspecy']?['pokemon_v2_pokemonspeciesflavortexts'] as List<dynamic>?) ?? [];
    String? pokedexEntry;
    if (flavorTexts.isNotEmpty) {
      pokedexEntry = flavorTexts[0]['flavor_text'] as String?;
      // Clean up the flavor text (remove newlines and extra spaces)
      pokedexEntry = pokedexEntry?.replaceAll('\n', ' ').replaceAll('\f', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    }

    // ✨ NEW: Extract region and generation
    // WHAT IT DOES:
    // 1. Navigates through nested GraphQL data structure
    // 2. Gets generation data from species (pokemon_v2_pokemonspecy -> pokemon_v2_generation)
    // 3. Extracts region name from generation (pokemon_v2_generation -> pokemon_v2_region -> name)
    // 4. Extracts generation name (pokemon_v2_generation -> name)
    //
    // DATA STRUCTURE:
    // pokemon_v2_pokemonspecy: {
    //   pokemon_v2_generation: {
    //     name: "generation-i",
    //     pokemon_v2_region: {
    //       name: "kanto"
    //     }
    //   }
    // }
    //
    // GENERATION TO REGION MAPPING:
    // Generation I → Kanto       | Generation VI → Kalos
    // Generation II → Johto      | Generation VII → Alola
    // Generation III → Hoenn     | Generation VIII → Galar
    // Generation IV → Sinnoh     | Generation IX → Paldea
    // Generation V → Unova       |
    final generation = data['pokemon_v2_pokemonspecy']?['pokemon_v2_generation'];
    final region = generation?['pokemon_v2_region']?['name'] as String?;
    final generationName = generation?['name'] as String?;

    return Pokemon(
      id: data['id'] as int,
      name: data['name'] as String,
      types: types,
      height: data['height'] as int?,
      weight: data['weight'] as int?,
      stats: statsMap,
      totalStats: total,
      genderRate: data['pokemon_v2_pokemonspecy']?['gender_rate'] as int?,
      eggGroups: eggGroups,
      abilities: abilities,
      moves: moves,
      speciesId: data['pokemon_v2_pokemonspecy']?['id'] as int?,
      pokedexEntry: pokedexEntry,  // ✨ NEW: Pass cleaned Pokédex text
      region: region,                // ✨ NEW: Pass region name
      generation: generationName,    // ✨ NEW: Pass generation name
    );
  }

  String get formattedHeight => ((height ?? 0) / 10 * 3.28084).toStringAsFixed(1);
  String get formattedWeight => ((weight ?? 0) / 10 * 2.20462).toStringAsFixed(1);
  String get typesString => types.join(', ');
}
