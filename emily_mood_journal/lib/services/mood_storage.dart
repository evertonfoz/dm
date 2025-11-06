import 'dart:convert';
import '../models/mood_entry.dart';
import 'preferences_service.dart';

class MoodStorage {

  static Future<List<MoodEntry>> getMoodEntries() async {
    final entriesJson = await PreferencesService.getMoodEntries();
    
    return entriesJson
        .map((json) => MoodEntry.fromJson(jsonDecode(json)))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  static Future<void> saveMoodEntry(MoodEntry entry) async {
    final entries = await getMoodEntries();
    
    // Remove existing entry with same ID if it exists
    entries.removeWhere((e) => e.id == entry.id);
    
    // Add new entry
    entries.add(entry);
    
    // Save back to storage
    final entriesJson = entries
        .map((entry) => jsonEncode(entry.toJson()))
        .toList();
    
    await PreferencesService.setMoodEntries(entriesJson);
  }

  static Future<void> deleteMoodEntry(String id) async {
    final entries = await getMoodEntries();
    
    entries.removeWhere((entry) => entry.id == id);
    
    final entriesJson = entries
        .map((entry) => jsonEncode(entry.toJson()))
        .toList();
    
    await PreferencesService.setMoodEntries(entriesJson);
  }

  static Future<bool> getDailyGoal() async {
    return await PreferencesService.getDailyGoal();
  }

  static Future<void> setDailyGoal(bool enabled) async {
    await PreferencesService.setDailyGoal(enabled);
  }

  static Future<bool> isFirstTime() async {
    return await PreferencesService.isFirstTime();
  }

  static Future<void> setFirstTimeCompleted() async {
    await PreferencesService.setFirstTimeCompleted();
  }

  static Future<bool> hasEntryToday() async {
    final entries = await getMoodEntries();
    final today = DateTime.now();
    
    return entries.any((entry) {
      final entryDate = DateTime(
        entry.timestamp.year,
        entry.timestamp.month,
        entry.timestamp.day,
      );
      final todayDate = DateTime(today.year, today.month, today.day);
      return entryDate.isAtSameMomentAs(todayDate);
    });
  }

  static Future<List<MoodEntry>> getEntriesForDate(DateTime date) async {
    final entries = await getMoodEntries();
    
    return entries.where((entry) {
      final entryDate = DateTime(
        entry.timestamp.year,
        entry.timestamp.month,
        entry.timestamp.day,
      );
      final targetDate = DateTime(date.year, date.month, date.day);
      return entryDate.isAtSameMomentAs(targetDate);
    }).toList();
  }
}

