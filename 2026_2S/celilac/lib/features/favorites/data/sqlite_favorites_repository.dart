import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../establishments/domain/entities/establishment.dart';
import '../domain/repositories/favorites_repository.dart';
import 'favorite_establishment_row.dart';

class SqliteFavoritesRepository implements FavoritesRepository {
  SqliteFavoritesRepository({Future<Database> Function()? openDatabase})
    : _openDatabase = openDatabase ?? _openDefaultDatabase;

  static const String tableName = 'favorites';
  static const String databaseFileName = 'celilac_favorites.db';

  /// 1: tabela inicial. 2: coluna `logo_source`.
  /// 3: catálogo no Supabase (ids passam a ser uuids; favoritos antigos saem).
  static const int schemaVersion = 3;

  final Future<Database> Function() _openDatabase;
  Future<Database>? _database;

  Future<Database> get _db => _database ??= _openDatabase();

  static Future<Database> _openDefaultDatabase() async {
    final directory = await getDatabasesPath();
    final path = p.join(directory, databaseFileName);
    return openDatabase(
      path,
      version: schemaVersion,
      onCreate: createSchema,
      onUpgrade: upgradeSchema,
    );
  }

  static Future<void> createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        neighborhood TEXT NOT NULL,
        distance_in_km REAL NOT NULL,
        rating REAL NOT NULL,
        dietary_options TEXT NOT NULL,
        logo_source TEXT,
        saved_at INTEGER NOT NULL
      )
    ''');
  }

  static Future<void> upgradeSchema(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Cada passo roda só se a migração atravessa aquela versão.
    if (oldVersion < 2 && newVersion >= 2) {
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN logo_source TEXT',
      );
    }
    if (oldVersion < 3 && newVersion >= 3) {
      // Os favoritos salvos apontam para os ids '1'..'12' do catálogo fake,
      // que não existem no Supabase (lá os ids são uuids). A cópia guardada
      // também traz caminhos de assets em vez de URLs. Recomeçar do zero é a
      // opção mais simples e honesta para um catálogo fictício.
      await db.delete(tableName);
    }
  }

  @override
  Future<List<Establishment>> loadAll() async {
    final db = await _db;
    final rows = await db.query(tableName, orderBy: 'saved_at DESC');
    return [for (final row in rows) establishmentFromRow(row)];
  }

  @override
  Future<bool> isFavorite(String establishmentId) async {
    final db = await _db;
    final rows = await db.query(
      tableName,
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [establishmentId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  @override
  Future<void> add(Establishment establishment, {DateTime? savedAt}) async {
    final db = await _db;
    await db.insert(
      tableName,
      establishment.toRow(savedAt: savedAt ?? DateTime.now()),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> remove(String establishmentId) async {
    final db = await _db;
    await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [establishmentId],
    );
  }

  Future<void> close() async {
    final db = _database;
    _database = null;
    if (db != null) {
      await (await db).close();
    }
  }
}

