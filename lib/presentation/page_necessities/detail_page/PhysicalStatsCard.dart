import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pie_chart/pie_chart.dart';

class PhysicalStatsCard extends StatelessWidget {
  final double? height;
  final double? weight;
  final int? genderRate;
  final String eggGroups;
  final bool isDarkMode;

  const PhysicalStatsCard({
    Key? key,
    required this.height,
    required this.weight,
    required this.genderRate,
    required this.eggGroups,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gradientList = <List<Color>>[
      [Color.fromRGBO(92, 100, 250, 1.0), Color.fromRGBO(0, 15, 188, 1.0)],
      [Color.fromRGBO(255, 0, 194, 1.0), Color.fromRGBO(255, 75, 189, 1.0)],
    ];
    return Container(
      padding: const EdgeInsets.all(20.0), // Internal padding for the stats card (all sides)
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
          Text(
            'Height: ${height}""',
            style: GoogleFonts.roboto( // Use retro 8-bit font style
              fontSize: 16, // Set font size to 16 pixels
              color: isDarkMode ? Colors.white : Colors.black, // Use red color to match Pokémon brand
              fontWeight: FontWeight.bold, // Make text bold for emphasis and readability
            ),
          ),
          Text(
            'Weight: ${weight} lbs',
            style: GoogleFonts.roboto( // Use retro 8-bit font style
              fontSize: 16, // Set font size to 16 pixels
              color: isDarkMode ? Colors.white : Colors.black, // Use red color to match Pokémon brand
              fontWeight: FontWeight.normal, // Make text bold for emphasis and readability
            ),
          ),
          const SizedBox(height: 20),
          PieChart(
            dataMap: _buildGenderMap(genderRate),
            chartLegendSpacing: 32,
            chartRadius: MediaQuery.of(context).size.width / 3.2,
            gradientList: gradientList,
            chartType: ChartType.ring,
            ringStrokeWidth: 32,
            centerText: "Gender",
            chartValuesOptions: ChartValuesOptions(
              showChartValuesInPercentage: true,
              decimalPlaces: 1,
            ),
            legendOptions: LegendOptions(
              legendTextStyle: GoogleFonts.roboto(
                fontSize: 14,
                color: isDarkMode ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Egg Groups: ${eggGroups}',
            style: GoogleFonts.roboto(
              fontSize: 16,
              color: isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper method to build individual stat rows
  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.red, size: 20),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to build gender ratio map
  Map<String, double> _buildGenderMap(int? genderRate) {
    if (genderRate == null || genderRate == -1) {
      return {"Genderless": 1.0};
    } else if (genderRate == 0) {
      return {"Male": 1.0};
    } else if (genderRate == 8) {
      return {"Female": 1.0};
    } else {
      return {
        "Male": (8 - genderRate) / 8.0,
        "Female": genderRate / 8.0,
      };
    }
  }
}
