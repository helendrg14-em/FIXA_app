import 'package:dio/dio.dart';

import '../core/config.dart';
import 'modelos.dart';
import 'repositorio.dart';

/// Llama a la API .NET de FIXA (rutas /api/v1/publico, sin cuenta).
class ApiRepositorio implements Repositorio {
  ApiRepositorio({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              // Render gratis se duerme sin tráfico y tarda hasta un minuto en despertar.
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 90),
              headers: {'Accept': 'application/json'},
            ));

  final Dio _dio;

  /// Render gratis se duerme sin tráfico: se despierta la API al abrir la app, para que el
  /// primer envío del vecino no espere. Si falla no pasa nada: es solo un aviso.
  void despertar() => _dio
      .getUri<void>(Uri.parse(AppConfig.apiBaseUrl).resolve('/salud'))
      .ignore();

  /// Pasa cualquier fallo a un mensaje que el vecino entienda.
  Future<T> _llamar<T>(Future<T> Function() pedido) async {
    try {
      return await pedido();
    } on DioException catch (e) {
      throw _traducir(e);
    }
  }

  FixaError _traducir(DioException e) {
    final respuesta = e.response;
    if (respuesta == null) {
      return const FixaError(
          'No hay conexión con FIXA. Revisa tu internet e intenta de nuevo.');
    }
    final estado = respuesta.statusCode;
    final datos = respuesta.data;
    if (estado == 429) {
      return const FixaError(
          'Hiciste muchos intentos seguidos. Espera un minuto y vuelve a probar.',
          estadoHttp: 429);
    }
    if (datos is Map) {
      // ProblemDetails: reglas de negocio en "title"; validación del modelo en "errors".
      final errores = datos['errors'];
      if (errores is Map && errores.isNotEmpty) {
        final mensajes =
            errores.values.expand((v) => v is List ? v : [v]).map((v) => '$v');
        return FixaError(mensajes.join('\n'), estadoHttp: estado);
      }
      final titulo = datos['title'];
      if (titulo is String && titulo.isNotEmpty) {
        return FixaError(titulo, estadoHttp: estado);
      }
    }
    return FixaError('Ocurrió un error inesperado. Intenta de nuevo.',
        estadoHttp: estado);
  }

  @override
  Future<List<Categoria>> categorias() => _llamar(() async {
        final res = await _dio.get<List<dynamic>>('/categorias');
        final lista = <Categoria>[];
        for (final fila in res.data ?? const []) {
          final cat =
              Categoria.desdeJson(Map<String, dynamic>.from(fila as Map));
          if (cat != null) lista.add(cat);
        }
        return lista;
      });

  @override
  Future<List<TipoIncidencia>> tipos(CodigoCategoria categoria) =>
      _llamar(() async {
        final res = await _dio
            .get<List<dynamic>>('/categorias/${categoria.name}/tipos');
        return [
          for (final fila in res.data ?? const [])
            TipoIncidencia(
                (fila as Map)['valor'] as String, fila['texto'] as String),
        ];
      });

  @override
  Future<List<CasoCercano>> cercanos(
          CodigoCategoria categoria, double latitud, double longitud) =>
      _llamar(() async {
        final res =
            await _dio.get<List<dynamic>>('/casos/cercanos', queryParameters: {
          'categoria': categoria.name,
          'latitud': latitud,
          'longitud': longitud,
        });
        return [
          for (final fila in res.data ?? const [])
            CasoCercano.desdeJson(Map<String, dynamic>.from(fila as Map))
        ];
      });

  @override
  Future<ReporteCreado> reportar(NuevoReporte reporte) => _llamar(() async {
        final formulario = FormData.fromMap({
          'Categoria': reporte.categoria!.name,
          'Latitud': reporte.latitud,
          'Longitud': reporte.longitud,
          'TipoIncidencia': reporte.tipo!.valor,
          'Descripcion': reporte.descripcion.trim(),
          if (reporte.direccion case final lugar?) ...{
            if (lugar.titulo.isNotEmpty)
              'Direccion': _acotarDireccion(lugar.titulo),
            if (lugar.detalle.isNotEmpty)
              'Referencia': _acotarDireccion(lugar.detalle),
          },
          if (reporte.numeroLuminarias != null)
            'NumeroLuminarias': reporte.numeroLuminarias,
          if (reporte.correo?.trim().isNotEmpty ?? false)
            'CorreoContacto': reporte.correo!.trim(),
          'ClaveIdempotencia': reporte.claveIdempotencia,
          if (reporte.tokenDispositivo case final token?)
            'TokenDispositivo': token,
          'Fotos': [
            MultipartFile.fromBytes(reporte.foto!,
                filename: 'foto.webp',
                contentType: DioMediaType('image', 'webp'))
          ],
        });
        final res = await _dio.post<Map<String, dynamic>>('/reportes',
            data: formulario);
        return _creado(res, reporte, esApoyo: false);
      });

  @override
  Future<ReporteCreado> apoyar(int casoId, NuevoReporte reporte) =>
      _llamar(() async {
        final res = await _dio
            .post<Map<String, dynamic>>('/casos/$casoId/apoyos', data: {
          'latitud': reporte.latitud,
          'longitud': reporte.longitud,
          'claveIdempotencia': reporte.claveIdempotencia,
          if (reporte.tokenDispositivo case final token?)
            'tokenDispositivo': token,
          if (reporte.correo?.trim().isNotEmpty ?? false)
            'correoContacto': reporte.correo!.trim(),
        });
        return _creado(res, reporte, esApoyo: true);
      });

  ReporteCreado _creado(
      Response<Map<String, dynamic>> res, NuevoReporte reporte,
      {required bool esApoyo}) {
    final datos = res.data ?? const {};
    final clave = datos['clave'] as String?;
    if (clave == null) {
      // 200 sin clave: el mismo reporte ya se había registrado y la clave solo se entrega una vez.
      throw FixaError(
          'Este reporte ya se registró antes con el código ${datos['codigo']}. '
          'Búscalo en Mis reportes.');
    }
    return ReporteCreado(
      credenciales: Credenciales(
        codigo: datos['codigo'] as String,
        clave: clave,
        categoria: reporte.categoria?.etiqueta,
        guardadoEl: DateTime.now(),
      ),
      unidad: datos['unidad'] as String? ?? '',
      esApoyo: esApoyo,
    );
  }

  String _acotarDireccion(String valor) =>
      valor.length > 200 ? valor.substring(0, 200) : valor;
  Map<String, String> _acceso(Credenciales c) =>
      {'codigo': c.codigo.trim(), 'clave': c.clave.trim()};

  @override
  Future<void> actualizarDispositivo(Credenciales credenciales, String token) =>
      _llamar(() async {
        await _dio.patch<void>('/dispositivo', data: {
          ..._acceso(credenciales),
          'tokenDispositivo': token,
        });
      });
  @override
  Future<Seguimiento> seguimiento(Credenciales credenciales) =>
      _llamar(() async {
        final res = await _dio.post<Map<String, dynamic>>('/seguimiento',
            data: _acceso(credenciales));
        return Seguimiento.desdeJson(res.data!);
      });

  @override
  Future<String> conformidad(Credenciales credenciales,
          {required bool conforme}) =>
      _llamar(() async {
        final res = await _dio.post<Map<String, dynamic>>('/conformidad',
            data: {..._acceso(credenciales), 'conforme': conforme});
        return res.data?['mensaje'] as String? ?? 'Listo.';
      });

  @override
  Future<String> pedirRevision(Credenciales credenciales, String motivo) =>
      _llamar(() async {
        final res = await _dio.post<Map<String, dynamic>>('/revisiones',
            data: {..._acceso(credenciales), 'motivo': motivo.trim()});
        return res.data?['mensaje'] as String? ?? 'Recibimos tu solicitud.';
      });

  @override
  Future<List<PuntoMapa>> mapa({CodigoCategoria? categoria}) =>
      _llamar(() async {
        final res = await _dio.get<Map<String, dynamic>>('/mapa',
            queryParameters: {
              if (categoria != null) 'categoria': categoria.name
            });
        final puntos = <PuntoMapa>[];
        for (final f in (res.data?['features'] as List?) ?? const []) {
          final coordenadas =
              ((f as Map)['geometry'] as Map)['coordinates'] as List;
          final propiedades = f['properties'] as Map;
          puntos.add(PuntoMapa(
            longitud: (coordenadas[0] as num).toDouble(),
            latitud: (coordenadas[1] as num).toDouble(),
            categoria:
                CodigoCategoria.desdeApi(propiedades['categoria'] as String?),
            estado: propiedades['estado'] as String? ?? '',
          ));
        }
        return puntos;
      });
}
