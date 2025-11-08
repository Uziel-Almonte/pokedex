import 'package:flutter/material.dart';
import 'dart:async';
//fonts de google
import 'package:google_fonts/google_fonts.dart';



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
Future<Map<String, dynamic>?> showFilterDialog(BuildContext context, String? _selectedType, int? _selectedGeneration, String? _selectedAbility) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              'Filter Options',
              style: GoogleFonts.pressStart2p(fontSize: 12),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // FILTRO POR TIPO
                  Text('Type:', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      'normal', 'fire', 'water', 'electric', 'grass', 'ice',
                      'fighting', 'poison', 'ground', 'flying', 'psychic',
                      'bug', 'rock', 'ghost', 'dragon', 'dark', 'steel', 'fairy'
                    ].map((type) {
                      final isSelected = _selectedType == type;
                      return FilterChip(
                        label: Text(type.toUpperCase(), style: const TextStyle(fontSize: 10)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setDialogState(() {
                            _selectedType = selected ? type : null;
                          });
                        },
                        selectedColor: Colors.red.withOpacity(0.3),
                      );
                    }).toList(),
                  ),
                  const Divider(height: 32),

                  // FILTRO POR GENERACIÓN
                  Text('Generation:', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(9, (index) {
                      final gen = index + 1;
                      final isSelected = _selectedGeneration == gen;
                      return FilterChip(
                        label: Text('Gen $gen'),
                        selected: isSelected,
                        onSelected: (selected) {
                          setDialogState(() {
                            _selectedGeneration = selected ? gen : null;
                          });
                        },
                        selectedColor: Colors.blue.withOpacity(0.3),
                      );
                    }),
                  ),
                  const Divider(height: 32),

                  // FILTRO POR HABILIDAD
                  Text('Ability:', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Enter ability name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      suffixIcon: _selectedAbility != null
                          ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          setDialogState(() {
                            _selectedAbility = null;
                          });
                        },
                      )
                          : null,
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        _selectedAbility = value.isEmpty ? null : value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              // Botón para limpiar todos los filtros
              TextButton(
                onPressed: () {
                  setDialogState(() {
                    _selectedType = null;
                    _selectedGeneration = null;
                    _selectedAbility = null;
                  });
                },
                child: const Text('Clear All'),
              ),
              // Botón para aplicar filtros
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, {
                    'type': _selectedType,
                    'generation': _selectedGeneration,
                    'ability': _selectedAbility,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Apply'),
              ),
            ],
          );
        },
      );
    },
  );
}