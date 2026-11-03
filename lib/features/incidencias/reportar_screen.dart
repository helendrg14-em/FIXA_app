import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/tema.dart';
import '../../data/models/incidencia.dart';
import 'estado_chip.dart';
import 'incidencias_provider.dart';

/// Formulario de reporte: foto + ubicación GPS + categoría.
class ReportarScreen extends StatefulWidget {
  const ReportarScreen({super.key});

  @override
  State<ReportarScreen> createState() => _ReportarScreenState();
}

class _ReportarScreenState extends State<ReportarScreen> {
  final _descripcion = TextEditingController();
  Categoria _categoria = Categoria.bache;
  XFile? _foto;
  Position? _posicion;
  String? _errorUbicacion;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _obtenerUbicacion();
  }

  @override
  void dispose() {
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _obtenerUbicacion() async {
    setState(() => _errorUbicacion = null);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw 'Activa el GPS del celular';
      }
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        throw 'Se necesita permiso de ubicación para reportar';
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) setState(() => _posicion = pos);
    } catch (e) {
      if (mounted) setState(() => _errorUbicacion = e.toString());
    }
  }

  Future<void> _tomarFoto() async {
    final foto = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
      imageQuality: 70,
    );
    if (foto != null) setState(() => _foto = foto);
  }

  Future<void> _enviar() async {
    final pos = _posicion;
    if (pos == null || _foto == null) return;
    setState(() => _enviando = true);
    try {
      await context.read<IncidenciasProvider>().reportar(
            categoria: _categoria,
            descripcion: _descripcion.text.trim(),
            lat: pos.latitude,
            lng: pos.longitude,
            fotoPath: _foto!.path,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Reporte enviado a ${_categoria.unidad}'),
      ));
      context.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _enviando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo enviar. Intenta de nuevo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final listo = _foto != null && _posicion != null && !_enviando;
    final falta = _foto == null
        ? 'Falta tomar la foto'
        : _posicion == null
            ? 'Falta obtener la ubicación'
            : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo reporte')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        children: [
          const _Titulo('1. Toma una foto del problema'),
          _CuadroFoto(foto: _foto, onTap: _tomarFoto),
          const SizedBox(height: 10),
          _EstadoUbicacion(
            posicion: _posicion,
            error: _errorUbicacion,
            onActualizar: _obtenerUbicacion,
          ),

          const _Titulo('2. ¿Qué problema es?'),
          for (final c in Categoria.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _OpcionCategoria(
                categoria: c,
                elegida: c == _categoria,
                onTap: () => setState(() => _categoria = c),
              ),
            ),

          const _Titulo('3. Cuéntanos más (opcional)'),
          TextField(
            controller: _descripcion,
            maxLines: 3,
            maxLength: 300,
            decoration: const InputDecoration(
              hintText: 'Ej: bache profundo en el carril derecho',
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: FixaColores.borde)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (falta != null) ...[
                  Text(falta, style: const TextStyle(color: FixaColores.textoSuave)),
                  const SizedBox(height: 8),
                ],
                FilledButton.icon(
                  onPressed: listo ? _enviar : null,
                  icon: _enviando
                      ? const SizedBox.square(
                          dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send),
                  label: const Text('Enviar reporte'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 10),
      child: Text(texto, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
    );
  }
}

class _CuadroFoto extends StatelessWidget {
  const _CuadroFoto({required this.foto, required this.onTap});
  final XFile? foto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foto = this.foto;
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Material(
        color: FixaColores.verdeClaro,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: foto == null
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_camera, size: 48, color: FixaColores.verde),
                    SizedBox(height: 8),
                    Text('Toca para abrir la cámara',
                        style: TextStyle(fontWeight: FontWeight.w600, color: FixaColores.pino)),
                  ],
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(File(foto.path), fit: BoxFit.cover),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: FixaColores.oscuro.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Tomar otra',
                            style: TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _EstadoUbicacion extends StatelessWidget {
  const _EstadoUbicacion({
    required this.posicion,
    required this.error,
    required this.onActualizar,
  });
  final Position? posicion;
  final String? error;
  final VoidCallback onActualizar;

  @override
  Widget build(BuildContext context) {
    final pos = posicion;
    final hayError = pos == null && error != null;
    final color = hayError ? FixaColores.naranjaOscuro : FixaColores.verde;

    return Container(
      padding: const EdgeInsets.only(left: 14, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: hayError ? FixaColores.naranjaClaro : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: hayError ? FixaColores.naranja : FixaColores.borde),
      ),
      child: Row(
        children: [
          Icon(pos != null ? Icons.location_on : Icons.location_searching, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: pos != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ubicación lista',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                          '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}',
                          style: const TextStyle(fontSize: 12, color: FixaColores.textoSuave)),
                    ],
                  )
                : Text(error ?? 'Buscando tu ubicación…'),
          ),
          IconButton(
            tooltip: 'Actualizar ubicación',
            icon: const Icon(Icons.refresh),
            onPressed: onActualizar,
          ),
        ],
      ),
    );
  }
}

class _OpcionCategoria extends StatelessWidget {
  const _OpcionCategoria({
    required this.categoria,
    required this.elegida,
    required this.onTap,
  });
  final Categoria categoria;
  final bool elegida;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: elegida,
      button: true,
      child: Material(
        color: elegida ? FixaColores.verdeClaro : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: elegida ? FixaColores.verde : FixaColores.borde,
            width: elegida ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(iconoDe(categoria),
                    color: elegida ? FixaColores.verde : FixaColores.textoSuave),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(categoria.etiqueta,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('Lo atiende: ${categoria.unidad}',
                          style: const TextStyle(fontSize: 12, color: FixaColores.textoSuave)),
                    ],
                  ),
                ),
                if (elegida) const Icon(Icons.check_circle, color: FixaColores.verde),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
