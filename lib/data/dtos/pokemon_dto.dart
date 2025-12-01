/// DTO para transferencia de datos desde GraphQL
/// Representa la estructura RAW de la API antes de convertir al modelo de dominio
class PokemonDTO {
  final int id;
  final String name;
  final int? height;
  final int? weight;
  final List<PokemonTypeDTO> types;
  final List<PokemonStatDTO> stats;
  final List<PokemonAbilityDTO> abilities;
  final List<PokemonMoveDTO> moves;
  final PokemonSpeciesDTO? species;

  const PokemonDTO({
    required this.id,
    required this.name,
    this.height,
    this.weight,
    required this.types,
    required this.stats,
    required this.abilities,
    required this.moves,
    this.species,
  });

  /// Factory constructor desde datos GraphQL RAW
  factory PokemonDTO.fromGraphQL(Map<String, dynamic> json) {
    return PokemonDTO(
      id: json['id'] as int,
      name: json['name'] as String,
      height: json['height'] as int?,
      weight: json['weight'] as int?,
      types: (json['pokemon_v2_pokemontypes'] as List<dynamic>?)
          ?.map((t) => PokemonTypeDTO.fromGraphQL(t as Map<String, dynamic>))
          .toList() ?? [],
      stats: (json['pokemon_v2_pokemonstats'] as List<dynamic>?)
          ?.map((s) => PokemonStatDTO.fromGraphQL(s as Map<String, dynamic>))
          .toList() ?? [],
      abilities: (json['pokemon_v2_pokemonabilities'] as List<dynamic>?)
          ?.map((a) => PokemonAbilityDTO.fromGraphQL(a as Map<String, dynamic>))
          .toList() ?? [],
      moves: (json['pokemon_v2_pokemonmoves'] as List<dynamic>?)
          ?.map((m) => PokemonMoveDTO.fromGraphQL(m as Map<String, dynamic>))
          .toList() ?? [],
      species: json['pokemon_v2_pokemonspecy'] != null
          ? PokemonSpeciesDTO.fromGraphQL(json['pokemon_v2_pokemonspecy'] as Map<String, dynamic>)
          : null,
    );
  }
}

class PokemonTypeDTO {
  final String name;

  const PokemonTypeDTO({required this.name});

  factory PokemonTypeDTO.fromGraphQL(Map<String, dynamic> json) {
    return PokemonTypeDTO(
      name: json['pokemon_v2_type']?['name'] as String? ?? 'unknown',
    );
  }
}

class PokemonStatDTO {
  final String name;
  final int baseStat;

  const PokemonStatDTO({
    required this.name,
    required this.baseStat,
  });

  factory PokemonStatDTO.fromGraphQL(Map<String, dynamic> json) {
    return PokemonStatDTO(
      name: json['pokemon_v2_stat']?['name'] as String? ?? 'unknown',
      baseStat: json['base_stat'] as int? ?? 0,
    );
  }
}

class PokemonAbilityDTO {
  final String name;
  final bool isHidden;

  const PokemonAbilityDTO({
    required this.name,
    required this.isHidden,
  });

  factory PokemonAbilityDTO.fromGraphQL(Map<String, dynamic> json) {
    return PokemonAbilityDTO(
      name: json['pokemon_v2_ability']?['name'] as String? ?? 'unknown',
      isHidden: json['is_hidden'] as bool? ?? false,
    );
  }
}

class PokemonMoveDTO {
  final String name;
  final int level;
  final int? power;
  final int? accuracy;
  final int? pp;
  final String? type;
  final String? learnMethod;

  const PokemonMoveDTO({
    required this.name,
    required this.level,
    this.power,
    this.accuracy,
    this.pp,
    this.type,
    this.learnMethod,
  });

  factory PokemonMoveDTO.fromGraphQL(Map<String, dynamic> json) {
    final move = json['pokemon_v2_move'];
    return PokemonMoveDTO(
      name: move?['name'] as String? ?? 'unknown',
      level: json['level'] as int? ?? 0,
      power: move?['power'] as int?,
      accuracy: move?['accuracy'] as int?,
      pp: move?['pp'] as int?,
      type: move?['pokemon_v2_type']?['name'] as String?,
      learnMethod: json['pokemon_v2_movelearnmethod']?['name'] as String?,
    );
  }
}

class PokemonSpeciesDTO {
  final int id;
  final int? genderRate;
  final int? generationId;
  final List<String> eggGroups;
  final String? pokedexEntry;
  final String? region;
  final String? generation;

  const PokemonSpeciesDTO({
    required this.id,
    this.genderRate,
    this.generationId,
    required this.eggGroups,
    this.pokedexEntry,
    this.region,
    this.generation,
  });

  factory PokemonSpeciesDTO.fromGraphQL(Map<String, dynamic> json) {
    final eggGroups = (json['pokemon_v2_pokemonegggroups'] as List<dynamic>?)
        ?.map((eg) => eg['pokemon_v2_egggroup']?['name'] as String?)
        .whereType<String>()
        .toList() ?? [];

    final flavorTexts = (json['pokemon_v2_pokemonspeciesflavortexts'] as List<dynamic>?) ?? [];
    String? pokedexEntry;
    if (flavorTexts.isNotEmpty) {
      pokedexEntry = flavorTexts[0]['flavor_text'] as String?;
      pokedexEntry = pokedexEntry?.replaceAll('\n', ' ').replaceAll('\f', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    }

    final generation = json['pokemon_v2_generation'];

    return PokemonSpeciesDTO(
      id: json['id'] as int,
      genderRate: json['gender_rate'] as int?,
      generationId: json['generation_id'] as int?,
      eggGroups: eggGroups,
      pokedexEntry: pokedexEntry,
      region: generation?['pokemon_v2_region']?['name'] as String?,
      generation: generation?['name'] as String?,
    );
  }
}
