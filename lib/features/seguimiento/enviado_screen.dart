import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/tema.dart';
import '../../data/modelos.dart';
import '../../ui/comunes.dart';

/// Reporte enviado: código y clave (R05). Si el vecino lo permitió, ya quedaron en este celular.
class EnviadoScreen extends StatelessWidget {
  const EnviadoScreen({super.key, required this.creado, required this.guardado});
  final ReporteCreado creado;
  final bool guardado;

  @override
  Widget build(BuildContext context) {
    final c = creado.credenciales;
    final unidad = creado.unidad.isEmpty ? 'La unidad responsable' : creado.unidad;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (salio, _) {
        if (!salio) context.go('/');
      },
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            children: [
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(color: FixaColores.hojaOscura, shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: FixaColores.lima, size: 40),
                ),
              ),
              const SizedBox(height: 18),
              Text(creado.esApoyo ? '¡Gracias por apoyar!' : '¡Reporte enviado!',
                  textAlign: TextAlign.center, style: tituloFixa(34)),
              const SizedBox(height: 8),
              Text(
                creado.esApoyo
                    ? 'Tu apoyo se sumó al caso que ya estaba abierto.'
                    : '$unidad ya lo recibió. Su avance aparece en Mis reportes.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: FixaColores.tinta2),
              ),
              const SizedBox(height: 22),
              Container(
                decoration: BoxDecoration(
                  color: FixaColores.blanco,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: FixaColores.linea),
                ),
                child: Column(
                  children: [
                    _Dato(etiqueta: 'Tu código', valor: c.codigo),
                    const Divider(height: 1, color: FixaColores.linea),
                    _Dato(etiqueta: 'Tu clave', valor: c.clave),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Aviso(
                tipo: guardado ? TipoAviso.info : TipoAviso.atencion,
                texto: guardado
                    ? 'Ya quedó guardado en este celular. Solo necesitas el código y la clave si cambias de celular.'
                    : 'No lo guardaste en este celular. Anota el código y la clave: la clave no se puede recuperar.',
              ),
            ],
          ),
        ),
        bottomNavigationBar: BarraAccion(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BotonPrincipal(
                texto: 'Compartir o guardar',
                icono: Icons.ios_share,
                onPressed: () => SharePlus.instance.share(ShareParams(
                  subject: 'Mi reporte de FIXA',
                  text: 'Mi reporte de FIXA\nCódigo: ${c.codigo}\nClave: ${c.clave}\n'
                      'Para seguirlo: abre FIXA → Seguir un reporte. No compartas la clave con otras personas.',
                )),
              ),
              const SizedBox(height: 10),
              OutlinedButton(onPressed: () => context.go('/'), child: const Text('Volver al inicio')),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.etiqueta, required this.valor});
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(etiqueta, style: const TextStyle(fontWeight: FontWeight.w700, color: FixaColores.tinta2, fontSize: 14)),
                SelectableText(valor, style: tituloFixa(28).copyWith(letterSpacing: 1)),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Copiar $etiqueta'.toLowerCase(),
            constraints: const BoxConstraints.tightFor(width: 48, height: 48),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: valor));
              if (context.mounted) mostrarMensaje(context, '${etiqueta.replaceFirst('Tu ', '')} copiado');
            },
            icon: const Icon(Icons.copy_rounded),
          ),
        ],
      ),
    );
  }
}
