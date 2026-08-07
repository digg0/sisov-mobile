import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

bool _initialized = false;

/// Inicializa o factory do sqflite conforme a plataforma.
/// No Chrome/Web o sqflite nativo não existe — usamos a implementação WASM.
Future<void> initDatabaseFactory() async {
  if (_initialized) return;
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }
  _initialized = true;
}
