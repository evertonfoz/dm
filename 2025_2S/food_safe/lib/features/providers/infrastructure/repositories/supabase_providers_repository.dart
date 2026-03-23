import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/provider.dart';
import '../../domain/repositories/providers_repository.dart';
import '../dtos/provider_dto.dart';
import '../mappers/provider_mapper.dart';
import '../../../../services/supabase_service.dart';

/// Supabase-backed implementation of ProvidersRepository.
///
/// Responsibilities:
/// - Sync incremental changes from Supabase (using `updated_at`)
/// - Persist a local cache in SharedPreferences for fast startup
/// - Provide read APIs over the local cache
class SupabaseProvidersRepository implements ProvidersRepository {
  static const _cacheKey = 'providers_cache_v1';
  static const _lastSyncKey = 'providers_last_sync_v1';

  final _client = SupabaseService().client;

  /// Load providers from local cache (fast path)
  @override
  Future<List<Provider>> loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list
          .map(
            (m) => ProviderMapper.toEntity(
              ProviderDto.fromMap(Map<String, dynamic>.from(m as Map)),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Synchronize incremental changes from Supabase.
  /// Returns the number of changed records applied to cache.
  @override
  Future<int> syncFromServer() async {
    if (kDebugMode) {
      debugPrint('SupabaseProvidersRepository.syncFromServer: starting');
    }
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getString(_lastSyncKey);

    try {
      PostgrestFilterBuilder query = _client.from('providers').select();
      if (lastSync != null && lastSync.isNotEmpty) {
        query = query.gte('updated_at', lastSync);
      }

      // execute() is provided by the supabase client but analyzer typings
      // may not always expose it depending on package versions. Use a
      // compatibility helper to attempt common execution variants.
      final dynamic response = await _executeQuery(query as dynamic);
      if (response == null) return 0;

      // response may have .error and .data depending on runtime; guard access
      final dynamic error = response.error ?? response['error'];
      if (error != null) {
        return 0;
      }

      final List<dynamic>? data =
          response.data ?? response['data'] as List<dynamic>?;
      if (data == null || data.isEmpty) {
        // No changes
        return 0;
      }

      // Load existing cache and merge
      final raw = prefs.getString(_cacheKey);
      final Map<int, Map<String, dynamic>> current = {};
      if (raw != null && raw.isNotEmpty) {
        try {
          final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
          for (final e in list) {
            final m = Map<String, dynamic>.from(e as Map);
            current[m['id'] as int] = m;
          }
        } catch (_) {}
      }

      // Apply changes
      int applied = 0;
      String? newest;
      for (final row in data) {
        final Map<String, dynamic> m = Map<String, dynamic>.from(row as Map);
        final id = m['id'] as int;
        current[id] = m;
        applied += 1;
        final updatedAt = m['updated_at'] as String?;
        if (updatedAt != null) {
          if (newest == null ||
              DateTime.parse(updatedAt).isAfter(DateTime.parse(newest))) {
            newest = updatedAt;
          }
        }
      }

      // Persist merged cache
      final merged = current.values.toList();
      await prefs.setString(_cacheKey, jsonEncode(merged));

      // Update last sync marker
      final nowIso = newest ?? DateTime.now().toIso8601String();
      await prefs.setString(_lastSyncKey, nowIso);

      return applied;
    } catch (_) {
      return 0;
    }
  }

  // Compatibility helper similar to the one used in the remote datasource:
  // attempt `.execute()`, then `.select()`, then await the builder itself.
  Future<dynamic> _executeQuery(dynamic builder) async {
    // Try the most common variants in a safe order — prefer `.select()` -> `.execute()` -> await.
    try {
      return await builder.select();
    } on NoSuchMethodError catch (_) {
      // fall through
    } catch (e) {
      return {'error': e.toString()};
    }

    try {
      return await builder.execute();
    } on NoSuchMethodError catch (_) {
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
  Future<List<Provider>> listAll() async => await loadFromCache();

  @override
  Future<List<Provider>> listFeatured() async {
    final all = await loadFromCache();
    return all.where((p) => p.featured).toList();
  }

  @override
  Future<Provider?> getById(int id) async {
    final all = await loadFromCache();
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
