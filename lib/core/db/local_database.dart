import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'database_init.dart';

/// Banco local (sqflite) do SISOV offline-first.
///
/// - [tableSyncQueue]: fila outbox de escritas pendentes
/// - [tableAnimals] / [tableProperties]: cache do rebanho para leitura offline
/// - [tableIdMap]: mapeia IDs temporários (`local_...`) → UUIDs do servidor
class LocalDatabase {
  LocalDatabase._();
  static final LocalDatabase instance = LocalDatabase._();

  static const _dbName = 'sisov_local.db';
  static const _dbVersion = 2;

  static const tableSyncQueue = 'sync_queue';
  static const tableAnimals = 'animals';
  static const tableProperties = 'properties';
  static const tableIdMap = 'id_map';

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    // Garante factory WASM no Chrome mesmo se main() não tiver rodado de novo.
    await initDatabaseFactory();

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createSyncQueue(db);
    await _createCacheTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createCacheTables(db);
      await db.execute(
        'ALTER TABLE $tableSyncQueue ADD COLUMN entity_type TEXT',
      );
      await db.execute(
        'ALTER TABLE $tableSyncQueue ADD COLUMN local_entity_id TEXT',
      );
    }
  }

  Future<void> _createSyncQueue(Database db) async {
    await db.execute('''
      CREATE TABLE $tableSyncQueue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_request_id TEXT NOT NULL,
        label TEXT NOT NULL,
        method TEXT NOT NULL DEFAULT 'POST',
        endpoint TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'PENDING',
        retry_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        created_at TEXT NOT NULL,
        entity_type TEXT,
        local_entity_id TEXT
      )
    ''');
  }

  Future<void> _createCacheTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableAnimals (
        sisov_id TEXT PRIMARY KEY,
        tag_id TEXT,
        property_id TEXT NOT NULL,
        breed TEXT NOT NULL,
        sex TEXT NOT NULL,
        birth_date TEXT NOT NULL,
        birth_city TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'ACTIVE',
        sync_status TEXT NOT NULL DEFAULT 'SYNCED',
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableProperties (
        id TEXT PRIMARY KEY,
        farm_name TEXT NOT NULL,
        city TEXT NOT NULL,
        state TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'SYNCED',
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableIdMap (
        local_id TEXT PRIMARY KEY,
        server_id TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }
}
