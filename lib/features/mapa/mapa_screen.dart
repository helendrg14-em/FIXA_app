import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../core/tema.dart';
import '../../data/mis_reportes.dart';
import '../../data/modelos.dart';
import '../../data/repositorio.dart';
import '../../ui/comunes.dart';

/// Mapa público: casos abiertos de la ciudad, sin datos personales (ubicación aproximada).
class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final _mapa = MapController();
  CodigoCategoria? _filtro;
  List<PuntoMapa> _puntos = [];
  LatLng? _yo;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final puntos = await context.read<MisReportes>().repositorio.mapa(categoria: _filtro);
      if (mounted) {
        setState(() {
          _puntos = puntos;
          _error = null;
        });
      }
    } on FixaError catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    }
  }

  Future<void> _centrarEnMi() async {
    try {
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) {
        if (mounted) mostrarMensaje(context, 'Activa el permiso de ubicación para centrar el mapa.');
        return;
      }
      final p = await Geolocator.getCurrentPosition();
      final yo = LatLng(p.latitude, p.longitude);
      setState(() => _yo = yo);
      _mapa.move(yo, 16);
    } catch (_) {
      if (mounted) mostrarMensaje(context, 'No se pudo obtener tu ubicación.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapa,
            options: const MapOptions(
              initialCenter: LatLng(AppConfig.latInicial, AppConfig.lngInicial),
              initialZoom: 13.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: AppConfig.userAgent,
              ),
              MarkerLayer(markers: [
                for (final p in _puntos)
                  Marker(
                    point: LatLng(p.latitud, p.longitud),
                    width: 44,
                    height: 54,
                    alignment: Alignment.topCenter,
                    child: Semantics(
                      label: '${p.categoria?.etiqueta ?? 'Caso'}, ${p.estado}',
                      child: _Pin(categoria: p.categoria, cerrado: p.estado == 'Cerrada'),
                    ),
                  ),
                if (_yo != null)
                  Marker(
                    point: _yo!,
                    width: 28,
                    height: 28,
                    child: Container(
                      decoration: BoxDecoration(
                        color: FixaColores.hojaViva,
                        shape: BoxShape.circle,
                        border: Border.all(color: FixaColores.blanco, width: 3),
                        boxShadow: [BoxShadow(color: FixaColores.hojaViva.withValues(alpha: 0.3), blurRadius: 0, spreadRadius: 8)],
                      ),
                    ),
                  ),
              ]),
              const RichAttributionWidget(attributions: [TextSourceAttribution('© OpenStreetMap contributors')]),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
                    decoration: BoxDecoration(
                      color: FixaColores.blanco,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [BoxShadow(color: Color(0x240B2418), blurRadius: 20, offset: Offset(0, 8))],
                    ),
                    child: Row(
                      children: [
                        IconButton(tooltip: 'Volver', onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
                        const Expanded(child: MarcaFixa(subtitulo: 'Casos abiertos de la ciudad')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _Filtro(texto: 'Todo', activo: _filtro == null, onTap: () => _filtrar(null)),
                        for (final c in CodigoCategoria.values)
                          _Filtro(texto: c.corta, icono: iconoDe(c), activo: _filtro == c, onTap: () => _filtrar(c)),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Aviso(texto: _error!, tipo: TipoAviso.error),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Centrar en mi ubicación',
        backgroundColor: FixaColores.blanco,
        foregroundColor: FixaColores.hojaOscura,
        onPressed: _centrarEnMi,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  void _filtrar(CodigoCategoria? c) {
    setState(() => _filtro = c);
    _cargar();
  }
}

class _Filtro extends StatelessWidget {
  const _Filtro({required this.texto, required this.activo, required this.onTap, this.icono});
  final String texto;
  final bool activo;
  final VoidCallback onTap;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: activo,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        avatar: icono == null ? null : Icon(icono, size: 18, color: activo ? FixaColores.blanco : FixaColores.hojaOscura),
        label: Text(texto),
        labelStyle: TextStyle(fontWeight: FontWeight.w700, color: activo ? FixaColores.blanco : FixaColores.tinta),
        backgroundColor: FixaColores.blanco,
        selectedColor: FixaColores.bosque,
        side: BorderSide(color: activo ? FixaColores.bosque : FixaColores.linea),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin({required this.categoria, required this.cerrado});
  final CodigoCategoria? categoria;
  final bool cerrado;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Icon(Icons.location_on, size: 54, color: cerrado ? FixaColores.tinta2 : FixaColores.bosque),
        Positioned(top: 9, child: Icon(iconoDe(categoria), size: 20, color: FixaColores.blanco)),
      ],
    );
  }
}
