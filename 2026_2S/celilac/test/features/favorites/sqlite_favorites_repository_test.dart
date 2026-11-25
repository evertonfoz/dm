import 'package:celilac/features/establishments/domain/entities/dietary_option.dart';
import 'package:celilac/features/establishments/domain/entities/establishment.dart';
import 'package:celilac/features/establishments/domain/entities/establishment_category.dart';
import 'package:celilac/features/favorites/data/sqlite_favorites_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _cafe = Establishment(
  id: '1',
  name: 'Café Aconchego',
  category: EstablishmentCategory.cafe,
  neighborhood: 'Centro',
  distanceInKm: 0.35,
  rating: 4.8,
  dietaryOptions: {DietaryOption.glutenFree, DietaryOption.lactoseFree},
  logoSource: 'assets/images/establishments/cafe_aconchego_logo.png',
);

const _bakery = Establishment(
  id: '2',
  name: 'Padaria Leve Grão',
  category: EstablishmentCategory.bakery,
  neighborhood: 'Jardim das Flores',
  distanceInKm: 1.2,
  rating: 4.6,
  dietaryOptions: {DietaryOption.glutenFree},
);

Future<Database> _openInMemoryDatabase() {
  return databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: SqliteFavoritesRepository.schemaVersion,
      onCreate: SqliteFavoritesRepository.createSchema,
      onUpgrade: SqliteFavoritesRepository.upgradeSchema,
      singleInstance: false,
    ),
  );
}

void main() {
  setUpAll(sqfliteFfiInit);

  late Database db;
  late SqliteFavoritesRepository repository;

  setUp(() async {
    db = await _openInMemoryDatabase();
    repository = SqliteFavoritesRepository(openDatabase: () async => db);
  });

  tearDown(() async {
    await db.close();
  });

  test('começa vazio', () async {
    expect(await repository.loadAll(), isEmpty);
    expect(await repository.isFavorite('1'), isFalse);
  });

  test('salva e devolve do mais recente para o mais antigo', () async {
    await repository.add(_cafe, savedAt: DateTime.utc(2026, 11, 4, 10));
    await repository.add(_bakery, savedAt: DateTime.utc(2026, 11, 4, 11));

    final all = await repository.loadAll();
    expect(all.map((e) => e.id).toList(), ['2', '1']);
    expect(await repository.isFavorite('1'), isTrue);
    expect(await repository.isFavorite('2'), isTrue);
  });

  test('salvar o mesmo id atualiza sem duplicar', () async {
    await repository.add(_cafe, savedAt: DateTime.utc(2026, 11, 4, 10));
    await repository.add(_bakery, savedAt: DateTime.utc(2026, 11, 4, 11));
    await repository.add(_cafe, savedAt: DateTime.utc(2026, 11, 4, 12));

    final all = await repository.loadAll();
    expect(all.map((e) => e.id).toList(), ['1', '2']);
  });

  test('remove apenas o estabelecimento indicado', () async {
    await repository.add(_cafe);
    await repository.add(_bakery);

    await repository.remove('1');

    final all = await repository.loadAll();
    expect(all.map((e) => e.id).toList(), ['2']);
    expect(await repository.isFavorite('1'), isFalse);
  });

  test('migra da versão 1 para a 2 preservando os dados já salvos', () async {
    final v1Db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        singleInstance: false,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE ${SqliteFavoritesRepository.tableName} (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              category TEXT NOT NULL,
              neighborhood TEXT NOT NULL,
              distance_in_km REAL NOT NULL,
              rating REAL NOT NULL,
              dietary_options TEXT NOT NULL,
              saved_at INTEGER NOT NULL
            )
          ''');
        },
      ),
    );
    addTearDown(v1Db.close);

    await v1Db.insert(SqliteFavoritesRepository.tableName, {
      'id': '2',
      'name': 'Padaria Leve Grão',
      'category': 'bakery',
      'neighborhood': 'Jardim das Flores',
      'distance_in_km': 1.2,
      'rating': 4.6,
      'dietary_options': 'glutenFree',
      'saved_at': 1000,
    });

    await SqliteFavoritesRepository.upgradeSchema(v1Db, 1, 2);

    final migratedRepo = SqliteFavoritesRepository(
      openDatabase: () async => v1Db,
    );
    await migratedRepo.add(_cafe, savedAt: DateTime.utc(2026, 11, 4, 12));

    final all = await migratedRepo.loadAll();
    expect(all.map((e) => e.id).toList(), ['1', '2']);
    expect(all.first.logoSource, _cafe.logoSource);
    expect(all.last.logoSource, isNull);
  });

  test(
    'migra para a versão 3 apagando os favoritos do catálogo fake',
    () async {
      final v2Db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 2,
          singleInstance: false,
          onCreate: SqliteFavoritesRepository.createSchema,
        ),
      );
      addTearDown(v2Db.close);
      final v2Repo = SqliteFavoritesRepository(openDatabase: () async => v2Db);
      await v2Repo.add(_cafe);
      await v2Repo.add(_bakery);

      await SqliteFavoritesRepository.upgradeSchema(v2Db, 2, 3);

      expect(await v2Repo.loadAll(), isEmpty);
      expect(await v2Repo.isFavorite('1'), isFalse);
    },
  );
}
