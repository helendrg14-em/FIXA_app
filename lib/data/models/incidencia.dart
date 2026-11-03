/// Ciclo de vida de una incidencia (trazabilidad para el ciudadano).
enum EstadoIncidencia {
  registrada('Registrada'),
  enProceso('En proceso'),
  resuelta('Resuelta'),
  confirmada('Confirmada');

  const EstadoIncidencia(this.etiqueta);
  final String etiqueta;

  static EstadoIncidencia fromApi(String valor) => switch (valor) {
        'en_proceso' => enProceso,
        'resuelta' => resuelta,
        'confirmada' => confirmada,
        _ => registrada,
      };
}

/// Tipo de problema; cada uno se deriva a una unidad municipal.
enum Categoria {
  bache('Bache / deterioro vial', 'Obras Públicas'),
  luminaria('Luminaria dañada', 'Alumbrado Público'),
  residuos('Acumulación de residuos', 'EMACRUZ'),
  otro('Otro', 'Subalcaldía');

  const Categoria(this.etiqueta, this.unidad);
  final String etiqueta;
  final String unidad;

  static Categoria fromApi(String valor) =>
      Categoria.values.firstWhere((c) => c.name == valor, orElse: () => otro);
}

class Incidencia {
  Incidencia({
    required this.id,
    required this.categoria,
    required this.descripcion,
    required this.lat,
    required this.lng,
    required this.estado,
    required this.fecha,
    this.fotoUrl,
  });

  final String id;
  final Categoria categoria;
  final String descripcion;
  final double lat;
  final double lng;
  final EstadoIncidencia estado;
  final DateTime fecha;

  /// URL en el servidor, o ruta local cuando se usa el modo mock.
  final String? fotoUrl;

  String get fechaTexto =>
      '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

  factory Incidencia.fromJson(Map<String, dynamic> json) => Incidencia(
        id: json['id'].toString(),
        categoria: Categoria.fromApi(json['categoria'] as String),
        descripcion: json['descripcion'] as String? ?? '',
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        estado: EstadoIncidencia.fromApi(json['estado'] as String),
        fecha: DateTime.parse(json['created_at'] as String),
        fotoUrl: json['foto_url'] as String?,
      );
}
