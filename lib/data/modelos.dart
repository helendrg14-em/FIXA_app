import 'dart:typed_data';

import 'direccion_osm.dart';

/// Las 3 categorías de FIXA (RN-01). El código es el mismo que usa la API.
enum CodigoCategoria {
  bache('Bache o calle dañada', 'Baches'),
  alumbrado('Foco o poste sin luz', 'Luz'),
  residuos('Basura acumulada', 'Basura');

  const CodigoCategoria(this.etiqueta, this.corta);
  final String etiqueta;
  final String corta;

  static CodigoCategoria? desdeApi(String? valor) =>
      CodigoCategoria.values.where((c) => c.name == valor).firstOrNull;
}

class Categoria {
  const Categoria(
      {required this.codigo,
      required this.nombre,
      required this.descripcion,
      this.unidad});

  final CodigoCategoria codigo;
  final String nombre;
  final String descripcion;
  final String? unidad;

  String get unidadVisible =>
      unidad ??
      switch (codigo) {
        CodigoCategoria.bache => 'Obras Públicas',
        CodigoCategoria.alumbrado => 'Alumbrado Público',
        CodigoCategoria.residuos => 'EMACRUZ',
      };

  static Categoria? desdeJson(Map<String, dynamic> json) {
    final codigo = CodigoCategoria.desdeApi(json['codigo'] as String?);
    if (codigo == null) return null;
    return Categoria(
      codigo: codigo,
      nombre: json['nombre'] as String? ?? codigo.etiqueta,
      descripcion: json['descripcion'] as String? ?? '',
      unidad: json['unidad'] as String?,
    );
  }
}

/// Subtipo que la API exige al reportar (por ejemplo, "Luminaria apagada").
class TipoIncidencia {
  const TipoIncidencia(this.valor, this.texto);
  final String valor;
  final String texto;

  bool get esOtro => valor == 'otro';
}

/// Código y clave de un reporte. La clave nunca se muestra en la lista: solo se usa para consultar.
class Credenciales {
  const Credenciales(
      {required this.codigo,
      required this.clave,
      this.categoria,
      this.guardadoEl});

  final String codigo;
  final String clave;
  final String? categoria;
  final DateTime? guardadoEl;

  Map<String, dynamic> aJson() => {
        'codigo': codigo,
        'clave': clave,
        if (categoria != null) 'categoria': categoria,
        if (guardadoEl != null) 'guardadoEl': guardadoEl!.toIso8601String(),
      };

  factory Credenciales.desdeJson(Map<String, dynamic> json) => Credenciales(
        codigo: json['codigo'] as String,
        clave: json['clave'] as String,
        categoria: json['categoria'] as String?,
        guardadoEl: DateTime.tryParse(json['guardadoEl'] as String? ?? ''),
      );
}

/// Respuesta de la API al crear un reporte o un apoyo (R05).
class ReporteCreado {
  const ReporteCreado(
      {required this.credenciales, required this.unidad, this.esApoyo = false});
  final Credenciales credenciales;
  final String unidad;
  final bool esApoyo;
}

/// Etapas que ve el vecino: las mismas 4 del portal y del panel.
enum Etapa {
  recibido('Recibido'),
  enRevision('En revisión'),
  programado('Programado'),
  cerrado('Cerrado');

  const Etapa(this.texto);
  final String texto;
}

/// Estado del caso según la API (EstadoCaso.Texto()) y en qué etapa queda.
class EstadoCaso {
  const EstadoCaso(this.texto);
  final String texto;

  static const _etapas = {
    'Recibida': Etapa.recibido,
    'En revisión': Etapa.enRevision,
    'Asignada': Etapa.enRevision,
    'Programada': Etapa.programado,
    'En atención': Etapa.programado,
    'Pendiente de validación': Etapa.programado,
    'Cerrada': Etapa.cerrado,
  };

  /// `null` cuando el caso terminó sin arreglo de FIXA (rechazado, duplicado o derivado).
  Etapa? get etapa => _etapas[texto];
  bool get terminoSinArreglo => etapa == null;
  bool get cerrado => etapa == Etapa.cerrado;
}

class Seguimiento {
  const Seguimiento({
    required this.codigo,
    required this.estado,
    required this.categoria,
    this.unidad,
    required this.fechaRegistro,
    this.fechaCierre,
    this.ultimaActualizacion,
    this.esApoyo = false,
    this.conformidad,
    this.revisionDisponibleHasta,
    this.revisionEstado,
    this.revisionRespuesta,
  });

  final String codigo;
  final EstadoCaso estado;
  final String categoria;
  final String? unidad;
  final DateTime fechaRegistro;
  final DateTime? fechaCierre;
  final DateTime? ultimaActualizacion;
  final bool esApoyo;
  final bool? conformidad;
  final DateTime? revisionDisponibleHasta;
  final String? revisionEstado;
  final String? revisionRespuesta;

  /// El vecino puede confirmar la solución o pedir revisión hasta 15 días después del cierre (R12).
  bool puedeResponderCierre(DateTime ahora) =>
      estado.cerrado &&
      revisionDisponibleHasta != null &&
      ahora.isBefore(revisionDisponibleHasta!);

  factory Seguimiento.desdeJson(Map<String, dynamic> json) {
    final revision = json['revision'] as Map<String, dynamic>?;
    return Seguimiento(
      codigo: json['codigo'] as String,
      estado: EstadoCaso(json['estado'] as String),
      categoria: json['categoria'] as String? ?? '',
      unidad: json['unidad'] as String?,
      fechaRegistro: DateTime.parse(json['fechaRegistro'] as String),
      fechaCierre: DateTime.tryParse(json['fechaCierre'] as String? ?? ''),
      ultimaActualizacion:
          DateTime.tryParse(json['ultimaActualizacion'] as String? ?? ''),
      esApoyo: json['esApoyo'] as bool? ?? false,
      conformidad: json['conformidad'] as bool?,
      revisionDisponibleHasta:
          DateTime.tryParse(json['revisionDisponibleHasta'] as String? ?? ''),
      revisionEstado: revision?['estado'] as String?,
      revisionRespuesta: revision?['respuesta'] as String?,
    );
  }
}

/// Caso abierto cerca del lugar que se va a reportar (R13).
class CasoCercano {
  const CasoCercano({
    required this.casoId,
    required this.estado,
    required this.tipo,
    required this.distanciaMetros,
    required this.vecinosQueReportaron,
    this.desde,
  });

  final int casoId;
  final String estado;
  final String tipo;
  final int distanciaMetros;
  final int vecinosQueReportaron;
  final DateTime? desde;

  factory CasoCercano.desdeJson(Map<String, dynamic> json) => CasoCercano(
        casoId: (json['casoId'] as num).toInt(),
        estado: json['estado'] as String? ?? '',
        tipo: json['tipo'] as String? ?? '',
        distanciaMetros: (json['distanciaMetros'] as num?)?.toInt() ?? 0,
        vecinosQueReportaron:
            (json['vecinosQueReportaron'] as num?)?.toInt() ?? 1,
        desde: DateTime.tryParse(json['desde'] as String? ?? ''),
      );
}

/// Punto anónimo del mapa público (la API redondea la ubicación).
class PuntoMapa {
  const PuntoMapa(
      {required this.latitud,
      required this.longitud,
      required this.categoria,
      required this.estado});
  final double latitud;
  final double longitud;
  final CodigoCategoria? categoria;
  final String estado;
}

/// Lo que el vecino va llenando en los 3 pasos del reporte.
class NuevoReporte {
  NuevoReporte({required this.claveIdempotencia});

  /// Se genera una vez por reporte: si el envío se corta y se reintenta, la API no lo duplica.
  final String claveIdempotencia;
  CodigoCategoria? categoria;
  Categoria? fichaCategoria;
  TipoIncidencia? tipo;
  int? numeroLuminarias;
  Uint8List? foto;
  double? latitud;
  double? longitud;
  DireccionOsm? direccion;

  String get lugarVisible {
    final nombre = [
      direccion?.titulo,
      direccion?.detalle,
    ].whereType<String>().where((valor) => valor.isNotEmpty).join(' · ');
    if (nombre.isNotEmpty) return nombre;
    return latitud != null && longitud != null
        ? '${latitud!.toStringAsFixed(5)}, ${longitud!.toStringAsFixed(5)}'
        : 'Sin ubicación';
  }

  String descripcion = '';
  String? correo;
  String? tokenDispositivo;
}
