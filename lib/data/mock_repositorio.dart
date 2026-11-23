import 'dart:math';

import 'modelos.dart';
import 'repositorio.dart';

/// Datos de ejemplo en memoria, para probar las pantallas sin la API (FIXA_MOCK=true).
class MockRepositorio implements Repositorio {
  final _reportes = <String, (Credenciales, Seguimiento)>{};
  int _correlativo = 417;

  static const _unidades = {
    CodigoCategoria.bache: 'Secretaría Municipal de Obras Públicas',
    CodigoCategoria.alumbrado: 'UOD de Alumbrado Público',
    CodigoCategoria.residuos: 'EMACRUZ',
  };

  static const _tipos = {
    CodigoCategoria.bache: [
      TipoIncidencia('bache', 'Bache'),
      TipoIncidencia('hundimiento', 'Hundimiento'),
      TipoIncidencia('calle_deteriorada', 'Calle deteriorada'),
      TipoIncidencia('otro', 'Otro'),
    ],
    CodigoCategoria.alumbrado: [
      TipoIncidencia('luminaria_apagada', 'Luminaria apagada'),
      TipoIncidencia('luminaria_intermitente', 'Luminaria que parpadea'),
      TipoIncidencia('otro', 'Otro'),
    ],
    CodigoCategoria.residuos: [
      TipoIncidencia('basura_en_calle', 'Basura en la calle'),
      TipoIncidencia(
          'basura_en_espacio_publico', 'Basura en un espacio público'),
      TipoIncidencia('otro', 'Otro'),
    ],
  };

  Future<void> _espera() => Future.delayed(const Duration(milliseconds: 500));

  @override
  Future<List<Categoria>> categorias() async {
    await _espera();
    return [
      for (final c in CodigoCategoria.values)
        Categoria(
            codigo: c,
            nombre: c.etiqueta,
            descripcion: 'Lo arregla ${_unidades[c]}.'),
    ];
  }

  @override
  Future<List<TipoIncidencia>> tipos(CodigoCategoria categoria) async {
    await _espera();
    return _tipos[categoria]!;
  }

  @override
  Future<List<CasoCercano>> cercanos(
      CodigoCategoria categoria, double latitud, double longitud) async {
    await _espera();
    if (categoria != CodigoCategoria.bache) return [];
    return const [
      CasoCercano(
          casoId: 12,
          estado: 'En revisión',
          tipo: 'Bache',
          distanciaMetros: 40,
          vecinosQueReportaron: 2)
    ];
  }

  Credenciales _nuevas(CodigoCategoria categoria) {
    _correlativo++;
    const letras = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final azar = Random();
    final clave =
        List.generate(7, (_) => letras[azar.nextInt(letras.length)]).join();
    return Credenciales(
      codigo: 'FX-2026-${_correlativo.toString().padLeft(6, '0')}',
      clave: '${clave.substring(0, 3)}-${clave.substring(3)}',
      categoria: categoria.etiqueta,
      guardadoEl: DateTime.now(),
    );
  }

  @override
  Future<ReporteCreado> reportar(NuevoReporte reporte) async {
    await _espera();
    final categoria = reporte.categoria!;
    final credenciales = _nuevas(categoria);
    _reportes[credenciales.codigo] = (
      credenciales,
      Seguimiento(
        codigo: credenciales.codigo,
        estado: const EstadoCaso('Recibida'),
        categoria: categoria.etiqueta,
        unidad: _unidades[categoria],
        fechaRegistro: DateTime.now(),
      ),
    );
    return ReporteCreado(
        credenciales: credenciales, unidad: _unidades[categoria]!);
  }

  @override
  Future<ReporteCreado> apoyar(int casoId, NuevoReporte reporte) async {
    final creado = await reportar(reporte);
    return ReporteCreado(
        credenciales: creado.credenciales,
        unidad: creado.unidad,
        esApoyo: true);
  }

  @override
  Future<void> actualizarDispositivo(
      Credenciales credenciales, String token) async {}

  @override
  Future<Seguimiento> seguimiento(Credenciales credenciales) async {
    await _espera();
    final guardado = _reportes[credenciales.codigo];
    if (guardado != null && guardado.$1.clave == credenciales.clave) {
      return guardado.$2;
    }
    if (credenciales.codigo == 'FX-2026-000391') {
      final cierre = DateTime.now().subtract(const Duration(days: 3));
      return Seguimiento(
        codigo: credenciales.codigo,
        estado: const EstadoCaso('Cerrada'),
        categoria: 'Fallas de alumbrado público',
        unidad: 'UOD de Alumbrado Público',
        fechaRegistro: cierre.subtract(const Duration(days: 6)),
        fechaCierre: cierre,
        revisionDisponibleHasta: cierre.add(const Duration(days: 15)),
      );
    }
    throw const FixaError('El código o la clave no coinciden.',
        estadoHttp: 401);
  }

  @override
  Future<String> conformidad(Credenciales credenciales,
      {required bool conforme}) async {
    await _espera();
    return conforme
        ? 'Gracias por confirmar la solución.'
        : 'Registramos que no estás conforme.';
  }

  @override
  Future<String> pedirRevision(Credenciales credenciales, String motivo) async {
    await _espera();
    return 'Recibimos tu solicitud. El supervisor la revisará.';
  }

  @override
  Future<List<PuntoMapa>> mapa({CodigoCategoria? categoria}) async {
    await _espera();
    const puntos = [
      PuntoMapa(
          latitud: -17.779,
          longitud: -63.183,
          categoria: CodigoCategoria.bache,
          estado: 'En revisión'),
      PuntoMapa(
          latitud: -17.788,
          longitud: -63.176,
          categoria: CodigoCategoria.alumbrado,
          estado: 'Programada'),
      PuntoMapa(
          latitud: -17.776,
          longitud: -63.190,
          categoria: CodigoCategoria.residuos,
          estado: 'Recibida'),
      PuntoMapa(
          latitud: -17.772,
          longitud: -63.172,
          categoria: CodigoCategoria.bache,
          estado: 'Recibida'),
    ];
    return [
      for (final p in puntos)
        if (categoria == null || p.categoria == categoria) p
    ];
  }
}
