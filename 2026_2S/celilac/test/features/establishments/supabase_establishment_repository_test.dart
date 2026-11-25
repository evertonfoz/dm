import 'dart:async';

import 'package:celilac/features/establishments/data/supabase_establishment_repository.dart';
import 'package:celilac/features/establishments/domain/entities/establishment_category.dart';
import 'package:celilac/features/establishments/domain/repositories/establishment_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../support/supabase_api_json.dart';

const _publishableKey = 'sb_publishable_chave_de_teste';
const _json = {'content-type': 'application/json; charset=utf-8'};

/// O repositório com um SupabaseClient de verdade, mas com o HTTP trocado
/// por [httpClient]: nada sai do computador.
SupabaseEstablishmentRepository _repositoryOn(
  http.Client httpClient, {
  int retryCount = 0, // cada teste vê uma única chamada, salvo se pedir mais
}) {
  final client = SupabaseClient(
    testSupabaseUrl,
    _publishableKey,
    httpClient: httpClient,
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
  addTearDown(client.dispose);
  return SupabaseEstablishmentRepository(
    client,
    requestTimeout: const Duration(milliseconds: 200),
    retryCount: retryCount,
  );
}

/// Um "servidor" que responde [body] e, nos pedidos seguintes, cada item de
/// [thenReplies] (o último se repete). Anota os pedidos recebidos.
({SupabaseEstablishmentRepository repository, List<http.Request> requests})
_serverReplying(
  String body, {
  int status = 200,
  Map<String, String>? headers,
  List<({String body, int status})> thenReplies = const [],
  int retryCount = 0,
}) {
  final replies = [(body: body, status: status), ...thenReplies];
  final requests = <http.Request>[];
  final httpClient = MockClient((request) async {
    requests.add(request);
    final reply = replies[(requests.length - 1).clamp(0, replies.length - 1)];
    // `request:` é preenchido por qualquer client HTTP real; o postgrest o lê.
    return http.Response(
      reply.body,
      reply.status,
      headers: headers ?? _json,
      request: request,
    );
  });
  return (
    repository: _repositoryOn(httpClient, retryCount: retryCount),
    requests: requests,
  );
}

/// Exige uma EstablishmentRepositoryException cuja causa é do tipo [C].
Matcher _failsWithCause<C>() => throwsA(
  isA<EstablishmentRepositoryException>().having(
    (e) => e.cause,
    'cause',
    isA<C>(),
  ),
);

void main() {
  group('fetchNearby', () {
    test('pede as colunas da lista, ordenadas, com a chave pública', () async {
      final server = _serverReplying(nearbyResponseJson);

      final establishments = await server.repository.fetchNearby();

      final request = server.requests.single;
      expect(request.method, 'GET');
      expect(request.url.path, '/rest/v1/establishments');
      expect(
        request.url.queryParameters['select'],
        SupabaseEstablishmentRepository.nearbyColumns,
      );
      expect(
        request.url.queryParameters['order'],
        'distance_in_km.asc.nullslast,name.asc.nullslast',
      );
      expect(request.headers['apikey'], _publishableKey);

      expect(establishments.map((e) => e.name), [
        'Café Aconchego',
        'Empório da Terra',
      ]);
      expect(establishments.first.category, EstablishmentCategory.cafe);
      expect(
        establishments.first.logoSource,
        '$testSupabaseUrl/storage/v1/object/public/establishments/'
        'cafe_aconchego/logo.png',
      );
      expect(establishments.last.logoSource, isNull);
    });

    test('uma falha passageira (503) é repetida uma vez sozinha', () async {
      final server = _serverReplying(
        'Service Unavailable',
        status: 503,
        thenReplies: [(body: nearbyResponseJson, status: 200)],
        retryCount: 1,
      );

      final establishments = await server.repository.fetchNearby();

      expect(server.requests, hasLength(2));
      expect(establishments, hasLength(2));
    });

    test('lista vazia é resultado, não erro (tabela vazia ou RLS)', () async {
      final server = _serverReplying('[]');

      expect(await server.repository.fetchNearby(), isEmpty);
    });
  });

  group('fetchDetails', () {
    test('faz UMA chamada com os dados embutidos e filtra pelo id', () async {
      final server = _serverReplying(cafeAconchegoDetailsResponseJson);

      final details = await server.repository.fetchDetails(cafeAconchegoId);

      final request = server.requests.single;
      expect(request.url.path, '/rest/v1/establishments');
      expect(
        request.url.queryParameters['select'],
        SupabaseEstablishmentRepository.detailsColumns,
      );
      expect(request.url.queryParameters['id'], 'eq.$cafeAconchegoId');

      expect(details, isNotNull);
      expect(details!.establishmentId, cafeAconchegoId);
      expect(details.openingHours, hasLength(7));
      expect(details.photos, hasLength(3));
      expect(details.photos.first.source, startsWith('https://'));
    });

    test('id inexistente devolve null', () async {
      final server = _serverReplying('[]');

      expect(
        await server.repository.fetchDetails(
          'a0000000-0000-4000-8000-000000000099',
        ),
        isNull,
      );
    });

    test('lugar sem linha em establishment_details devolve null', () async {
      final server = _serverReplying(
        '[{"id": "$emporioDaTerraId", "establishment_details": null, '
        '"opening_hours": [], "establishment_photos": []}]',
      );

      expect(await server.repository.fetchDetails(emporioDaTerraId), isNull);
    });

    test(
      'id que não é uuid (favorito antigo, "1") devolve null sem rede',
      () async {
        final server = _serverReplying('[]');

        expect(await server.repository.fetchDetails('1'), isNull);
        expect(server.requests, isEmpty);
      },
    );
  });

  group('falhas viram EstablishmentRepositoryException', () {
    test('chave inválida (401)', () async {
      final server = _serverReplying(
        '{"message": "Invalid API key"}',
        status: 401,
      );

      await expectLater(
        server.repository.fetchNearby(),
        _failsWithCause<PostgrestException>(),
      );
    });

    test(
      'erro do servidor com página HTML (gateway, projeto pausado)',
      () async {
        final server = _serverReplying(
          '<html><body>Service Unavailable</body></html>',
          status: 503,
          headers: {'content-type': 'text/html'},
        );

        await expectLater(
          server.repository.fetchDetails(cafeAconchegoId),
          _failsWithCause<PostgrestException>(),
        );
      },
    );

    test('sem internet', () async {
      final httpClient = MockClient((request) async {
        throw http.ClientException('Failed host lookup', request.url);
      });
      final repository = _repositoryOn(httpClient);

      await expectLater(
        repository.fetchNearby(),
        _failsWithCause<http.ClientException>(),
      );
    });

    test('servidor que não responde (tempo esgotado)', () async {
      // Um servidor mudo: só "termina" quando o client desiste e aborta,
      // como faria uma conexão de verdade.
      final httpClient = MockClient.streaming((request, _) async {
        await (request as http.Abortable).abortTrigger;
        throw http.RequestAbortedException(request.url);
      });
      final repository = _repositoryOn(httpClient);

      await expectLater(
        repository.fetchNearby(),
        _failsWithCause<TimeoutException>(),
      );
    });

    test('JSON fora do contrato (categoria que o app não conhece)', () async {
      final server = _serverReplying(
        nearbyResponseJson.replaceFirst('"cafe"', '"bar"'),
      );

      await expectLater(
        server.repository.fetchNearby(),
        _failsWithCause<ArgumentError>(),
      );
    });
  });
}
