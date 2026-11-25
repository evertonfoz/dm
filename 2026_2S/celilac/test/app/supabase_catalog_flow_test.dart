import 'package:celilac/features/establishments/data/supabase_establishment_repository.dart';
import 'package:celilac/features/home/presentation/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../support/pump_app.dart';
import '../support/supabase_api_json.dart';

void main() {
  testWidgets('sem internet, a Home mostra o erro; com a rede de volta, '
      '"Tentar novamente" carrega o catálogo do Supabase', (tester) async {
    var online = false;
    final httpClient = MockClient((request) async {
      if (!online) {
        throw http.ClientException('Failed host lookup', request.url);
      }
      return http.Response(
        nearbyResponseJson,
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
        request: request,
      );
    });
    // O SupabaseClient abre um isolate para JSON: criar e descartar fora
    // do relógio falso do testWidgets (runAsync), senão o teste trava.
    final client = (await tester.runAsync(
      () async => SupabaseClient(
        testSupabaseUrl,
        'sb_publishable_chave_de_teste',
        httpClient: httpClient,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      ),
    ))!;
    final repository = SupabaseEstablishmentRepository(client, retryCount: 0);

    await pumpWithProfile(
      tester,
      Scaffold(body: HomePage(repository: repository)),
      exploreRepository: repository,
      size: const Size(360, 2400),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível carregar os estabelecimentos.'),
      findsOne,
    );

    online = true;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(find.text('Café Aconchego'), findsOne);
    expect(find.text('Empório da Terra'), findsOne);
    expect(find.text('Tentar novamente'), findsNothing);

    await tester.runAsync(client.dispose);
  });
}
