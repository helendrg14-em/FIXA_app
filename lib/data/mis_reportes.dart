import 'package:flutter/foundation.dart';

import 'almacen_local.dart';
import 'modelos.dart';
import 'repositorio.dart';

/// Reportes guardados en este celular y su último estado conocido.
class MisReportes extends ChangeNotifier {
  MisReportes(this.repositorio, this._almacen);

  final Repositorio repositorio;
  final AlmacenLocal _almacen;

  List<Credenciales> _guardados = [];
  final Map<String, Seguimiento> _estados = {};
  final Map<String, String> _errores = {};
  bool cargado = false;

  List<Credenciales> get guardados => List.unmodifiable(_guardados);
  Seguimiento? estadoDe(String codigo) => _estados[codigo];
  String? errorDe(String codigo) => _errores[codigo];
  bool tiene(String codigo) => _guardados.any((c) => c.codigo == codigo);

  /// Reportes cerrados que esperan que el vecino diga si quedó bien (R12).
  List<Seguimiento> get porConfirmar => [
        for (final c in _guardados)
          if (_estados[c.codigo] case final s? when s.puedeResponderCierre(DateTime.now()) && s.conformidad == null) s,
      ];

  Future<void> cargar() async {
    _guardados = await _almacen.leer();
    cargado = true;
    notifyListeners();
  }

  Future<void> guardar(Credenciales credenciales) async {
    if (tiene(credenciales.codigo)) return;
    _guardados = [credenciales, ..._guardados];
    await _almacen.escribir(_guardados);
    notifyListeners();
  }

  Future<void> quitar(String codigo) async {
    _guardados = [for (final c in _guardados) if (c.codigo != codigo) c];
    _estados.remove(codigo);
    await _almacen.escribir(_guardados);
    notifyListeners();
  }

  /// Consulta el estado de todos los reportes guardados. Un fallo en uno no frena a los demás.
  Future<void> actualizar() async {
    await Future.wait([for (final c in _guardados) actualizarUno(c)]);
  }

  Future<Seguimiento?> actualizarUno(Credenciales c) async {
    try {
      final s = await repositorio.seguimiento(c);
      _estados[c.codigo] = s;
      _errores.remove(c.codigo);
      notifyListeners();
      return s;
    } on FixaError catch (e) {
      _errores[c.codigo] = e.mensaje;
      notifyListeners();
      return null;
    }
  }

  Credenciales? credencialesDe(String codigo) => _guardados.where((c) => c.codigo == codigo).firstOrNull;
}
