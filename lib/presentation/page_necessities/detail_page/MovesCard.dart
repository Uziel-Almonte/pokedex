// dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MovesCard extends StatefulWidget {
  final List<dynamic>? moves;
  final bool isDarkMode;

  const MovesCard({Key? key, required this.moves, required this.isDarkMode}) : super(key: key);

  @override
  State<MovesCard> createState() => _MovesCardState();
}

class _MovesCardState extends State<MovesCard> {
  String _selectedMethod = 'All';
  String _sortBy = 'level'; // 'level' or 'name'

  // Keeps track of expanded sections to avoid rebuilding
  final Map<String, bool> expandedSections = {};

  @override
  Widget build(BuildContext context) {
    if (widget.moves == null || widget.moves!.isEmpty) {
      return const SizedBox.shrink();
    }

    // Remove duplicates and get unique moves
    final uniqueMoves = _getUniqueMoves(widget.moves!);

    // Apply filters and sorting
    final filteredMoves = _filterAndSortMoves(uniqueMoves);

    // Group moves by level for display
    final movesByKey = _groupMovesByKey(filteredMoves);

    // Get available methods for dropdown
    final availableMethods = _getAvailableMethods(uniqueMoves);

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
          // Header
          Text(
            'Moves',
            style: GoogleFonts.pressStart2p(
              fontSize: 16,
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Filter Controls
          _buildControlsSection(availableMethods),
          const SizedBox(height: 12),

          // Moves count
          Text(
            '${filteredMoves.length} move${filteredMoves.length != 1 ? 's' : ''}',
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: widget.isDarkMode ? Colors.white : Colors.grey[800],
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),

          // Scrollable moves list
          SizedBox(
            height: 400,
            child: ListView.builder(
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: movesByKey.length,
              itemBuilder: (context, index) {
                final key = movesByKey.keys.elementAt(index);
                final groupMoves = movesByKey[key]!;

                return _buildGroupSection(key, groupMoves);
              },
            )
          ),
        ],
      ),
    );
  }

  /// Builds filter and sort controls
  Widget _buildControlsSection(List<String> availableMethods) {
    return Row(
      children: [
        // Method filter dropdown
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: widget.isDarkMode ? Colors.grey[700] : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[400]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedMethod,
                isExpanded: true,
                icon: const Icon(Icons.filter_list, size: 20),
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: widget.isDarkMode ? Colors.white : Colors.black,
                ),
                dropdownColor: widget.isDarkMode ? Colors.grey[700] : Colors.white,
                items: availableMethods.map((method) {
                  return DropdownMenuItem(
                    value: method,
                    child: Text(_formatMethodName(method)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMethod = value!;
                  });
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Sort toggle button
        Container(
          decoration: BoxDecoration(
            color: widget.isDarkMode ? Colors.grey[700] : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[400]!),
          ),
          child: IconButton(
            icon: Icon(
              _sortBy == 'level' ? Icons.sort_by_alpha : Icons.format_list_numbered,
              size: 20,
            ),
            tooltip: _sortBy == 'level' ? 'Sort by Name' : 'Sort by Level',
            onPressed: () {
              setState(() {
                _sortBy = _sortBy == 'level' ? 'name' : 'level';
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGroupSection(String key, List<Map<String, dynamic>> groupMoves) {
    final isLevelSort = _sortBy == 'level';

    // Parse key safely
    final keyParts = key.split('-');
    final levelNum = int.tryParse(keyParts[0]) ?? 0;

    // Determine display text
    String displayKey;
    if (isLevelSort) {
      if (levelNum == 0) {
        final method = keyParts.length > 1 ? keyParts[1] : 'other';
        displayKey = method == 'egg' ? 'Egg' : method == 'tutor' ? 'Tutor' : 'TM/HM';
      } else {
        displayKey = 'Lv. $levelNum';
      }
    } else {
      displayKey = key.toUpperCase();
    }

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 8),
      key: PageStorageKey(key), // Mantiene estado de expansión
      initiallyExpanded: expandedSections[key] ?? false,
      onExpansionChanged: (isExpanded) {
        setState(() {
          expandedSections[key] = isExpanded;
        });
      },
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _sortBy == 'level'
                  ? _getLevelColor(levelNum)
                  : Colors.blue[700],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              displayKey,
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${groupMoves.length} move${groupMoves.length > 1 ? 's' : ''}',
            style: GoogleFonts.roboto(fontSize: 14),
          ),
        ],
      ),
      // CHILDREN SE CONSTRUYEN SOLO CUANDO SE NECESITAN
      // Flutter automáticamente hace lazy loading de los children del ExpansionTile
      children: groupMoves.map((moveData) {
        return _buildMoveListTile(moveData);
      }).toList(),
    );
  }

  /// Builds a single move list tile
  Widget _buildMoveListTile(Map<String, dynamic> moveData) {
    final move = moveData['move'] as Map<String, dynamic>;
    final method = moveData['method'] as String;

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Row(
        children: [
          Expanded(
            child: Text(
              _formatMoveName(move['name'] ?? 'Unknown Move'),
              style: GoogleFonts.roboto(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: widget.isDarkMode ? Colors.white : Colors.grey[800],
              ),
            ),
          ),
          _buildMethodBadge(method),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            if (move['pokemon_v2_type'] != null)
              _buildTypeBadge(move['pokemon_v2_type']['name']),
            _buildStatText('PWR', move['power']),
            _buildStatText('ACC', move['accuracy'], suffix: '%'),
            _buildStatText('PP', move['pp']),
          ],
        ),
      ),
    );
  }

  /// Builds type badge
  Widget _buildTypeBadge(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getTypeColor(type),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type.toUpperCase(),
        style: GoogleFonts.roboto(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Builds stat text
  Widget _buildStatText(String label, dynamic value, {String suffix = ''}) {
    return Text(
      '$label: ${value ?? '--'}$suffix',
      style: GoogleFonts.roboto(
        fontSize: 11,
        color: widget.isDarkMode ? Colors.white : Colors.grey[800],
      ),
    );
  }

  /// Builds method badge
  Widget _buildMethodBadge(String method) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getMethodColor(method),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        _formatMethodName(method).toUpperCase(),
        style: GoogleFonts.roboto(
          fontSize: 9,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Removes duplicates based on move name and method
  List<Map<String, dynamic>> _getUniqueMoves(List<dynamic> moves) {
    final seen = <String>{};
    final uniqueList = <Map<String, dynamic>>[];

    for (var moveData in moves) {
      final move = moveData['pokemon_v2_move'] as Map<String, dynamic>?;
      if (move == null) continue;

      final moveName = move['name'] as String? ?? 'unknown';
      final level = moveData['level'] as int? ?? 0;
      final method = moveData['method'] as String? ?? 'other';

      final key = '$moveName-$method';

      if (!seen.contains(key)) {
        seen.add(key);
        uniqueList.add({
          'level': level,
          'method': method,
          'move': move,
        });
      }
    }

    return uniqueList;
  }

  /// Filters and sorts moves
  List<Map<String, dynamic>> _filterAndSortMoves(List<Map<String, dynamic>> moves) {
    var filtered = moves;

    // Apply method filter
    if (_selectedMethod != 'All') {
      filtered = filtered.where((m) => m['method'] == _selectedMethod).toList();
    }

    // Apply sorting
    if (_sortBy == 'level') {
      filtered.sort((a, b) {
        final levelA = a['level'] as int;
        final levelB = b['level'] as int;
        if (levelA != levelB) return levelA.compareTo(levelB);
        return (a['move']['name'] as String).compareTo(b['move']['name'] as String);
      });
    } else {
      filtered.sort((a, b) =>
          (a['move']['name'] as String).compareTo(b['move']['name'] as String)
      );
    }

    return filtered;
  }

  /// Groups moves by level or by first letter (depending on sort mode)
  /// Groups moves by level or by first letter (depending on sort mode)
  Map<String, List<Map<String, dynamic>>> _groupMovesByKey(List<Map<String, dynamic>> moves) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var move in moves) {
      String key;

      if (_sortBy == 'level') {
        final level = move['level'] as int;
        final method = move['method'] as String;
        // Create composite key: "level-method"
        key = '$level-$method';
      } else {
        // Group by first letter for alphabetical sorting
        key = move['name'].toString()[0].toUpperCase();
      }

      grouped.putIfAbsent(key, () => []).add(move);
    }

    // Sort the groups
    return Map.fromEntries(
        grouped.entries.toList()..sort((a, b) {
          if (_sortBy == 'level') {
            // Extract level numbers from composite keys for numeric comparison
            final aLevel = int.parse(a.key.split('-')[0]);
            final bLevel = int.parse(b.key.split('-')[0]);

            // First sort by level numerically
            final levelCompare = aLevel.compareTo(bLevel);
            if (levelCompare != 0) return levelCompare;

            // If same level, sort by method alphabetically
            return a.key.compareTo(b.key);
          }
          // Alphabetical sorting by letter
          return a.key.compareTo(b.key);
        })
    );
  }


  /// Gets available methods
  List<String> _getAvailableMethods(List<Map<String, dynamic>> moves) {
    final methods = moves.map((m) => m['method'] as String).toSet().toList();
    methods.sort();
    return ['All', ...methods];
  }

  /// Formats method name
  String _formatMethodName(String method) {
    switch (method) {
      case 'level-up': return 'Level Up';
      case 'machine': return 'TM/HM';
      case 'egg': return 'Egg Move';
      case 'tutor': return 'Move Tutor';
      case 'All': return 'All Methods';
      default: return method.toUpperCase();
    }
  }

  /// Formats move name
  String _formatMoveName(String name) {
    return name.split('-').map((word) =>
    word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  /// Gets color for level badge
  Color _getLevelColor(int level) {
    if (level == 0) return Colors.purple;
    if (level <= 20) return Colors.green;
    if (level <= 40) return Colors.blue;
    if (level <= 60) return Colors.orange;
    return Colors.red;
  }

  /// Gets color for method
  Color _getMethodColor(String method) {
    switch (method) {
      case 'level-up': return Colors.green[700]!;
      case 'machine': return Colors.purple[700]!;
      case 'egg': return Colors.pink[700]!;
      case 'tutor': return Colors.orange[700]!;
      default: return Colors.grey[700]!;
    }
  }

  /// Gets color for type
  Color _getTypeColor(String type) {
    const typeColors = {
      'normal': Color(0xFFA8A878),
      'fire': Color(0xFFF08030),
      'water': Color(0xFF6890F0),
      'electric': Color(0xFFF8D030),
      'grass': Color(0xFF78C850),
      'ice': Color(0xFF98D8D8),
      'fighting': Color(0xFFC03028),
      'poison': Color(0xFFA040A0),
      'ground': Color(0xFFE0C068),
      'flying': Color(0xFFA890F0),
      'psychic': Color(0xFFF85888),
      'bug': Color(0xFFA8B820),
      'rock': Color(0xFFB8A038),
      'ghost': Color(0xFF705898),
      'dragon': Color(0xFF7038F8),
      'dark': Color(0xFF705848),
      'steel': Color(0xFFB8B8D0),
      'fairy': Color(0xFFEE99AC),
    };
    return typeColors[type.toLowerCase()] ?? Colors.grey;
  }
}
