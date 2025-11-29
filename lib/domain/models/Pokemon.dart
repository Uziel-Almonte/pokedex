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

  String get formattedHeight => ((height ?? 0) / 10 * 3.28084).toStringAsFixed(1);
  String get formattedWeight => ((weight ?? 0) / 10 * 2.20462).toStringAsFixed(1);
  String get typesString => types.join(', ');
}


