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
      if (mounted && solicitud == _consulta) setState(() => _puntos = puntos);
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
                            width: 48,
                            height: 52,
                            alignment: Alignment.topCenter,
                            child: _PinReporte(
                              punto: punto,
                              onTap: () =>
                                  setState(() => _seleccionado = punto),
                            ),
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
            if (_seleccionado case final seleccionado?)
              TarjetaFixa(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(seleccionado.categoria?.etiqueta ?? 'Reporte',
                        style: tituloFixa(16)),
                    const SizedBox(height: 6),
                    EstadoFixa(EstadoCaso(seleccionado.estado)),
                  ],
                ),
              )
            else
              Text('Toca un pin para ver el reporte.',
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
    final color = switch (punto.categoria) {
      CodigoCategoria.bache => FixaColores.tinta2,
      CodigoCategoria.alumbrado => FixaColores.sol,
      CodigoCategoria.residuos || null => FixaColores.hojaOscura,
    };
    final frente = punto.categoria == CodigoCategoria.alumbrado
        ? FixaColores.bosque
        : FixaColores.blanco;
    return Semantics(
      label: punto.categoria?.etiqueta ?? 'Reporte',
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            const Icon(Icons.location_on, size: 50, color: FixaColores.blanco),
            Positioned(
                top: 2, child: Icon(Icons.location_on, size: 45, color: color)),
            Positioned(
                top: 8,
                child: Icon(iconoDe(punto.categoria), size: 19, color: frente)),
          ],
        ),
      ),
    );
  }
}
