import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/establishment.dart';
import '../domain/entities/establishment_details.dart';
import '../domain/repositories/establishment_repository.dart';
import 'establishment_json.dart';

/// Lê o catálogo do Supabase, pela API REST, com a chave pública.
///
/// Só leitura: o RLS do banco libera `select` e nada mais.
class SupabaseEstablishmentRepository implements EstablishmentRepository {
  SupabaseEstablishmentRepository(
    this._client, {
    this.requestTimeout = const Duration(seconds: 8),
    this.retryCount = 1,
  });

  final SupabaseClient _client;

  /// Quanto cada tentativa pode esperar. Sem limite, uma conexão travada
  /// deixaria a tela carregando para sempre.
  final Duration requestTimeout;

  /// Novas tentativas automáticas (sem internet, tempo esgotado, 503).
  /// Depois delas, a tela mostra o "Tentar novamente".
  final int retryCount;

  static const String imagesBucket = 'establishments';

  /// Colunas da lista: exatamente os campos de `Establishment`.
  static const String nearbyColumns =
      'id,name,category,neighborhood,distance_in_km,rating,'
      'dietary_options,logo_path';

  /// Detalhe em UMA chamada: a API embute as tabelas filhas pela chave
  /// estrangeira, sem escrevermos `join`.
  static const String detailsColumns =
      'id,'
      'establishment_details(description,address,phone,safety_practices),'
      'opening_hours(weekday,opens_at,closes_at),'
      'establishment_photos(position,path,description)';

  @override
  Future<List<Establishment>> fetchNearby() {
    return _guard('carregar os estabelecimentos', () async {
      final rows = await _client
          .from('establishments')
          .select(nearbyColumns)
          // Atenção: no Dart, order() é DECRESCENTE se nada for dito.
          .order('distance_in_km', ascending: true)
          .order('name', ascending: true)
          .retry(count: retryCount, requestTimeout: requestTimeout);
      return [
        for (final row in rows)
          establishmentFromJson(row, publicUrl: _publicUrl),
      ];
    });
  }

  @override
  Future<EstablishmentDetails?> fetchDetails(String establishmentId) async {
    // Um id que nem é uuid (como os '1'..'12' do fake) não pode existir no
    // banco. Sem este teste, o Postgres recusaria o filtro com erro 400, e a
    // tela mostraria "Tentar novamente" para algo que nunca vai funcionar.
    if (!_uuidPattern.hasMatch(establishmentId)) {
      return null;
    }

    return _guard('carregar o detalhe do estabelecimento', () async {
      final row = await _client
          .from('establishments')
          .select(detailsColumns)
          .eq('id', establishmentId)
          .maybeSingle() // zero linhas viram null, não erro
          .retry(count: retryCount, requestTimeout: requestTimeout);
      if (row == null) {
        return null;
      }
      return establishmentDetailsFromJson(row, publicUrl: _publicUrl);
    });
  }

  /// Monta a URL pública sem ir à rede: é só texto.
  String _publicUrl(String path) =>
      _client.storage.from(imagesBucket).getPublicUrl(path);

  /// Toda falha vira [EstablishmentRepositoryException]: rede, tempo
  /// esgotado, erro do servidor ou JSON diferente do esperado.
  Future<T> _guard<T>(String action, Future<T> Function() run) async {
    try {
      return await run();
    } catch (error, stackTrace) {
      debugPrint('Não foi possível $action: $error');
      Error.throwWithStackTrace(
        EstablishmentRepositoryException(
          'Não foi possível $action.',
          cause: error,
        ),
        stackTrace,
      );
    }
  }

  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
}
