import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sisov_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Tabela de Usuários para o Login
    await db.execute('''
      CREATE TABLE usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        senha TEXT NOT NULL
      )
    ''');

    // Inserir usuário padrão
    await db.insert('usuarios', {'nome': 'admin', 'senha': '123'});

    // Tabela de Ovinos com todos os campos solicitados
    await db.execute('''
      CREATE TABLE ovinos (
        id TEXT PRIMARY KEY,
        tagId TEXT NOT NULL,
        sexo TEXT,
        raca TEXT,
        dataNasc TEXT,
        municipio TEXT,
        estado TEXT,
        pesoNasc REAL,
        pai TEXT,
        mae TEXT
      )
    ''');
  }

  // --- MÉTODOS PARA LOGIN ---
  Future<Map<String, dynamic>?> login(String usuario, String senha) async {
    final db = await instance.database;
    final result = await db.query(
      'usuarios',
      where: 'nome = ? AND senha = ?',
      whereArgs: [usuario, senha],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // --- MÉTODOS PARA OVINOS ---
  Future<int> insertOvino(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('ovinos', row);
  }

  Future<List<Map<String, dynamic>>> getOvinos() async {
    final db = await instance.database;
    return await db.query('ovinos', orderBy: 'tagId ASC');
  }

  // Método opcional para deletar (caso precise limpar algo)
  Future<int> deleteOvino(String id) async {
    final db = await instance.database;
    return await db.delete('ovinos', where: 'id = ?', whereArgs: [id]);
  }
}