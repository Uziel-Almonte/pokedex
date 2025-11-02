Estado de cumplimiento de una tarea:

X - no se ha iniciado

I - en desarrollo

O - completo




1. Interfaz de Usuario (UI/UX) — 25 %
Lista de Pokémon

I - Mostrar nombre, imagen, tipo(s) y número (#dex). 

I - Implementar barra de búsqueda con debounce (300–500 ms). 

X - Diseño moderno, accesible y responsivo (Material 3). 

O - Aplicar temas dinámicos (oscuro/claro). 

X - Pantalla de error con mensaje y botón “Reintentar”. 

Pantalla de Detalles

O - Mostrar nombre, número, tipos, sprite/official-artwork. 

O - Si hay 2 tipos, mostrar ambos; si falta imagen oficial, usar sprite. 

O - Mostrar estadísticas base (HP, Atk, Def, SpA, SpD, Spe) y total. 

X - Visualizar stats con radar chart o barras; incluir valores y porcentajes. 

X - Mostrar habilidades: nombre, si es oculta (isHidden == true) y efecto resumido (≤ 160 caracteres).

X - Mostrar evoluciones (pre-evo → evo1 → evo2 / ramas) y triggers (nivel, objeto, intercambio, amistad, hora).

X - Si no evoluciona, mostrar mensaje “No evoluciona”.

X - Mostrar movimientos filtrables por método (level-up / TM / Tutor / Egg) y orden (nivel / nombre).

X - Paginación local (≥ 20 sin lag).

X - Acciones: Favorito, Compartir, Abrir en mapa/regiones (si aplica).

X - Favorito persiste en < 150 ms y se refleja al volver a la lista.

X - Mostrar matchups (debilidades, resistencias, inmunidades x4–x0).

O - Mostrar peso, altura y egg groups.

X - Variantes/formas (dropdown → Alola, Galar, etc.).

X - Botón Shiny toggle (si existen assets).

2. Uso de GraphQL — 10 %

I - Integrar API GraphQL de PokeAPI.

X - Implementar paginación basada en cursor.

X - Agregar cache local y manejo de errores (timeout, rate limit, sin conexión).

3. Gestión de Estado y Arquitectura — 15 %

X - Usar arquitectura de 3 capas: data/, domain/, presentation/.

X - Utilizar Riverpod o BLoC (u otro gestor de estado).

X - Separar modelos, DTOs y mapeos correctamente.

4. Filtrado y Ordenación — 10 %

X - Filtrar Pokémon por nombre.

I - Agregar dropdown de filtros: tipo, generación, región, habilidad o poder.

X - Ordenar por nombre, número o poder.

X - Mantener filtros activos entre sesiones.

5. Favoritos y Persistencia Local — 10 %

X - Guardar Pokémon favoritos en almacenamiento local (Hive, Isar u otro).

X - Mostrar lista de favoritos en vista dedicada.

X - Habilitar modo offline para favoritos y último listado visto.

6. Animaciones y Transiciones — 5 %

X - Implementar animaciones Hero, microinteracciones y transiciones suaves.

X - Animar al agregar/quitar favoritos o cambiar de vista.

7. Compartir Pokémon — 5 %

I - Generar una Pokémon Card y compartirla como imagen.

8. Mapa Interactivo — 5 %

X - Mostrar regiones/juegos donde aparece cada Pokémon.

X - Usar mapas interactivos (flutter_map, leaflet o similar).

9. Accesibilidad e Internacionalización — 5 %

X - Agregar etiquetas Semantics y tamaños táctiles adecuados.

X - Implementar soporte multilenguaje (español/inglés, mínimo en trivia).

10. Sección Interactiva: “¿Quién es este Pokémon?” — 10 %

X - Mostrar silueta del Pokémon y pedir nombre.

X - Sistema de puntuación y tiempo límite.

X - Ranking local y persistencia de resultados.

X - esbloquear logros visuales al alcanzar puntajes altos.
