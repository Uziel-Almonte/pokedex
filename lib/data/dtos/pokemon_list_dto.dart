import '../../domain/models/Pokemon.dart';

/// Lightweight model for displaying Pokémon in list views
/// Contains only essential data needed for cards in HomePageState
class PokemonListItem {
  final int id;
  final String name;
  final List<String> types;
  final int? generationId;

  PokemonListItem({
    required this.id,
    required this.name,
    required this.types,
    this.generationId,
  });

  /// Factory from GraphQL - lightweight query data
  factory PokemonListItem.fromGraphQL(Map<String, dynamic> data) {
    return PokemonListItem(
      id: data['id'],
      name: data['name'],
      types: List<String>.from(
          data['pokemon_v2_pokemontypes']?.map(
                  (t) => t['pokemon_v2_type']['name']
          ) ?? []
      ),
      generationId: data['pokemon_v2_pokemonspecy']?['generation_id'],
    );
  }

  /// Factory from full Pokemon model - for conversion when needed
  factory PokemonListItem.fromPokemon(Pokemon pokemon) {
    return PokemonListItem(
      id: pokemon.id,
      name: pokemon.name,
      types: pokemon.types,
      generationId: null,
    );
  }

  String get typesString => types.join(', ');

  String get imageUrl =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';
}
