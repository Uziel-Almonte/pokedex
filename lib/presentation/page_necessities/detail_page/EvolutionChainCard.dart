import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../data/queries.dart';
import '../../../domain/main.dart';
import '../../pages/DetailPageState.dart';

// Main widget that displays the evolution chain
class EvolutionChainCard extends StatefulWidget {
  final int pokemonId;
  final int speciesId;
  final bool isDarkMode;

  const EvolutionChainCard({
    Key? key,
    required this.pokemonId,
    required this.speciesId,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<EvolutionChainCard> createState() => _EvolutionChainCardState();
}

class _EvolutionChainCardState extends State<EvolutionChainCard> {
  @override
  Widget build(BuildContext context) {
    final client = GraphQLProvider.of(context).value;

    return FutureBuilder<Map<String, dynamic>?>(
      future: fetchEvolutionChain(widget.speciesId, client),
      builder: (context, snapshot) {
        // Show loading indicator while fetching data
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }

        // Show error message if data fetch failed
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        // Extract evolution chain data from the response
        final chainData = snapshot.data!['pokemon_v2_evolutionchain'];
        if (chainData == null) return const SizedBox.shrink();

        final allSpecies = chainData['pokemon_v2_pokemonspecies'] as List<dynamic>?;
        if (allSpecies == null || allSpecies.isEmpty) return const SizedBox.shrink();

        // Build the evolution tree structure
        final evolutionTree = _buildEvolutionTree(allSpecies);

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.isDarkMode ? Colors.grey[800] : Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section title
              Text(
                'Evolution Chain',
                style: GoogleFonts.pressStart2p(
                  fontSize: 16,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // Display the evolution tree
              _buildEvolutionDisplay(evolutionTree),
            ],
          ),
        );
      },
    );
  }

  // Shows a loading card while fetching evolution data
  Widget _buildLoadingCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.red),
      ),
    );
  }

  // Builds a tree structure from the flat list of species
  // Returns a map where each species ID points to its evolutions
  Map<int?, List<EvolutionNode>> _buildEvolutionTree(List<dynamic> allSpecies) {
    final Map<int?, List<EvolutionNode>> tree = {};

    // Convert each species to an EvolutionNode
    // Convert each species to an EvolutionNode
    for (var species in allSpecies) {
      // Safely extract evolution data (may be empty list)
      final evolutionsList = species['pokemon_v2_pokemonevolutions'] as List?;
      final evolutionData = (evolutionsList != null && evolutionsList.isNotEmpty)
          ? evolutionsList.first
          : null;

      // Safely extract Pokémon ID (may be empty list)
      final pokemonsList = species['pokemon_v2_pokemons'] as List?;
      final pokemonId = (pokemonsList != null && pokemonsList.isNotEmpty)
          ? pokemonsList.first['id'] as int?
          : species['id'] as int?;

      final node = EvolutionNode(
        speciesId: species['id'] as int,
        pokemonId: pokemonId ?? species['id'] as int,
        name: species['name'] as String,
        evolvesFromId: species['evolves_from_species_id'] as int?,
        minLevel: evolutionData?['min_level'] as int?,
        itemName: evolutionData?['pokemon_v2_item']?['name'] as String?,
      );

      // Group by parent species (evolvesFromId)
      tree.putIfAbsent(node.evolvesFromId, () => []).add(node);
    }

    return tree;
  }

  // Displays the evolution tree starting from the base species
  Widget _buildEvolutionDisplay(Map<int?, List<EvolutionNode>> tree) {
    // Find the base species (the one with no parent)
    final baseSpecies = tree[null];
    if (baseSpecies == null || baseSpecies.isEmpty) {
      return Text(
        'No evolution data available',
        style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey),
      );
    }

    return Center(
      child: _buildEvolutionStage(baseSpecies.first, tree, 0),
    );

    // Build the tree starting from the first base species
    return _buildEvolutionStage(baseSpecies.first, tree, 0);
  }

  // Recursively builds each evolution stage
  // level parameter is used for indentation (shows evolution depth)
  Widget _buildEvolutionStage(
      EvolutionNode node,
      Map<int?, List<EvolutionNode>> tree,
      int level,
      ) {
    // Get all Pokémon that evolve from this node
    final evolutions = tree[node.speciesId] ?? [];
    final isCurrentPokemon = node.pokemonId == widget.pokemonId;

    return Column(
      children: [
        // Display the current Pokémon card
        _buildPokemonCard(node, isCurrentPokemon, level),

        // If this Pokémon has evolutions, show them
        if (evolutions.isNotEmpty) ...[
          // Arrow pointing down to next evolution(s)
          Padding(
            padding: EdgeInsets.only(left: level * 20.0),
            child: Icon(
              Icons.arrow_downward,
              color: Colors.blue,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),

          // Handle multiple evolutions (like Eevee)
          if (evolutions.length > 1) ...[
            // Show a branching structure for multiple evolutions
            _buildMultipleEvolutions(evolutions, tree, level),
          ] else ...[
            // Single evolution - show it directly below
            _buildEvolutionStage(evolutions.first, tree, level),
          ],
        ],
      ],
    );
  }

  // Builds a grid layout for Pokémon with multiple evolution paths
  Widget _buildMultipleEvolutions(
      List<EvolutionNode> evolutions,
      Map<int?, List<EvolutionNode>> tree,
      int level,
      ) {
    return Padding(
      padding: EdgeInsets.only(left: level * 10.0),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: evolutions.map((evolution) {
          return SizedBox(
            width: 150, // Fixed width for each branch
            child: _buildEvolutionStage(evolution, tree, level + 1),
          );
        }).toList(),
      ),
    );
  }

  // Builds a card for a single Pokémon in the evolution chain
  Widget _buildPokemonCard(EvolutionNode node, bool isCurrent, int level) {
    return GestureDetector(
      onTap: isCurrent
          ? null // Don't navigate if it's the current Pokémon
          : () {
        // Navigate to the selected Pokémon's detail page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PokeDetailPage(
              title: 'Pokédex',
              initialPokemonId: node.pokemonId,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          // Highlight the current Pokémon with a blue border
          color: isCurrent
              ? Colors.blue.withOpacity(0.1)
              : (widget.isDarkMode ? Colors.grey[700] : Colors.grey[100]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent ? Colors.blue : Colors.grey[300]!,
            width: isCurrent ? 3 : 1,
          ),
        ),
        child: Column(
          children: [
            // Pokémon sprite image
            Image.network(
              'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${node.pokemonId}.png',
              height: 80,
              width: 80,
              errorBuilder: (context, error, stackTrace) {
                // Fallback if image fails to load
                return Icon(Icons.catching_pokemon, size: 80, color: Colors.grey);
              },
            ),
            const SizedBox(height: 8),

            // Pokémon name
            Text(
              node.name.toUpperCase(),
              style: GoogleFonts.pressStart2p(
                fontSize: 10,
                color: isCurrent ? Colors.blue : (widget.isDarkMode ? Colors.white : Colors.black),
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),

            // Show evolution requirement (level or item)
            if (node.minLevel != null) ...[
              Text(
                'Lv. ${node.minLevel}',
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ] else if (node.itemName != null) ...[
              Text(
                node.itemName!.replaceAll('-', ' '),
                style: GoogleFonts.roboto(
                  fontSize: 10,
                  color: Colors.purple,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // Show "Current" badge for the active Pokémon
            if (isCurrent) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'CURRENT',
                  style: GoogleFonts.roboto(
                    fontSize: 8,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Data class representing a single Pokémon in the evolution chain
class EvolutionNode {
  final int speciesId;       // Species ID (used for evolution tree logic)
  final int pokemonId;       // Pokémon ID (used for images and navigation)
  final String name;         // Pokémon name
  final int? evolvesFromId;  // Parent species ID (null for base form)
  final int? minLevel;       // Level required to evolve (if applicable)
  final String? itemName;    // Item required to evolve (if applicable)

  EvolutionNode({
    required this.speciesId,
    required this.pokemonId,
    required this.name,
    this.evolvesFromId,
    this.minLevel,
    this.itemName,
  });
}
