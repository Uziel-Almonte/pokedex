import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '/domain/models/Pokemon.dart';
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

  const LoadPokemonList({
    required this.pokemonId,
    this.selectedType,
    this.selectedGeneration,
    this.selectedAbility,
  });

  @override
  List<Object?> get props => [pokemonId, selectedType, selectedGeneration, selectedAbility];
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

  const UpdateFilters({this.type, this.generation, this.ability});

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
  final bool hasReachedMax;

  const HomeLoaded({
    required this.pokemonList,
    required this.currentPokemonId,
    this.searchQuery = '',
    this.selectedType,
    this.selectedGeneration,
    this.selectedAbility,
    this.hasReachedMax = false,
  });

  @override
  List<Object?> get props => [
    pokemonList,
    currentPokemonId,
    searchQuery,
    selectedType,
    selectedGeneration,
    selectedAbility,
    hasReachedMax,
  ];

  HomeLoaded copyWith({
    List<Map<String, dynamic>>? pokemonList,
    int? currentPokemonId,
    String? searchQuery,
    String? selectedType,
    int? selectedGeneration,
    String? selectedAbility,
    bool? hasReachedMax,
  }) {
    return HomeLoaded(
      pokemonList: pokemonList ?? this.pokemonList,
      currentPokemonId: currentPokemonId ?? this.currentPokemonId,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedType: selectedType ?? this.selectedType,
      selectedGeneration: selectedGeneration ?? this.selectedGeneration,
      selectedAbility: selectedAbility ?? this.selectedAbility,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final dynamic client;
  static const int _pageSize = 50;

  HomeBloc({required this.client}) : super(HomeInitial()) {
    on<LoadPokemonList>(_onLoadPokemonList);
    on<LoadMorePokemon>(_onLoadMorePokemon);
    on<SearchPokemon>(_onSearchPokemon);
    on<UpdateFilters>(_onUpdateFilters);
  }

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
        1, // Start from page 1
      );

      emit(HomeLoaded(
        pokemonList: pokemonList,
        currentPokemonId: event.pokemonId,
        selectedType: event.selectedType,
        selectedGeneration: event.selectedGeneration,
        selectedAbility: event.selectedAbility,
        hasReachedMax: pokemonList.length < _pageSize,
      ));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }


  Future<void> _onLoadMorePokemon(
      LoadMorePokemon event,
      Emitter<HomeState> emit,
      ) async {
    final currentState = state;
    if (currentState is HomeLoaded && !currentState.hasReachedMax) {
      try {
        // Calculate the next starting ID for pagination
        final nextPage = (currentState.pokemonList.length ~/ _pageSize) + 1;

        // Fetch more Pokemon using the GraphQL query with filters
        final morePokemon = await fetchPokemonList(
          client,
          currentState.selectedType,
          currentState.selectedGeneration,
          currentState.selectedAbility,
          nextPage,
        );

        // Append to existing list instead of replacing
        final updatedList = [...currentState.pokemonList, ...morePokemon];

        emit(currentState.copyWith(
          pokemonList: updatedList,
          hasReachedMax: morePokemon.length < _pageSize,
        ));
      } catch (e) {
        emit(HomeError(e.toString()));
      }
    }
  }


  Future<List<Map<String, dynamic>>> _fetchPokemonRange(
      int startId,
      int count,
      String? type,
      int? generation,
      String? ability,
      ) async {
    final List<Map<String, dynamic>> results = [];
    int currentId = startId;
    int attempts = 0;
    final maxAttempts = count * 3; // Allow more attempts when filtering

    while (results.length < count && attempts < maxAttempts) {
      final pokemonData = await fetchPokemon(currentId, client);
      if (pokemonData != null) {
        if (_matchesFilters(pokemonData, type, generation, ability)) {
          results.add(pokemonData);
        }
      }
      currentId++;
      attempts++;
    }

    return results;
  }


  bool _matchesFilters(
      Map<String, dynamic> pokemon,
      String? type,
      int? generation,
      String? ability,
      ) {
    // Implement filter logic here
    if (type != null) {
      final types = (pokemon['pokemontypes'] as List?)
          ?.map((t) => t['type']?['name'])
          .toList();
      if (types?.contains(type) != true) return false;
    }

    if (generation != null) {
      if (pokemon['generation']?['id'] != generation) return false;
    }

    if (ability != null) {
      final abilities = (pokemon['pokemonabilities'] as List?)
          ?.map((a) => a['ability']?['name'])
          .toList();
      if (abilities?.contains(ability) != true) return false;
    }

    return true;
  }

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
        ));
      }
      return;
    }

    emit(HomeLoading());
    try {
      final results = await searchPokemonByName(event.query, client);
      emit(HomeLoaded(
        pokemonList: results,
        currentPokemonId: 1,
        searchQuery: event.query,
        hasReachedMax: true,
      ));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  void _onUpdateFilters(
      UpdateFilters event,
      Emitter<HomeState> emit,
      ) {
    add(LoadPokemonList(
      pokemonId: 1,
      selectedType: event.type,
      selectedGeneration: event.generation,
      selectedAbility: event.ability,
    ));
  }
}