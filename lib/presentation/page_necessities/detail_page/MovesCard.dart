// dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MovesCard extends StatelessWidget {
  final List<dynamic>? moves;
  final bool isDarkMode;

  const MovesCard({Key? key, required this.moves, required this.isDarkMode}) : super(key: key);


  Widget build(BuildContext context) {
    if (moves == null || moves!.isEmpty) {
      return const SizedBox.shrink();
    }

    // Group moves by level
    final Map<int, List<Map<String, dynamic>>> movesByLevel = {};
    for (var moveData in moves!) {
      final level = moveData['level'] as int? ?? 0;
      final move = moveData['pokemon_v2_move'] as Map<String, dynamic>?;
      if (move != null) movesByLevel.putIfAbsent(level, () => []).add(move);
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
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
          Text(
            'Moves by Level',
            style: GoogleFonts.pressStart2p(
              fontSize: 16,
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 300,
            child: ListView.builder(
              itemCount: movesByLevel.keys.length,
              itemBuilder: (context, index) {
                final level = movesByLevel.keys.elementAt(index);
                final levelMoves = movesByLevel[level]!;

                return ExpansionTile(
                  title: Text(
                    level == 0 ? 'Base Moves' : 'Level $level',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  children: levelMoves.map((move) {
                    return ListTile(
                      dense: true,
                      title: Text(
                        move['name'] ?? 'Unknown Move',
                        style: GoogleFonts.roboto(fontSize: 13),
                      ),
                      subtitle: Row(children: [
                        if (move['pokemon_v2_type'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(8)),
                            child: Text(move['pokemon_v2_type']['name'].toUpperCase(), style: GoogleFonts.roboto(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        const SizedBox(width: 8),
                        Text('PWR: ${move['power'] ?? '--'} | ACC: ${move['accuracy'] ?? '--'}% | PP: ${move['pp'] ?? '--'}', style: GoogleFonts.roboto(fontSize: 11, color: Colors.grey[600])),
                      ]),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
