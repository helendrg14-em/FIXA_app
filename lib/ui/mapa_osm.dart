import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../core/config.dart';
import '../core/tema.dart';
import '../data/direccion_osm.dart';
import '../data/geocodificador_osm.dart';
import '../data/repositorio.dart';
import 'comunes.dart';

const centroFixa = LatLng(AppConfig.latInicial, AppConfig.lngInicial);

class MapaOsm extends StatelessWidget {
  const MapaOsm({
    super.key,
    required this.centro,
    required this.zoom,
    this.controlador,
    this.interactivo = true,
    this.marcadores = const [],
    this.alMover,
    this.alTocar,
  });

  final LatLng centro;
  final double zoom;
  final MapController? controlador;
  final bool interactivo;
  final List<Marker> marcadores;
  final PositionCallback? alMover;
  final TapCallback? alTocar;

  @override
  Widget build(BuildContext context) => FlutterMap(
        mapController: controlador,
        options: MapOptions(
          initialCenter: centro,
          initialZoom: zoom,
          maxZoom: 19,
          interactionOptions: InteractionOptions(
            flags: interactivo
                ? InteractiveFlag.all & ~InteractiveFlag.rotate
                : InteractiveFlag.none,
          ),
          onPositionChanged: alMover,
          onTap: alTocar,
        ),
        children: [
          TileLayer(
            urlTemplate: AppConfig.tilesOsm,
            userAgentPackageName: AppConfig.userAgent,
            maxNativeZoom: 19,
          ),
          if (marcadores.isNotEmpty) MarkerLayer(markers: marcadores),
          const SimpleAttributionWidget(
            source: Text('© OpenStreetMap',
                style: TextStyle(fontSize: 11, color: FixaColores.tinta2)),
            backgroundColor: Colors.transparent,
          ),
        ],
      );
}

Future<LatLng> miUbicacion() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw const FixaError('Activa el GPS para usar tu ubicación.');
  }
  var permiso = await Geolocator.checkPermission();
  if (permiso == LocationPermission.denied) {
    permiso = await Geolocator.requestPermission();
  }
  if (permiso == LocationPermission.denied ||
      permiso == LocationPermission.deniedForever) {
    throw const FixaError('Activa el permiso de ubicación para usar el GPS.');
  }
  final posicion = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
    accuracy: LocationAccuracy.high,
    timeLimit: Duration(seconds: 15),
  ));
  return LatLng(posicion.latitude, posicion.longitude);
}

class BuscarDireccion extends StatefulWidget {
  const BuscarDireccion(
      {super.key, required this.alElegir, this.etiqueta = 'Buscar dirección'});
  final ValueChanged<DireccionOsm> alElegir;
  final String etiqueta;

  @override
  State<BuscarDireccion> createState() => _BuscarDireccionState();
}

class _BuscarDireccionState extends State<BuscarDireccion> {
  final _texto = TextEditingController();
  List<DireccionOsm> _resultados = [];
  String? _aviso;
  bool _buscando = false;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    if (_buscando) return;
    if (_texto.text.trim().length < 3) {
      setState(() => _aviso = 'Escribe al menos 3 caracteres.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _buscando = true;
      _aviso = null;
      _resultados = [];
    });
    try {
      final resultados =
          await context.read<GeocodificadorOsm>().buscar(_texto.text);
      if (!mounted) return;
      setState(() {
        _resultados = resultados;
        if (resultados.isEmpty) _aviso = 'No encontramos esa dirección.';
      });
    } on FixaError catch (error) {
      if (mounted) setState(() => _aviso = error.mensaje);
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _texto,
            readOnly: _buscando,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _buscar(),
            onChanged: (_) => setState(() {
              _aviso = null;
              _resultados = [];
            }),
            decoration: InputDecoration(
              hintText: widget.etiqueta,
              prefixIcon: IconButton(
                tooltip: 'Buscar',
                onPressed: _buscando ? null : _buscar,
                icon: const Icon(Icons.search),
              ),
            ),
          ),
          if (_buscando) const LinearProgressIndicator(),
          if (_aviso case final aviso?)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(aviso, style: Theme.of(context).textTheme.bodySmall),
            ),
          if (_resultados.isNotEmpty) ...[
            const SizedBox(height: 6),
            TarjetaFixa(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final resultado in _resultados)
                    ListTile(
                      leading: const Icon(Icons.place_outlined),
                      title: Text(resultado.titulo),
                      subtitle: Text(resultado.detalle,
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      onTap: () {
                        _texto.text = resultado.titulo;
                        setState(() => _resultados = []);
                        widget.alElegir(resultado);
                      },
                    ),
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child:
                        Text('© OpenStreetMap', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
}
