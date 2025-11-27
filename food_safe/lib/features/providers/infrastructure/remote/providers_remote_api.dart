import '../dtos/provider_dto.dart';

class PageCursor {
  final String? value; // p.ex., next offset/last id token
  const PageCursor(this.value);
}

class RemotePage<T> {
  final List<T> items;
  final PageCursor? next;
  const RemotePage({required this.items, this.next});
}

abstract class ProvidersRemoteApi {
  /// Busca página de providers ordenada por updated_at DESC.
  /// since => filtro inclusivo (>= since).
  Future<RemotePage<ProviderDto>> fetchProviders({
    DateTime? since,
    int limit = 200,
    PageCursor? cursor,
  });

  /// Upsert (create or update) providers on the remote side.
  /// Returns the number of items acknowledged by the remote (best-effort).
  Future<int> upsertProviders(List<ProviderDto> dtos);

  /// Delete providers from remote by their IDs.
  /// Returns the number of items deleted.
  Future<int> deleteProviders(List<int> ids);
}
