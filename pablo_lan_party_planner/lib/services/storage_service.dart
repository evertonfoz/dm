import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/event.dart';

class StorageService {
  Future<List<Event>> loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('events') ?? [];
    return list.map((e) => Event.fromJson(jsonDecode(e))).toList();
  }

  Future<void> saveEvents(List<Event> events) async {
    final prefs = await SharedPreferences.getInstance();
    final list = events.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('events', list);
  }

  Future<bool> getConsentAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('consent_accepted') ?? false;
  }

  Future<void> setConsentAccepted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('consent_accepted', value);
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name');
  }

  Future<void> setUserName(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', value);
  }

  Future<void> removeUserName() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
  }

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email');
  }

  Future<void> setUserEmail(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', value);
  }

  Future<void> removeUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');
  }

  Future<bool> getConsentMarketing() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('consent_marketing') ?? true; // assume true por padrão
  }

  Future<void> setConsentMarketing(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('consent_marketing', value);
  }
}
