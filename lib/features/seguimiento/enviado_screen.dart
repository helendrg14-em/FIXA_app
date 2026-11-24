import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/tema.dart';
import '../../data/mis_reportes.dart';
import '../../data/modelos.dart';
import '../../ui/comunes.dart';
import 'comprobante.dart';

class EnviadoScreen extends StatefulWidget {
  const EnviadoScreen(
      {super.key, required this.creado, required this.guardado});

  final ReporteCreado creado;
  final bool guardado;

  @override
  State<EnviadoScreen> createState() => _EnviadoScreenState();
}

class _EnviadoScreenState extends State<EnviadoScreen> {
  final _comprobante = Comprobante();
  bool _exportando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MisReportes>().actualizarUno(widget.creado.credenciales);
    });
  }

  Future<void> _exportar(ReporteCreado reporte, {required bool imagen}) async {
    if (_exportando) return;
    setState(() => _exportando = true);
    try {
      if (imagen) {
        final guardado = await _comprobante.guardarImagen(reporte);
        if (mounted && guardado) {
          mostrarMensaje(context, 'Comprobante guardado.');
        }
      } else {
        await _comprobante.abrirCorreo(reporte);
      }
    } on PlatformException catch (error) {
      if (mounted) {
        mostrarMensaje(
            context, error.message ?? 'No se pudo exportar el comprobante.');
      }
    } on MissingPluginException {
      if (mounted) {
        mostrarMensaje(context, 'Esta opción está disponible en Android.');
      }
    } on StateError {
      if (mounted) {
        mostrarMensaje(context, 'No se pudo generar el comprobante.');
      }
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final seguimiento = context.select(
        (MisReportes mis) => mis.estadoDe(widget.creado.credenciales.codigo));
    final reporte = ReporteCreado(
      credenciales: widget.creado.credenciales,
      unidad: seguimiento?.unidad ?? widget.creado.unidad,
      esApoyo: widget.creado.esApoyo,
    );
    final estado = seguimiento?.estado ??
        (reporte.esApoyo ? null : const EstadoCaso('Recibida'));
    final credenciales = reporte.credenciales;
    final categoria = categoriaPorNombre(credenciales.categoria ?? '');
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(13, 14, 13, 22),
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: FixaColores.hojaOscura,
                  foregroundColor: FixaColores.blanco,
                  child: Icon(Icons.check),
                ),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(
                        reporte.esApoyo
                            ? '¡Apoyo registrado!'
                            : '¡Reporte enviado!',
                        style: tituloFixa(23))),
              ],
            ),
            const SizedBox(height: 9),
            Text(
                'Guarda tu comprobante para consultar el avance cuando quieras.',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            TarjetaFixa(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Unidad asignada automáticamente',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 5),
                  Row(children: [
                    Icon(iconoDe(categoria), color: FixaColores.hojaOscura),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(
                            reporte.unidad.isEmpty
                                ? 'Por asignar'
                                : reporte.unidad,
                            style: tituloFixa(17))),
                  ]),
                  if (estado != null) ...[
                    const SizedBox(height: 5),
                    EstadoFixa(estado),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            TarjetaFixa(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Dato(etiqueta: 'Código único', valor: credenciales.codigo),
                  const Divider(height: 20, color: FixaColores.linea),
                  _Dato(etiqueta: 'Clave privada', valor: credenciales.clave),
                  const SizedBox(height: 13),
                  Text('Guarda tu clave. No la compartas públicamente.',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.verified_user_outlined,
                    size: 20, color: FixaColores.hojaOscura),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.guardado
                        ? 'Disponible en Mis reportes de este celular.'
                        : 'Conserva el código y la clave para consultar el avance.',
                    style: const TextStyle(
                        fontSize: 13, color: FixaColores.tinta2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _AccionComprobante(
                    icono: Icons.download_outlined,
                    texto: 'Guardar imagen',
                    onPressed: _exportando
                        ? null
                        : () => _exportar(reporte, imagen: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AccionComprobante(
                    icono: Icons.mail_outline,
                    texto: 'Enviar por correo',
                    onPressed: _exportando
                        ? null
                        : () => _exportar(reporte, imagen: false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BarraAccion(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BotonPrincipal(
              texto: 'Ver seguimiento ahora',
              icono: Icons.arrow_forward,
              onPressed: () => context.push(
                  '/reporte/${Uri.encodeComponent(credenciales.codigo)}',
                  extra: credenciales),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: FixaColores.hojaOscura,
                  minimumSize: const Size.fromHeight(44),
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                onPressed: () => context.go('/mapa'),
                child: const Text('Volver al mapa'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccionComprobante extends StatelessWidget {
  const _AccionComprobante(
      {required this.icono, required this.texto, this.onPressed});

  final IconData icono;
  final String texto;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 48,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: FixaColores.hojaOscura,
            side: const BorderSide(color: FixaColores.linea),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            textStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          icon: Icon(icono, size: 20, color: FixaColores.hojaOscura),
          label: Text(texto,
              style: const TextStyle(color: FixaColores.hojaOscura)),
          onPressed: onPressed,
        ),
      );
}

class _Dato extends StatelessWidget {
  const _Dato({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(etiqueta, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                SelectableText(valor, style: tituloFixa(19)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: FixaColores.menta,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: valor));
                if (context.mounted) {
                  mostrarMensaje(context, 'Copiado al portapapeles.');
                }
              },
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.copy_outlined,
                    size: 20, color: FixaColores.hojaOscura),
              ),
            ),
          ),
        ],
      );
}
