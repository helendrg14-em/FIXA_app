import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/tema.dart';
import '../../data/mis_reportes.dart';
import '../../data/modelos.dart';
import '../../ui/comunes.dart';
import 'conformidad.dart';

/// Detalle de un reporte guardado: etapa, unidad, fechas y conformidad.
class DetalleScreen extends StatefulWidget {
  const DetalleScreen({super.key, required this.codigo});
  final String codigo;

  @override
  State<DetalleScreen> createState() => _DetalleScreenState();
}

class _DetalleScreenState extends State<DetalleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final mis = context.read<MisReportes>();
      if (!mis.cargado) await mis.cargar();
      final c = mis.credencialesDe(widget.codigo);
      if (c != null) await mis.actualizarUno(c);
    });
  }

  Future<void> _quitar(BuildContext context) async {
    final mis = context.read<MisReportes>();
    final si = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('¿Quitar de este celular?'),
        content: const Text('El reporte sigue su curso. Para volver a verlo necesitarás el código y la clave.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(contexto, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(contexto, true), child: const Text('Quitar')),
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
    final c = mis.credencialesDe(widget.codigo);
    final s = mis.estadoDe(widget.codigo);
    final error = mis.errorDe(widget.codigo);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.codigo),
        actions: [
          if (c != null)
            IconButton(tooltip: 'Quitar de este celular', onPressed: () => _quitar(context), icon: const Icon(Icons.delete_outline)),
        ],
      ),
      body: c == null
          ? const Center(child: Text('Este reporte ya no está guardado en el celular.'))
          : RefreshIndicator(
              onRefresh: () async => mis.actualizarUno(c),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                children: [
                  if (s == null && error == null) const LinearProgressIndicator(),
                  if (error != null) Aviso(texto: error, tipo: TipoAviso.error),
                  if (s != null) ...[
                    Row(children: [
                      Icon(iconoDe(categoriaPorNombre(s.categoria)), color: FixaColores.hojaOscura, size: 28),
                      const SizedBox(width: 10),
                      Expanded(child: Text(s.categoria, style: tituloFixa(24))),
                    ]),
                    if (s.esApoyo) ...[
                      const SizedBox(height: 4),
                      const Text('Apoyaste un caso que ya estaba abierto.', style: TextStyle(color: FixaColores.tinta2)),
                    ],
                    const SizedBox(height: 16),
                    AvanceEtapas(estado: s.estado),
                    const SizedBox(height: 16),
                    _Recorrido(estado: s.estado),
                    const SizedBox(height: 16),
                    _Fila(icono: Icons.apartment_outlined, titulo: 'Lo atiende', valor: s.unidad ?? 'Por asignar'),
                    _Fila(icono: Icons.event_outlined, titulo: 'Reportado el', valor: fecha(s.fechaRegistro)),
                    if (s.ultimaActualizacion != null)
                      _Fila(icono: Icons.update, titulo: 'Última novedad', valor: fecha(s.ultimaActualizacion!)),
                    if (s.fechaCierre != null) _Fila(icono: Icons.task_alt, titulo: 'Cerrado el', valor: fecha(s.fechaCierre!)),
                    if (s.conformidad != null)
                      _Fila(
                        icono: s.conformidad! ? Icons.thumb_up_alt_outlined : Icons.thumb_down_alt_outlined,
                        titulo: 'Tu respuesta',
                        valor: s.conformidad! ? 'Quedó bien' : 'No quedó bien',
                      ),
                    if (s.revisionEstado != null) ...[
                      const SizedBox(height: 8),
                      Aviso(
                        titulo: 'Revisión del cierre: ${s.revisionEstado}',
                        texto: s.revisionRespuesta ?? 'El supervisor todavía no respondió.',
                        tipo: TipoAviso.atencion,
                      ),
                    ],
                    if (s.puedeResponderCierre(DateTime.now()) && s.conformidad == null) ...[
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
                  color: e.index < actual || (e.index == actual && e == Etapa.cerrado)
                      ? FixaColores.hojaViva
                      : e.index == actual
                          ? FixaColores.sol
                          : FixaColores.linea,
                ),
                const SizedBox(width: 12),
                Text(e.texto,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: e.index == actual ? FontWeight.w700 : FontWeight.w400,
                      color: e.index <= actual ? FixaColores.tinta : FixaColores.tinta2,
                    )),
                if (e.index == actual && e != Etapa.cerrado) ...[
                  const SizedBox(width: 8),
                  Text('· ${estado.texto}', style: const TextStyle(color: FixaColores.tinta2)),
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
          Flexible(child: Text(valor, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}
