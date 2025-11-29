import '../dtos/pokemon_dto.dart';
import '../../domain/models/Pokemon.dart';

/// Mapper para convertir DTOs a modelos de dominio
class PokemonMapper {
  /// Convierte PokemonDTO a Pokemon (modelo de dominio)
  static Pokemon toDomain(PokemonDTO dto) {
    // Extraer tipos
    final types = dto.types.map((t) => t.name).toList();
    if (types.isEmpty) types.add('Unknown');

    // Construir mapa de estadísticas
    final Map<String, int> statsMap = {};
    int totalStats = 0;
    for (var stat in dto.stats) {
      statsMap[stat.name] = stat.baseStat;
      totalStats += stat.baseStat;
    }

    // Extraer egg groups
    final eggGroups = dto.species?.eggGroups.join(', ') ?? 'Unknown';

    // Convertir abilities a formato Map<String, dynamic>
    final abilities = dto.abilities.map((a) => {
      'pokemon_v2_ability': {'name': a.name},
      'is_hidden': a.isHidden,
    }).toList();

    // Convertir moves a formato Map<String, dynamic>
    final moves = dto.moves.map((m) => {
      'level': m.level,
      'pokemon_v2_move': {
        'name': m.name,
        'power': m.power,
        'accuracy': m.accuracy,
        'pp': m.pp,
        'pokemon_v2_type': m.type != null ? {'name': m.type} : null,
      },
    }).toList();

    return Pokemon(
      id: dto.id,
      name: dto.name,
      types: types,
      height: dto.height,
      weight: dto.weight,
      stats: statsMap,
      totalStats: totalStats,
      genderRate: dto.species?.genderRate,
      eggGroups: eggGroups,
      abilities: abilities,
      moves: moves,
      speciesId: dto.species?.id,
      pokedexEntry: dto.species?.pokedexEntry,
      region: dto.species?.region,
      generation: dto.species?.generation,
    );
  }

  /// Convierte lista de DTOs a lista de modelos de dominio
  static List<Pokemon> toDomainList(List<PokemonDTO> dtos) {
    return dtos.map((dto) => toDomain(dto)).toList();
  }
}
