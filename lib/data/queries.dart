import 'package:graphql_flutter/graphql_flutter.dart';
import 'dtos/pokemon_dto.dart';
import 'dtos/pokemon_list_dto.dart';
import 'mappers/pokemon_mapper.dart';
import '../domain/models/Pokemon.dart';

/**
 * QUERIES.DART - GraphQL Query Functions
 *
 * This file contains all GraphQL query functions for fetching Pokémon data.
 * Each function builds a GraphQL query string, executes it, and returns structured data.
 */

/**
 * FETCH POKEMON - Get complete details for a single Pokémon by ID
 *
 * This function fetches comprehensive data for a single Pokémon including:
 * - Basic info (id, name, height, weight)
 * - Types (fire, water, grass, etc.)
 * - Base stats (HP, Attack, Defense, Sp. Attack, Sp. Defense, Speed)
 * - Abilities (normal and hidden)
 * - Moves (level-up, TM, egg moves, etc.)
 * - Species data (gender rate, egg groups, generation)
 * - ✨ NEW: Pokédex entry (flavor text description)
 * - ✨ NEW: Region and generation information
 */
Future<Pokemon?> fetchPokemon(int id, GraphQLClient client) async {
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
          pokemon_v2_movelearnmethod { 
            name
          }
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
          # ✨ NEW: Fetch generation and region data
          # This nested query navigates through the species relationship to get:
          # 1. Generation name (e.g., "generation-i", "generation-iv")
          # 2. Region name (e.g., "kanto", "johto", "hoenn")
          # The generation table links to the region table, showing where Pokémon originated
          pokemon_v2_generation {
            name
            pokemon_v2_region {
              name
            }
          }
          # ✨ NEW: Fetch Pokédex entries (flavor text)
          # FILTER EXPLANATION:
          # - language_id: {_eq: 9} → Gets English text only (9 = English)
          # - limit: 1 → Gets only one entry (most recent)
          # - order_by: {version_id: desc} → Sorts by game version, newest first
          #
          # WHY WE FILTER:
          # - Each Pokémon has ~50+ flavor texts across all games and languages
          # - We only want one English description for the detail page
          # - We prefer the most recent game's description
          #
          # EXAMPLE DATA RETURNED:
          # {
          #   flavor_text: "A strange seed was planted on its back at birth...",
          #   pokemon_v2_version: {
          #     name: "scarlet"
          #   }
          # }
          pokemon_v2_pokemonspeciesflavortexts(where: {language_id: {_eq: 9}}, limit: 1, order_by: {version_id: desc}) {
            flavor_text
            pokemon_v2_version {
              name
            }
          }
        }
      }
    }
  ''';

  final result = await client.query(QueryOptions(document: gql(query)));
  final pokemon_raw = result.data?['pokemon_v2_pokemon'];

  if (pokemon_raw != null && pokemon_raw.isNotEmpty) {
    final dto = PokemonDTO.fromGraphQL(pokemon_raw[0]);
    return PokemonMapper.toDomain(dto);
  }
  return null;
}

/**
 * FETCH POKEMON LIST - Get paginated list with filters
 */
Future<List<PokemonListItem>> fetchPokemonList(
  GraphQLClient client,
  String? selectedType,
  int? selectedGeneration,
  String? selectedAbility,
  String sortOrder,
    String sortBy,
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

  final orderByField = sortBy == 'name' ? 'name' : 'id';

  final query = '''
    query GetPokemonList {
      pokemon_v2_pokemon($whereClause, limit: 50, offset: $offset, order_by: {$orderByField: $orderDirection}) {
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
  final pokemons = result.data?['pokemon_v2_pokemon'] as List<dynamic>? ?? [];

  // Return the list directly
  return pokemons
      .map((p) => PokemonListItem.fromGraphQL(p as Map<String, dynamic>))
      .toList();
}

/**
 * SEARCH POKEMON BY NAME - Returns list of matching Pokémon
 */
Future<List<PokemonListItem>> searchPokemonByName(String name, GraphQLClient client, int counter) async {

  final offset = (counter - 1) * 50;
  final query = '''
    query SearchPokemonByName {
      pokemon_v2_pokemon(where: {name: {_ilike: "%$name%"}}, limit: 50, offset: $offset, order_by: {id: asc}) {
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
  final pokemons = result.data?['pokemon_v2_pokemon'] as List<dynamic>? ?? [];

  return pokemons
      .take(50) // Take only 50, use length > 50 to determine hasMore in bloc
      .map((p) => PokemonListItem.fromGraphQL(p as Map<String, dynamic>))
      .toList();
}

/**
 * SEARCH SINGLE POKEMON BY NAME - Returns first matching Pokémon
 */
Future<PokemonListItem?> searchSinglePokemonByName(String name, GraphQLClient client) async {
  final results = await searchPokemonByName(name, client, 1);
  return results.isNotEmpty ? results.first : null;
}


/**
 * SEARCH SINGLE POKEMON BY NAME (FULL DATA) - Returns first matching Pokémon with complete details
 * Used in detail page search functionality
 */
Future<Pokemon?> searchPokemonByNameFull(String name, GraphQLClient client) async {
  final query = '''
    query SearchPokemonByName {
      pokemon_v2_pokemon(
        where: {name: {_ilike: "%$name%"}},
        limit: 1
      ) {
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
          is_hidden
          pokemon_v2_ability {
            name
          }
        }
        pokemon_v2_pokemonmoves {
          level
          pokemon_v2_movelearnmethod {  
            name
          }
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
          pokemon_v2_pokemonspeciesflavortexts(
            where: {language_id: {_eq: 9}},
            order_by: {version_id: desc},
            limit: 1
          ) {
            flavor_text
          }
          pokemon_v2_generation {
            name
            pokemon_v2_region {
              name
            }
          }
        }
      }
    }
  ''';

  final result = await client.query(QueryOptions(document: gql(query)));
  final pokemon = result.data?['pokemon_v2_pokemon'] as List<dynamic>? ?? [];

  if (pokemon.isNotEmpty) {
    final dto = PokemonDTO.fromGraphQL(pokemon[0] as Map<String, dynamic>);
    return PokemonMapper.toDomain(dto);
  }
  return null;
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

/**
 * FETCH POKEMON FORMS - Get all available forms/variants for a species
 *
 * This function fetches all different forms of a Pokemon (e.g., Alola, Galar, Mega, etc.)
 * Returns a list of form names and their corresponding Pokemon IDs
 *
 * EXAMPLE FORMS:
 * - Raichu: Normal, Alola
 * - Meowth: Normal, Alola, Galar
 * - Darmanitan: Standard, Zen, Galar-Standard, Galar-Zen
 * - Charizard: Normal, Mega-X, Mega-Y, Gigantamax
 *
 * HOW IT WORKS:
 * 1. Queries pokemon_v2_pokemonspecies by species ID
 * 2. Gets all pokemon_v2_pokemons (each represents a different form)
 * 3. For each pokemon, extracts form information from:
 *    - pokemon_v2_pokemonforms.pokemon_v2_pokemonformnames (human-readable names)
 *    - pokemon_v2_pokemonforms.form_name (internal form identifier)
 *    - Pokemon name itself (e.g., "raichu-alola" → "Alola Form")
 * 4. Returns list of forms with IDs and readable names
 *
 * FORM NAME EXTRACTION PRIORITY:
 * Priority 1: pokemon_name from pokemon_v2_pokemonformnames (most reliable)
 * Priority 2: Parse form_name field
 * Priority 3: Extract from pokemon name (e.g., "raichu-alola" → "Alola Form")
 *
 * @param speciesId - The species ID (NOT pokemon ID, but species ID from pokemon_v2_pokemonspecy)
 * @param client - GraphQL client for making the query
 * @return List of maps containing: id, name, formName, isDefault, isMega
 */
Future<List<Map<String, dynamic>>> fetchPokemonForms(int speciesId, GraphQLClient client) async {
  final query = '''
    query GetPokemonForms {
      # Query the species table to get all pokemon entries for this species
      # IMPORTANT: We query by species_id, not pokemon_id
      # Example: Raichu species (id=26) has 2 pokemon entries: raichu (id=26) and raichu-alola (id=10100)
      pokemon_v2_pokemonspecies(where: {id: {_eq: $speciesId}}) {
        
        # Get all pokemon entries for this species, ordered by ID (default form first)
        # Each entry in pokemon_v2_pokemons represents a different form
        # Example for Raichu:
        #   - Entry 1: id=26, name="raichu" (Normal form)
        #   - Entry 2: id=10100, name="raichu-alola" (Alola form)
        pokemon_v2_pokemons(order_by: {id: asc}) {
          id              # Pokemon ID (used to fetch full data later)
          name            # Pokemon name (e.g., "raichu-alola")
          
          # Form metadata from pokemon_v2_pokemonforms table
          pokemon_v2_pokemonforms {
            form_name     # Internal form identifier (e.g., "alola", "mega-x")
            is_default    # True for the default/normal form
            is_mega       # True for Mega evolutions
            
            # Human-readable form names in English (language_id: 9)
            # This is the MOST RELIABLE source for form names
            # Example for Alola Raichu:
            #   name: "Raichu" (form name)
            #   pokemon_name: "Alolan Raichu" (full readable name)
            pokemon_v2_pokemonformnames(where: {language_id: {_eq: 9}}, limit: 1) {
              name          # Form name only (e.g., "Alolan")
              pokemon_name  # Full pokemon name with form (e.g., "Alolan Raichu")
            }
          }
        }
      }
    }
  ''';

  // Execute the GraphQL query
  final result = await client.query(QueryOptions(document: gql(query)));

  // Extract species data from the query result
  // Result structure: { pokemon_v2_pokemonspecies: [ { pokemon_v2_pokemons: [...] } ] }
  final species = result.data?['pokemon_v2_pokemonspecies'];

  // Validate that we got data back
  // Return empty list if:
  // - species is null (query failed)
  // - species is empty array (species ID not found)
  if (species == null || species.isEmpty) {
    return [];
  }

  // Extract the list of pokemon entries (forms) for this species
  // Each entry in this list is a different form of the same Pokemon species
  // Example for Raichu: [raichu, raichu-alola]
  final pokemons = species[0]['pokemon_v2_pokemons'] as List<dynamic>? ?? [];

  // Transform each pokemon entry into a map with form information
  // This mapping function extracts and formats the form name for display in the dropdown
  return pokemons.map<Map<String, dynamic>>((pokemon) {
    // Extract form data from the pokemon entry
    final forms = pokemon['pokemon_v2_pokemonforms'] as List<dynamic>? ?? [];
    final form = forms.isNotEmpty ? forms[0] : null;

    // Get the pokemon's internal name (e.g., "raichu", "raichu-alola", "charizard-mega-x")
    // This is the KEY to determining the form name
    final pokemonName = pokemon['name'] as String;

    // Initialize form attributes with defaults
    String formName = 'Normal';  // Default display name
    bool isDefault = form?['is_default'] ?? true;  // Is this the default/normal form?
    bool isMega = form?['is_mega'] ?? false;  // Is this a Mega evolution?

    // FORM NAME EXTRACTION LOGIC
    // ===========================
    // We try multiple methods to get the most accurate form name

    if (form != null) {
      // Get form metadata from the query result
      final formNames = form['pokemon_v2_pokemonformnames'] as List<dynamic>? ?? [];
      final rawFormName = form['form_name'] as String? ?? '';

      // PRIORITY 1: Use pokemon_name from pokemon_v2_pokemonformnames
      // ============================================================
      // This is the MOST RELIABLE source - it's the official localized name
      // Example: "Alolan Raichu", "Galarian Meowth", "Mega Charizard X"
      if (formNames.isNotEmpty && formNames[0]['pokemon_name'] != null) {
        final pokemonFormName = formNames[0]['pokemon_name'] as String;

        // Only use this name if it's DIFFERENT from the base pokemon name
        // Example: If base is "Raichu" and form is "Alolan Raichu", use "Alolan Raichu"
        // But if both are "Raichu", skip this method (it's the normal form)
        if (pokemonFormName.toLowerCase() != pokemonName.split('-')[0].toLowerCase()) {
          formName = pokemonFormName;
        }
      }

      // PRIORITY 2: Parse the form_name field
      // ======================================
      // If pokemon_name isn't available or is the same as base name,
      // try to extract from the pokemon's internal name
      // Example: "raichu-alola" → "Alola Form"
      else if (rawFormName.isNotEmpty) {
        // Split pokemon name by dashes to separate base name from form identifier
        // Example: "raichu-alola" → ["raichu", "alola"]
        // Example: "charizard-mega-x" → ["charizard", "mega", "x"]
        final nameParts = pokemonName.split('-');

        if (nameParts.length > 1) {
          // Get everything after the base pokemon name
          // Example: ["raichu", "alola"] → "alola"
          // Example: ["charizard", "mega", "x"] → "mega-x"
          final formPart = nameParts.sublist(1).join('-');

          // Convert to readable format with proper capitalization
          // Example: "alola" → "Alola"
          // Example: "mega-x" → "Mega X"
          formName = formPart.split('-')
              .map((word) => word[0].toUpperCase() + word.substring(1))
              .join(' ');

          // SPECIAL CASE 1: Regional variants
          // Add "Form" suffix for regional forms (Alola, Galar, Hisui, Paldea)
          // Example: "Alola" → "Alola Form"
          if (['alola', 'galar', 'hisui', 'paldea'].contains(formPart.toLowerCase())) {
            formName = '$formName Form';
          }

          // SPECIAL CASE 2: Mega evolutions
          // Keep as is - already formatted correctly
          // Example: "Mega X" stays as "Mega X" (no "Form" suffix)
          else if (formPart.toLowerCase().startsWith('mega')) {
            // Ensure "Mega" is properly formatted
            formName = formName.replaceAll('Mega ', 'Mega ');
            if (!formName.toLowerCase().contains('mega')) {
              formName = 'Mega $formName';
            }
          }

          // SPECIAL CASE 3: Gigantamax forms
          // Convert "gmax" to user-friendly "Gigantamax"
          // Example: "charizard-gmax" → "Gigantamax"
          else if (formPart.toLowerCase() == 'gmax') {
            formName = 'Gigantamax';
          }
        }
      }

      // FALLBACK: Extract from pokemon name if still "Normal" but not default
      // =====================================================================
      // If we still have "Normal" as the form name but is_default is false,
      // it means we couldn't extract the name from pokemon_name or form_name
      // As a last resort, try parsing the pokemon name directly
      // Example: "deoxys-attack" → "Attack Form"
      if (formName == 'Normal' && !isDefault) {
        final nameParts = pokemonName.split('-');
        if (nameParts.length > 1) {
          // Capitalize each word and add "Form" suffix
          formName = nameParts.sublist(1)
              .map((word) => word[0].toUpperCase() + word.substring(1))
              .join(' ') + ' Form';
        }
      }
    }

    // Return the form data as a map
    // This map will be used in the dropdown selector UI
    return {
      'id': pokemon['id'] as int,        // Pokemon ID to fetch full data
      'name': pokemonName,                // Internal pokemon name
      'formName': formName,               // Human-readable form name for display
      'isDefault': isDefault,             // Is this the normal/default form?
      'isMega': isMega,                   // Is this a Mega evolution? (for special icon)
    };
  }).toList();
}

