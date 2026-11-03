import 'package:dio/dio.dart';

import 'api_client.dart';
import 'models/incidencia.dart';

/// Contrato de acceso a datos. Las pantallas no saben si los datos
/// vienen de Laravel o de memoria.
abstract class IncidenciasRepository {
  Future<List<Incidencia>> misIncidencias();

  Future<Incidencia> reportar({
    required Categoria categoria,
    required String descripcion,
    required double lat,
    required double lng,
    String? fotoPath,
  });
}

/// Implementación real contra la API Laravel.
class ApiIncidenciasRepository implements IncidenciasRepository {
  ApiIncidenciasRepository(this._api);
  final ApiClient _api;

  @override
  Future<List<Incidencia>> misIncidencias() async {
    final res = await _api.dio.get('/incidencias');
    final lista = res.data['data'] as List;
    return lista
        .map((e) => Incidencia.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Incidencia> reportar({
    required Categoria categoria,
    required String descripcion,
    required double lat,
    required double lng,
    String? fotoPath,
  }) async {
    final form = FormData.fromMap({
      'categoria': categoria.name,
      'descripcion': descripcion,
      'lat': lat,
      'lng': lng,
      if (fotoPath != null) 'foto': await MultipartFile.fromFile(fotoPath),
    });
    final res = await _api.dio.post('/incidencias', data: form);
    return Incidencia.fromJson(res.data['data'] as Map<String, dynamic>);
  }
}

/// Datos en memoria para desarrollar la app antes de tener backend.
class MockIncidenciasRepository implements IncidenciasRepository {
  final List<Incidencia> _datos = [
    Incidencia(
      id: '1',
      categoria: Categoria.bache,
      descripcion: 'Bache grande frente al mercado',
      lat: -17.7790,
      lng: -63.1870,
      estado: EstadoIncidencia.enProceso,
      fecha: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Incidencia(
      id: '2',
      categoria: Categoria.luminaria,
      descripcion: 'Poste sin luz en la esquina',
      lat: -17.7880,
      lng: -63.1760,
      estado: EstadoIncidencia.resuelta,
      fecha: DateTime.now().subtract(const Duration(days: 10)),
    ),
    Incidencia(
      id: '3',
      categoria: Categoria.residuos,
      descripcion: 'Basura acumulada junto al canal',
      lat: -17.7755,
      lng: -63.1745,
      estado: EstadoIncidencia.registrada,
      fecha: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  @override
  Future<List<Incidencia>> misIncidencias() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return List.of(_datos.reversed);
  }

  @override
  Future<Incidencia> reportar({
    required Categoria categoria,
    required String descripcion,
    required double lat,
    required double lng,
    String? fotoPath,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final nueva = Incidencia(
      id: '${_datos.length + 1}',
      categoria: categoria,
      descripcion: descripcion,
      lat: lat,
      lng: lng,
      estado: EstadoIncidencia.registrada,
      fecha: DateTime.now(),
      fotoUrl: fotoPath,
    );
    _datos.add(nueva);
    return nueva;
  }
}
