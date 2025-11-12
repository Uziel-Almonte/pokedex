import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatsCard extends StatelessWidget {
  final Map<String, int> stats;
  final int totalStats;
  final bool isDarkMode;

  const StatsCard({
    Key? key,
    required this.stats,
    required this.totalStats,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0), // Add margin (matches other cards)
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white, // White background for stats card (clean, readable)
        borderRadius: BorderRadius.circular(15), // Rounded corners (15px radius for modern look)
        boxShadow: [ // Add shadow for depth and elevation effect
          BoxShadow(
            color: Colors.grey.withOpacity(0.3), // Light grey shadow (30% opacity for subtle effect)
            spreadRadius: 2, // Shadow spread (2px outward)
            blurRadius: 5, // Shadow blur (5px for soft edges)
            offset: const Offset(0, 2), // Shadow position (2px down, 0px horizontal)
          ),
        ],
      ),
      child: Column(
        children: [
          // STATS TITLE
          // "BASE STATS" header in retro gaming font
          Text(
            'BASE STATS',
            style: GoogleFonts.pressStart2p(
              fontSize: 14, // Medium size for section header
              color: Colors.red, // Pokémon red theme
              fontWeight: FontWeight.bold, // Bold for emphasis
            ),
          ),
          const SizedBox(height: 15), // Spacing after title

          // HP STAT (Health Points)
          // Red color represents health/vitality
          _buildStatRow('HP', stats['hp'] ?? 0, Colors.red),
          const SizedBox(height: 8), // Spacing between stats

          // ATTACK STAT
          // Orange color represents physical power
          _buildStatRow('ATK', stats['attack'] ?? 0, Colors.orange),
          const SizedBox(height: 8),

          // DEFENSE STAT
          // Yellow color represents protection/armor
          _buildStatRow('DEF', stats['defense'] ?? 0, Colors.yellow[700]!),
          const SizedBox(height: 8),

          // SPECIAL ATTACK STAT
          // Blue color represents special/magical power
          _buildStatRow('SpA', stats['special-attack'] ?? 0, Colors.blue),
          const SizedBox(height: 8),

          // SPECIAL DEFENSE STAT
          // Green color represents special resistance/nature
          _buildStatRow('SpD', stats['special-defense'] ?? 0, Colors.green),
          const SizedBox(height: 8),

          // SPEED STAT
          // Pink color represents agility/quickness
          _buildStatRow('SPE', stats['speed'] ?? 0, Colors.pink),
          const SizedBox(height: 12), // Extra spacing before divider

          // DIVIDER LINE
          // Separates individual stats from the total
          const Divider(thickness: 2, color: Colors.grey),
          const SizedBox(height: 8),

          // TOTAL STATS ROW
          // Shows the sum of all base stats (power level indicator)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between label and value
            children: [
              Text(
                'TOTAL',
                style: GoogleFonts.pressStart2p(
                  fontSize: 12, // Slightly smaller than title
                  color: isDarkMode ? Colors.white : Colors.black, // Black for contrast
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                totalStats.toString(), // Display calculated total
                style: GoogleFonts.pressStart2p(
                  fontSize: 14, // Larger to emphasize the total
                  color: Colors.purple, // Purple for special emphasis
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // HELPER METHOD: Build a stat row widget
  // This reusable method creates a single row displaying a Pokémon stat
  //
  // PARAMETERS:
  // - statName: The display name of the stat (e.g., "HP", "ATK", "DEF")
  // - statValue: The numeric value of the stat (0-255 typically)
  // - color: The color for the progress bar (visual coding by stat type)
  //
  // LAYOUT: [Stat Name] [Numeric Value] [Colored Progress Bar]
  // Example: HP          45           [████████░░░░░░░░░░]
  //
  // RETURNS: A Row widget containing the stat display
  Widget _buildStatRow(String statName, int statValue, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribute space evenly
      children: [
        // STAT NAME LABEL
        // Displays the abbreviated stat name (HP, ATK, DEF, etc.)
        Expanded(
          child: Text(
            statName, // The stat label passed as parameter
            style: GoogleFonts.roboto(
              fontSize: 16, // Readable size for stat names
              color: isDarkMode ? Colors.white : Colors.black, // Black for high contrast
              fontWeight: FontWeight.w500, // Medium weight (not too bold, not too light)
            ),
          ),
        ),
        const SizedBox(width: 10), // Spacing between name and value

        // STAT VALUE NUMBER
        // Displays the numeric stat value (e.g., 45, 120, 255)
        Text(
          statValue.toString(), // Convert integer to string for display
          style: GoogleFonts.roboto(
            fontSize: 16, // Same size as name for consistency
            color: isDarkMode ? Colors.white : Colors.black, // Black for readability
            fontWeight: FontWeight.bold, // Bold to emphasize the number
          ),
        ),
        const SizedBox(width: 10), // Spacing between value and progress bar

        // VISUAL PROGRESS BAR
        // Shows the stat value as a colored bar (like in Pokémon games)
        // Higher values = longer bar, easier to compare stats visually
        Container(
          height: 8, // Thin horizontal bar (8px height)
          width: 100, // Fixed width (100px) - all bars same length for comparison
          decoration: BoxDecoration(
            color: Colors.grey[300], // Light grey background (unfilled portion)
            borderRadius: BorderRadius.circular(4), // Rounded corners (4px radius)
          ),

          // FRACTIONALLY SIZED BOX - Creates the filled portion
          // This widget fills a fraction of the parent container based on widthFactor
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft, // Align filled part to the left side

            // CALCULATE FILL PERCENTAGE
            // widthFactor: 0.0 to 1.0 (0% to 100%)
            // Formula: statValue / 255
            // Why 255? It's the maximum value for any Pokémon stat
            // Examples:
            //   - HP 45 / 255 = 0.176 (17.6% filled)
            //   - Attack 120 / 255 = 0.470 (47% filled)
            //   - Speed 255 / 255 = 1.0 (100% filled - rare!)
            widthFactor: statValue / 255, // Dynamic width based on stat value

            // COLORED FILL CONTAINER
            // This is the actual colored bar that represents the stat value
            child: Container(
              decoration: BoxDecoration(
                color: color, // Dynamic color based on stat type (passed as parameter)
                // Color meanings: Red=HP, Orange=ATK, Yellow=DEF, Blue=SpA, Green=SpD, Pink=SPE
                borderRadius: BorderRadius.circular(4), // Match parent corners
              ),
            ),
          ),
        ),
      ],
    );
  }
}
