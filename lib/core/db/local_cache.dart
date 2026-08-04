import 'package:sqflite/sqflite.dart';

import 'local_database.dart';

/// Acesso ao cache local de animais e propriedades + mapa de IDs.
class LocalCache {
  LocalCache._();
  static final LocalCache instance = LocalCache._();

  Future<Database> get _db => LocalDatabase.instance.database;

  // ─── ID map ────────────────────────────────────────────────────────────

  Future<void> mapId({
    required String localId,
    required String serverId,
    required String entityType,
  }) async {
    final db = await _db;
    await db.insert(
      LocalDatabase.tableIdMap,
      {
        'local_id': localId,
        'server_id': serverId,
        'entity_type': entityType,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> resolveServerId(String localId) async {
    if (!localId.startsWith('local_')) return localId;
    final db = await _db;
    final rows = await db.query(
      LocalDatabase.tableIdMap,
      where: 'local_id = ?',
      whereArgs: [localId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['server_id'] as String;
  }

  /// Substitui qualquer valor `local_...` por server_id conhecido.
  /// Retorna null se ainda houver ID local sem mapeamento.
  Future<String?> rewriteIdsInString(String value) async {
    if (!value.contains('local_')) return value;

    var result = value;
    final matches = RegExp(r'local_[0-9a-fA-F\-]+').allMatches(value);
    for (final match in matches) {
      final localId = match.group(0)!;
      final serverId = await resolveServerId(localId);
      if (serverId == null) return null;
      result = result.replaceAll(localId, serverId);
    }
    return result;
  }

  Future<Map<String, dynamic>?> rewriteIdsInMap(
    Map<String, dynamic> payload,
  ) async {
    final rewritten = <String, dynamic>{};
    for (final entry in payload.entries) {
      final value = entry.value;
      if (value is String && value.startsWith('local_')) {
        final serverId = await resolveServerId(value);
        if (serverId == null) return null;
        rewritten[entry.key] = serverId;
      } else {
        rewritten[entry.key] = value;
      }
    }
    return rewritten;
  }

  // ─── Properties ────────────────────────────────────────────────────────

  Future<void> upsertProperty(Map<String, dynamic> property) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    await db.insert(
      LocalDatabase.tableProperties,
      {
        'id': property['id']?.toString() ?? '',
        'farm_name': property['farmName']?.toString() ?? '',
        'city': property['city']?.toString() ?? '',
        'state': property['state']?.toString() ?? '',
        'sync_status': property['syncStatus']?.toString() ?? 'SYNCED',
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> replaceProperties(List<Map<String, dynamic>> properties) async {
    final db = await _db;
    await db.transaction((txn) async {
      // Mantém propriedades ainda não sincronizadas.
      await txn.delete(
        LocalDatabase.tableProperties,
        where: "sync_status = 'SYNCED'",
      );
      final now = DateTime.now().toIso8601String();
      for (final property in properties) {
        await txn.insert(
          LocalDatabase.tableProperties,
          {
            'id': property['id']?.toString() ?? '',
            'farm_name': property['farmName']?.toString() ?? '',
            'city': property['city']?.toString() ?? '',
            'state': property['state']?.toString() ?? '',
            'sync_status': 'SYNCED',
            'updated_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<Map<String, dynamic>>> getProperties() async {
    final db = await _db;
    final rows = await db.query(
      LocalDatabase.tableProperties,
      orderBy: 'farm_name ASC',
    );
    return rows
        .map(
          (r) => {
            'id': r['id'],
            'farmName': r['farm_name'],
            'city': r['city'],
            'state': r['state'],
            'syncStatus': r['sync_status'],
          },
        )
        .toList();
  }

  Future<void> promoteProperty({
    required String localId,
    required String serverId,
    Map<String, dynamic>? serverData,
  }) async {
    final db = await _db;
    await db.transaction((txn) async {
      final rows = await txn.query(
        LocalDatabase.tableProperties,
        where: 'id = ?',
        whereArgs: [localId],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        final row = rows.first;
        await txn.delete(
          LocalDatabase.tableProperties,
          where: 'id = ?',
          whereArgs: [localId],
        );
        await txn.insert(
          LocalDatabase.tableProperties,
          {
            'id': serverId,
            'farm_name':
                serverData?['farmName']?.toString() ?? row['farm_name'],
            'city': serverData?['city']?.toString() ?? row['city'],
            'state': serverData?['state']?.toString() ?? row['state'],
            'sync_status': 'SYNCED',
            'updated_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await txn.insert(
        LocalDatabase.tableIdMap,
        {
          'local_id': localId,
          'server_id': serverId,
          'entity_type': 'property',
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      // Atualiza property_id dos animais locais que ainda apontam para o ID local.
      await txn.update(
        LocalDatabase.tableAnimals,
        {'property_id': serverId},
        where: 'property_id = ?',
        whereArgs: [localId],
      );
    });
  }

  // ─── Animals ───────────────────────────────────────────────────────────

  Future<void> upsertAnimal(Map<String, dynamic> animal) async {
    final db = await _db;
    final sisovId =
        animal['sisovId']?.toString() ?? animal['id']?.toString() ?? '';
    if (sisovId.isEmpty) return;

    await db.insert(
      LocalDatabase.tableAnimals,
      {
        'sisov_id': sisovId,
        'tag_id': animal['tagId']?.toString(),
        'property_id': animal['propertyId']?.toString() ??
            (animal['property'] is Map
                ? animal['property']['id']?.toString()
                : null) ??
            '',
        'breed': animal['breed']?.toString() ?? '',
        'sex': animal['sex']?.toString() ?? '',
        'birth_date': animal['birthDate']?.toString() ?? '',
        'birth_city': animal['birthCity']?.toString() ?? '',
        'status': animal['status']?.toString() ?? 'ACTIVE',
        'sync_status': animal['syncStatus']?.toString() ?? 'SYNCED',
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> replaceAnimals(List<Map<String, dynamic>> animals) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete(
        LocalDatabase.tableAnimals,
        where: "sync_status = 'SYNCED'",
      );
      final now = DateTime.now().toIso8601String();
      for (final animal in animals) {
        final sisovId =
            animal['sisovId']?.toString() ?? animal['id']?.toString() ?? '';
        if (sisovId.isEmpty) continue;
        await txn.insert(
          LocalDatabase.tableAnimals,
          {
            'sisov_id': sisovId,
            'tag_id': animal['tagId']?.toString(),
            'property_id': animal['propertyId']?.toString() ??
                (animal['property'] is Map
                    ? animal['property']['id']?.toString()
                    : null) ??
                '',
            'breed': animal['breed']?.toString() ?? '',
            'sex': animal['sex']?.toString() ?? '',
            'birth_date': animal['birthDate']?.toString() ?? '',
            'birth_city': animal['birthCity']?.toString() ?? '',
            'status': animal['status']?.toString() ?? 'ACTIVE',
            'sync_status': 'SYNCED',
            'updated_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<Map<String, dynamic>>> getAnimals() async {
    final db = await _db;
    final rows = await db.query(
      LocalDatabase.tableAnimals,
      orderBy: 'updated_at DESC',
    );
    return rows.map(_animalRowToMap).toList();
  }

  Future<Map<String, dynamic>?> getAnimal(String identifier) async {
    final db = await _db;
    final byId = await db.query(
      LocalDatabase.tableAnimals,
      where: 'sisov_id = ? OR tag_id = ?',
      whereArgs: [identifier, identifier],
      limit: 1,
    );
    if (byId.isEmpty) return null;
    return _animalRowToMap(byId.first);
  }

  Future<void> promoteAnimal({
    required String localId,
    required String serverId,
    Map<String, dynamic>? serverData,
  }) async {
    final db = await _db;
    await db.transaction((txn) async {
      final rows = await txn.query(
        LocalDatabase.tableAnimals,
        where: 'sisov_id = ?',
        whereArgs: [localId],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        final row = rows.first;
        await txn.delete(
          LocalDatabase.tableAnimals,
          where: 'sisov_id = ?',
          whereArgs: [localId],
        );
        await txn.insert(
          LocalDatabase.tableAnimals,
          {
            'sisov_id': serverId,
            'tag_id': serverData?['tagId']?.toString() ?? row['tag_id'],
            'property_id': serverData?['propertyId']?.toString() ??
                row['property_id'],
            'breed': serverData?['breed']?.toString() ?? row['breed'],
            'sex': serverData?['sex']?.toString() ?? row['sex'],
            'birth_date':
                serverData?['birthDate']?.toString() ?? row['birth_date'],
            'birth_city':
                serverData?['birthCity']?.toString() ?? row['birth_city'],
            'status': serverData?['status']?.toString() ?? row['status'],
            'sync_status': 'SYNCED',
            'updated_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await txn.insert(
        LocalDatabase.tableIdMap,
        {
          'local_id': localId,
          'server_id': serverId,
          'entity_type': 'animal',
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> updateAnimalStatus(String sisovId, String status) async {
    final db = await _db;
    await db.update(
      LocalDatabase.tableAnimals,
      {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'sisov_id = ?',
      whereArgs: [sisovId],
    );
  }

  Future<void> deleteAnimal(String sisovId) async {
    final db = await _db;
    await db.delete(
      LocalDatabase.tableAnimals,
      where: 'sisov_id = ?',
      whereArgs: [sisovId],
    );
  }

  Future<void> deleteProperty(String id) async {
    final db = await _db;
    await db.delete(
      LocalDatabase.tableProperties,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Map<String, dynamic> _animalRowToMap(Map<String, Object?> r) => {
        'sisovId': r['sisov_id'],
        'tagId': r['tag_id'],
        'propertyId': r['property_id'],
        'breed': r['breed'],
        'sex': r['sex'],
        'birthDate': r['birth_date'],
        'birthCity': r['birth_city'],
        'status': r['status'],
        'syncStatus': r['sync_status'],
      };
}
