import 'package:graphql_flutter/graphql_flutter.dart';

    class GraphQLService {
      GraphQLClient? _client;
      static final GraphQLService _instance = GraphQLService._internal();

      factory GraphQLService() => _instance;

      GraphQLService._internal();

      /*inicializacion hive y cliente, se hace una llamada
  al cliente para inicializarlo y se manda error si no inicializa*/
      Future<void> init(
          {String uri = 'https://beta.pokeapi.co/graphql/v1beta'}) async {
        await initHiveForFlutter();
        final httpLink = HttpLink(uri);
        _client = GraphQLClient(
          link: httpLink,
          cache: GraphQLCache(store: HiveStore()),
        );
      }

      //retorna el cliente si este no ha sido inicializado manda error
      GraphQLClient get client {
        if (_client == null) {
          throw Exception('GraphQL no se ha inicializado.');
        }
        return _client!;
      }

      //metodo para ejecutar consultas
      Future<QueryResult> query(String document,
          {Map<String, dynamic>? variables}) {
        final options = QueryOptions(
            document: gql(document), variables: variables ?? {});
        return client.query(options);
      }

      //para realizar mutaciones
      Future<QueryResult> mutate(String document,
          {Map<String, dynamic>? variables}) {
        final options = MutationOptions(
            document: gql(document), variables: variables ?? {});
        return client.mutate(options);
      }
    }