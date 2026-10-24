import 'package:celilac/features/establishments/domain/entities/dietary_option.dart';
import 'package:celilac/features/profile/domain/entities/dietary_profile.dart';
import 'package:celilac/features/profile/presentation/profile_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_profile_repository.dart';

const _ana = DietaryProfile(
  name: 'Ana',
  restrictions: {DietaryOption.glutenFree},
);

void main() {
  group('load', () {
    test('começa vazio e ainda não carregado', () {
      final controller = ProfileController(MemoryProfileRepository());

      expect(controller.profile, DietaryProfile.empty);
      expect(controller.isLoaded, isFalse);
    });

    test('carrega o perfil gravado e avisa uma vez', () async {
      final controller = ProfileController(
        MemoryProfileRepository(stored: _ana),
      );
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.load();

      expect(controller.profile, _ana);
      expect(controller.isLoaded, isTrue);
      expect(notifications, 1);
    });

    test('chamar duas vezes lê o repositório uma vez só', () async {
      final repository = MemoryProfileRepository(stored: _ana);
      final controller = ProfileController(repository);

      // Ao mesmo tempo (Splash e uma tela, por exemplo) e depois de pronto.
      await Future.wait([controller.load(), controller.load()]);
      await controller.load();

      expect(repository.loadCalls, 1);
    });

    test('falha na leitura: segue com o perfil vazio, sem erro', () async {
      final controller = ProfileController(
        MemoryProfileRepository(failOnLoad: true),
      );

      await controller.load();

      expect(controller.profile, DietaryProfile.empty);
      expect(controller.isLoaded, isTrue);
    });
  });

  group('save', () {
    test('grava, atualiza e avisa', () async {
      final repository = MemoryProfileRepository();
      final controller = ProfileController(repository);
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.save(_ana);

      expect(repository.stored, _ana);
      expect(controller.profile, _ana);
      expect(notifications, 1);
    });

    test('falha na gravação: repassa o erro e nada muda', () async {
      final repository = MemoryProfileRepository(failOnSave: true);
      final controller = ProfileController(repository);
      await controller.load();
      var notifications = 0;
      controller.addListener(() => notifications++);

      await expectLater(controller.save(_ana), throwsException);

      expect(controller.profile, DietaryProfile.empty);
      expect(repository.stored, DietaryProfile.empty);
      expect(notifications, 0);
    });
  });
}
