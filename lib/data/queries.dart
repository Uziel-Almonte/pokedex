import 'package:graphql_flutter/graphql_flutter.dart';

Future<List<Map<String, dynamic>>> fetchPokemonList(GraphQLClient client, String? _selectedType, int? _selectedGeneration, String? _selectedAbility, int _counter) async {
  // Construir condiciones de filtro dinámicamente
  final whereConditions = <String>[];

  if (_selectedType != null) {
    whereConditions.add('pokemontypes: {type: {name: {_eq: "$_selectedType"}}}');
  }

  if (_selectedGeneration != null) {
    whereConditions.add('pokemonspecy: {generation_id: {_eq: $_selectedGeneration}}');
  }

  if (_selectedAbility != null) {
    whereConditions.add('pokemonabilities: {ability: {name: {_ilike: "%$_selectedAbility%"}}}');
  }

  // Build the WHERE clause
  final whereClause = whereConditions.isNotEmpty
      ? 'where: {${whereConditions.join(', ')}}'
      : '';


  final query = '''
    query GetPokemonList {
      pokemon($whereClause limit: 50, offset: ${(_counter - 1) * 50}, order_by: {id: asc}) { 
        id 
        name 
        pokemontypes {
          type {
            name 
          }
        }
        pokemonabilities {
          ability {
            name
          }
        }
        pokemonspecy {
          generation_id
        }
      }
    }
  ''';
  // Execute the query using the GraphQL client
  final result = await client.query(QueryOptions(document: gql(query)));
  // Extract the species data from the result
  final pokemons = result.data?['pokemon'] as List<dynamic>?;

  // Return the first species if available, otherwise null
  return pokemons?.cast<Map<String, dynamic>>() ?? [];
}



Future<Map<String, dynamic>?> fetchPokemon(int id, GraphQLClient client) async {
  // Define the GraphQL query to get Pokémon species by ID
  // Now includes base stats (HP, Attack, Defense, Special Attack, Special Defense, Speed)
  final query = '''
      query GetPokemonById {
        pokemon(where: {id: {_eq: $id}}) {
          id
          name
          height
          weight
          pokemontypes{
              type{
                 name
              }
          }
          pokemonstats{
            base_stat
            stat{
              name
            }
          }
          pokemonabilities{
            ability{
              name
            }
            is_hidden
          }
          pokemonmoves(order_by: {level: asc}) {
            level
            move {
              name
              power
              accuracy
              pp
              type {
                name
              }
            }
          }
          pokemonspecy {
            gender_rate
            pokemonegggroups {
              egggroup {
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
  final species = result.data?['pokemon'];
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
      pokemon(where: {name: {_ilike: "%$name%"}}, limit: 20) {
        id
        name
        pokemontypes {
          type {
            name
          }
        }
        pokemonabilities {
          ability {
            name
          }
        }
      }
    }
  ''';
  // Execute the query using the GraphQL client
  final result = await client.query(QueryOptions(document: gql(query)));
  // Extract the species data from the result
  final pokemons = result.data?['pokemon'] as List<dynamic>?;
  // Return the first species if available, otherwise null
  return pokemons?.cast<Map<String, dynamic>>() ?? [];
}

Future<Map<String, dynamic>?> searchSinglePokemonByName(String name, GraphQLClient client) async {
  final results = await searchPokemonByName(name, client);
  return results.isNotEmpty ? results.first : null;
}