import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskflow_app/services/photo_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PhotoService', () {
    late PhotoService photoService;

    setUp(() {
      photoService = PhotoService();
      SharedPreferences.setMockInitialValues({});
    });

    test('getPhotoPath retorna null quando não há foto salva', () async {
      final photoPath = await photoService.getPhotoPath();
      expect(photoPath, isNull);
    });

    test('getPhotoPath retorna null quando arquivo não existe', () async {
      // Simula um path salvo mas arquivo inexistente
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userPhotoPath', '/path/inexistente/foto.jpg');

      final photoPath = await photoService.getPhotoPath();
      expect(photoPath, isNull);
      
      // Verifica se a referência foi removida
      expect(prefs.getString('userPhotoPath'), isNull);
    });

    test('deletePhoto remove o path do SharedPreferences', () async {
      // Simula um path salvo
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userPhotoPath', '/path/inexistente/foto.jpg');

      final result = await photoService.deletePhoto();
      expect(result, isTrue);
      expect(prefs.getString('userPhotoPath'), isNull);
    });

    test('deletePhoto retorna true mesmo sem foto salva', () async {
      final result = await photoService.deletePhoto();
      expect(result, isTrue);
    });
  });
}
