import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PokeSelect extends StatelessWidget {
  final Map<String, dynamic> pokemon;
  final String types;
  final bool isDarkMode;
  final VoidCallback? onTap; // Add this

  const PokeSelect({
    super.key,
    required this.pokemon,
    required this.types,
    required this.isDarkMode,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pokemonName = pokemon['pokemonspecy']?['name']  ?? 'Unknown'; // returns name of pokemon
    final pokemonId = pokemon['pokemon_species_id'] ?? '0'; // returns id of pokemon

    return GestureDetector( // Wrap with GestureDetector
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 5,
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Image.network(
              'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$pokemonId.png',
              height: 100,
              width: 100,
            ),
            const SizedBox(height: 20),
            Text(
              '#$pokemonId',
              style: GoogleFonts.pressStart2p(
                fontSize: 16,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              pokemonName.toString().toUpperCase(),
              style: GoogleFonts.pressStart2p(
                fontSize: 24,
                color: isDarkMode ? Colors.red : Colors.blue[900],
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: const Offset(2, 2),
                    blurRadius: 3,
                    color: isDarkMode ? Colors.white : Colors.yellow,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Types: $types',
              style: GoogleFonts.roboto(
                fontSize: 18,
                color: Colors.green[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

