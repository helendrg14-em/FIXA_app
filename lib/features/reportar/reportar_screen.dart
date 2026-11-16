import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../core/tema.dart';
import '../../data/mis_reportes.dart';
import '../../data/modelos.dart';
import '../../data/repositorio.dart';
import '../../ui/comunes.dart';
import 'alerta_cercano.dart';

/// Reportar en 3 pasos (R04): qué problema → foto y lugar → detalle y envío.
class ReportarScreen extends StatefulWidget {
  const ReportarScreen({super.key});

  @override
  State<ReportarScreen> createState() => _ReportarScreenState();
}

String _nuevaClaveIdempotencia() {
  final azar = Random.secure();
  return List.generate(32, (_) => azar.nextInt(16).toRadixString(16)).join();
}

class _ReportarScreenState extends State<ReportarScreen> {
  final _reporte = NuevoReporte(claveIdempotencia: _nuevaClaveIdempotencia());
  int _paso = 1;
  bool _enviando = false;
  bool _guardarEnCelular = true;

  Repositorio get _repo => context.read<MisReportes>().repositorio;

  void _atras() {
    if (_paso == 1) {
      context.pop();
    } else {
      setState(() => _paso--);
    }
  }

  /// Antes de pasar al detalle, revisa si ya hay un caso abierto igual cerca (R13).
  Future<void> _continuarDesdeLugar() async {
    setState(() => _enviando = true);
    List<CasoCercano> cercanos = [];
    try {
      cercanos = await _repo.cercanos(_reporte.categoria!, _reporte.latitud!, _reporte.longitud!);
    } on FixaError {
      // Si la consulta falla, se sigue sin la alerta: no debe impedir reportar.
    }
    if (!mounted) return;
    setState(() => _enviando = false);
    if (cercanos.isEmpty) {
      setState(() => _paso = 3);
      return;
    }
    final apoyar = await mostrarAlertaCercano(context, cercanos.first, _reporte.categoria!);
    if (!mounted || apoyar == null) return;
    if (apoyar) {
      await _enviar(() => _repo.apoyar(cercanos.first.casoId, _reporte));
    } else {
      setState(() => _paso = 3);
    }
  }

  Future<void> _enviar(Future<ReporteCreado> Function() pedido) async {
    setState(() => _enviando = true);
    final mis = context.read<MisReportes>();
    try {
      var creado = await pedido();
      if (_guardarEnCelular) await mis.guardar(creado.credenciales);
      // La API no devuelve la unidad al crear: se consulta para mostrar quién lo recibió.
      final estado = await mis.actualizarUno(creado.credenciales);
      if (estado?.unidad != null) {
        creado = ReporteCreado(credenciales: creado.credenciales, unidad: estado!.unidad!, esApoyo: creado.esApoyo);
      }
      if (!mounted) return;
      context.pushReplacement('/enviado', extra: (creado, _guardarEnCelular));
    } on FixaError catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      mostrarMensaje(context, e.mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (contenido, boton) = switch (_paso) {
      1 => (
          _PasoCategoria(reporte: _reporte, alCambiar: () => setState(() {})),
          BotonPrincipal(
            texto: 'Continuar',
            onPressed: _reporte.categoria != null &&
                    _reporte.tipo != null &&
                    (_reporte.categoria != CodigoCategoria.alumbrado || _reporte.tipo!.esOtro || _reporte.numeroLuminarias != null)
                ? () => setState(() => _paso = 2)
                : null,
          ),
        ),
      2 => (
          _PasoFotoLugar(reporte: _reporte, alCambiar: () => setState(() {})),
          BotonPrincipal(
            texto: 'Continuar',
            cargando: _enviando,
            onPressed: _reporte.foto != null && _reporte.latitud != null ? _continuarDesdeLugar : null,
          ),
        ),
      _ => (
          _PasoDetalle(
            reporte: _reporte,
            guardar: _guardarEnCelular,
            alCambiarGuardar: (v) => setState(() => _guardarEnCelular = v),
            alCambiar: () => setState(() {}),
          ),
          BotonPrincipal(
            texto: 'Enviar reporte',
            cargando: _enviando,
            onPressed: _reporte.descripcion.trim().isNotEmpty ? () => _enviar(() => _repo.reportar(_reporte)) : null,
          ),
        ),
    };

    return PopScope(
      canPop: _paso == 1 && !_enviando,
      onPopInvokedWithResult: (salio, _) {
        if (!salio && !_enviando) _atras();
      },
      child: Scaffold(
        appBar: EncabezadoPaso(paso: _paso, onAtras: _enviando ? () {} : _atras),
        body: AnimatedSwitcher(duration: const Duration(milliseconds: 200), child: KeyedSubtree(key: ValueKey(_paso), child: contenido)),
        bottomNavigationBar: BarraAccion(child: boton),
      ),
    );
  }
}

// ---------------------------------------------------------------- Paso 1: qué problema

class _PasoCategoria extends StatefulWidget {
  const _PasoCategoria({required this.reporte, required this.alCambiar});
  final NuevoReporte reporte;
  final VoidCallback alCambiar;

  @override
  State<_PasoCategoria> createState() => _PasoCategoriaState();
}

class _PasoCategoriaState extends State<_PasoCategoria> {
  List<Categoria>? _categorias;
  List<TipoIncidencia>? _tipos;
  String? _error;

  Repositorio get _repo => context.read<MisReportes>().repositorio;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
    if (widget.reporte.categoria != null) _cargarTipos(widget.reporte.categoria!);
  }

  Future<void> _cargarCategorias() async {
    try {
      final c = await _repo.categorias();
      if (mounted) {
        setState(() {
          _categorias = c;
          _error = null;
        });
      }
    } on FixaError catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    }
  }

  Future<void> _cargarTipos(CodigoCategoria c) async {
    setState(() => _tipos = null);
    try {
      final t = await _repo.tipos(c);
      if (mounted && widget.reporte.categoria == c) setState(() => _tipos = t);
    } on FixaError catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    }
  }

  void _elegir(CodigoCategoria c) {
    if (widget.reporte.categoria == c) return;
    widget.reporte
      ..categoria = c
      ..tipo = null
      ..numeroLuminarias = null;
    widget.alCambiar();
    _cargarTipos(c);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reporte;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      children: [
        Text('¿Qué problema quieres reportar?', style: tituloFixa(30)),
        const SizedBox(height: 8),
        Text('Cada uno llega directo a la unidad que lo arregla.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: FixaColores.tinta2)),
        const SizedBox(height: 18),
        if (_error != null) ...[Aviso(texto: _error!, tipo: TipoAviso.error), const SizedBox(height: 12)],
        if (_categorias == null && _error == null) const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
        for (final c in _categorias ?? const <Categoria>[]) ...[
          _OpcionCategoria(categoria: c, elegida: r.categoria == c.codigo, onTap: () => _elegir(c.codigo)),
          const SizedBox(height: 12),
        ],
        if (r.categoria != null) ...[
          const SizedBox(height: 8),
          Text('¿Qué tipo es?', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          if (_tipos == null)
            const LinearProgressIndicator()
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in _tipos!)
                  ChoiceChip(
                    label: Text(t.texto),
                    selected: r.tipo?.valor == t.valor,
                    onSelected: (_) {
                      r.tipo = t;
                      if (t.esOtro) r.numeroLuminarias = null;
                      widget.alCambiar();
                      setState(() {});
                    },
                    labelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: r.tipo?.valor == t.valor ? FixaColores.blanco : FixaColores.tinta,
                        fontSize: 16),
                    selectedColor: FixaColores.hojaOscura,
                    backgroundColor: FixaColores.blanco,
                    showCheckmark: false,
                    side: BorderSide(color: r.tipo?.valor == t.valor ? FixaColores.hojaOscura : FixaColores.linea),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
              ],
            ),
          if (r.categoria == CodigoCategoria.alumbrado && r.tipo != null && !r.tipo!.esOtro) ...[
            const SizedBox(height: 18),
            _ContadorLuminarias(
              valor: r.numeroLuminarias,
              alCambiar: (v) {
                r.numeroLuminarias = v;
                widget.alCambiar();
                setState(() {});
              },
            ),
          ],
        ],
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () => _mostrarOtrosCasos(context),
          icon: const Icon(Icons.signpost_outlined),
          label: const Text('¿Es otra cosa? Te decimos a quién acudir'),
          style: TextButton.styleFrom(foregroundColor: FixaColores.hojaOscura, alignment: Alignment.centerLeft),
        ),
      ],
    );
  }

  void _mostrarOtrosCasos(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: FixaColores.blanco,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Si tu problema es otro', style: tituloFixa(24)),
              const SizedBox(height: 12),
              for (final (e, d) in const [
                ('CRE', 'Cortes de luz en tu domicilio y fallas de la red eléctrica.'),
                ('ABC', 'Carreteras de la red vial fundamental.'),
                ('Gobernación de Santa Cruz', 'Asuntos de competencia departamental.'),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                    Text(d, style: const TextStyle(color: FixaColores.tinta2)),
                  ]),
                ),
              const Aviso(
                tipo: TipoAviso.error,
                texto: 'FIXA no atiende emergencias. Si hay peligro inmediato, llama al 800125050.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpcionCategoria extends StatelessWidget {
  const _OpcionCategoria({required this.categoria, required this.elegida, required this.onTap});
  final Categoria categoria;
  final bool elegida;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: elegida,
      button: true,
      child: Material(
        color: elegida ? FixaColores.menta : FixaColores.blanco,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: elegida ? FixaColores.hojaOscura : FixaColores.linea, width: elegida ? 2.5 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: elegida ? FixaColores.hojaOscura : FixaColores.menta,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(iconoDe(categoria.codigo), size: 28, color: elegida ? FixaColores.lima : FixaColores.hojaOscura),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(categoria.codigo.etiqueta, style: tituloFixa(19, color: FixaColores.tinta)),
                      if (categoria.descripcion.isNotEmpty)
                        Text(categoria.descripcion, style: const TextStyle(color: FixaColores.tinta2, fontSize: 15)),
                    ],
                  ),
                ),
                Icon(elegida ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: elegida ? FixaColores.hojaOscura : FixaColores.linea, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContadorLuminarias extends StatelessWidget {
  const _ContadorLuminarias({required this.valor, required this.alCambiar});
  final int? valor;
  final ValueChanged<int?> alCambiar;

  @override
  Widget build(BuildContext context) {
    final v = valor ?? 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FixaColores.blanco,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FixaColores.linea),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text('¿Cuántos focos están afectados?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
          IconButton.outlined(
            tooltip: 'Uno menos',
            onPressed: v > 1 ? () => alCambiar(v - 1) : null,
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 44,
            child: Text(valor == null ? '–' : '$v',
                textAlign: TextAlign.center, style: tituloFixa(22, color: FixaColores.tinta), semanticsLabel: '$v focos'),
          ),
          IconButton.filled(
            tooltip: 'Uno más',
            onPressed: v < 200 ? () => alCambiar(v + 1) : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Paso 2: foto y lugar

class _PasoFotoLugar extends StatefulWidget {
  const _PasoFotoLugar({required this.reporte, required this.alCambiar});
  final NuevoReporte reporte;
  final VoidCallback alCambiar;

  @override
  State<_PasoFotoLugar> createState() => _PasoFotoLugarState();
}

class _PasoFotoLugarState extends State<_PasoFotoLugar> {
  final _mapa = MapController();
  bool _procesandoFoto = false;
  String? _errorUbicacion;

  @override
  void initState() {
    super.initState();
    if (widget.reporte.latitud == null) _ubicar();
  }

  Future<void> _ubicar() async {
    setState(() => _errorUbicacion = null);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) throw 'Activa la ubicación (GPS) del celular.';
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) {
        throw 'Necesitamos tu ubicación para saber dónde está el problema. También puedes mover el mapa.';
      }
      final p = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      if (!mounted) return;
      widget.reporte
        ..latitud = p.latitude
        ..longitud = p.longitude;
      _mapa.move(LatLng(p.latitude, p.longitude), 17);
      widget.alCambiar();
    } catch (e) {
      if (!mounted) return;
      // Sin GPS igual se puede marcar el punto moviendo el mapa desde el centro de la ciudad.
      widget.reporte
        ..latitud ??= AppConfig.latInicial
        ..longitud ??= AppConfig.lngInicial;
      setState(() => _errorUbicacion = e is String ? e : 'No se pudo obtener tu ubicación. Mueve el mapa hasta el lugar.');
      widget.alCambiar();
    }
  }

  /// RNF04: la foto viaja en WebP y pesa menos de 3 MB (el máximo de la API).
  Future<void> _tomarFoto() async {
    final foto = await ImagePicker().pickImage(source: ImageSource.camera);
    if (foto == null) return;
    setState(() => _procesandoFoto = true);
    Uint8List? webp;
    for (final calidad in [80, 65, 50]) {
      webp = await FlutterImageCompress.compressWithFile(foto.path,
          minWidth: 1600, minHeight: 1600, quality: calidad, format: CompressFormat.webp);
      if (webp != null && webp.lengthInBytes < 3 * 1024 * 1024) break;
    }
    if (!mounted) return;
    setState(() => _procesandoFoto = false);
    if (webp == null) {
      mostrarMensaje(context, 'No se pudo preparar la foto. Intenta tomarla de nuevo.');
      return;
    }
    widget.reporte.foto = webp;
    widget.alCambiar();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reporte;
    final centro = LatLng(r.latitud ?? AppConfig.latInicial, r.longitud ?? AppConfig.lngInicial);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      children: [
        Text('Foto y lugar', style: tituloFixa(30)),
        const SizedBox(height: 14),
        Semantics(
          button: true,
          label: r.foto == null ? 'Tomar la foto del problema' : 'Tomar otra foto',
          child: Material(
            color: FixaColores.bosque,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _procesandoFoto ? null : _tomarFoto,
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: _procesandoFoto
                    ? const Center(child: CircularProgressIndicator(color: FixaColores.lima))
                    : r.foto == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.photo_camera_outlined, size: 44, color: FixaColores.lima),
                              SizedBox(height: 8),
                              Text('Toca para tomar la foto',
                                  style: TextStyle(color: FixaColores.lima, fontWeight: FontWeight.w700, fontSize: 17)),
                              Text('Es obligatoria', style: TextStyle(color: FixaColores.menta2, fontSize: 14)),
                            ],
                          )
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.memory(r.foto!, fit: BoxFit.cover, semanticLabel: 'Foto del problema'),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Container(
                                  margin: const EdgeInsets.all(12),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(color: FixaColores.blanco, borderRadius: BorderRadius.circular(99)),
                                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                    Icon(Icons.photo_camera_outlined, size: 18),
                                    SizedBox(width: 6),
                                    Text('Tomar otra', style: TextStyle(fontWeight: FontWeight.w700)),
                                  ]),
                                ),
                              ),
                            ],
                          ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 220,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapa,
                  options: MapOptions(
                    initialCenter: centro,
                    initialZoom: 17,
                    onPositionChanged: (posicion, _) {
                      r
                        ..latitud = posicion.center.latitude
                        ..longitud = posicion.center.longitude;
                    },
                    onMapEvent: (e) {
                      if (e is MapEventMoveEnd) widget.alCambiar();
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: AppConfig.userAgent,
                    ),
                  ],
                ),
                // Pin fijo al centro: el vecino mueve el mapa, no el pin.
                const IgnorePointer(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 44),
                      child: Icon(Icons.location_on, size: 48, color: FixaColores.hojaOscura),
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(color: FixaColores.blanco, borderRadius: BorderRadius.circular(99)),
                    child: const Text('Mueve el mapa para ajustar el punto',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: BotonRedondo(icono: Icons.my_location, etiqueta: 'Usar mi ubicación', onTap: _ubicar),
                ),
              ],
            ),
          ),
        ),
        if (_errorUbicacion != null) ...[
          const SizedBox(height: 12),
          Aviso(texto: _errorUbicacion!, tipo: TipoAviso.atencion, icono: Icons.location_off_outlined),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------- Paso 3: detalle

class _PasoDetalle extends StatelessWidget {
  const _PasoDetalle({required this.reporte, required this.guardar, required this.alCambiarGuardar, required this.alCambiar});
  final NuevoReporte reporte;
  final bool guardar;
  final ValueChanged<bool> alCambiarGuardar;
  final VoidCallback alCambiar;

  @override
  Widget build(BuildContext context) {
    final etiqueta = Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 16);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      children: [
        Text('Cuéntanos un poco más', style: tituloFixa(30)),
        const SizedBox(height: 16),
        Text('Descripción', style: etiqueta),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: reporte.descripcion,
          minLines: 3,
          maxLines: 5,
          maxLength: 1000,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Ej.: bache profundo en el carril derecho, frente al mercado'),
          onChanged: (v) {
            reporte.descripcion = v;
            alCambiar();
          },
        ),
        const SizedBox(height: 8),
        Row(children: [
          Text('Tu correo', style: etiqueta),
          const SizedBox(width: 6),
          const Text('(opcional)', style: TextStyle(color: FixaColores.tinta2)),
        ]),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: reporte.correo,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(hintText: 'nombre@correo.com', prefixIcon: Icon(Icons.mail_outline)),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (v) => (v == null || v.trim().isEmpty || RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim()))
              ? null
              : 'Revisa el correo: falta la @ o el dominio.',
          onChanged: (v) => reporte.correo = v,
        ),
        const SizedBox(height: 6),
        const Text('Te avisamos cuando cambie el estado. No se publica.', style: TextStyle(color: FixaColores.tinta2, fontSize: 14)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
          decoration: BoxDecoration(
            color: FixaColores.blanco,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: FixaColores.linea),
          ),
          child: SwitchListTile(
            value: guardar,
            onChanged: alCambiarGuardar,
            contentPadding: EdgeInsets.zero,
            activeTrackColor: FixaColores.hojaOscura,
            secondary: const Icon(Icons.smartphone, color: FixaColores.hojaOscura),
            title: const Text('Guardar en este celular', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Así ves el avance sin escribir la clave. No guarda tu nombre ni tu número.'),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: FixaColores.blanco,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: FixaColores.linea),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Revisa antes de enviar', style: tituloFixa(17, color: FixaColores.tinta)),
              const SizedBox(height: 10),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: reporte.foto == null
                        ? const SizedBox.square(dimension: 56)
                        : Image.memory(reporte.foto!, width: 56, height: 56, fit: BoxFit.cover, excludeFromSemantics: true),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(reporte.categoria?.etiqueta ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        Text(
                          [
                            reporte.tipo?.texto,
                            if (reporte.numeroLuminarias != null)
                              '${reporte.numeroLuminarias} ${reporte.numeroLuminarias == 1 ? 'foco' : 'focos'}',
                          ].whereType<String>().join(' · '),
                          style: const TextStyle(color: FixaColores.tinta2, fontSize: 14),
                        ),
                        Text('Punto: ${reporte.latitud?.toStringAsFixed(5)}, ${reporte.longitud?.toStringAsFixed(5)}',
                            style: const TextStyle(color: FixaColores.tinta2, fontSize: 14)),
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
