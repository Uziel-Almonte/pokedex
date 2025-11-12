import 'package:graphql_flutter/graphql_flutter.dart';

Future<List<Map<String, dynamic>>> fetchPokemonList(GraphQLClient client, String? _selectedType, int? _selectedGeneration, String? _selectedAbility, String sortOrder, int _counter) async {
  // Construir condiciones de filtro dinámicamente
  final whereConditions = <String>[];

  if (_selectedType != null) {
    whereConditions.add('pokemon_v2_pokemontypes: {pokemon_v2_type: {name: {_eq: "$_selectedType"}}}');
  }

  if (_selectedGeneration != null) {
    whereConditions.add('pokemon_v2_pokemonspecy: {generation_id: {_eq: $_selectedGeneration}}');
  }

  if (_selectedAbility != null) {
    whereConditions.add('pokemon_v2_pokemonabilities: {pokemon_v2_ability: {name: {_ilike: "%$_selectedAbility%"}}}');
  }

  // Build the WHERE clause
  final whereClause = whereConditions.isNotEmpty
      ? 'where: {${whereConditions.join(', ')}}'
      : '';


  final query = '''
    query GetPokemonList {
      pokemon_v2_pokemon($whereClause limit: 50, offset: ${(_counter - 1) * 50}, order_by: {id: $sortOrder}) { 
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
  // Execute the query using the GraphQL client
  final result = await client.query(QueryOptions(document: gql(query)));
  // Extract the species data from the result
  final pokemons = result.data?['pokemon_v2_pokemon'] as List<dynamic>?;

  // Return the first species if available, otherwise null
  return pokemons?.cast<Map<String, dynamic>>() ?? [];
}



Future<Map<String, dynamic>?> fetchPokemon(int id, GraphQLClient client) async {
  // Define the GraphQL query to get Pokémon species by ID
  // Now includes base stats (HP, Attack, Defense, Special Attack, Special Defense, Speed)
  final query = '''
      query GetPokemonById {
        pokemon_v2_pokemon(where: {id: {_eq: $id}}) {
          id
          name
          height
          weight
          pokemon_v2_pokemontypes{
              pokemon_v2_type{
                 name
              }
          }
          pokemon_v2_pokemonstats{
            base_stat
            pokemon_v2_stat{
              name
            }
          }
          pokemon_v2_pokemonabilities{
            pokemon_v2_ability{
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
            gender_rate
            pokemon_v2_pokemonegggroups {
              pokemon_v2_egggroup {
                name
              }
            }
          }
        }
      }
    ''';
  // Execute the query using the GraphQL client
  final result = await client.query(QueryOptions(document: gql(query)));
  // Extract the species data from the result
  final species = result.data?['pokemon_v2_pokemon'];
  // Return the first species if available, otherwise null
  return (species != null && species.isNotEmpty) ? species[0] : null;
}

Future<List<Map<String, dynamic>>> searchPokemonByName(String name, GraphQLClient client) async {
  // GraphQL query with WHERE clause for name matching
  // _ilike: case-insensitive pattern matching (PostgreSQL operator)
  // %$name%: matches any string containing the search term
  // Example: searching "pika" will match "pikachu"
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
        pokemon_v2_pokemonabilities {
          pokemon_v2_ability {
            name
          }
        }
      }
    }
  ''';
  // Execute the query using the GraphQL client
  final result = await client.query(QueryOptions(document: gql(query)));
  // Extract the species data from the result
  final pokemons = result.data?['pokemon_v2_pokemon'] as List<dynamic>?;
  // Return the first species if available, otherwise null
  return pokemons?.cast<Map<String, dynamic>>() ?? [];
}

Future<Map<String, dynamic>?> searchSinglePokemonByName(String name, GraphQLClient client) async {
  final results = await searchPokemonByName(name, client);
  return results.isNotEmpty ? results.first : null;
}