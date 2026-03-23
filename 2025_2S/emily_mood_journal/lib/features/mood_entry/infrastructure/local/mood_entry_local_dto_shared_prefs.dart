import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../data/dtos/mood_entry_dto.dart';
import 'mood_entry_local_dto.dart';

/// Implementação baseada em SharedPreferences para persistir `MoodEntryDto`.
/// Observações:
/// - Usa JSON serializado sob a chave `_cacheKey`.
/// - Assume que `MoodEntryDto` expõe `toJson()` e `fromJson()`.
class MoodEntryLocalDtoSharedPrefs implements MoodEntryLocalDto {
  static const _cacheKey = 'mood_entry_cache_v1';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  @override
  Future<void> upsertAll(List<MoodEntryDto> dtos) async {
    final prefs = await _prefs;
    final raw = prefs.getString(_cacheKey);

    final Map<String, Map<String, dynamic>> current = {};
    if (raw != null && raw.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
        for (final e in list) {
          final m = Map<String, dynamic>.from(e as Map);
          final key = m['id']?.toString();
          if (key != null) current[key] = m;
        }
      } catch (e) {
        // Dados corrompidos: limpar chave e seguir com lista vazia
        await prefs.remove(_cacheKey);
      }
    }

    for (final dto in dtos) {
      current[dto.id] = dto.toJson();
    }

    final merged = current.values.toList();
    await prefs.setString(_cacheKey, jsonEncode(merged));
  }

  @override
  Future<List<MoodEntryDto>> listAll() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list
          .map(
              (e) => MoodEntryDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      // Falha ao decodificar: limpar chave e retornar lista vazia
      await prefs.remove(_cacheKey);
      return [];
    }
  }

  @override
  Future<MoodEntryDto?> getById(String id) async {
    final prefs = await _prefs;
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      for (final e in list) {
        final m = Map<String, dynamic>.from(e as Map);
        if (m['id'] == id) return MoodEntryDto.fromJson(m);
      }
    } catch (_) {
      // se dados corrompidos, limpar e retornar null
      await prefs.remove(_cacheKey);
    }
    return null;
  }

  @override
  Future<void> clear() async {
    final prefs = await _prefs;
    await prefs.remove(_cacheKey);
  }
}
