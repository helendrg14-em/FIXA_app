import 'package:latlong2/latlong.dart';

class DireccionOsm {
  const DireccionOsm(
      {required this.punto, required this.titulo, required this.detalle});

  final LatLng punto;
  final String titulo;
  final String detalle;

  factory DireccionOsm.desdeJson(Map<String, dynamic> json) {
    final direccion = json['address'] as Map<String, dynamic>? ?? const {};
    final titulo = [
      direccion['road'],
      direccion['pedestrian'],
      json['name'],
    ].whereType<String>().where((valor) => valor.isNotEmpty).firstOrNull;
    final detalle = [
      direccion['city_district'],
      direccion['suburb'],
      direccion['neighbourhood'],
    ]
        .whereType<String>()
        .where((valor) => valor.isNotEmpty)
        .toSet()
        .join(' · ');
    final nombre = json['display_name'] as String? ?? '';
    return DireccionOsm(
      punto: LatLng(double.parse(json['lat'] as String),
          double.parse(json['lon'] as String)),
      titulo: titulo ?? nombre.split(',').first,
      detalle: detalle.isEmpty ? nombre : detalle,
    );
  }
}
