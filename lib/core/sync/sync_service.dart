import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../api/api_client.dart';
import '../db/local_cache.dart';
import '../db/local_database.dart';
import '../utils/api_error_messages.dart';

/// Serviço central de sincronização offline-first (padrão outbox).
///
/// Toda escrita do app passa por [submitWrite]:
/// - Com internet, a requisição é enviada imediatamente ao backend.
/// - Sem internet (ou em falha de rede), ela é gravada na fila local
///   e reenviada automaticamente quando a conexão voltar.
///
/// Suporta IDs temporários `local_...`: antes do envio, o payload/endpoint
/// é reescrito com os UUIDs reais assim que o [LocalCache] tiver o mapeamento.
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  static const _uuid = Uuid();
  final Connectivity _connectivity = Connectivity();
  final LocalCache _cache = LocalCache.instance;

  /// Quantidade de operações ainda não sincronizadas (para exibir na UI).
  final ValueNotifier<int> pendingCount = ValueNotifier<int>(0);

  StreamSubscription<List<ConnectivityResult>>? _connSub;
  Timer? _periodicTimer;
  bool _isSyncing = false;
  bool _initialized = false;
  bool _paused = false;

  /// Mensagem padrão exibida quando algo é salvo apenas localmente.
  static const offlineMessage =
      'Salvo no aparelho. Será enviado automaticamente quando houver internet.';

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await LocalDatabase.instance.database;
    await _refreshPendingCount();

    _connSub = _connectivity.onConnectivityChanged.listen((results) {
      if (!_isOffline(results)) {
        flush();
      }
    });

    _periodicTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (pendingCount.value > 0) flush();
    });

    unawaited(flush());
  }

  void dispose() {
    _connSub?.cancel();
    _periodicTimer?.cancel();
  }

  /// Pausa o flush (ex.: durante logout/wipe).
  void pause() => _paused = true;

  void resume() => _paused = false;

  Future<void> refreshPendingCount() => _refreshPendingCount();

  bool _isOffline(List<ConnectivityResult> results) {
    return results.isEmpty ||
        results.every((r) => r == ConnectivityResult.none);
  }

  Future<bool> _hasLink() async {
    final results = await _connectivity.checkConnectivity();
    return !_isOffline(results);
  }

  /// Verifica se a API responde de fato (não só se há Wi‑Fi/dados).
  Future<bool> _canReachApi() async {
    if (!await _hasLink()) return false;
    try {
      final response = await ApiClient.get('/health').timeout(
        const Duration(seconds: 5),
      );
      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  /// Envia uma escrita agora (se houver internet) ou a coloca na fila.
  ///
  /// [entityType] / [localEntityId] permitem promover o registro local
  /// (`local_...`) para o UUID do servidor após o sucesso.
  Future<Map<String, dynamic>> submitWrite({
    required String endpoint,
    required Map<String, dynamic> payload,
    required String label,
    String? entityType,
    String? localEntityId,
  }) async {
    final requestId = _uuid.v4();

    if (await _canReachApi()) {
      try {
        final rewrittenEndpoint = await _cache.rewriteIdsInString(endpoint);
        final rewrittenPayload = await _cache.rewriteIdsInMap(payload);

        if (rewrittenEndpoint != null && rewrittenPayload != null) {
          final response = await ApiClient.post(
            rewrittenEndpoint,
            rewrittenPayload,
            requestId: requestId,
          );

          if (response.statusCode >= 200 && response.statusCode < 300) {
            final data = _tryDecode(response.body);
            await _promoteAfterSuccess(
              entityType: entityType,
              localEntityId: localEntityId,
              responseData: data,
            );
            return {'success': true, 'data': data};
          }

          return {
            'success': false,
            'message': ApiErrorMessages.fromHttp(
              statusCode: response.statusCode,
              body: response.body,
              action: _actionForEndpoint(endpoint),
            ),
          };
        }
        // IDs locais ainda sem mapeamento: enfileira.
      } catch (_) {
        // Falha de rede durante o envio: cai para a fila.
      }
    }

    // Evita enfileirar a mesma transferência várias vezes (toques repetidos).
    if (endpoint.contains('/transfer') &&
        await _hasPendingEndpoint(endpoint)) {
      return {
        'success': true,
        'queued': true,
        'message': offlineMessage,
        'localEntityId': localEntityId,
      };
    }

    await _enqueue(
      requestId: requestId,
      label: label,
      endpoint: endpoint,
      payload: payload,
      entityType: entityType,
      localEntityId: localEntityId,
    );

    return {
      'success': true,
      'queued': true,
      'message': offlineMessage,
      'localEntityId': localEntityId,
    };
  }

  Future<bool> _hasPendingEndpoint(String endpoint) async {
    final db = await LocalDatabase.instance.database;
    final rows = await db.query(
      LocalDatabase.tableSyncQueue,
      where: 'status = ? AND endpoint = ?',
      whereArgs: ['PENDING', endpoint],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> _enqueue({
    required String requestId,
    required String label,
    required String endpoint,
    required Map<String, dynamic> payload,
    String? entityType,
    String? localEntityId,
  }) async {
    final db = await LocalDatabase.instance.database;
    await db.insert(LocalDatabase.tableSyncQueue, {
      'client_request_id': requestId,
      'label': label,
      'method': 'POST',
      'endpoint': endpoint,
      'payload_json': jsonEncode(payload),
      'status': 'PENDING',
      'retry_count': 0,
      'created_at': DateTime.now().toIso8601String(),
      'entity_type': entityType,
      'local_entity_id': localEntityId,
    });
    await _refreshPendingCount();
  }

  /// Processa a fila em ordem (FIFO).
  Future<void> flush() async {
    if (_paused || _isSyncing) return;
    if (!await _canReachApi()) return;

    _isSyncing = true;
    try {
      final db = await LocalDatabase.instance.database;

      final rows = await db.query(
        LocalDatabase.tableSyncQueue,
        where: 'status = ?',
        whereArgs: ['PENDING'],
        orderBy: 'id ASC',
      );

      for (final row in rows) {
        final id = row['id'] as int;
        final endpoint = row['endpoint'] as String;
        final requestId = row['client_request_id'] as String;
        final payload =
            jsonDecode(row['payload_json'] as String) as Map<String, dynamic>;
        final entityType = row['entity_type'] as String?;
        final localEntityId = row['local_entity_id'] as String?;

        final rewrittenEndpoint = await _cache.rewriteIdsInString(endpoint);
        final rewrittenPayload = await _cache.rewriteIdsInMap(payload);

        // Dependência ainda não sincronizada (ex.: animal espera property).
        if (rewrittenEndpoint == null || rewrittenPayload == null) {
          break;
        }

        try {
          final response = await ApiClient.post(
            rewrittenEndpoint,
            rewrittenPayload,
            requestId: requestId,
          );

          if (response.statusCode >= 200 && response.statusCode < 300) {
            final data = _tryDecode(response.body);
            await _promoteAfterSuccess(
              entityType: entityType,
              localEntityId: localEntityId,
              responseData: data,
            );
            await db.delete(
              LocalDatabase.tableSyncQueue,
              where: 'id = ?',
              whereArgs: [id],
            );
          } else if (response.statusCode >= 400 && response.statusCode < 500) {
            await _markFailed(
              db,
              id,
              row,
              'HTTP ${response.statusCode}: ${response.body}',
            );
          } else {
            await _incrementRetry(db, id, row, 'HTTP ${response.statusCode}');
            break;
          }
        } catch (e) {
          await _incrementRetry(db, id, row, e.toString());
          break;
        }
      }
    } finally {
      _isSyncing = false;
      await _refreshPendingCount();
    }
  }

  Future<void> _promoteAfterSuccess({
    required String? entityType,
    required String? localEntityId,
    required dynamic responseData,
  }) async {
    if (entityType == null || localEntityId == null) return;
    if (!localEntityId.startsWith('local_')) return;

    final data = _extractData(responseData);
    if (data == null) return;

    if (entityType == 'property') {
      final serverId = data['id']?.toString();
      if (serverId == null || serverId.isEmpty) return;
      await _cache.promoteProperty(
        localId: localEntityId,
        serverId: serverId,
        serverData: data,
      );
    } else if (entityType == 'animal') {
      final serverId =
          data['sisovId']?.toString() ?? data['id']?.toString();
      if (serverId == null || serverId.isEmpty) return;
      await _cache.promoteAnimal(
        localId: localEntityId,
        serverId: serverId,
        serverData: data,
      );
    }
  }

  Map<String, dynamic>? _extractData(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final nested = responseData['data'];
      if (nested is Map<String, dynamic>) return nested;
      return responseData;
    }
    return null;
  }

  Future<void> _markFailed(
    Database db,
    int id,
    Map<String, Object?> row,
    String error,
  ) async {
    await db.update(
      LocalDatabase.tableSyncQueue,
      {
        'status': 'FAILED',
        'retry_count': (row['retry_count'] as int) + 1,
        'last_error': error,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> _incrementRetry(
    Database db,
    int id,
    Map<String, Object?> row,
    String error,
  ) async {
    await db.update(
      LocalDatabase.tableSyncQueue,
      {
        'retry_count': (row['retry_count'] as int) + 1,
        'last_error': error,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> _refreshPendingCount() async {
    final db = await LocalDatabase.instance.database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) AS c FROM ${LocalDatabase.tableSyncQueue} WHERE status = 'PENDING'",
    );
    pendingCount.value = Sqflite.firstIntValue(result) ?? 0;
  }

  dynamic _tryDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  ApiAction _actionForEndpoint(String endpoint) {
    if (endpoint.contains('/transfer')) return ApiAction.transfer;
    if (endpoint.contains('slaughter')) return ApiAction.slaughter;
    if (endpoint.contains('management-events')) return ApiAction.management;
    if (endpoint.startsWith('/properties')) return ApiAction.createProperty;
    if (endpoint.startsWith('/animals')) return ApiAction.createAnimal;
    return ApiAction.generic;
  }

  /// Gera um ID temporário local (`local_<uuid>`).
  static String newLocalId() => 'local_${_uuid.v4()}';
}
