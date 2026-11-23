import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../core/tema.dart';
import '../../data/direccion_osm.dart';
import '../../data/modelos.dart';
import '../../data/repositorio.dart';
import '../../ui/comunes.dart';
import '../../ui/mapa_osm.dart';

class PasoFotoLugar extends StatefulWidget {
  const PasoFotoLugar(
      {super.key,
      required this.reporte,
      required this.alCambiar,
      required this.bloqueado});
  final NuevoReporte reporte;
  final VoidCallback alCambiar;
  final bool bloqueado;

  @override
  State<PasoFotoLugar> createState() => _PasoFotoLugarState();
}

class _PasoFotoLugarState extends State<PasoFotoLugar> {
  static const _maximoFoto = 3 * 1024 * 1024;
  final _selector = ImagePicker();
  bool _procesandoFoto = false;

  Future<void> _tomarFoto() async {
    if (_procesandoFoto) return;
    setState(() => _procesandoFoto = true);
    try {
      final foto = await _selector.pickImage(source: ImageSource.camera);
      if (foto == null || !mounted) return;
      for (final calidad in [80, 65, 50]) {
        final webp = await FlutterImageCompress.compressWithFile(
          foto.path,
          minWidth: 1600,
          minHeight: 1600,
          quality: calidad,
          format: CompressFormat.webp,
        );
        if (!mounted) return;
        if (webp != null &&
            webp.isNotEmpty &&
            webp.lengthInBytes <= _maximoFoto) {
          widget.reporte.foto = webp;
          widget.alCambiar();
          return;
        }
      }
      mostrarMensaje(context,
          'No se pudo preparar una foto de hasta 3 MB. Intenta tomarla otra vez.');
    } on PlatformException {
      if (mounted) {
        mostrarMensaje(
            context, 'No pudimos abrir la cámara o preparar la foto.');
      }
    } on UnsupportedError {
      if (mounted) {
        mostrarMensaje(context, 'Este dispositivo no pudo preparar la foto.');
      }
    } finally {
      if (mounted) setState(() => _procesandoFoto = false);
    }
  }

  Future<void> _editar() async {
    final reporte = widget.reporte;
    final resultado = await Navigator.of(context).push<_Lugar>(
      MaterialPageRoute(
          builder: (_) =>
              _EditarLugar(punto: _punto, direccion: reporte.direccion)),
    );
    if (!mounted || resultado == null) return;
    reporte
      ..latitud = resultado.punto.latitude
      ..longitud = resultado.punto.longitude
      ..direccion = resultado.direccion;
    widget.alCambiar();
  }

  LatLng? get _punto {
    final reporte = widget.reporte;
    return reporte.latitud == null || reporte.longitud == null
        ? null
        : LatLng(reporte.latitud!, reporte.longitud!);
  }

  @override
  Widget build(BuildContext context) {
    final reporte = widget.reporte;
    final punto = _punto;
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
      children: [
        Text('Foto y lugar', style: tituloFixa(23)),
        const SizedBox(height: 16),
        TarjetaFixa(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Foto del problema', style: tituloFixa(17)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: AspectRatio(
                  aspectRatio: 2.45,
                  child: _procesandoFoto
                      ? const Center(child: CircularProgressIndicator())
                      : reporte.foto == null
                          ? const ColoredBox(
                              color: FixaColores.menta,
                              child: Center(
                                  child: Icon(Icons.photo_camera_outlined,
                                      color: FixaColores.hojaOscura, size: 35)),
                            )
                          : Image.memory(reporte.foto!,
                              fit: BoxFit.cover,
                              semanticLabel: 'Foto del problema'),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed:
                    _procesandoFoto || widget.bloqueado ? null : _tomarFoto,
                icon: const Icon(Icons.photo_camera_outlined),
                label:
                    Text(reporte.foto == null ? 'Tomar foto' : 'Cambiar foto'),
              ),
              const SizedBox(height: 6),
              Text('Evita incluir rostros o placas.',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: 15),
        TarjetaFixa(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ubicación', style: tituloFixa(17)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: AspectRatio(
                  aspectRatio: 2.1,
                  child: MapaOsm(
                    key: ValueKey(punto),
                    centro: punto ?? centroFixa,
                    zoom: punto == null ? 14.5 : 16.5,
                    interactivo: false,
                    marcadores: [if (punto != null) _marcador(punto)],
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  const Icon(Icons.map_outlined,
                      color: FixaColores.hojaOscura, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            reporte.direccion?.titulo ??
                                (punto == null
                                    ? 'Selecciona el lugar'
                                    : 'Punto en el mapa'),
                            style: tituloFixa(14)),
                        if (punto != null)
                          Text(
                            reporte.direccion?.detalle ?? reporte.lugarVisible,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: widget.bloqueado ? null : _editar,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Editar'),
                        Icon(Icons.chevron_right, size: 19)
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Marker _marcador(LatLng punto) => Marker(
      point: punto,
      width: 46,
      height: 46,
      child: const _PinLugar(),
    );

class _PinLugar extends StatelessWidget {
  const _PinLugar();

  @override
  Widget build(BuildContext context) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: FixaColores.hojaOscura,
          shape: BoxShape.circle,
          border: Border.all(color: FixaColores.blanco, width: 3),
        ),
        child: const Icon(Icons.location_on_outlined,
            color: FixaColores.blanco, size: 23),
      );
}

class _Lugar {
  const _Lugar(this.punto, this.direccion);
  final LatLng punto;
  final DireccionOsm? direccion;
}

class _EditarLugar extends StatefulWidget {
  const _EditarLugar({this.punto, this.direccion});
  final LatLng? punto;
  final DireccionOsm? direccion;

  @override
  State<_EditarLugar> createState() => _EditarLugarState();
}

class _EditarLugarState extends State<_EditarLugar> {
  final _mapa = MapController();
  late LatLng _punto = widget.punto ?? centroFixa;
  late DireccionOsm? _direccion = widget.direccion;
  bool _ubicando = false;

  @override
  void dispose() {
    _mapa.dispose();
    super.dispose();
  }

  void _elegir(LatLng punto, [DireccionOsm? direccion]) {
    _mapa.move(punto, 17);
    _punto = punto;
    _direccion = direccion;
  }

  Future<void> _ubicar() async {
    if (_ubicando) return;
    setState(() => _ubicando = true);
    try {
      final punto = await miUbicacion();
      if (mounted) _elegir(punto);
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

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Editar ubicación')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
          children: [
            BuscarDireccion(
              etiqueta: 'Buscar dirección o referencia',
              alElegir: (direccion) => _elegir(direccion.punto, direccion),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: SizedBox(
                height: 300,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MapaOsm(
                      centro: _punto,
                      zoom: 16,
                      controlador: _mapa,
                      alTocar: (_, punto) => _elegir(punto),
                      alMover: (camara, gesto) {
                        if (!gesto) return;
                        _punto = camara.center;
                        _direccion = null;
                      },
                    ),
                    const IgnorePointer(child: Center(child: _PinLugar())),
                    Positioned(
                      right: 8,
                      bottom: 28,
                      child: IconButton.filled(
                        tooltip: 'Usar mi ubicación',
                        onPressed: _ubicando ? null : _ubicar,
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
            Text('Mueve el mapa hasta el lugar del problema.',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        bottomNavigationBar: BarraAccion(
          child: BotonPrincipal(
            texto: 'Confirmar ubicación',
            icono: Icons.check,
            onPressed: () => Navigator.pop(context, _Lugar(_punto, _direccion)),
          ),
        ),
      );
}
