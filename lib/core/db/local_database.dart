import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Banco de dados local (sqflite) usado como base para o funcionamento
/// offline-first do SISOV. Por enquanto guarda a fila de sincronização
/// (padrão outbox): toda escrita feita sem internet fica registrada aqui
/// e é enviada automaticamente quando a conexão volta.
class LocalDatabase {
  LocalDatabase._();
  static final LocalDatabase instance = LocalDatabase._();

  static const _dbName = 'sisov_local.db';
  static const _dbVersion = 1;

  /// Nome da tabela que representa a fila de operações pendentes.
  static const tableSyncQueue = 'sync_queue';

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
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
        created_at TEXT NOT NULL
      )
    ''');
  }
}
