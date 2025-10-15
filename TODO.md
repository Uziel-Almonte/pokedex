1. Interfaz de Usuario (UI/UX) — 25 %
Lista de Pokémon

 Mostrar nombre, imagen, tipo(s) y número (#dex).

 Implementar barra de búsqueda con debounce (300–500 ms).

 Diseño moderno, accesible y responsivo (Material 3).

 Aplicar temas dinámicos (oscuro/claro).

 Pantalla de error con mensaje y botón “Reintentar”.

Pantalla de Detalles

 Mostrar nombre, número, tipos, sprite/official-artwork.

 Si hay 2 tipos, mostrar ambos; si falta imagen oficial, usar sprite.

 Mostrar estadísticas base (HP, Atk, Def, SpA, SpD, Spe) y total.

 Visualizar stats con radar chart o barras; incluir valores y porcentajes.

 Mostrar habilidades: nombre, si es oculta (isHidden == true) y efecto resumido (≤ 160 caracteres).

 Mostrar evoluciones (pre-evo → evo1 → evo2 / ramas) y triggers (nivel, objeto, intercambio, amistad, hora).

 Si no evoluciona, mostrar mensaje “No evoluciona”.

 Mostrar movimientos filtrables por método (level-up / TM / Tutor / Egg) y orden (nivel / nombre).

 Paginación local (≥ 20 sin lag).

 Acciones: Favorito, Compartir, Abrir en mapa/regiones (si aplica).

 Favorito persiste en < 150 ms y se refleja al volver a la lista.

 Mostrar matchups (debilidades, resistencias, inmunidades x4–x0).

 Mostrar peso, altura y egg groups.

 Variantes/formas (dropdown → Alola, Galar, etc.).

 Botón Shiny toggle (si existen assets).

2. Uso de GraphQL — 10 %

 Integrar API GraphQL de PokeAPI.

 Implementar paginación basada en cursor.

 Agregar cache local y manejo de errores (timeout, rate limit, sin conexión).

3. Gestión de Estado y Arquitectura — 15 %

 Usar arquitectura de 3 capas: data/, domain/, presentation/.

 Utilizar Riverpod o BLoC (u otro gestor de estado).

 Separar modelos, DTOs y mapeos correctamente.

4. Filtrado y Ordenación — 10 %

 Filtrar Pokémon por nombre.

 Agregar dropdown de filtros: tipo, generación, región, habilidad o poder.

 Ordenar por nombre, número o poder.

 Mantener filtros activos entre sesiones.

5. Favoritos y Persistencia Local — 10 %

 Guardar Pokémon favoritos en almacenamiento local (Hive, Isar u otro).

 Mostrar lista de favoritos en vista dedicada.

 Habilitar modo offline para favoritos y último listado visto.

6. Animaciones y Transiciones — 5 %

 Implementar animaciones Hero, microinteracciones y transiciones suaves.

 Animar al agregar/quitar favoritos o cambiar de vista.

7. Compartir Pokémon — 5 %

 Generar una Pokémon Card y compartirla como imagen.

8. Mapa Interactivo — 5 %

 Mostrar regiones/juegos donde aparece cada Pokémon.

 Usar mapas interactivos (flutter_map, leaflet o similar).

9. Accesibilidad e Internacionalización — 5 %

 Agregar etiquetas Semantics y tamaños táctiles adecuados.

 Implementar soporte multilenguaje (español/inglés, mínimo en trivia).

10. Sección Interactiva: “¿Quién es este Pokémon?” — 10 %

 Mostrar silueta del Pokémon y pedir nombre.

 Sistema de puntuación y tiempo límite.

 Ranking local y persistencia de resultados.

 Desbloquear logros visuales al alcanzar puntajes altos.
