import 'package:flutter/material.dart';
// Import GraphQL Flutter package for GraphQL client and widgets
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// Import the GraphQLService singleton
import '../presentation/app_theme.dart';
import '../data/graphql.dart';
//fonts de google
import '../presentation/theme_provider.dart';
import '../presentation/pages/HomePageState.dart';
import '../domain/state_management/bloc_state_home.dart';



class PokeHomePage extends StatefulWidget {
  // Constructor for MyHomePage, requires a title
  const PokeHomePage({super.key, required this.title, this.initialPokemonId});

  // Title field for the home page
  final String title;
  final int? initialPokemonId;

  // Create the state for this widget
  @override
  State<PokeHomePage> createState() => HomePageState();
}
// Main entry point for the app
void main() async {
  // Ensure Flutter widget binding is initialized before running async code
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize the GraphQLService singleton
  await GraphQLService().init();
  // Run the Flutter app, providing the GraphQL client to the widget tree
  runApp(
    ChangeNotifierProvider<AppThemeState>(
      create: (_) => AppThemeState(),
      child: GraphQLProvider(
        client: ValueNotifier(GraphQLService().client),
        child: const MyApp(),
      ),
    ),
  );
}

// Main application widget
class MyApp extends StatelessWidget {
  // Constructor for MyApp
  const MyApp({super.key});

  // Build method returns the widget tree for the app
  @override
  Widget build(BuildContext context) {
    final appThemeState = Provider.of<AppThemeState>(context);
    // Return a MaterialApp widget
    return MaterialApp(

      title: 'Pokedex', // Set the app title
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: appThemeState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: BlocProvider(
        create: (context) => HomeBloc(
          client: GraphQLService().client,
        )..add(const LoadPokemonList(pokemonId: 1)),
        child: const PokeHomePage(title: 'Pokedex'),
      ), // Set the home page
    );
  }
}
