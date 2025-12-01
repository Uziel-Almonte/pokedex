/// ============================================================================
/// TYPE EFFECTIVENESS CALCULATOR
/// ============================================================================
///
/// This file contains the complete type matchup chart for Pokémon battles.
/// It calculates weaknesses, resistances, and immunities based on a Pokémon's
/// type combination (single or dual-type).
///
/// EFFECTIVENESS MULTIPLIERS:
/// - x4.0: Double weakness (both types are weak to the same attacking type)
/// - x2.0: Weakness (one type is weak to the attacking type)
/// - x1.0: Neutral (normal damage)
/// - x0.5: Resistance (one type resists the attacking type)
/// - x0.25: Double resistance (both types resist the same attacking type)
/// - x0.0: Immunity (at least one type is immune to the attacking type)
///
/// EXAMPLE:
/// - Charizard (Fire/Flying):
///   * x4 weak to Rock (Fire x2, Flying x2)
///   * x2 weak to Water, Electric
///   * x0.5 resistant to Fighting, Bug, Steel, Fire, Grass, Fairy
///   * x0.25 resistant to nothing
///   * x0 immune to Ground
///
/// ============================================================================

class TypeEffectiveness {
  /// Type effectiveness chart
  /// Maps defending type -> attacking type -> damage multiplier
  ///
  /// Based on official Pokémon Generation VIII+ type chart
  static const Map<String, Map<String, double>> _typeChart = {
    'normal': {
      'fighting': 2.0,
      'ghost': 0.0,
    },
    'fire': {
      'water': 2.0,
      'ground': 2.0,
      'rock': 2.0,
      'fire': 0.5,
      'grass': 0.5,
      'ice': 0.5,
      'bug': 0.5,
      'steel': 0.5,
      'fairy': 0.5,
    },
    'water': {
      'electric': 2.0,
      'grass': 2.0,
      'fire': 0.5,
      'water': 0.5,
      'ice': 0.5,
      'steel': 0.5,
    },
    'electric': {
      'ground': 2.0,
      'electric': 0.5,
      'flying': 0.5,
      'steel': 0.5,
    },
    'grass': {
      'fire': 2.0,
      'ice': 2.0,
      'poison': 2.0,
      'flying': 2.0,
      'bug': 2.0,
      'water': 0.5,
      'electric': 0.5,
      'grass': 0.5,
      'ground': 0.5,
    },
    'ice': {
      'fire': 2.0,
      'fighting': 2.0,
      'rock': 2.0,
      'steel': 2.0,
      'ice': 0.5,
    },
    'fighting': {
      'flying': 2.0,
      'psychic': 2.0,
      'fairy': 2.0,
      'bug': 0.5,
      'rock': 0.5,
      'dark': 0.5,
    },
    'poison': {
      'ground': 2.0,
      'psychic': 2.0,
      'fighting': 0.5,
      'poison': 0.5,
      'bug': 0.5,
      'grass': 0.5,
      'fairy': 0.5,
    },
    'ground': {
      'water': 2.0,
      'grass': 2.0,
      'ice': 2.0,
      'poison': 0.5,
      'rock': 0.5,
      'electric': 0.0,
    },
    'flying': {
      'electric': 2.0,
      'ice': 2.0,
      'rock': 2.0,
      'fighting': 0.5,
      'bug': 0.5,
      'grass': 0.5,
      'ground': 0.0,
    },
    'psychic': {
      'bug': 2.0,
      'ghost': 2.0,
      'dark': 2.0,
      'fighting': 0.5,
      'psychic': 0.5,
    },
    'bug': {
      'fire': 2.0,
      'flying': 2.0,
      'rock': 2.0,
      'fighting': 0.5,
      'grass': 0.5,
      'ground': 0.5,
    },
    'rock': {
      'water': 2.0,
      'grass': 2.0,
      'fighting': 2.0,
      'ground': 2.0,
      'steel': 2.0,
      'normal': 0.5,
      'fire': 0.5,
      'poison': 0.5,
      'flying': 0.5,
    },
    'ghost': {
      'ghost': 2.0,
      'dark': 2.0,
      'poison': 0.5,
      'bug': 0.5,
      'normal': 0.0,
      'fighting': 0.0,
    },
    'dragon': {
      'ice': 2.0,
      'dragon': 2.0,
      'fairy': 2.0,
      'fire': 0.5,
      'water': 0.5,
      'electric': 0.5,
      'grass': 0.5,
    },
    'dark': {
      'fighting': 2.0,
      'bug': 2.0,
      'fairy': 2.0,
      'ghost': 0.5,
      'dark': 0.5,
      'psychic': 0.0,
    },
    'steel': {
      'fire': 2.0,
      'fighting': 2.0,
      'ground': 2.0,
      'normal': 0.5,
      'grass': 0.5,
      'ice': 0.5,
      'flying': 0.5,
      'psychic': 0.5,
      'bug': 0.5,
      'rock': 0.5,
      'dragon': 0.5,
      'steel': 0.5,
      'fairy': 0.5,
      'poison': 0.0,
    },
    'fairy': {
      'poison': 2.0,
      'steel': 2.0,
      'fighting': 0.5,
      'bug': 0.5,
      'dark': 0.5,
      'dragon': 0.0,
    },
  };

  /// Calculate the defensive effectiveness against all types
  ///
  /// Takes a single type or dual-type combination and returns a map
  /// of all attacking types to their effectiveness multiplier.
  ///
  /// For dual-type Pokémon, multipliers are combined:
  /// - Fire/Flying vs Rock: 2.0 * 2.0 = 4.0 (double weakness)
  /// - Fire/Flying vs Fighting: 0.5 * 0.5 = 0.25 (double resistance)
  /// - Fire/Flying vs Ground: 0.5 * 0.0 = 0.0 (immunity overrides)
  static Map<String, double> calculateDefensiveMatchups(List<String> types) {
    // Initialize all types to neutral (1.0)
    final Map<String, double> effectiveness = {
      'normal': 1.0,
      'fire': 1.0,
      'water': 1.0,
      'electric': 1.0,
      'grass': 1.0,
      'ice': 1.0,
      'fighting': 1.0,
      'poison': 1.0,
      'ground': 1.0,
      'flying': 1.0,
      'psychic': 1.0,
      'bug': 1.0,
      'rock': 1.0,
      'ghost': 1.0,
      'dragon': 1.0,
      'dark': 1.0,
      'steel': 1.0,
      'fairy': 1.0,
    };

    // For each defending type, apply its resistances/weaknesses
    for (final defendingType in types) {
      final typeMatchups = _typeChart[defendingType.toLowerCase()];
      if (typeMatchups != null) {
        typeMatchups.forEach((attackingType, multiplier) {
          effectiveness[attackingType] = (effectiveness[attackingType] ?? 1.0) * multiplier;
        });
      }
    }

    return effectiveness;
  }

  /// Get weaknesses (effectiveness >= 2.0)
  /// Returns map of type -> multiplier, sorted by multiplier descending
  static Map<String, double> getWeaknesses(List<String> types) {
    final effectiveness = calculateDefensiveMatchups(types);
    final weaknesses = <String, double>{};

    effectiveness.forEach((type, multiplier) {
      if (multiplier >= 2.0) {
        weaknesses[type] = multiplier;
      }
    });

    // Sort by multiplier (highest first)
    return Map.fromEntries(
      weaknesses.entries.toList()..sort((a, b) => b.value.compareTo(a.value))
    );
  }

  /// Get resistances (0.0 < effectiveness < 1.0)
  /// Returns map of type -> multiplier, sorted by multiplier ascending
  static Map<String, double> getResistances(List<String> types) {
    final effectiveness = calculateDefensiveMatchups(types);
    final resistances = <String, double>{};

    effectiveness.forEach((type, multiplier) {
      if (multiplier > 0.0 && multiplier < 1.0) {
        resistances[type] = multiplier;
      }
    });

    // Sort by multiplier (lowest first)
    return Map.fromEntries(
      resistances.entries.toList()..sort((a, b) => a.value.compareTo(b.value))
    );
  }

  /// Get immunities (effectiveness == 0.0)
  /// Returns list of types that deal 0 damage
  static List<String> getImmunities(List<String> types) {
    final effectiveness = calculateDefensiveMatchups(types);
    final immunities = <String>[];

    effectiveness.forEach((type, multiplier) {
      if (multiplier == 0.0) {
        immunities.add(type);
      }
    });

    return immunities;
  }

  /// Get color for type (used in UI)
  static Map<String, int> getTypeColor(String type) {
    const typeColors = {
      'normal': 0xFFA8A878,
      'fire': 0xFFF08030,
      'water': 0xFF6890F0,
      'electric': 0xFFF8D030,
      'grass': 0xFF78C850,
      'ice': 0xFF98D8D8,
      'fighting': 0xFFC03028,
      'poison': 0xFFA040A0,
      'ground': 0xFFE0C068,
      'flying': 0xFFA890F0,
      'psychic': 0xFFF85888,
      'bug': 0xFFA8B820,
      'rock': 0xFFB8A038,
      'ghost': 0xFF705898,
      'dragon': 0xFF7038F8,
      'dark': 0xFF705848,
      'steel': 0xFFB8B8D0,
      'fairy': 0xFFEE99AC,
    };

    final colorValue = typeColors[type.toLowerCase()] ?? 0xFF68A090;
    return {
      'primary': colorValue,
      'light': colorValue,
    };
  }
}

