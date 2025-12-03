import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/provider.dart';
import '../../domain/repositories/providers_repository.dart';
import '../dtos/provider_dto.dart';
import '../local/providers_local_dao.dart';
import '../mappers/provider_mapper.dart';
import '../remote/providers_remote_api.dart';

/// Implementação concreta de [ProvidersRepository] usando:
/// - Fonte remota (Supabase) via [ProvidersRemoteApi]
/// - Cache local via [ProvidersLocalDao]
///
/// Mantém um marcador incremental em SharedPreferences (`_lastSyncKey`) para
/// permitir sync delta usando o campo `updated_at`.
/// Também rastreia IDs deletados localmente (`_deletedIdsKey`) para sincronizar
/// deleções com o servidor.
class ProvidersRepositoryImpl implements ProvidersRepository {
  static const _lastSyncKey = 'providers_last_sync_v2';
  static const _deletedIdsKey = 'providers_deleted_ids_v2';

  final ProvidersRemoteApi remoteApi;
  final ProvidersLocalDao localDao;

  ProvidersRepositoryImpl({required this.remoteApi, required this.localDao});

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  /// Adiciona um ID à lista de deletados pendentes
  Future<void> _markAsDeleted(int id) async {
    final prefs = await _prefs;
    final List<String> deleted = prefs.getStringList(_deletedIdsKey) ?? [];
    if (!deleted.contains(id.toString())) {
      deleted.add(id.toString());
      await prefs.setStringList(_deletedIdsKey, deleted);
      if (kDebugMode) {
        debugPrint('Marked provider $id as deleted (pending sync)');
      }
    }
  }

  /// Retorna a lista de IDs deletados pendentes
  Future<List<int>> _getDeletedIds() async {
    final prefs = await _prefs;
    final List<String> deleted = prefs.getStringList(_deletedIdsKey) ?? [];
    return deleted.map((s) => int.tryParse(s)).whereType<int>().toList();
  }

  /// Limpa a lista de IDs deletados após sync bem-sucedido
  Future<void> _clearDeletedIds() async {
    final prefs = await _prefs;
    await prefs.remove(_deletedIdsKey);
    if (kDebugMode) {
      debugPrint('Cleared deleted IDs list after successful sync');
    }
  }

  @override
  Future<List<Provider>> loadFromCache() async {
    final dtos = await localDao.listAll();
    return dtos.map(ProviderMapper.toEntity).toList();
  }

  @override
  Future<int> syncFromServer() async {
    if (kDebugMode) {
      debugPrint('ProvidersRepositoryImpl.syncFromServer: starting');
    }
    final prefs = await _prefs;
    final lastSyncIso = prefs.getString(_lastSyncKey);
    DateTime? since;
    if (lastSyncIso != null && lastSyncIso.isNotEmpty) {
      try {
        since = DateTime.parse(lastSyncIso);
      } catch (_) {}
    }

    // Strategy: If we have a lastSync marker, PULL first (server wins conflicts).
    // If no lastSync (first sync), PUSH first to send initial local data.
    int pushedCount = 0;
    final items = <ProviderDto>[];

    if (since != null) {
      // PULL-first strategy: server data is newer, apply it first
      if (kDebugMode) {
        debugPrint('  [1/3] About to fetch remote deltas (pull-first)...');
      }
      final page = await remoteApi.fetchProviders(since: since, limit: 500);
      if (kDebugMode) {
        debugPrint('  [1/3] Remote fetch complete: ${page.items.length} items');
      }
      items.addAll(page.items);

      // Apply remote items to local cache (remote wins)
      if (items.isNotEmpty) {
        await localDao.upsertAll(items);
        if (kDebugMode) {
          debugPrint('  [1/3] Remote data applied to local cache');
        }
      }

      // Push deletions first (but keep the list for filtering upserts)
      final deletedIds = await _getDeletedIds();
      if (deletedIds.isNotEmpty) {
        if (kDebugMode) {
          debugPrint(
            '  [2a/4] About to delete ${deletedIds.length} items from remote...',
          );
        }
        try {
          await remoteApi.deleteProviders(deletedIds);
          // Also remove from local cache to prevent them from coming back
          final local = await localDao.listAll();
          final filteredLocal = local
              .where((dto) => !deletedIds.contains(dto.id))
              .toList();
          if (filteredLocal.length < local.length) {
            await localDao.clear();
            await localDao.upsertAll(filteredLocal);
            if (kDebugMode) {
              debugPrint(
                '  [2a/4] Removed ${local.length - filteredLocal.length} items from local cache',
              );
            }
          }
          if (kDebugMode) {
            debugPrint('  [2a/4] Delete complete');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('  [2a/4] Delete failed (will retry next sync): $e');
          }
        }
      }

      // Now push local modifications (they may overwrite remote if truly newer)
      // BUT exclude any IDs that are in the deleted list
      if (kDebugMode) {
        debugPrint('  [2b/4] About to push local modifications...');
      }
      try {
        final local = await localDao.listAll();
        // Filter out deleted items before upserting (use the saved deletedIds)
        final localToSync = deletedIds.isEmpty
            ? local
            : local.where((dto) => !deletedIds.contains(dto.id)).toList();

        if (kDebugMode) {
          debugPrint(
            '  [2b/4] Local cache has: ${local.length} items (${localToSync.length} to sync after filtering deletions)',
          );
        }
        if (localToSync.isNotEmpty) {
          pushedCount = await remoteApi.upsertProviders(localToSync);
          if (kDebugMode) {
            debugPrint(
              '  [2b/4] Push complete: pushed $pushedCount items to remote',
            );
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('  [2b/4] Push failed (will retry next sync): $e');
        }
      }

      // Clear deleted IDs list after successful sync
      if (deletedIds.isNotEmpty) {
        await _clearDeletedIds();
      }

      // Update lastSync marker
      if (items.isNotEmpty) {
        final newest = _computeNewest(items);
        await prefs.setString(_lastSyncKey, newest.toIso8601String());
        if (kDebugMode) {
          debugPrint('  [3/3] LastSync marker updated');
        }
      }
    } else {
      // PUSH-first strategy: initial sync, send local data first
      // Push deletions first (but keep the list for filtering upserts)
      final deletedIds = await _getDeletedIds();
      if (deletedIds.isNotEmpty) {
        if (kDebugMode) {
          debugPrint(
            '  [1a/4] About to delete ${deletedIds.length} items from remote (initial sync)...',
          );
        }
        try {
          await remoteApi.deleteProviders(deletedIds);
          // Also remove from local cache to prevent them from coming back
          final local = await localDao.listAll();
          final filteredLocal = local
              .where((dto) => !deletedIds.contains(dto.id))
              .toList();
          if (filteredLocal.length < local.length) {
            await localDao.clear();
            await localDao.upsertAll(filteredLocal);
            if (kDebugMode) {
              debugPrint(
                '  [1a/4] Removed ${local.length - filteredLocal.length} items from local cache',
              );
            }
          }
          if (kDebugMode) {
            debugPrint('  [1a/4] Delete complete');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('  [1a/4] Delete failed (will retry next sync): $e');
          }
        }
      }

      if (kDebugMode) {
        debugPrint(
          '  [1b/4] About to push local modifications (initial sync)...',
        );
      }
      try {
        final local = await localDao.listAll();
        // Filter out deleted items before upserting (use the saved deletedIds)
        final localToSync = deletedIds.isEmpty
            ? local
            : local.where((dto) => !deletedIds.contains(dto.id)).toList();

        if (kDebugMode) {
          debugPrint(
            '  [1b/4] Local cache has: ${local.length} items (${localToSync.length} to sync after filtering deletions)',
          );
        }
        if (localToSync.isNotEmpty) {
          pushedCount = await remoteApi.upsertProviders(localToSync);
          if (kDebugMode) {
            debugPrint(
              '  [1b/4] Push complete: pushed $pushedCount items to remote',
            );
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('  [1b/4] Push failed (will retry next sync): $e');
        }
      }

      // Clear deleted IDs list after successful sync
      if (deletedIds.isNotEmpty) {
        await _clearDeletedIds();
      }

      // Then pull all from server
      if (kDebugMode) {
        debugPrint('  [2/3] About to fetch all from remote...');
      }
      final page = await remoteApi.fetchProviders(limit: 500);
      if (kDebugMode) {
        debugPrint('  [2/3] Remote fetch complete: ${page.items.length} items');
      }
      items.addAll(page.items);

      // Apply to local cache
      if (items.isNotEmpty) {
        await localDao.upsertAll(items);
        if (kDebugMode) {
          debugPrint('  [2/3] Remote data applied to local cache');
        }

        final newest = _computeNewest(items);
        await prefs.setString(_lastSyncKey, newest.toIso8601String());
        if (kDebugMode) {
          debugPrint('  [3/3] LastSync marker updated');
        }
      }
    }

    if (kDebugMode) {
      debugPrint(
        'ProvidersRepositoryImpl.syncFromServer: complete (pushed: $pushedCount, pulled: ${items.length})',
      );
    }
    return items.length;
  }

  DateTime _computeNewest(List<ProviderDto> dtos) {
    DateTime newest = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    for (final d in dtos) {
      try {
        final t = DateTime.parse(d.updated_at);
        if (t.isAfter(newest)) {
          newest = t;
        }
      } catch (_) {}
    }
    return newest == DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)
        ? DateTime.now().toUtc()
        : newest;
  }

  @override
  Future<List<Provider>> listAll() async => loadFromCache();

  @override
  Future<List<Provider>> listFeatured() async {
    final all = await loadFromCache();
    return all.where((p) => p.featured).toList();
  }

  @override
  Future<Provider?> getById(int id) async {
    final dto = await localDao.getById(id);
    return dto == null ? null : ProviderMapper.toEntity(dto);
  }

  /// Marca um provider como deletado para sincronização futura com o servidor.
  /// Deve ser chamado antes de remover do cache local.
  Future<void> markProviderAsDeleted(int id) async {
    await _markAsDeleted(id);
  }
}
