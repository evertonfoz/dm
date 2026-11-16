import 'package:celilac/features/establishments/domain/entities/establishment.dart';
import 'package:celilac/features/establishments/domain/entities/establishment_category.dart';
import 'package:celilac/features/explore/domain/explore_sort.dart';
import 'package:celilac/features/explore/presentation/explore_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/explore_catalog.dart';
import '../../support/stub_establishment_repository.dart';

ExploreController _controller(
  List<Future<List<Establishment>> Function()> results,
) => ExploreController(StubEstablishmentRepository(nearbyResults: results));

void main() {
  test('começa carregando e passa a pronto com o catálogo', () async {
    final controller = _controller([() async => catalog]);
    addTearDown(controller.dispose);
    expect(controller.status, ExploreStatus.loading);

    await controller.load();

    expect(controller.status, ExploreStatus.ready);
    expect(controller.catalog, catalog);
  });

  test('load chamado várias vezes busca uma só vez', () async {
    final repository = StubEstablishmentRepository(
      nearbyResults: [() async => catalog],
    );
    final controller = ExploreController(repository);
    addTearDown(controller.dispose);

    await (controller.load(), controller.load()).wait;

    expect(repository.nearbyCalls, 1);
  });

  test('falha vira estado de erro e retry recupera', () async {
    final controller = _controller([
      () async => throw Exception('sem rede'),
      () async => catalog,
    ]);
    addTearDown(controller.dispose);

    await controller.load();
    expect(controller.status, ExploreStatus.failure);

    await controller.retry();
    expect(controller.status, ExploreStatus.ready);
    expect(controller.catalog, catalog);
  });

  group('filtros', () {
    late ExploreController controller;
    late int notifications;

    setUp(() {
      controller = _controller([() async => catalog]);
      notifications = 0;
      controller.addListener(() => notifications++);
    });
    tearDown(() => controller.dispose());

    test('toggleCategory liga e desliga', () {
      controller.toggleCategory(EstablishmentCategory.cafe);
      expect(controller.filters.categories, {EstablishmentCategory.cafe});
      controller.toggleCategory(EstablishmentCategory.cafe);
      expect(controller.filters.categories, isEmpty);
      expect(notifications, 2);
    });

    test('não notifica quando nada mudou', () {
      controller.setQuery('');
      controller.setSort(ExploreSort.distance);
      controller.setOnlyFavorites(false);
      expect(notifications, 0);
    });

    test('showOnly zera os outros filtros e escolhe só a categoria', () {
      controller.setQuery('pao');
      controller.setOnlyFavorites(true);

      controller.showOnly(EstablishmentCategory.bakery);

      expect(controller.filters.query, '');
      expect(controller.filters.onlyFavorites, isFalse);
      expect(controller.filters.categories, {EstablishmentCategory.bakery});
    });

    test('clearFilters mantém a ordenação escolhida', () {
      controller.setSort(ExploreSort.rating);
      controller.setQuery('cafe');

      controller.clearFilters();

      expect(controller.filters.hasActiveFilters, isFalse);
      expect(controller.filters.sort, ExploreSort.rating);
    });
  });
}
