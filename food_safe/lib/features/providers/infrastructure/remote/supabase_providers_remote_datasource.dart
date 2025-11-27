import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../dtos/provider_dto.dart';
import 'providers_remote_api.dart';
import '../../../../services/supabase_service.dart';

/// Implementação Supabase de [ProvidersRemoteApi].
///
/// Esta classe atua como um datasource remoto e segue a convenção de nomes do
/// projeto/documentação: sufixo `Datasource` para implementações concretas de
/// fontes remotas.
class SupabaseProvidersRemoteDatasource implements ProvidersRemoteApi {
  final SupabaseClient _client;

  SupabaseProvidersRemoteDatasource({SupabaseClient? client})
    : _client = client ?? SupabaseService().client;

  @override
  Future<RemotePage<ProviderDto>> fetchProviders({
    DateTime? since,
    int limit = 200,
    PageCursor? cursor,
  }) async {
    final int offset = _parseOffset(cursor?.value);
    if (kDebugMode) {
      print(
        'SupabaseProvidersRemoteDatasource.fetchProviders: since=$since limit=$limit offset=$offset',
      );
    }
    PostgrestFilterBuilder query = _client.from('providers').select();
    if (since != null) {
      // Use > (gt) instead of >= (gte) to avoid re-fetching the last synced item
      query = query.gt('updated_at', since.toIso8601String());
    }

    try {
      final dynamic response = await _executeQuery(
        query
                .order('updated_at', ascending: false)
                .range(offset, offset + limit - 1)
            as dynamic,
      );

      // Tolerant extraction of `error` and `data` similar to upsert
      dynamic error;
      List<dynamic>? data;

      if (response == null) {
        error = null;
        data = null;
      } else if (response is List) {
        data = response;
      } else if (response is Map) {
        if (response.containsKey('error')) error = response['error'];
        if (response.containsKey('data'))
          data = response['data'] as List<dynamic>?;
      } else {
        try {
          error = response.error;
        } catch (_) {
          try {
            error = response['error'];
          } catch (_) {
            error = null;
          }
        }
        try {
          data = response.data as List<dynamic>?;
        } catch (_) {
          try {
            data = response['data'] as List<dynamic>?;
          } catch (_) {
            if (response is List) data = response;
          }
        }
      }

      if (error != null) {
        return const RemotePage(items: []);
      }
      if (data == null || data.isEmpty) return const RemotePage(items: []);

      final items = data
          .map((e) => ProviderDto.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();

      final nextCursor = items.length == limit
          ? PageCursor((offset + limit).toString())
          : null;

      return RemotePage(items: items, next: nextCursor);
    } catch (_) {
      return const RemotePage(items: []);
    }
  }

  @override
  Future<int> upsertProviders(List<ProviderDto> dtos) async {
    if (dtos.isEmpty) return 0;
    try {
      final List<Map<String, dynamic>> payload = dtos
          .map((d) => d.toMap())
          .toList();
      print(
        'SupabaseProvidersRemoteDatasource.upsertProviders: sending ${payload.length} items',
      );
      final dynamic response = await _executeQuery(
        (_client.from('providers').upsert(payload) as dynamic),
      );
      // Extract `error` and `data` from response in a tolerant way. Different
      // client/runtime shapes may return a List (data), a Map, or an object
      // with `.data` and `.error` properties. Handle common cases safely.
      dynamic error;
      List<dynamic>? data;

      if (response == null) {
        error = null;
        data = null;
      } else if (response is List) {
        data = response;
      } else if (response is Map) {
        if (response.containsKey('error')) error = response['error'];
        if (response.containsKey('data')) {
          data = response['data'] as List<dynamic>?;
        }
      } else {
        // Generic object: try property accessors with safe fallbacks
        try {
          error = response.error;
        } catch (_) {
          try {
            error = response['error'];
          } catch (_) {
            error = null;
          }
        }
        try {
          data = response.data as List<dynamic>?;
        } catch (_) {
          try {
            data = response['data'] as List<dynamic>?;
          } catch (_) {
            if (response is List) data = response;
          }
        }
      }

      if (error != null) {
        final eStr = error.toString();
        print('Supabase upsert response error: $eStr');
        if (eStr.contains('row-level security') ||
            eStr.contains('violates row-level security') ||
            eStr.toLowerCase().contains('permission denied') ||
            eStr.contains('42501')) {
          print(
            'Supabase upsert diagnostic: the request was denied by Row-Level Security (RLS).',
          );
          print(
            '  - Fix options: grant anonymous INSERT/UPDATE policies for table `providers` (for testing),',
          );
          print('    or authenticate users and use per-user RLS policies.');
        }
      } else {
        if (kDebugMode) print('Supabase upsert response error: <none>');
      }

      if (kDebugMode)
        print('Supabase upsert response data length: ${data?.length}');
      if (error != null) return 0;
      if (data == null) return 0;
      return data.length;
    } catch (_) {
      return 0;
    }
  }

  // Helper to execute a dynamic Postgrest builder in a way that is tolerant
  // to different versions of the supabase/postgrest client. Older/newer
  // versions expose different chaining methods (`execute`, `select`, or are
  // awaitable). Try common variants and fallback gracefully.
  Future<dynamic> _executeQuery(dynamic builder) async {
    // Try the most common variants in a safe order so we avoid calling
    // non-existent methods that trigger NoSuchMethodError in some runtime
    // implementations. Prefer `.select()` (common) -> `.execute()` -> await.
    try {
      return await builder.select();
    } on NoSuchMethodError catch (_) {
      // fall through
    } catch (e) {
      // If it's a PostgrestException it likely contains details about RLS
      // / permission issues. Convert to a safe response so callers can
      // inspect `response.error` instead of letting the exception bubble.
      return {'error': e.toString()};
    }

    try {
      return await builder.execute();
    } on NoSuchMethodError catch (_) {
      // fall through
    } catch (e) {
      return {'error': e.toString()};
    }

    try {
      return await builder;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  @override
  Future<int> deleteProviders(List<int> ids) async {
    if (ids.isEmpty) return 0;
    try {
      if (kDebugMode) {
        print(
          'SupabaseProvidersRemoteDatasource.deleteProviders: deleting ${ids.length} items',
        );
      }
      final dynamic response = await _executeQuery(
        (_client.from('providers').delete().inFilter('id', ids) as dynamic),
      );

      // Extract error/data from response
      dynamic error;
      List<dynamic>? data;

      if (response == null) {
        error = null;
        data = null;
      } else if (response is List) {
        data = response;
      } else if (response is Map) {
        if (response.containsKey('error')) error = response['error'];
        if (response.containsKey('data')) {
          data = response['data'] as List<dynamic>?;
        }
      } else {
        try {
          error = response.error;
        } catch (_) {
          try {
            error = response['error'];
          } catch (_) {
            error = null;
          }
        }
        try {
          data = response.data as List<dynamic>?;
        } catch (_) {
          try {
            data = response['data'] as List<dynamic>?;
          } catch (_) {
            if (response is List) data = response;
          }
        }
      }

      if (error != null) {
        final eStr = error.toString();
        print('Supabase delete response error: $eStr');
        if (eStr.contains('row-level security') ||
            eStr.contains('violates row-level security') ||
            eStr.toLowerCase().contains('permission denied') ||
            eStr.contains('42501')) {
          print(
            'Supabase delete diagnostic: the request was denied by Row-Level Security (RLS).',
          );
          print(
            '  - Fix options: grant anonymous DELETE policies for table `providers` (for testing),',
          );
          print('    or authenticate users and use per-user RLS policies.');
        }
        return 0;
      }

      if (kDebugMode) {
        print('Supabase delete response data length: ${data?.length}');
      }
      // Return count of deleted items
      return ids.length;
    } catch (e) {
      if (kDebugMode) {
        print('SupabaseProvidersRemoteDatasource.deleteProviders error: $e');
      }
      return 0;
    }
  }

  int _parseOffset(String? raw) {
    if (raw == null) return 0;
    final v = int.tryParse(raw);
    return v == null || v < 0 ? 0 : v;
  }
}
