import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../api/api_client.dart';
import '../db/local_database.dart';

/// Serviço central de sincronização offline-first (padrão outbox).
///
/// Toda escrita do app passa por [submitWrite]:
/// - Com internet, a requisição é enviada imediatamente ao backend.
/// - Sem internet (ou em falha de rede), ela é gravada na fila local
///   ([LocalDatabase.tableSyncQueue]) e reenviada automaticamente assim que
///   a conexão voltar (ou periodicamente).
///
/// Cada item carrega um `clientRequestId` único, enviado no header
/// `X-Client-Request-Id`, garantindo idempotência (o backend ignora reenvios
/// duplicados).
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  static const _uuid = Uuid();
  final Connectivity _connectivity = Connectivity();

  /// Quantidade de operações ainda não sincronizadas (para exibir na UI).
  final ValueNotifier<int> pendingCount = ValueNotifier<int>(0);

  StreamSubscription<List<ConnectivityResult>>? _connSub;
  Timer? _periodicTimer;
  bool _isSyncing = false;
  bool _initialized = false;

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

    // Rede de segurança: tenta esvaziar a fila periodicamente, caso um
    // evento de conectividade tenha sido perdido.
    _periodicTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (pendingCount.value > 0) flush();
    });

    // Tentativa inicial ao abrir o app.
    unawaited(flush());
  }

  void dispose() {
    _connSub?.cancel();
    _periodicTimer?.cancel();
  }

  bool _isOffline(List<ConnectivityResult> results) {
    return results.isEmpty || results.every((r) => r == ConnectivityResult.none);
  }

  Future<bool> _hasConnection() async {
    final results = await _connectivity.checkConnectivity();
    return !_isOffline(results);
  }

  /// Envia uma escrita agora (se houver internet) ou a coloca na fila.
  ///
  /// Retorna um mapa no mesmo formato dos services:
  /// - `{'success': true, 'data': ...}` quando enviado ao servidor;
  /// - `{'success': true, 'queued': true, 'message': ...}` quando enfileirado;
  /// - `{'success': false, 'message': ...}` quando o servidor recusou (erro real).
  Future<Map<String, dynamic>> submitWrite({
    required String endpoint,
    required Map<String, dynamic> payload,
    required String label,
  }) async {
    final requestId = _uuid.v4();

    if (await _hasConnection()) {
      try {
        final response =
            await ApiClient.post(endpoint, payload, requestId: requestId);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return {
            'success': true,
            'data': _tryDecode(response.body),
          };
        }

        // Servidor respondeu recusando (validação, permissão, etc.).
        // Não adianta reenviar — devolve o erro ao usuário.
        final decoded = _tryDecode(response.body);
        final message = decoded is Map && decoded['message'] != null
            ? decoded['message'].toString()
            : 'Erro ao enviar (código ${response.statusCode}).';
        return {'success': false, 'message': message};
      } catch (_) {
        // Falha de rede durante o envio: cai para a fila.
      }
    }

    await _enqueue(
      requestId: requestId,
      label: label,
      endpoint: endpoint,
      payload: payload,
    );

    return {
      'success': true,
      'queued': true,
      'message': offlineMessage,
    };
  }

  Future<void> _enqueue({
    required String requestId,
    required String label,
    required String endpoint,
    required Map<String, dynamic> payload,
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
    });
    await _refreshPendingCount();
  }

  /// Processa a fila em ordem (FIFO). Preserva a ordem parando no primeiro
  /// item que falhar por rede/servidor indisponível.
  Future<void> flush() async {
    if (_isSyncing) return;
    if (!await _hasConnection()) return;

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

        try {
          final response =
              await ApiClient.post(endpoint, payload, requestId: requestId);

          if (response.statusCode >= 200 && response.statusCode < 300) {
            await db.delete(
              LocalDatabase.tableSyncQueue,
              where: 'id = ?',
              whereArgs: [id],
            );
          } else if (response.statusCode >= 400 && response.statusCode < 500) {
            // Recusa definitiva do servidor: marca como FALHO e segue adiante.
            await _markFailed(db, id, row, 'HTTP ${response.statusCode}: ${response.body}');
          } else {
            // Servidor indisponível (5xx): tenta mais tarde, preservando ordem.
            await _incrementRetry(db, id, row, 'HTTP ${response.statusCode}');
            break;
          }
        } catch (e) {
          // Falha de rede: interrompe e tenta novamente depois.
          await _incrementRetry(db, id, row, e.toString());
          break;
        }
      }
    } finally {
      _isSyncing = false;
      await _refreshPendingCount();
    }
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
      'SELECT COUNT(*) AS c FROM ${LocalDatabase.tableSyncQueue}',
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
}
