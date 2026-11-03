import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../core/tema.dart';
import '../../data/models/incidencia.dart';
import 'estado_chip.dart';
import 'incidencias_provider.dart';

/// Pantalla principal: mapa de Santa Cruz con los reportes del usuario.
class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<IncidenciasProvider>().cargar());
  }

  void _verDetalle(Incidencia i) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(iconoDe(i.categoria), color: FixaColores.verde),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(i.categoria.etiqueta,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  ),
                  EstadoChip(i.estado),
                ],
              ),
              if (i.descripcion.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(i.descripcion),
              ],
              const SizedBox(height: 12),
              Text('${i.categoria.unidad} · ${i.fechaTexto}',
                  style: const TextStyle(color: FixaColores.textoSuave)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final incidencias = context.watch<IncidenciasProvider>().items;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    options: const MapOptions(
                      initialCenter: LatLng(AppConfig.latInicial, AppConfig.lngInicial),
                      initialZoom: 14,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: AppConfig.userAgent,
                      ),
                      MarkerLayer(
                        markers: [
                          for (final i in incidencias)
                            Marker(
                              point: LatLng(i.lat, i.lng),
                              width: 48,
                              height: 48,
                              alignment: Alignment.topCenter,
                              child: _Pin(i, onTap: () => _verDetalle(i)),
                            ),
                        ],
                      ),
                      const RichAttributionWidget(
                        attributions: [TextSourceAttribution('© OpenStreetMap contributors')],
                      ),
                    ],
                  ),
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
                        child: _Encabezado(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _PanelAcciones(cantidad: incidencias.length),
          ],
        ),
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x220D2C22), blurRadius: 12, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Image.asset('assets/logo_simbolo.png', height: 38, excludeFromSemantics: true),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FIXA',
                    style: TextStyle(
                        fontSize: 20,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        color: FixaColores.oscuro)),
                Text('Reporte y gestión ciudadana',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: FixaColores.textoSuave)),
              ],
            ),
          ),
          if (AppConfig.usarMock)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: FixaColores.naranjaClaro,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Demo',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: FixaColores.naranjaOscuro)),
            ),
        ],
      ),
    );
  }
}

/// Marcador con el ícono del problema y el color de su estado.
class _Pin extends StatelessWidget {
  const _Pin(this.incidencia, {required this.onTap});
  final Incidencia incidencia;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${incidencia.categoria.etiqueta}, ${incidencia.estado.etiqueta}',
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Icon(Icons.location_on, size: 48, color: EstadoChip.colorDe(incidencia.estado)),
            Positioned(
              top: 8,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Icon(iconoDe(incidencia.categoria),
                    size: 14, color: EstadoChip.colorDe(incidencia.estado)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelAcciones extends StatelessWidget {
  const _PanelAcciones({required this.cantidad});
  final int cantidad;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x220D2C22), blurRadius: 12, offset: Offset(0, -3))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton.icon(
                onPressed: () => context.push('/reportar'),
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Reportar un problema'),
              ),
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: () => context.push('/mis-reportes'),
                icon: const Icon(Icons.list_alt),
                label: Text('Mis reportes ($cantidad)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
