import 'package:celilac/features/favorites/presentation/favorites_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_favorites_repository.dart';
import '../../support/stub_establishment_repository.dart';

void main() {
  test('carrega os favoritos e não repete a leitura se chamado de novo', () async {
    final repository = MemoryFavoritesRepository(stored: [testCafe]);
    final controller = FavoritesController(repository);
    addTearDown(controller.dispose);

    await (controller.load(), controller.load()).wait;

    expect(controller.isLoaded, isTrue);
    expect(controller.favorites, [testCafe]);
    expect(controller.isFavorite(testCafe.id), isTrue);
    expect(repository.loadCalls, 1);
  });

  test('em caso de falha ao ler, segue vazio e marca como carregado', () async {
    final repository = MemoryFavoritesRepository(failOnLoad: true);
    final controller = FavoritesController(repository);
    addTearDown(controller.dispose);

    await controller.load();

    expect(controller.isLoaded, isTrue);
    expect(controller.favorites, isEmpty);
  });

  test('toggle adiciona quando não está salvo e remove quando já está', () async {
    final repository = MemoryFavoritesRepository();
    final controller = FavoritesController(repository);
    addTearDown(controller.dispose);
    await controller.load();

    final added = await controller.toggle(testCafe);
    expect(added, isTrue);
    expect(controller.isFavorite(testCafe.id), isTrue);
    expect(controller.favorites, [testCafe]);

    final stillFavorite = await controller.toggle(testCafe);
    expect(stillFavorite, isFalse);
    expect(controller.isFavorite(testCafe.id), isFalse);
    expect(controller.favorites, isEmpty);
  });

  test('se falhar ao gravar, propaga o erro e não muda a memória', () async {
    final repository = MemoryFavoritesRepository(failOnChange: true);
    final controller = FavoritesController(repository);
    addTearDown(controller.dispose);
    await controller.load();

    await expectLater(controller.toggle(testCafe), throwsException);
    expect(controller.isFavorite(testCafe.id), isFalse);
    expect(controller.favorites, isEmpty);
  });
}

