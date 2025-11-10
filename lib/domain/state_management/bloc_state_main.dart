import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '/domain/models/Pokemon.dart';
import '/data/queries.dart';

// Events
abstract class DetailEvent extends Equatable {
  const DetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadPokemonDetail extends DetailEvent {
  final int pokemonId;

  const LoadPokemonDetail(this.pokemonId);

  @override
  List<Object?> get props => [pokemonId];
}

class SearchPokemonDetail extends DetailEvent {
  final String query;

  const SearchPokemonDetail(this.query);

  @override
  List<Object?> get props => [query];
}

class IncrementDetailPokemonId extends DetailEvent {}

// States
abstract class DetailState extends Equatable {
  const DetailState();

  @override
  List<Object?> get props => [];
}

class DetailInitial extends DetailState {}

class DetailLoading extends DetailState {}

class DetailLoaded extends DetailState {
  final Pokemon pokemon;
  final int currentPokemonId;
  final String searchQuery;

  const DetailLoaded({
    required this.pokemon,
    required this.currentPokemonId,
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [pokemon, currentPokemonId, searchQuery];
}

class DetailError extends DetailState {
  final String message;

  const DetailError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class DetailBloc extends Bloc<DetailEvent, DetailState> {
  final dynamic client; // GraphQL client

  DetailBloc({required this.client}) : super(DetailInitial()) {
    on<LoadPokemonDetail>(_onLoadPokemonDetail);
    on<SearchPokemonDetail>(_onSearchPokemonDetail);
    on<IncrementDetailPokemonId>(_onIncrementPokemonId);
  }

  Future<void> _onLoadPokemonDetail(
      LoadPokemonDetail event,
      Emitter<DetailState> emit,
      ) async {
    emit(DetailLoading());
    try {
      final pokemonData = await fetchPokemon(event.pokemonId, client);
      if (pokemonData != null) {
        final pokemon = Pokemon.fromGraphQL(pokemonData);
        emit(DetailLoaded(
          pokemon: pokemon,
          currentPokemonId: event.pokemonId,
        ));
      } else {
        emit(const DetailError('Pokemon not found'));
      }
    } catch (e) {
      emit(DetailError(e.toString()));
    }
  }

  Future<void> _onSearchPokemonDetail(
      SearchPokemonDetail event,
      Emitter<DetailState> emit,
      ) async {
    if (event.query.isEmpty) {
      final currentState = state;
      if (currentState is DetailLoaded) {
        add(LoadPokemonDetail(currentState.currentPokemonId));
      }
      return;
    }

    emit(DetailLoading());
    try {
      final pokemonData = await searchSinglePokemonByName(event.query, client);
      if (pokemonData != null) {
        final pokemon = Pokemon.fromGraphQL(pokemonData);
        emit(DetailLoaded(
          pokemon: pokemon,
          currentPokemonId: pokemon.id,
          searchQuery: event.query,
        ));
      } else {
        emit(const DetailError('Pokemon not found'));
      }
    } catch (e) {
      emit(DetailError(e.toString()));
    }
  }

  void _onIncrementPokemonId(
      IncrementDetailPokemonId event,
      Emitter<DetailState> emit,
      ) {
    final currentState = state;
    if (currentState is DetailLoaded) {
      add(LoadPokemonDetail(currentState.currentPokemonId + 1));
    }
  }
}
