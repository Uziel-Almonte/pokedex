// Import Flutter material design package
import 'package:flutter/material.dart';
//fonts de google
import 'package:google_fonts/google_fonts.dart';
// Import the TCG service for Pokémon trading cards
import 'tcgCards.dart';




// New: Show Pokémon trading cards in a bottom sheet using TCG service
// This method fetches cards by Pokémon name and displays them in a grid
void showPokemonCards(String pokemonName, BuildContext context, bool isDarkMode) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return FutureBuilder<List<Map<String, dynamic>>>(
        future: TCGService.searchCardsByPokemon(pokemonName),
        builder: (context, snapshot) {
          // Show loading spinner while fetching data
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.4,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: const Center(child: CircularProgressIndicator(color: Colors.red)),
            );
          }

          // Show error if something went wrong
          if (snapshot.hasError) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.3,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error loading cards: ${snapshot.error}',
                    style: GoogleFonts.roboto(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }

          final cards = snapshot.data ?? [];

          // Show message if no cards found
          if (cards.isEmpty) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.3,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Center(
                child: Text(
                  'No trading cards found for $pokemonName',
                  style: GoogleFonts.pressStart2p(fontSize: 10, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[900] : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    // Drag handle
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Title
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        '${pokemonName.toUpperCase()} CARDS (${cards.length})',
                        style: GoogleFonts.pressStart2p(fontSize: 14, color: Colors.red),
                      ),
                    ),
                    // Cards grid
                    Expanded(
                      child: GridView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.68,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: cards.length,
                        itemBuilder: (context, index) {
                          final card = cards[index];
                          // Extract image URL - it's a direct string in TCGDex API
                          // Format: "https://assets.tcgdex.net/en/swsh/swsh3/136"
                          // We can append "/high.png" or "/low.png" for different qualities
                          final baseImageUrl = card['image']?.toString() ?? '';
                          final imageUrl = baseImageUrl.isNotEmpty ? '$baseImageUrl/high.png' : '';

                          return GestureDetector(
                            onTap: () {
                              if (imageUrl.isNotEmpty) {
                                showDialog(
                                  context: context,
                                  builder: (_) => Dialog(
                                    backgroundColor: Colors.black,
                                    child: InteractiveViewer(
                                      child: Image.network(
                                        imageUrl,
                                        errorBuilder: (c, e, s) => Center(
                                          child: Text('Image not available', style: GoogleFonts.roboto(color: Colors.white)),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Card image
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(10),
                                      ),
                                      child: imageUrl.isNotEmpty
                                          ? Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, progress) {
                                          if (progress == null) return child;
                                          return const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.red,
                                            ),
                                          );
                                        },
                                        errorBuilder: (c, e, s) => const Center(
                                          child: Icon(Icons.error, color: Colors.red),
                                        ),
                                      )
                                          : const Center(
                                        child: Icon(Icons.image_not_supported),
                                      ),
                                    ),
                                  ),
                                  // Card info (name and set)
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          card['name']?.toString() ?? 'Unknown',
                                          style: GoogleFonts.roboto(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          card['set']?['name']?.toString() ?? card['id']?.toString() ?? '',
                                          style: GoogleFonts.roboto(
                                            fontSize: 10,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}
