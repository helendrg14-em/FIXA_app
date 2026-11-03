import 'package:flutter/foundation.dart';

import '../../data/incidencias_repository.dart';
import '../../data/models/incidencia.dart';

/// Lista de incidencias del ciudadano, compartida por el mapa
/// y por "Mis reportes".
class IncidenciasProvider extends ChangeNotifier {
  IncidenciasProvider(this._repo);
  final IncidenciasRepository _repo;

  List<Incidencia> items = [];
  bool cargando = false;
  String? error;

  Future<void> cargar() async {
    cargando = true;
    error = null;
    notifyListeners();
    try {
      items = await _repo.misIncidencias();
    } catch (e) {
      error = 'No se pudieron cargar los reportes';
    }
    cargando = false;
    notifyListeners();
  }

  Future<void> reportar({
    required Categoria categoria,
    required String descripcion,
    required double lat,
    required double lng,
    String? fotoPath,
  }) async {
    final nueva = await _repo.reportar(
      categoria: categoria,
      descripcion: descripcion,
      lat: lat,
      lng: lng,
      fotoPath: fotoPath,
    );
    items = [nueva, ...items];
    notifyListeners();
  }
}
