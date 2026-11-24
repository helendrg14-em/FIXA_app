import 'package:flutter/foundation.dart';

import 'almacen_local.dart';
import 'modelos.dart';
import 'repositorio.dart';

class MisReportes extends ChangeNotifier {
  MisReportes(this.repositorio, this._almacen);

  final Repositorio repositorio;
  final AlmacenLocal _almacen;

  List<Credenciales> _guardados = [];
  final Map<String, Seguimiento> _estados = {};
  final Map<String, String> _errores = {};
  Future<void>? _carga;
  Future<void> _escrituras = Future.value();
  bool cargado = false;

  List<Credenciales> get guardados => List.unmodifiable(_guardados);
  Seguimiento? estadoDe(String codigo) => _estados[codigo];
  String? errorDe(String codigo) => _errores[codigo];
  bool tiene(String codigo) => credencialesDe(codigo) != null;

  /// Si el caso sigue abierto. Mientras no se conoce su estado, se trata como abierto.
  bool vigente(String codigo) {
    final estado = _estados[codigo]?.estado;
    return estado == null || !(estado.cerrado || estado.terminoSinArreglo);
  }

  /// Los guardados con los abiertos primero y, dentro de cada grupo, del más reciente al más antiguo.
  List<Credenciales> get recientes {
    DateTime fecha(Credenciales c) =>
        _estados[c.codigo]?.fechaRegistro ?? c.guardadoEl ?? DateTime(2000);
    int abierto(Credenciales c) => vigente(c.codigo) ? 0 : 1;
    return [..._guardados]..sort((a, b) {
        final grupo = abierto(a).compareTo(abierto(b));
        return grupo != 0 ? grupo : fecha(b).compareTo(fecha(a));
      });
  }

  Future<void> cargar() async {
    if (cargado) return;
    try {
      await (_carga ??= _cargar());
    } finally {
      _carga = null;
    }
  }

  Future<void> _cargar() async {
    _guardados = await _almacen.leer();
    cargado = true;
    notifyListeners();
  }

  Future<void> _escribir(List<Credenciales> Function() cambiar) {
    final operacion = _escrituras.then((_) async {
      await cargar();
      final siguiente = cambiar();
      if (identical(siguiente, _guardados)) return;
      await _almacen.escribir(siguiente);
      _guardados = siguiente;
      notifyListeners();
    });
    _escrituras =
        operacion.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return operacion;
  }

  Future<void> guardar(Credenciales credenciales) => _escribir(
        () => tiene(credenciales.codigo)
            ? _guardados
            : [credenciales, ..._guardados],
      );

  Future<void> guardarConsulta(
      Credenciales credenciales, Seguimiento seguimiento) async {
    try {
      await guardar(credenciales);
    } on Exception {
      // La consulta sigue disponible en memoria cuando falla el almacenamiento.
    }
    _registrarEstado(credenciales.codigo, seguimiento);
  }

  Future<void> quitar(String codigo) async {
    await _escribir(() => [
          for (final c in _guardados)
            if (c.codigo != codigo) c
        ]);
    _estados.remove(codigo);
    _errores.remove(codigo);
    notifyListeners();
  }

  Future<void> actualizar() async {
    await Future.wait([for (final c in _guardados) actualizarUno(c)]);
  }

  void _registrarEstado(String codigo, Seguimiento seguimiento) {
    _estados[codigo] = seguimiento;
    _errores.remove(codigo);
    notifyListeners();
  }

  Future<Seguimiento?> actualizarUno(Credenciales credenciales) async {
    try {
      final seguimiento = await repositorio.seguimiento(credenciales);
      _registrarEstado(credenciales.codigo, seguimiento);
      return seguimiento;
    } on FixaError catch (error) {
      _errores[credenciales.codigo] = error.mensaje;
      notifyListeners();
      return null;
    }
  }

  Credenciales? credencialesDe(String codigo) =>
      _guardados.where((c) => c.codigo == codigo).firstOrNull;
}
