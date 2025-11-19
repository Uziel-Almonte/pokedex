import 'package:graphql_flutter/graphql_flutter.dart';

/**
 * QUERIES.DART - GraphQL Query Functions
 *
 * This file contains all GraphQL query functions for fetching Pokémon data.
 * Each function builds a GraphQL query string, executes it, and returns structured data.
 */

/**
 * FETCH POKEMON - Get complete details for a single Pokémon by ID
 */
Future<Map<String, dynamic>?> fetchPokemon(int id, GraphQLClient client) async {
  final query = '''
    query GetPokemonById {
      pokemon_v2_pokemon(where: {id: {_eq: $id}}) {
        id
        name
        height
        weight
        pokemon_v2_pokemontypes {
          pokemon_v2_type {
            name
          }
        }
        pokemon_v2_pokemonstats {
          base_stat
          pokemon_v2_stat {
            name
          }
        }
        pokemon_v2_pokemonabilities {
          pokemon_v2_ability {
            name
          }
          is_hidden
        }
        pokemon_v2_pokemonmoves(order_by: {level: asc}) {
          level
          pokemon_v2_move {
            name
            power
            accuracy
            pp
            pokemon_v2_type {
              name
            }
          }
        }
        pokemon_v2_pokemonspecy {
          id
          gender_rate
          generation_id
          pokemon_v2_pokemonegggroups {
            pokemon_v2_egggroup {
              name
            }
          }
        }
      }
    }
  ''';

  final result = await client.query(QueryOptions(document: gql(query)));
  final species = result.data?['pokemon_v2_pokemon'];
  return (species != null && species.isNotEmpty) ? species[0] : null;
}

/**
 * FETCH POKEMON LIST - Get paginated list with filters
 */
Future<List<Map<String, dynamic>>> fetchPokemonList(
  GraphQLClient client,
  String? selectedType,
  int? selectedGeneration,
  String? selectedAbility,
  String sortOrder,
  int counter
) async {
  // Build dynamic filter conditions
  List<String> whereConditions = [];

  // Type filter
  if (selectedType != null && selectedType.isNotEmpty) {
    whereConditions.add(
      'pokemon_v2_pokemontypes: {pokemon_v2_type: {name: {_eq: "$selectedType"}}}'
    );
  }

  // Generation filter
  if (selectedGeneration != null) {
    whereConditions.add(
      'pokemon_v2_pokemonspecy: {generation_id: {_eq: $selectedGeneration}}'
    );
  }

  // Ability filter
  if (selectedAbility != null && selectedAbility.isNotEmpty) {
    whereConditions.add(
      'pokemon_v2_pokemonabilities: {pokemon_v2_ability: {name: {_ilike: "%$selectedAbility%"}}}'
    );
  }

  // Build WHERE clause
  final whereClause = whereConditions.isNotEmpty
    ? 'where: {${whereConditions.join(', ')}}'
    : '';

  // Calculate offset for pagination
  final offset = (counter - 1) * 50;
  final orderDirection = sortOrder == 'desc' ? 'desc' : 'asc';

  final query = '''
    query GetPokemonList {
      pokemon_v2_pokemon($whereClause, limit: 50, offset: $offset, order_by: {id: $orderDirection}) {
        id
        name
        pokemon_v2_pokemontypes {
          pokemon_v2_type {
            name
          }
        }
        pokemon_v2_pokemonabilities {
          pokemon_v2_ability {
            name
          }
        }
        pokemon_v2_pokemonspecy {
          generation_id
        }
      }
    }
  ''';

  final result = await client.query(QueryOptions(document: gql(query)));
  final pokemons = result.data?['pokemon_v2_pokemon'] as List<dynamic>?;
  return pokemons?.cast<Map<String, dynamic>>() ?? [];
}

/**
 * SEARCH POKEMON BY NAME - Returns list of matching Pokémon
 */
Future<List<Map<String, dynamic>>> searchPokemonByName(String name, GraphQLClient client) async {
  final query = '''
    query SearchPokemonByName {
      pokemon_v2_pokemon(where: {name: {_ilike: "%$name%"}}, limit: 20) {
        id
        name
        pokemon_v2_pokemontypes {
          pokemon_v2_type {
            name
          }
        }
        pokemon_v2_pokemonspecy {
          generation_id
        }
      }
    }
  ''';

  final result = await client.query(QueryOptions(document: gql(query)));
  final pokemons = result.data?['pokemon_v2_pokemon'] as List<dynamic>?;
  return pokemons?.cast<Map<String, dynamic>>() ?? [];
}

/**
 * SEARCH SINGLE POKEMON BY NAME - Returns first matching Pokémon
 */
Future<Map<String, dynamic>?> searchSinglePokemonByName(String name, GraphQLClient client) async {
  final results = await searchPokemonByName(name, client);
  return results.isNotEmpty ? results.first : null;
}

/**
 * FETCH EVOLUTION CHAIN - Get evolution data for a species
 */
Future<Map<String, dynamic>?> fetchEvolutionChain(int speciesId, GraphQLClient client) async {
  final query = '''
    query GetEvolutionChain {
      pokemon_v2_pokemonspecies(where: {id: {_eq: $speciesId}}) {
        id
        name
        pokemon_v2_evolutionchain {
          pokemon_v2_pokemonspecies(order_by: {order: asc}) {
            id
            name
            evolves_from_species_id
            pokemon_v2_pokemonevolutions {
              min_level
              evolution_item_id
              pokemon_v2_item {
                name
              }
            }
            pokemon_v2_pokemons(limit: 1) {
              id
            }
          }
        }
      }
    }
  ''';

  // Executes the query
  final result = await client.query(QueryOptions(document: gql(query)));

  // returns the map of data for the pokemon
  final species = result.data?['pokemon_v2_pokemonspecies'];
  // returns the first element in the list (the map itself)
  return (species != null && species.isNotEmpty) ? species[0] : null;
}

