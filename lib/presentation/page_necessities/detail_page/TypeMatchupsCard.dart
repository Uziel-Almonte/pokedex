/// ============================================================================
/// TYPE MATCHUPS CARD - DEFENSIVE TYPE EFFECTIVENESS DISPLAY
/// ============================================================================
///
/// This widget displays a comprehensive breakdown of a Pokémon's defensive
/// type matchups, showing weaknesses, resistances, and immunities.
///
/// FEATURES:
/// - **Weaknesses**: Types that deal 2x or 4x damage (red/dark red)
/// - **Resistances**: Types that deal 0.5x or 0.25x damage (green/dark green)
/// - **Immunities**: Types that deal 0x damage (blue)
/// - **Visual Multipliers**: Shows exact damage multiplier (x4, x2, x0.5, etc.)
/// - **Color-Coded**: Each type has its official Pokémon color
/// - **Organized Sections**: Clear separation between weaknesses/resistances/immunities
///
/// DISPLAY FORMAT:
/// Each type is shown as a colored chip with the type name and multiplier.
/// Example: [ROCK x4] [WATER x2] [ELECTRIC x2] (Weaknesses for Charizard)
///
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/type_effectiveness.dart';

class TypeMatchupsCard extends StatelessWidget {
  final List<String> types;
  final bool isDarkMode;

  const TypeMatchupsCard({
    Key? key,
    required this.types,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate all matchups
    final weaknesses = TypeEffectiveness.getWeaknesses(types);
    final resistances = TypeEffectiveness.getResistances(types);
    final immunities = TypeEffectiveness.getImmunities(types);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TITLE
              Center(
                child: Text(
                  'TYPE MATCHUPS',
                  style: GoogleFonts.pressStart2p(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white : Colors.blue[900],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // WEAKNESSES SECTION
              if (weaknesses.isNotEmpty) ...[
                _buildSectionTitle('WEAKNESSES', Colors.red[700]!),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: weaknesses.entries.map((entry) {
                    return _buildTypeChip(
                      entry.key,
                      entry.value,
                      _getWeaknessColor(entry.value),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // RESISTANCES SECTION
              if (resistances.isNotEmpty) ...[
                _buildSectionTitle('RESISTANCES', Colors.green[700]!),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: resistances.entries.map((entry) {
                    return _buildTypeChip(
                      entry.key,
                      entry.value,
                      _getResistanceColor(entry.value),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // IMMUNITIES SECTION
              if (immunities.isNotEmpty) ...[
                _buildSectionTitle('IMMUNITIES', Colors.blue[700]!),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: immunities.map((type) {
                    return _buildTypeChip(type, 0.0, Colors.blue[700]!);
                  }).toList(),
                ),
              ],

              // NO SPECIAL MATCHUPS MESSAGE
              if (weaknesses.isEmpty && resistances.isEmpty && immunities.isEmpty) ...[
                Center(
                  child: Text(
                    'No special matchups',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build section title (WEAKNESSES, RESISTANCES, IMMUNITIES)
  Widget _buildSectionTitle(String title, Color color) {
    return Row(
      children: [
        Icon(
          _getSectionIcon(title),
          color: color,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.pressStart2p(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Get icon for section
  IconData _getSectionIcon(String title) {
    switch (title) {
      case 'WEAKNESSES':
        return Icons.arrow_downward;
      case 'RESISTANCES':
        return Icons.shield;
      case 'IMMUNITIES':
        return Icons.block;
      default:
        return Icons.info;
    }
  }

  /// Build individual type chip with multiplier
  Widget _buildTypeChip(String type, double multiplier, Color backgroundColor) {
    final typeColors = TypeEffectiveness.getTypeColor(type);
    final typeColor = Color(typeColors['primary']!);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: typeColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Type icon (using emoji representation)
          Text(
            _getTypeEmoji(type),
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 6),
          // Type name
          Text(
            type.toUpperCase(),
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              shadows: [
                const Shadow(
                  color: Colors.black45,
                  offset: Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Multiplier badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _formatMultiplier(multiplier),
              style: GoogleFonts.roboto(
                fontSize: 10,
                color: backgroundColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Format multiplier for display
  String _formatMultiplier(double multiplier) {
    if (multiplier == 0.0) return 'x0';
    if (multiplier == 0.25) return 'x¼';
    if (multiplier == 0.5) return 'x½';
    if (multiplier == 2.0) return 'x2';
    if (multiplier == 4.0) return 'x4';
    return 'x${multiplier.toStringAsFixed(1)}';
  }

  /// Get color for weakness based on multiplier
  Color _getWeaknessColor(double multiplier) {
    if (multiplier >= 4.0) return Colors.red[900]!; // x4 - Dark red
    if (multiplier >= 2.0) return Colors.red[700]!; // x2 - Red
    return Colors.orange[700]!; // Others
  }

  /// Get color for resistance based on multiplier
  Color _getResistanceColor(double multiplier) {
    if (multiplier <= 0.25) return Colors.green[900]!; // x0.25 - Dark green
    if (multiplier <= 0.5) return Colors.green[700]!; // x0.5 - Green
    return Colors.lightGreen[700]!; // Others
  }

  /// Get emoji representation for type
  String _getTypeEmoji(String type) {
    const typeEmojis = {
      'normal': '⚪',
      'fire': '🔥',
      'water': '💧',
      'electric': '⚡',
      'grass': '🌿',
      'ice': '❄️',
      'fighting': '👊',
      'poison': '☠️',
      'ground': '⛰️',
      'flying': '🦅',
      'psychic': '🔮',
      'bug': '🐛',
      'rock': '🪨',
      'ghost': '👻',
      'dragon': '🐉',
      'dark': '🌙',
      'steel': '⚙️',
      'fairy': '🧚',
    };
    return typeEmojis[type.toLowerCase()] ?? '❓';
  }
}
