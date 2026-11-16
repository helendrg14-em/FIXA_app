import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'modelos.dart';

/// "Mis reportes" del celular (R06). El código y la clave se guardan cifrados con el Keystore
/// de Android, nunca en texto plano.
class AlmacenLocal {
  AlmacenLocal([FlutterSecureStorage? almacen]) : _almacen = almacen ?? const FlutterSecureStorage();

  final FlutterSecureStorage _almacen;
  static const _llave = 'fixa_mis_reportes';

  Future<List<Credenciales>> leer() async {
    final texto = await _almacen.read(key: _llave);
    if (texto == null || texto.isEmpty) return [];
    try {
      return [for (final fila in jsonDecode(texto) as List) Credenciales.desdeJson(Map<String, dynamic>.from(fila as Map))];
    } on FormatException {
      return [];
    }
  }

  Future<void> escribir(List<Credenciales> reportes) =>
      _almacen.write(key: _llave, value: jsonEncode([for (final r in reportes) r.aJson()]));
}

/// Versión en memoria para las pruebas.
class AlmacenEnMemoria extends AlmacenLocal {
  AlmacenEnMemoria([this._datos = const []]);
  List<Credenciales> _datos;

  @override
  Future<List<Credenciales>> leer() async => _datos;

  @override
  Future<void> escribir(List<Credenciales> reportes) async => _datos = List.of(reportes);
}
