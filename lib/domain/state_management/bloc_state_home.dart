import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '/data/queries.dart';

// Events
abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class LoadPokemonList extends HomeEvent {
  final int pokemonId;
  final String? selectedType;
  final int? selectedGeneration;
  final String? selectedAbility;
  final String? sortOrder;
  final String? sortBy;

  const LoadPokemonList({
    required this.pokemonId,
    this.selectedType,
    this.selectedGeneration,
    this.selectedAbility,
    this.sortOrder,
    this.sortBy,
  });

  @override
  List<Object?> get props => [pokemonId, selectedType, selectedGeneration, selectedAbility, sortOrder, sortBy];
}

class LoadMorePokemon extends HomeEvent {
  const LoadMorePokemon();
}

class SearchPokemon extends HomeEvent {
  final String query;

  const SearchPokemon(this.query);

  @override
  List<Object?> get props => [query];
}

class UpdateFilters extends HomeEvent {
  final String? type;
  final int? generation;
  final String? ability;
  final String? sortOrder;
  final String? sortBy;


  const UpdateFilters({this.type, this.generation, this.ability, this.sortOrder, this.sortBy});

  @override
  List<Object?> get props => [type, generation, ability];

}

// States
abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<Map<String, dynamic>> pokemonList;
  final int currentPokemonId;
  final String searchQuery;
  final String? selectedType;
  final int? selectedGeneration;
  final String? selectedAbility;
  final String sortOrder;
  final String sortBy;
  final bool hasReachedMax;
  final int currentSearchPage;

  const HomeLoaded({
    required this.pokemonList,
    required this.currentPokemonId,
    this.searchQuery = '',
    this.selectedType,
    this.selectedGeneration,
    this.selectedAbility,
    this.sortOrder='asc',
    this.sortBy='id',
    this.hasReachedMax = false,
    this.currentSearchPage = 1,
  });

  @override
  List<Object?> get props => [
    pokemonList,
    currentPokemonId,
    searchQuery,
    selectedType,
    selectedGeneration,
    selectedAbility,
    sortOrder,
    sortBy,
    hasReachedMax,
    currentSearchPage,
  ];

  HomeLoaded copyWith({
    List<Map<String, dynamic>>? pokemonList,
    int? currentPokemonId,
    String? searchQuery,
    String? selectedType,
    int? selectedGeneration,
    String? selectedAbility,
    bool? hasReachedMax,
    String? sortOrder,
    String? sortBy,
    int? currentSearchPage,
  }) {
    return HomeLoaded(
      pokemonList: pokemonList ?? this.pokemonList,
      currentPokemonId: currentPokemonId ?? this.currentPokemonId,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedType: selectedType ?? this.selectedType,
      selectedGeneration: selectedGeneration ?? this.selectedGeneration,
      selectedAbility: selectedAbility ?? this.selectedAbility,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      sortOrder: sortOrder ?? this.sortOrder,
      sortBy: sortBy ?? this.sortBy,
      currentSearchPage: currentSearchPage ?? this.currentSearchPage,
    );
  }
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}




/// HomeBloc
/// Handles loading, pagination, searching and filter updates for the Home page.
/// Accepts a GraphQL client through the constructor to keep networking out of widgets.
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final dynamic client;
  static const int _pageSize = 50;

  HomeBloc({required this.client}) : super(HomeInitial()) {
    on<LoadPokemonList>(_onLoadPokemonList);
    on<LoadMorePokemon>(_onLoadMorePokemon);
    on<SearchPokemon>(_onSearchPokemon);
    on<UpdateFilters>(_onUpdateFilters);
  }

  /// Handler for initial load or reload with filters.
  /// Emits HomeLoading, fetches the first page via fetchPokemonList, then emits HomeLoaded.
  Future<void> _onLoadPokemonList(
      LoadPokemonList event,
      Emitter<HomeState> emit,
      ) async {
    emit(HomeLoading());
    try {
      final pokemonList = await fetchPokemonList(
        client,
        event.selectedType,
        event.selectedGeneration,
        event.selectedAbility,
        event.sortOrder ?? 'asc',
        event.sortBy ?? 'id',
        1, // Start from page 1
      );

      emit(HomeLoaded(
        pokemonList: pokemonList,
        currentPokemonId: event.pokemonId,
        selectedType: event.selectedType,
        selectedGeneration: event.selectedGeneration,
        selectedAbility: event.selectedAbility,
        sortOrder: event.sortOrder ?? 'asc',
        hasReachedMax: pokemonList.length < _pageSize,
      ));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  /// Handler to load the next page when user scrolls near bottom.
  /// Calculates next page from current list length, fetches, appends and emits updated state.
  Future<void> _onLoadMorePokemon(
      LoadMorePokemon event,
      Emitter<HomeState> emit,
      ) async {
    final currentState = state;
    if (currentState is HomeLoaded && !currentState.hasReachedMax) {
      try {
        List<Map<String, dynamic>> morePokemon;
        int nextPage;

        // Check if we're in search mode
        if (currentState.searchQuery.isNotEmpty) {
          // Use currentSearchPage counter for search pagination
          nextPage = currentState.currentSearchPage + 1;
          morePokemon = await searchPokemonByName(
            currentState.searchQuery,
            client,
            nextPage,
          );
        } else {
          // Normal pagination with filters
          nextPage = (currentState.pokemonList.length ~/ _pageSize) + 1;
          morePokemon = await fetchPokemonList(
            client,
            currentState.selectedType,
            currentState.selectedGeneration,
            currentState.selectedAbility,
            currentState.sortOrder,
            currentState.sortBy,
            nextPage,
          );
        }

        // Append to existing list instead of replacing
        final updatedList = [...currentState.pokemonList, ...morePokemon];

        emit(currentState.copyWith(
          pokemonList: updatedList,
          hasReachedMax: morePokemon.length < _pageSize,
          currentSearchPage: currentState.searchQuery.isNotEmpty ? nextPage : currentState.currentSearchPage,
        ));
      } catch (e) {
        emit(HomeError(e.toString()));
      }
    }
  }



  /// Handler for search event.
  /// If query is empty, triggers LoadPokemonList to restore the list.
  /// Otherwise searches by name and emits a HomeLoaded with terminal results.
  Future<void> _onSearchPokemon(
      SearchPokemon event,
      Emitter<HomeState> emit,
      ) async {
    if (event.query.isEmpty) {
      final currentState = state;
      if (currentState is HomeLoaded) {
        add(LoadPokemonList(
          pokemonId: 1,
          selectedType: currentState.selectedType,
          selectedGeneration: currentState.selectedGeneration,
          selectedAbility: currentState.selectedAbility,
          sortOrder: currentState.sortOrder,
          sortBy: currentState.sortBy,
        ));
      }
      return;
    }

    emit(HomeLoading());
    try {
      final results = await searchPokemonByName(event.query, client, 1);
      emit(HomeLoaded(
        pokemonList: results,
        currentPokemonId: 1,
        searchQuery: event.query,
        currentSearchPage: 1,
        hasReachedMax: results.length < _pageSize,
      ));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  /// Handler to update filters: transforms into a LoadPokemonList event.
  void _onUpdateFilters(
      UpdateFilters event,
      Emitter<HomeState> emit,
      ) {
    add(LoadPokemonList(
      pokemonId: 1,
      selectedType: event.type,
      selectedGeneration: event.generation,
      selectedAbility: event.ability,
      sortOrder: event.sortOrder ?? 'asc',
      sortBy: event.sortBy ?? 'id',
    ));
  }
}