Estado de cumplimiento de una tarea:

X - no se ha iniciado

I - en desarrollo

O - completo




1. Interfaz de Usuario (UI/UX) — 25 %
Lista de Pokémon

O - Mostrar nombre, imagen, tipo(s) y número (#dex).

O - Implementar barra de búsqueda con debounce (300–500 ms).

O - Diseño moderno, accesible y responsivo (Material 3).

O - Aplicar temas dinámicos (oscuro/claro).

I - Pantalla de error con mensaje y botón "Reintentar".

Pantalla de Detalles

O - Mostrar nombre, número, tipos, sprite/official-artwork.

O - Si hay 2 tipos, mostrar ambos; si falta imagen oficial, usar sprite.

O - Mostrar estadísticas base (HP, Atk, Def, SpA, SpD, Spe) y total.

O - Visualizar stats con barras de progreso con colores por tipo de stat.

O - Mostrar habilidades: nombre, si es oculta (isHidden == true) y efecto resumido.

O - Mostrar evoluciones (pre-evo → evo1 → evo2 / ramas) y triggers (nivel, objeto, intercambio, amistad, hora).

O - Si no evoluciona, mostrar mensaje "No evoluciona".

O - Mostrar movimientos filtrables por método (level-up) agrupados por nivel.

O - Paginación local (≥ 20 sin lag).

I - Acciones: Favorito, Compartir, Abrir en mapa/regiones (si aplica).

O - Favorito persiste en < 150 ms y se refleja al volver a la lista.

X - Mostrar matchups (debilidades, resistencias, inmunidades x4–x0).

O - Mostrar peso, altura y egg groups.

X - Variantes/formas (dropdown → Alola, Galar, etc.).

O - Botón Shiny toggle (si existen assets).

2. Uso de GraphQL — 10 %

O - Integrar API GraphQL de PokeAPI.

O - Implementar paginación basada en cursor (actualmente usa offset).

O - Agregar cache local (Hive integrado con graphql_flutter).

O - Manejo de errores básico implementado.

3. Gestión de Estado y Arquitectura — 15 %

O - Usar arquitectura de 3 capas: data/, domain/, presentation/.

O - Utilizar BLoC (flutter_bloc) para gestión de estado.

O - Separar modelos (Pokemon class), queries (queries.dart) y mapeos correctamente.

4. Filtrado y Ordenación — 10 %

O - Filtrar Pokémon por nombre con búsqueda debounced.

O - Agregar dropdown de filtros: tipo, generación, y habilidad implementados.

O - Ordenar por nombre, número o poder (actualmente solo orden ascendente/descendente por ID).

X - Mantener filtros activos entre sesiones.

5. Favoritos y Persistencia Local — 10 %

O - Guardar Pokémon favoritos en almacenamiento local (Hive, Isar u otro).

O - Mostrar lista de favoritos en vista dedicada.

O - Habilitar modo offline para favoritos y último listado visto.

6. Animaciones y Transiciones — 5 %

X - Implementar animaciones Hero, microinteracciones y transiciones suaves.

O - Animar al agregar/quitar favoritos o cambiar de vista.

7. Compartir Pokémon — 5 %

O - Generar una Pokémon Card desde TCG y visualizarla (botón VIEW CARDS implementado con paginación optimizada).

X - Compartir tarjeta como imagen exportable.

8. Mapa Interactivo — 5 %

O - Mostrar regiones/juegos donde aparece cada Pokémon.

X - Usar mapas interactivos (flutter_map, leaflet o similar).

9. Accesibilidad e Internacionalización — 5 %

O - Agregar etiquetas Semantics y tamaños táctiles adecuados.

X - Implementar soporte multilenguaje (español/inglés, mínimo en trivia).

10. Sección Interactiva: "¿Quién es este Pokémon?" — 10 %

O - Mostrar silueta del Pokémon y pedir nombre.

O - Sistema de puntuación y tiempo límite.

X - Ranking local y persistencia de resultados.

O - Desbloquear logros visuales al alcanzar puntajes altos.


## Características Adicionales Implementadas

- **Tarjetas TCG**: Integración con TCGDex API para mostrar cartas de colección reales
- **Gradientes por Tipo**: Cada Pokémon muestra gradientes visuales basados en su(s) tipo(s)
- **Pie Charts**: Visualización de gender ratio con gráficos circulares
- **Tarjetas de Información**:
  - StatsCard (estadísticas base con barras de progreso)
  - AbilitiesCard (habilidades normales y ocultas)
  - MovesCard (movimientos agrupados por nivel)
  - EvolutionChainCard (cadena evolutiva completa)
  - PhysicalStatsCard (altura, peso, gender ratio, egg groups)
- **Navegación**: Botones prev/next para navegar entre Pokémon en detail page
- **Diseño Retro**: Fuente Press Start 2P (estilo 8-bit) en títulos y encabezados

## Progreso General Estimado: ~45-50%
