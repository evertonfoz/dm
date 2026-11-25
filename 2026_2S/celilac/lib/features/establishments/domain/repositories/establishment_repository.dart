import '../entities/establishment.dart';
import '../entities/establishment_details.dart';

/// O contrato do catálogo, igual para o fake e para o Supabase:
///
/// - um lugar que não existe devolve `null` em [fetchDetails];
/// - uma falha (sem rede, tempo esgotado, servidor fora, dado inesperado)
///   lança uma exceção, que as telas mostram com "Tentar novamente".
abstract interface class EstablishmentRepository {
  Future<List<Establishment>> fetchNearby();

  Future<EstablishmentDetails?> fetchDetails(String establishmentId);
}

/// Falha ao buscar o catálogo. Esconde das telas o tipo de erro de cada
/// tecnologia (Supabase, HTTP, JSON), mas guarda o original em [cause].
class EstablishmentRepositoryException implements Exception {
  const EstablishmentRepositoryException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'EstablishmentRepositoryException: $message ($cause)';
}
