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
  });

  factory Pokemon.fromGraphQL(Map<String, dynamic> data) {
    // Extract types
    final types = (data['pokemontypes'] as List<dynamic>?)
        ?.map((t) => t['type']?['name'] as String?)
        .whereType<String>()
        .toList() ?? ['Unknown'];

    // Extract stats
    final statsData = (data['pokemonstats'] as List<dynamic>?) ?? [];

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
      final statName = stat['stat']?['name'] as String?;
      final baseStat = stat['base_stat'] as int?;
      if (statName != null && baseStat != null) {
        statsMap[statName] = baseStat;
        total += baseStat;
      }
    }

    // Extract egg groups
    final eggGroups = (data['pokemonspecy']?['pokemonegggroups'] as List<dynamic>?)
        ?.map((eg) => eg['egggroup']?['name'] as String?)
        .whereType<String>()
        .join(', ') ?? 'Unknown';

    return Pokemon(
      id: data['id'] as int,
      name: data['name'] as String,
      types: types,
      height: data['height'] as int?,
      weight: data['weight'] as int?,
      stats: statsMap,
      totalStats: total,
      genderRate: data['pokemonspecy']?['gender_rate'] as int?,
      eggGroups: eggGroups,
    );
  }

  String get formattedHeight => ((height ?? 0) / 10 * 3.28084).toStringAsFixed(1);
  String get formattedWeight => ((weight ?? 0) / 10 * 2.20462).toStringAsFixed(1);
  String get typesString => types.join(', ');
}
