import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/**
 * POKEDEX ENTRY CARD COMPONENT
 *
 * This widget displays the Pokédex entry (flavor text), region, and generation
 * for a Pokémon on the detail page. It provides lore and context about where
 * the Pokémon originates from.
 *
 * FEATURES:
 * - Displays official Pokédex description text
 * - Shows the region where the Pokémon was first discovered (Kanto, Johto, etc.)
 * - Displays which generation the Pokémon belongs to (Gen I-IX)
 * - Fully themed for light/dark mode
 * - Gracefully handles missing data with placeholder text
 */
class PokedexEntryCard extends StatelessWidget {
  // The Pokédex entry text (flavor text) from the games
  // This is the official description that appears in the Pokédex
  // Example: "A strange seed was planted on its back at birth. The plant sprouts and grows with this Pokémon."
  final String? pokedexEntry;

  // The region where this Pokémon originates from
  // Examples: "kanto", "johto", "hoenn", "sinnoh", "unova", "kalos", "alola", "galar", "paldea"
  final String? region;

  // The generation when this Pokémon was introduced
  // Format: "generation-i", "generation-ii", etc.
  // Used to determine which game the Pokémon first appeared in
  final String? generation;

  // Dark mode flag for theming
  // Controls colors, backgrounds, and text for optimal visibility
  final bool isDarkMode;

  const PokedexEntryCard({
    super.key,
    required this.pokedexEntry,
    required this.region,
    required this.generation,
    required this.isDarkMode,
  });

  /**
   * FORMAT GENERATION NAME
   * Converts API format to user-friendly display format
   *
   * TRANSFORMATION:
   * Input:  "generation-i"   → Output: "Generation I"
   * Input:  "generation-iv"  → Output: "Generation IV"
   * Input:  "generation-ix"  → Output: "Generation IX"
   * Input:  null             → Output: "Unknown"
   *
   * HOW IT WORKS:
   * 1. Split string by hyphen: ["generation", "i"]
   * 2. Take second part (roman numeral)
   * 3. Convert to uppercase: "I"
   * 4. Prepend "Generation": "Generation I"
   */
  String _formatGenerationName(String? gen) {
    if (gen == null) return 'Unknown';
    // Convert "generation-i" to "Generation I"
    final parts = gen.split('-');
    if (parts.length == 2) {
      return 'Generation ${parts[1].toUpperCase()}';
    }
    return gen;
  }

  /**
   * FORMAT REGION NAME
   * Capitalizes the first letter of the region name
   *
   * TRANSFORMATION:
   * Input:  "kanto"  → Output: "Kanto"
   * Input:  "johto"  → Output: "Johto"
   * Input:  "alola"  → Output: "Alola"
   * Input:  null     → Output: "Unknown"
   *
   * HOW IT WORKS:
   * 1. Take first character: "k"
   * 2. Convert to uppercase: "K"
   * 3. Append rest of string: "K" + "anto" = "Kanto"
   */
  String _formatRegionName(String? reg) {
    if (reg == null) return 'Unknown';
    // Capitalize first letter
    return reg[0].toUpperCase() + reg.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Add horizontal margins to keep card away from screen edges
      margin: const EdgeInsets.symmetric(horizontal: 16),
      // Add padding inside the card for content spacing
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // Theme-aware background: very dark grey for dark mode, white for light mode
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        // Rounded corners for modern card appearance
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          // Subtle shadow for depth and elevation effect
          BoxShadow(
            // Semi-transparent black shadow (10% opacity)
            // Using withValues instead of deprecated withOpacity
            color: Colors.black.withValues(alpha: 0.1),
            spreadRadius: 2,  // How far the shadow spreads
            blurRadius: 8,    // How blurred/soft the shadow edges are
            offset: const Offset(0, 3),  // Shadow positioned 3px down
          ),
        ],
      ),
      child: Column(
        // Align children to the left edge of the card
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CARD TITLE SECTION
          // Shows a book icon with "POKÉDEX ENTRY" text
          Row(
            children: [
              // Book icon representing the Pokédex
              Icon(
                Icons.menu_book,
                color: Colors.red,  // Pokémon brand red
                size: 24,
              ),
              const SizedBox(width: 8),  // Space between icon and text
              Text(
                'POKÉDEX ENTRY',
                style: GoogleFonts.pressStart2p(
                  fontSize: 14,
                  // Theme-aware red: lighter shade for dark mode, darker for light mode
                  color: isDarkMode ? Colors.red[300] : Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),  // Space before main content

          // POKEDEX ENTRY TEXT SECTION
          // Conditionally displays the description or a "not available" message
          if (pokedexEntry != null) ...[
            // CASE 1: We have Pokédex entry data
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                // Slightly different background to distinguish text area
                color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  // Themed border color
                  color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: Text(
                pokedexEntry!,  // The actual Pokédex description
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white : Colors.black87,
                  height: 1.5,  // Line height for better readability
                ),
                // Justify text for a more polished appearance (like a book)
                textAlign: TextAlign.justify,
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            // CASE 2: No Pokédex entry available
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: Text(
                'No Pokédex entry available.',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: Colors.grey[500],  // Grey to indicate missing data
                  fontStyle: FontStyle.italic,  // Italic for placeholder text
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // REGION AND GENERATION INFO SECTION
          // Two equal-width cards displayed side by side
          Row(
            children: [
              // REGION CARD (LEFT)
              // Shows which game region the Pokémon is from
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    // Blue color scheme for region (like water/oceans on a map)
                    color: isDarkMode ? Colors.blue[900] : Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode ? Colors.blue[700]! : Colors.blue[200]!,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Globe icon representing world/region
                      Icon(
                        Icons.public,
                        color: isDarkMode ? Colors.blue[300] : Colors.blue[700],
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      // Label text in retro font
                      Text(
                        'REGION',
                        style: GoogleFonts.pressStart2p(
                          fontSize: 8,  // Small font for label
                          color: isDarkMode ? Colors.blue[300] : Colors.blue[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Actual region name (e.g., "Kanto", "Johto")
                      Text(
                        _formatRegionName(region),
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),  // Space between the two cards

              // GENERATION CARD (RIGHT)
              // Shows which generation the Pokémon belongs to (Gen I-IX)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    // Purple color scheme for generation (representing time/history)
                    color: isDarkMode ? Colors.purple[900] : Colors.purple[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode ? Colors.purple[700]! : Colors.purple[200]!,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      // History/time icon representing generations over time
                      Icon(
                        Icons.history,
                        color: isDarkMode ? Colors.purple[300] : Colors.purple[700],
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      // Label text in retro font (abbreviated to save space)
                      Text(
                        'GEN',
                        style: GoogleFonts.pressStart2p(
                          fontSize: 8,  // Small font for label
                          color: isDarkMode ? Colors.purple[300] : Colors.purple[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Actual generation (e.g., "Generation I", "Generation IV")
                      Text(
                        _formatGenerationName(generation),
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
