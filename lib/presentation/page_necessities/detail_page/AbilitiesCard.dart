import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class AbilitiesCard extends StatelessWidget {
  final List<dynamic>? abilities;
  final bool isDarkMode;

  const AbilitiesCard({Key? key, required this.abilities, required this.isDarkMode}) : super(key: key);

  Widget build(BuildContext context) {
    if (abilities == null || abilities!.isEmpty)
      return const SizedBox.shrink();


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
            'Abilities',
            style: GoogleFonts.pressStart2p(
              fontSize: 16,
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...abilities!.map((abilityData) {
            final ability = abilityData['pokemon_v2_ability'];
            final isHidden = abilityData['is_hidden'] ?? false;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isHidden ? Colors.orange.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isHidden ? Colors.orange : Colors.blue,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              ability['name'] ?? 'Unknown',
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isHidden) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'HIDDEN',
                                  style: GoogleFonts.roboto(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (ability['effect'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            ability['effect'],
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }


}