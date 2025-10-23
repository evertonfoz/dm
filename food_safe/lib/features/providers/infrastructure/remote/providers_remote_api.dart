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

  // Futuro: escrita/edição no remoto, se o app vier a suportar:
  // Future<void> upsertProviders(List<ProviderDto> dtos);
}
