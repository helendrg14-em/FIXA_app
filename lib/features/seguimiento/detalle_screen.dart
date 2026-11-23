import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/tema.dart';
import '../../data/mis_reportes.dart';
import '../../data/modelos.dart';
import '../../data/notificaciones_fcm.dart';
import '../../data/repositorio.dart';
import '../../ui/comunes.dart';
import 'conformidad.dart';

/// Detalle de un reporte guardado: etapa, unidad, fechas y conformidad.
class DetalleScreen extends StatefulWidget {
  const DetalleScreen({super.key, required this.codigo, this.acceso});
  final String codigo;
  final Credenciales? acceso;

  @override
  State<DetalleScreen> createState() => _DetalleScreenState();
}

class _DetalleScreenState extends State<DetalleScreen> {
  final _notificaciones = NotificacionesFcm();
  late final _avisosDisponibles = _notificaciones.disponibles();
  bool _activandoAvisos = false;

  Future<void> _activarAvisos(Credenciales credenciales) async {
    if (_activandoAvisos) return;
    final repositorio = context.read<MisReportes>().repositorio;
    setState(() => _activandoAvisos = true);
    try {
      final token = await _notificaciones.solicitarToken();
      if (!mounted) return;
      if (token == null) {
        mostrarMensaje(
            context, 'Revisa los permisos de notificación y tu conexión.');
        return;
      }
      await repositorio.actualizarDispositivo(credenciales, token);
      if (mounted) {
        mostrarMensaje(context, 'Avisos activados para este reporte.');
      }
    } on FixaError catch (error) {
      if (mounted) mostrarMensaje(context, error.mensaje);
    } finally {
      if (mounted) setState(() => _activandoAvisos = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final mis = context.read<MisReportes>();
      if (!mis.cargado) {
        try {
          await mis.cargar();
        } on Exception {
          if (mounted && widget.acceso == null) {
            mostrarMensaje(context, 'No se pudieron cargar tus reportes.');
          }
        }
      }
      if (!mounted) return;
      final c = mis.credencialesDe(widget.codigo) ?? widget.acceso;
      if (c != null && mis.estadoDe(widget.codigo) == null) {
        await mis.actualizarUno(c);
      }
    });
  }

  Future<void> _quitar(BuildContext context) async {
    final mis = context.read<MisReportes>();
    final si = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('¿Quitar de este celular?'),
        content: const Text(
            'El reporte sigue su curso. Para volver a verlo necesitarás el código y la clave.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(contexto, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(contexto, true),
              child: const Text('Quitar')),
        ],
      ),
    );
    if (si != true) return;
    await mis.quitar(widget.codigo);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final mis = context.watch<MisReportes>();
    final c = mis.credencialesDe(widget.codigo) ?? widget.acceso;
    final s = mis.estadoDe(widget.codigo);
    final error = mis.errorDe(widget.codigo);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seguimiento del reporte'),
        actions: [
          if (c != null)
            FutureBuilder<bool>(
              future: _avisosDisponibles,
              builder: (_, estado) => estado.data == true
                  ? IconButton(
                      tooltip: 'Activar avisos en este celular',
                      onPressed:
                          _activandoAvisos ? null : () => _activarAvisos(c),
                      icon: const Icon(Icons.notifications_none),
                    )
                  : const SizedBox.shrink(),
            ),
          if (mis.tiene(widget.codigo))
            IconButton(
                tooltip: 'Quitar de este celular',
                onPressed: () => _quitar(context),
                icon: const Icon(Icons.delete_outline)),
        ],
      ),
      body: c == null
          ? const Center(
              child: Text('Este reporte ya no está guardado en el celular.'))
          : RefreshIndicator(
              onRefresh: () async => mis.actualizarUno(c),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 26),
                children: [
                  if (s == null && error == null)
                    const LinearProgressIndicator(),
                  if (error != null) Aviso(texto: error, tipo: TipoAviso.error),
                  if (s != null) ...[
                    Row(children: [
                      Icon(iconoDe(categoriaPorNombre(s.categoria)),
                          color: FixaColores.hojaOscura, size: 28),
                      const SizedBox(width: 10),
                      Expanded(child: Text(s.categoria, style: tituloFixa(24))),
                    ]),
                    if (s.esApoyo) ...[
                      const SizedBox(height: 4),
                      const Text('Apoyaste un caso que ya estaba abierto.',
                          style: TextStyle(color: FixaColores.tinta2)),
                    ],
                    const SizedBox(height: 16),
                    TarjetaFixa(child: AvanceEtapas(estado: s.estado)),
                    const SizedBox(height: 16),
                    TarjetaFixa(child: _Recorrido(estado: s.estado)),
                    const SizedBox(height: 16),
                    _Fila(
                        icono: Icons.apartment_outlined,
                        titulo: 'Lo atiende',
                        valor: s.unidad ?? 'Por asignar'),
                    _Fila(
                        icono: Icons.event_outlined,
                        titulo: 'Reportado el',
                        valor: fecha(s.fechaRegistro)),
                    if (s.ultimaActualizacion != null)
                      _Fila(
                          icono: Icons.update,
                          titulo: 'Última novedad',
                          valor: fecha(s.ultimaActualizacion!)),
                    if (s.fechaCierre != null)
                      _Fila(
                          icono: Icons.task_alt,
                          titulo: 'Cerrado el',
                          valor: fecha(s.fechaCierre!)),
                    if (s.conformidad != null)
                      _Fila(
                        icono: s.conformidad!
                            ? Icons.thumb_up_alt_outlined
                            : Icons.thumb_down_alt_outlined,
                        titulo: 'Tu respuesta',
                        valor: s.conformidad! ? 'Quedó bien' : 'No quedó bien',
                      ),
                    if (s.revisionEstado != null) ...[
                      const SizedBox(height: 8),
                      Aviso(
                        titulo: 'Revisión del cierre: ${s.revisionEstado}',
                        texto: s.revisionRespuesta ??
                            'El supervisor todavía no respondió.',
                        tipo: TipoAviso.atencion,
                      ),
                    ],
                    if (s.puedeResponderCierre(DateTime.now()) &&
                        s.conformidad == null) ...[
                      const SizedBox(height: 16),
                      BloqueConformidad(credenciales: c, seguimiento: s),
                    ],
                  ],
                ],
              ),
            ),
    );
  }
}

/// Las 4 etapas en vertical, cada una con su nombre.
class _Recorrido extends StatelessWidget {
  const _Recorrido({required this.estado});
  final EstadoCaso estado;

  @override
  Widget build(BuildContext context) {
    final actual = estado.etapa?.index ?? -1;
    return Column(
      children: [
        for (final e in Etapa.values)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(
                  e.index < actual || (e.index == actual && e == Etapa.cerrado)
                      ? Icons.check_circle
                      : e.index == actual
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                  color: e.index < actual ||
                          (e.index == actual && e == Etapa.cerrado)
                      ? FixaColores.hojaViva
                      : e.index == actual
                          ? FixaColores.sol
                          : FixaColores.linea,
                ),
                const SizedBox(width: 12),
                Text(e.texto,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          e.index == actual ? FontWeight.w700 : FontWeight.w400,
                      color: e.index <= actual
                          ? FixaColores.tinta
                          : FixaColores.tinta2,
                    )),
                if (e.index == actual && e != Etapa.cerrado) ...[
                  const SizedBox(width: 8),
                  Text('· ${estado.texto}',
                      style: const TextStyle(color: FixaColores.tinta2)),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({required this.icono, required this.titulo, required this.valor});
  final IconData icono;
  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icono, color: FixaColores.tinta2),
          const SizedBox(width: 12),
          Text(titulo, style: const TextStyle(color: FixaColores.tinta2)),
          const Spacer(),
          Flexible(
              child: Text(valor,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}
