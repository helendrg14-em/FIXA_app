import 'modelos.dart';

/// Error que se le puede mostrar al vecino tal cual.
class FixaError implements Exception {
  const FixaError(this.mensaje, {this.estadoHttp});
  final String mensaje;
  final int? estadoHttp;

  bool get credencialesInvalidas => estadoHttp == 401;

  @override
  String toString() => mensaje;
}

/// Todo lo que la app pide a la API. Hay una versión real (ApiRepositorio) y otra de ejemplo
/// (MockRepositorio) para trabajar sin servidor.
abstract class Repositorio {
  Future<List<Categoria>> categorias();
  Future<List<TipoIncidencia>> tipos(CodigoCategoria categoria);
  Future<List<CasoCercano>> cercanos(
      CodigoCategoria categoria, double latitud, double longitud);
  Future<ReporteCreado> reportar(NuevoReporte reporte);
  Future<ReporteCreado> apoyar(int casoId, NuevoReporte reporte);
  Future<void> actualizarDispositivo(Credenciales credenciales, String token);

  Future<Seguimiento> seguimiento(Credenciales credenciales);
  Future<String> conformidad(Credenciales credenciales,
      {required bool conforme});
  Future<String> pedirRevision(Credenciales credenciales, String motivo);
  Future<List<PuntoMapa>> mapa({CodigoCategoria? categoria});
}
