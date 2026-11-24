import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/tema.dart';
import '../../data/direccion_osm.dart';
import '../../data/mis_reportes.dart';
import '../../data/modelos.dart';
import '../../data/repositorio.dart';
import '../../ui/comunes.dart';
import '../../ui/mapa_osm.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final _mapa = MapController();
  CodigoCategoria? _filtro;
  List<PuntoMapa> _puntos = [];
  PuntoMapa? _seleccionado;
  LatLng? _marcado;
  String? _error;
  bool _cargando = false;
  bool _ubicando = false;
  int _consulta = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _mapa.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final solicitud = ++_consulta;
    setState(() {
      _cargando = true;
      _error = null;
      _seleccionado = null;
    });
    try {
      final puntos = await context
          .read<MisReportes>()
          .repositorio
          .mapa(categoria: _filtro);
      // El vecino solo ve los problemas abiertos: los casos cerrados no aparecen en el mapa.
      final abiertos = [
        for (final punto in puntos)
          if (punto.estado != 'Cerrada') punto
      ];
      if (mounted && solicitud == _consulta) {
        setState(() => _puntos = abiertos);
      }
    } on FixaError catch (error) {
      if (mounted && solicitud == _consulta) {
        setState(() => _error = error.mensaje);
      }
    } finally {
      if (mounted && solicitud == _consulta) setState(() => _cargando = false);
    }
  }

  void _centrar(LatLng punto) {
    setState(() => _marcado = punto);
    _mapa.move(punto, 16);
  }

  Future<void> _centrarEnMi() async {
    if (_ubicando) return;
    setState(() => _ubicando = true);
    try {
      final punto = await miUbicacion();
      if (mounted) _centrar(punto);
    } catch (error) {
      if (mounted) {
        mostrarMensaje(
            context,
            error is FixaError
                ? error.mensaje
                : 'No se pudo obtener tu ubicación.');
      }
    } finally {
      if (mounted) setState(() => _ubicando = false);
    }
  }

  /// Abre el globo del reporte y baja un poco el mapa para que el globo entre completo.
  void _seleccionar(PuntoMapa punto) {
    setState(() => _seleccionado = punto);
    _mapa.move(LatLng(punto.latitud, punto.longitud), _mapa.camera.zoom,
        offset: const Offset(0, 90));
  }

  void _filtrar(CodigoCategoria? categoria) {
    if (_filtro == categoria) return;
    setState(() {
      _filtro = categoria;
      _puntos = [];
    });
    _cargar();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: const Text('Mapa de reportes'),
            automaticallyImplyLeading: false),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 11, 16, 23),
          children: [
            BuscarDireccion(
                alElegir: (DireccionOsm direccion) =>
                    _centrar(direccion.punto)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 5,
              children: [
                FiltroFixa(
                    texto: 'Todos',
                    activo: _filtro == null,
                    onTap: () => _filtrar(null)),
                for (final c in CodigoCategoria.values)
                  FiltroFixa(
                      texto: c.corta,
                      activo: _filtro == c,
                      onTap: () => _filtrar(c)),
              ],
            ),
            const SizedBox(height: 9),
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: SizedBox(
                height: (MediaQuery.sizeOf(context).height * 0.445)
                    .clamp(240.0, 520.0),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MapaOsm(
                      centro: centroFixa,
                      zoom: 14.5,
                      controlador: _mapa,
                      alTocar: (_, __) {
                        if (_seleccionado != null) {
                          setState(() => _seleccionado = null);
                        }
                      },
                      marcadores: [
                        for (final punto in _puntos)
                          Marker(
                            point: LatLng(punto.latitud, punto.longitud),
                            width: 32,
                            height: 42,
                            alignment: Alignment.topCenter,
                            child: _PinReporte(
                              punto: punto,
                              onTap: () => _seleccionar(punto),
                            ),
                          ),
                        // Globo con la foto y el estado, encima del pin tocado.
                        if (_seleccionado case final seleccionado?)
                          Marker(
                            point: LatLng(
                                seleccionado.latitud, seleccionado.longitud),
                            width: _GloboReporte.ancho,
                            height: _GloboReporte.alto,
                            alignment: Alignment.topCenter,
                            child: _GloboReporte(punto: seleccionado),
                          ),
                        if (_marcado case final marcado?)
                          Marker(
                            point: marcado,
                            width: 22,
                            height: 22,
                            child: const Icon(Icons.adjust,
                                color: FixaColores.azul),
                          ),
                      ],
                    ),
                    if (_cargando)
                      const Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: LinearProgressIndicator()),
                    Positioned(
                      right: 8,
                      bottom: 28,
                      child: IconButton.filled(
                        tooltip: 'Centrar en mi ubicación',
                        onPressed: _ubicando ? null : _centrarEnMi,
                        style: IconButton.styleFrom(
                            backgroundColor: FixaColores.blanco,
                            foregroundColor: FixaColores.hojaOscura),
                        icon: _ubicando
                            ? const SizedBox.square(
                                dimension: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.my_location),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text('Toca un pin para ver la foto y el estado del reporte.',
                style: Theme.of(context).textTheme.bodySmall),
            if (_error case final error?) ...[
              const SizedBox(height: 8),
              Aviso(texto: error, tipo: TipoAviso.error),
              TextButton(
                  onPressed: _cargar,
                  child: const Text('Volver a cargar reportes')),
            ],
            const SizedBox(height: 12),
            BotonPrincipal(
              texto: 'Reportar un problema',
              icono: Icons.add,
              onPressed: () => context.push('/reportar'),
            ),
          ],
        ),
      );
}

class _PinReporte extends StatelessWidget {
  const _PinReporte({required this.punto, required this.onTap});
  final PuntoMapa punto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Los mismos colores que el mapa del panel web.
    final color = switch (punto.categoria) {
      CodigoCategoria.bache => const Color(0xFFD0600B),
      CodigoCategoria.alumbrado => const Color(0xFFC99A06),
      CodigoCategoria.residuos => const Color(0xFF1F7D47),
      null => const Color(0xFF677A64),
    };
    return Semantics(
      label: punto.categoria?.etiqueta ?? 'Reporte',
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: CustomPaint(painter: _PinGota(color)),
      ),
    );
  }
}

/// Pin en forma de gota con un círculo blanco al centro. La punta queda abajo, sobre el punto.
class _PinGota extends CustomPainter {
  const _PinGota(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Se dibuja en una caja de 24 x 32 y se escala al tamaño del marcador.
    final escala = size.height / 34;
    canvas
      ..translate((size.width - 24 * escala) / 2, escala)
      ..scale(escala);
    final gota = ui.Path()
      ..moveTo(12, 32)
      ..cubicTo(12, 32, 0, 20.8, 0, 11.9)
      ..cubicTo(0, 5.3, 5.4, 0, 12, 0)
      ..cubicTo(18.6, 0, 24, 5.3, 24, 11.9)
      ..cubicTo(24, 20.8, 12, 32, 12, 32)
      ..close();
    canvas
      ..drawShadow(gota, Colors.black, 2, false)
      ..drawPath(gota, Paint()..color = color)
      ..drawPath(
          gota,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5)
      ..drawCircle(const Offset(12, 11.9), 4.6, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_PinGota anterior) => anterior.color != color;
}

/// Miniatura de la foto del reporte. Mientras carga, o si no hay foto, muestra un ícono.
class _FotoReporte extends StatelessWidget {
  const _FotoReporte({required this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    const vacio = ColoredBox(
      color: FixaColores.papel,
      child:
          Center(child: Icon(Icons.image_outlined, color: FixaColores.tinta2)),
    );
    return url == null
        ? vacio
        : Image.network(
            url!,
            fit: BoxFit.cover,
            semanticLabel: 'Foto del problema',
            loadingBuilder: (_, imagen, progreso) =>
                progreso == null ? imagen : vacio,
            errorBuilder: (_, __, ___) => vacio,
          );
  }
}

/// Globo que aparece sobre el pin tocado, como en una app de mapas: foto arriba,
/// categoría y estado abajo, con una punta que señala el pin.
class _GloboReporte extends StatelessWidget {
  const _GloboReporte({required this.punto});
  final PuntoMapa punto;

  static const ancho = 220.0;
  static const _altoFoto = 112.0;
  static const _altoTexto = 74.0;
  static const _punta = 10.0;
  // Espacio para que el globo quede encima del pin (que mide 42 px de alto).
  static const _sobrePin = 44.0;
  static const alto = _altoFoto + _altoTexto + _punta + _sobrePin;

  @override
  Widget build(BuildContext context) => GestureDetector(
        // Tocar el globo no debe cerrarlo (el toque al mapa sí lo cierra).
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.only(bottom: _sobrePin),
          child: Column(
            children: [
              Material(
                color: FixaColores.blanco,
                elevation: 6,
                borderRadius: BorderRadius.circular(14),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: ancho,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: _altoFoto,
                        width: ancho,
                        child: _FotoReporte(url: punto.miniatura),
                      ),
                      SizedBox(
                        height: _altoTexto,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(punto.categoria?.etiqueta ?? 'Reporte',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: tituloFixa(15)),
                              EstadoFixa(EstadoCaso(punto.estado)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              CustomPaint(
                size: const Size(20, _punta),
                painter: _PuntaGlobo(),
              ),
            ],
          ),
        ),
      );
}

/// Triángulo blanco bajo el globo que apunta al pin.
class _PuntaGlobo extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final punta = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(punta, Paint()..color = FixaColores.blanco);
  }

  @override
  bool shouldRepaint(_PuntaGlobo anterior) => false;
}
