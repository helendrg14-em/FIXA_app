import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/tema.dart';
import '../../data/mis_reportes.dart';
import '../../data/modelos.dart';
import '../../data/repositorio.dart';
import '../../ui/comunes.dart';

/// "¿Quedó bien?" (R12): confirmar la solución o pedir revisión hasta 15 días después del cierre.
class BloqueConformidad extends StatefulWidget {
  const BloqueConformidad(
      {super.key, required this.credenciales, required this.seguimiento});
  final Credenciales credenciales;
  final Seguimiento seguimiento;

  @override
  State<BloqueConformidad> createState() => _BloqueConformidadState();
}

class _BloqueConformidadState extends State<BloqueConformidad> {
  bool _enviando = false;

  Future<void> _responder(bool conforme) async {
    final mis = context.read<MisReportes>();
    setState(() => _enviando = true);
    try {
      final mensaje = await mis.repositorio
          .conformidad(widget.credenciales, conforme: conforme);
      if (!mounted) return;
      mostrarMensaje(context, mensaje);
      if (!conforme) await _pedirRevision();
      await mis.actualizarUno(widget.credenciales);
    } on FixaError catch (e) {
      if (mounted) mostrarMensaje(context, e.mensaje);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _pedirRevision() async {
    final motivo = await pedirMotivoRevision(context);
    if (motivo == null || !mounted) return;
    try {
      final mensaje = await context
          .read<MisReportes>()
          .repositorio
          .pedirRevision(widget.credenciales, motivo);
      if (mounted) mostrarMensaje(context, mensaje);
    } on FixaError catch (e) {
      if (mounted) mostrarMensaje(context, e.mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasta = widget.seguimiento.revisionDisponibleHasta;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: FixaColores.solClaro.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
              'El supervisor cerró el caso con foto del trabajo. ¿Quedó bien?',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          // Uno debajo del otro: lado a lado el texto se partía en dos líneas.
          FilledButton(
            onPressed: _enviando ? null : () => _responder(true),
            style:
                FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: const Text('Sí, quedó bien'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _enviando ? null : () => _responder(false),
            style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                side: const BorderSide(color: FixaColores.linea)),
            child: const Text('Pedir revisión'),
          ),
          if (hasta != null) ...[
            const SizedBox(height: 8),
            Text('Puedes responder hasta el ${fecha(hasta)} (15 días).',
                style:
                    const TextStyle(color: FixaColores.tinta2, fontSize: 14)),
          ],
        ],
      ),
    );
  }
}

/// Pide el motivo de la revisión (la API exige al menos 10 caracteres).
Future<String?> pedirMotivoRevision(BuildContext context) {
  final control = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (contexto) => StatefulBuilder(
      builder: (contexto, setEstado) => AlertDialog(
        title: const Text('¿Qué quedó mal?'),
        content: TextField(
          controller: control,
          autofocus: true,
          minLines: 3,
          maxLines: 5,
          maxLength: 1000,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
              hintText: 'Ej.: el bache se volvió a abrir con la lluvia'),
          onChanged: (_) => setEstado(() {}),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(contexto),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: control.text.trim().length >= 10
                ? () => Navigator.pop(contexto, control.text.trim())
                : null,
            child: const Text('Pedir revisión'),
          ),
        ],
      ),
    ),
  );
}
