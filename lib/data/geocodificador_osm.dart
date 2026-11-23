import 'package:dio/dio.dart';

import '../core/config.dart';
import 'direccion_osm.dart';
import 'repositorio.dart';

class GeocodificadorOsm {
  GeocodificadorOsm({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.geocodificadorOsm,
              headers: {
                'User-Agent': 'FIXA (${AppConfig.userAgent})',
                'Accept-Language': 'es'
              },
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
            ));

  final Dio _dio;
  final _cache = <String, List<DireccionOsm>>{};
  DateTime? _ultimaConsulta;
  bool _consultando = false;

  Future<List<DireccionOsm>> buscar(String texto) async {
    final consulta = texto.trim().replaceAll(RegExp(r'\s+'), ' ');
    final clave = consulta.toLowerCase();
    final guardado = _cache[clave];
    if (guardado != null) return guardado;
    final anterior = _ultimaConsulta;
    if (_consultando ||
        (anterior != null &&
            DateTime.now().difference(anterior) < const Duration(seconds: 1))) {
      throw const FixaError(
          'Espera un segundo antes de buscar otra dirección.');
    }
    _consultando = true;
    _ultimaConsulta = DateTime.now();
    try {
      final res = await _dio.get<List<dynamic>>('/search', queryParameters: {
        'q': '$consulta, ${AppConfig.ciudad}, Bolivia',
        'format': 'jsonv2',
        'addressdetails': 1,
        'countrycodes': 'bo',
        'limit': 5,
      });
      final resultados = [
        for (final fila in res.data ?? const [])
          DireccionOsm.desdeJson(Map<String, dynamic>.from(fila as Map)),
      ];
      if (_cache.length >= 50) _cache.remove(_cache.keys.first);
      return _cache[clave] = resultados;
    } on DioException {
      throw const FixaError(
          'No pudimos buscar la dirección. Intenta de nuevo.');
    } on FormatException {
      throw const FixaError('OpenStreetMap no devolvió una dirección válida.');
    } finally {
      _consultando = false;
    }
  }
}
