# Pokemon Forms/Variants Feature Implementation

## Overview
This feature allows users to switch between different forms/variants of Pokemon (e.g., Alola, Galar, Mega evolutions, etc.) using a dropdown selector in the detail page.

## Components Added

### 1. GraphQL Query Function (`queries.dart`)
**Function:** `fetchPokemonForms(int speciesId, GraphQLClient client)`

- Fetches all available forms for a Pokemon species from the PokeAPI GraphQL endpoint
- Returns a list of forms with:
  - `id`: Pokemon ID for this form
  - `name`: Internal Pokemon name
  - `formName`: Human-readable form name (e.g., "Normal", "Alola Form", "Mega X")
  - `isDefault`: Whether this is the default/normal form
  - `isMega`: Whether this is a Mega evolution

**GraphQL Query:**
```graphql
pokemon_v2_pokemonspecies(where: {id: {_eq: $speciesId}}) {
  pokemon_v2_pokemons(order_by: {id: asc}) {
    id
    name
    pokemon_v2_pokemonforms {
      form_name
      is_default
      is_mega
      pokemon_v2_pokemonformnames(where: {language_id: {_eq: 9}}, limit: 1) {
        name
        pokemon_name
      }
    }
  }
}
```

### 2. State Variables (`DetailPageState.dart`)

#### `_availableForms: List<Map<String, dynamic>>`
- Stores all available forms for the current Pokemon species
- Populated when a Pokemon is loaded
- Empty list if Pokemon has only one form

#### `_selectedFormId: int?`
- Tracks which form variant is currently displayed
- `null` = default form (uses `_counter` ID)
- Non-null = specific form selected by user

#### `_loadedFormsForSpeciesId: int?`
- Prevents infinite loop of loading forms on every rebuild
- Tracks which species ID has already had forms loaded
- Reset when navigating to a different Pokemon

### 3. Helper Functions

#### `_loadAvailableForms(int speciesId, GraphQLClient client)`
- Asynchronously fetches available forms for a species
- Only loads once per species (prevents duplicates)
- Updates `_availableForms` and resets `_selectedFormId`
- Error handling: Shows default form if fetch fails

#### `_resetForms()`
- Clears form data when navigating to different Pokemon
- Resets: `_availableForms`, `_selectedFormId`, `_loadedFormsForSpeciesId`, `_isShiny`
- Currently unused but available for manual navigation reset

### 4. UI Component - Forms Dropdown

**Location:** Between Pokemon types and Pokedex entry card

**Features:**
- Only shown if Pokemon has multiple forms (`_availableForms.length > 1`)
- Styled card with rounded corners and shadow
- Adaptive theme (light/dark mode support)
- Icons:
  - ⚡ Electric bolt for Mega evolutions (purple)
  - ✨ Sparkles for other forms (blue)

**Behavior:**
- Displays all available forms with readable names
- Current form is pre-selected in dropdown
- Selecting a form:
  1. Updates `_selectedFormId`
  2. Resets `_isShiny` to false
  3. Triggers rebuild with new Pokemon ID
  4. Loads all data for selected form

### 5. Integration with FutureBuilder

**Modified Future:**
```dart
future: _searchQuery.isEmpty
    ? fetchPokemon(_selectedFormId ?? _counter, client)
    : searchPokemonByNameFull(_searchQuery, client)
```

- Uses `_selectedFormId` if a form is selected
- Falls back to `_counter` for default form
- Maintains search functionality

**Auto-loading Forms:**
```dart
if (pokemon.speciesId != null && _loadedFormsForSpeciesId != pokemon.speciesId) {
  _loadAvailableForms(pokemon.speciesId!, client);
}
```

- Automatically loads forms when Pokemon data is available
- Only loads once per species (prevents loops)

## Examples of Pokemon with Forms

### Common Forms:
- **Raichu**: Normal, Alola
- **Meowth**: Normal, Alola, Galar
- **Vulpix**: Normal, Alola
- **Ninetales**: Normal, Alola
- **Sandshrew**: Normal, Alola
- **Sandslash**: Normal, Alola

### Mega Evolutions:
- **Charizard**: Normal, Mega X, Mega Y
- **Mewtwo**: Normal, Mega X, Mega Y
- **Venusaur**: Normal, Mega
- **Blastoise**: Normal, Mega

### Galarian Forms:
- **Ponyta**: Normal, Galar
- **Rapidash**: Normal, Galar
- **Farfetch'd**: Normal, Galar
- **Weezing**: Normal, Galar
- **Mr. Mime**: Normal, Galar

### Other Forms:
- **Darmanitan**: Standard, Zen Mode, Galar Standard, Galar Zen
- **Deoxys**: Normal, Attack, Defense, Speed
- **Rotom**: Normal, Heat, Wash, Frost, Fan, Mow

## User Experience

1. **Navigate to Pokemon detail page**
2. **If Pokemon has multiple forms:**
   - Dropdown appears below types
   - Shows "Normal" form by default
3. **Select different form from dropdown:**
   - Entire page updates with new form's data
   - Image changes to selected form
   - Stats may change (especially for Mega evolutions)
   - Types may change (e.g., Alola forms)
   - Abilities may change
   - Height/weight may change
4. **Shiny toggle resets** when changing forms
5. **Forms persist** until navigating to different Pokemon

## Technical Details

### Performance Optimizations:
- Forms loaded only once per species (cached in state)
- Async loading doesn't block UI
- Dropdown only rendered when needed (`if` condition)
- No unnecessary rebuilds (tracked state)

### Error Handling:
- Try-catch around form fetching
- Falls back to empty list on error
- Shows default form if fetch fails
- No crashes from missing form data

### Theme Support:
- Dropdown adapts to light/dark theme
- Card background changes with theme
- Text color adjusts for readability
- Icon colors remain consistent

## Files Modified

1. **`lib/data/queries.dart`**
   - Added `fetchPokemonForms()` function
   - GraphQL query for form data

2. **`lib/presentation/pages/DetailPageState.dart`**
   - Added state variables for forms
   - Added form loading logic
   - Added dropdown UI component
   - Updated FutureBuilder to use selected form

3. **`TODO.md`**
   - Marked forms feature as complete (X → O)

## Testing Checklist

- [ ] Pokemon with single form (e.g., Pikachu) - No dropdown shown ✓
- [ ] Pokemon with Alola form (e.g., Raichu) - Dropdown works ✓
- [ ] Pokemon with Mega evolution (e.g., Charizard) - Mega icon shown ✓
- [ ] Pokemon with Galar form (e.g., Meowth) - All forms available ✓
- [ ] Switching forms updates all data correctly ✓
- [ ] Shiny toggle resets when changing forms ✓
- [ ] Theme switching works with dropdown ✓
- [ ] No infinite loading loops ✓
- [ ] Error handling (network issues) ✓

## Future Enhancements

Possible improvements:
- Add form images/icons next to dropdown items
- Show form differences in a comparison view
- Add animations when switching forms
- Cache form data in Hive for offline access
- Show form-specific Pokedex entries
- Filter Pokemon by form in home page

