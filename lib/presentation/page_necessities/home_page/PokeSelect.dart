import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pokedex/data/dtos/pokemon_list_dto.dart';
import 'package:pokedex/domain/models/Pokemon.dart';


/// Widget reutilizable para mostrar una tarjeta de Pokémon en la lista
/// Incluye gradientes de color basados en el tipo del Pokémon
class PokeSelect extends StatelessWidget {
  final PokemonListItem pokemon;
  final String types;
  final bool isDarkMode;
  final VoidCallback? onTap; // Callback para manejar el tap en la tarjeta

  const PokeSelect({
    super.key,
    required this.pokemon,
    required this.types,
    required this.isDarkMode,
    this.onTap,
  });

  // ============================================================================
  // MAPA DE COLORES OFICIALES DE POKÉMON
  // ============================================================================
  // Cada tipo de Pokémon tiene un color oficial que se usa en los juegos
  // y cartas de Pokémon. Estos colores se utilizan para crear gradientes
  // visuales que representan el tipo del Pokémon en la tarjeta.
  static const Map<String, Color> typeColors = {
    'normal': Color(0xFFA8A878),    // Gris beige - Pokémon normales como Rattata
    'fire': Color(0xFFF08030),      // Naranja/Rojo - Pokémon de fuego como Charizard
    'water': Color(0xFF6890F0),     // Azul - Pokémon de agua como Blastoise
    'electric': Color(0xFFF8D030),  // Amarillo - Pokémon eléctricos como Pikachu
    'grass': Color(0xFF78C850),     // Verde - Pokémon de planta como Venusaur
    'ice': Color(0xFF98D8D8),       // Celeste - Pokémon de hielo como Lapras
    'fighting': Color(0xFFC03028),  // Rojo oscuro - Pokémon de pelea como Machamp
    'poison': Color(0xFFA040A0),    // Morado - Pokémon venenosos como Gengar
    'ground': Color(0xFFE0C068),    // Marrón claro - Pokémon de tierra como Sandslash
    'flying': Color(0xFFA890F0),    // Morado claro - Pokémon voladores como Pidgeot
    'psychic': Color(0xFFF85888),   // Rosa - Pokémon psíquicos como Alakazam
    'bug': Color(0xFFA8B820),       // Verde oliva - Pokémon insecto como Butterfree
    'rock': Color(0xFFB8A038),      // Marrón - Pokémon de roca como Onix
    'ghost': Color(0xFF705898),     // Morado oscuro - Pokémon fantasma como Haunter
    'dragon': Color(0xFF7038F8),    // Morado intenso - Pokémon dragón como Dragonite
    'dark': Color(0xFF705848),      // Café oscuro - Pokémon siniestros como Umbreon
    'steel': Color(0xFFB8B8D0),     // Gris plateado - Pokémon de acero como Steelix
    'fairy': Color(0xFFEE99AC),     // Rosa claro - Pokémon hada como Clefairy
  };

  // ============================================================================
  // MÉTODO PARA GENERAR GRADIENTES BASADOS EN EL TIPO
  // ============================================================================
  /// Genera un gradiente de color basado en el/los tipo(s) del Pokémon
  ///
  /// CASOS:
  /// 1. Un solo tipo: Crea un gradiente del mismo color con variaciones de opacidad
  ///    Ejemplo: Charmander (Fire) → Gradiente naranja claro a naranja oscuro
  ///
  /// 2. Dos tipos: Crea un gradiente diagonal entre ambos colores
  ///    Ejemplo: Bulbasaur (Grass/Poison) → Gradiente verde a morado
  ///    Ejemplo: Pokémon Water/Ground → Gradiente azul a marrón
  ///
  /// 3. Tipo desconocido: Devuelve un gradiente gris como fallback
  LinearGradient _getTypeGradient() {
    // Dividir los tipos por coma y limpiar espacios
    // Ejemplo: "fire, flying" → ["fire", "flying"]
    final typeList = types.toLowerCase().split(', ').map((t) => t.trim()).toList();

    if (typeList.length == 1) {
      // ========================================================================
      // CASO 1: POKÉMON CON UN SOLO TIPO
      // ========================================================================
      // Buscar el color del tipo en el mapa, usar gris si no existe
      final color = typeColors[typeList[0]] ?? Colors.grey;

      // Crear gradiente del mismo color con diferentes opacidades
      // Esto da un efecto de profundidad y textura a la tarjeta
      return LinearGradient(
        begin: Alignment.topLeft,     // Comienza en la esquina superior izquierda
        end: Alignment.bottomRight,   // Termina en la esquina inferior derecha
        colors: [
          color.withOpacity(0.7),     // Color más claro (70% opacidad)
          color,                       // Color original (100% opacidad)
          color.withOpacity(0.9),     // Color ligeramente más oscuro (90% opacidad)
        ],
      );
    } else if (typeList.length >= 2) {
      // ========================================================================
      // CASO 2: POKÉMON CON DOS TIPOS (HÍBRIDO)
      // ========================================================================
      // Obtener los colores de ambos tipos
      final color1 = typeColors[typeList[0]] ?? Colors.grey;
      final color2 = typeColors[typeList[1]] ?? Colors.grey;

      // Crear gradiente diagonal que transiciona suavemente entre ambos colores
      // Esto representa visualmente la dualidad del tipo del Pokémon
      return LinearGradient(
        begin: Alignment.topLeft,     // Primer color arriba-izquierda
        end: Alignment.bottomRight,   // Segundo color abajo-derecha
        colors: [color1, color2],     // Transición suave entre ambos
      );
    }

    // ========================================================================
    // CASO 3: FALLBACK (TIPO DESCONOCIDO O INVÁLIDO)
    // ========================================================================
    // Si no se puede determinar el tipo, usar un gradiente gris neutro
    return LinearGradient(
      colors: [Colors.grey.shade300, Colors.grey.shade500],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Extraer información del Pokémon del objeto Map
    final pokemonName = pokemon.name ?? 'Unknown'; // Nombre del Pokémon
    final pokemonId = pokemon.id ?? '0'; // ID del Pokémon para la imagen
    final imageURL = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$pokemonId.png';
    return GestureDetector( // Detecta toques/clics en la tarjeta
      onTap: onTap, // Ejecuta el callback cuando se toca la tarjeta
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          // ====================================================================
          // APLICAR EL GRADIENTE DE COLOR BASADO EN EL TIPO
          // ====================================================================
          // En lugar de un color sólido, usamos el gradiente generado
          // por _getTypeGradient() para dar un efecto visual único a cada tipo
          gradient: _getTypeGradient(),
          borderRadius: BorderRadius.circular(20), // Bordes redondeados
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3), // Sombra oscura semi-transparente
              spreadRadius: 3,  // Qué tan lejos se extiende la sombra
              blurRadius: 8,    // Qué tan difusa es la sombra
              offset: const Offset(0, 4), // Desplazamiento hacia abajo
            ),
          ],
        ),
        child: Column(
          children: [
            // ==================================================================
            // IMAGEN DEL POKÉMON
            // ==================================================================
            // Cargar imagen oficial del Pokémon desde el repositorio de sprites
            Image.network(
              imageURL,
              height: 60,
              width: 60,
              errorBuilder: (context, error, stackTrace) {
                return Image.network(
                  'https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/i/8a5d5bc8-94fe-46e1-ac40-03969b602a62/dg4mjun-6ca3d4fd-44d1-4587-9152-7f817fa1a4c0.png/v1/fill/w_457,h_497/pokeball_recycle_bin_icon_empty_v2_by_blacklem00n_dg4mjun-fullview.png', // Use local asset as fallback
                  height: 60,
                  width: 60,
                );
              },
            ),
            const SizedBox(height: 20),

            // ==================================================================
            // NÚMERO DEL POKÉMON (#001, #025, etc.)
            // ==================================================================
            Text(
              '#$pokemonId',
              style: GoogleFonts.pressStart2p(
                fontSize: 16,
                color: Colors.white, // Blanco para contraste con el gradiente
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                    color: Colors.black.withOpacity(0.7), // Sombra negra para legibilidad
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ==================================================================
            // NOMBRE DEL POKÉMON
            // ==================================================================
            Text(
              pokemonName.toString().toUpperCase(),
              style: GoogleFonts.pressStart2p(
                fontSize: 24,
                color: Colors.white, // Blanco sobre el gradiente de color
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                    color: Colors.black.withOpacity(0.8), // Sombra más fuerte
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ==================================================================
            // TIPO(S) DEL POKÉMON
            // ==================================================================
            Text(
              'Types: $types',
              style: GoogleFonts.roboto(
                fontSize: 18,
                color: Colors.white, // Blanco con sombra para legibilidad
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    offset: const Offset(1, 1),
                    blurRadius: 3,
                    color: Colors.black.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
