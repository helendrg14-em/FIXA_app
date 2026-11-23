import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/tema.dart';
import '../../data/mis_reportes.dart';
import '../../data/modelos.dart';
import '../../data/notificaciones_fcm.dart';
import '../../data/repositorio.dart';
import '../../ui/comunes.dart';
import 'alerta_cercano.dart';
import 'paso_categoria.dart';
import 'paso_foto_lugar.dart';

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
  final _formulario = GlobalKey<FormState>();
  final _notificaciones = NotificacionesFcm();
  int _paso = 1;
  bool _enviando = false;
  bool _guardarEnCelular = true;

  Repositorio get _repo => context.read<MisReportes>().repositorio;

  void _atras() {
    if (_enviando) return;
    if (_paso > 1) {
      setState(() => _paso--);
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/mapa');
    }
  }

  Future<void> _continuarDesdeLugar() async {
    setState(() => _enviando = true);
    List<CasoCercano> cercanos = [];
    try {
      cercanos = await _repo.cercanos(
          _reporte.categoria!, _reporte.latitud!, _reporte.longitud!);
    } on FixaError {
      // La consulta de cercanos es opcional cuando no responde el servicio.
    }
    if (!mounted) return;
    final cercano = cercanos.firstOrNull;
    final apoyar = cercano == null
        ? false
        : await mostrarAlertaCercano(
            context, cercano, _reporte.fichaCategoria!);
    if (!mounted) return;
    setState(() => _enviando = false);
    if (apoyar == true) {
      await _enviar(() => _repo.apoyar(cercano!.casoId, _reporte));
    } else if (apoyar == false) {
      setState(() => _paso = 3);
    }
  }

  Future<void> _enviar(Future<ReporteCreado> Function() pedido) async {
    if (_enviando) return;
    FocusScope.of(context).unfocus();
    setState(() => _enviando = true);
    final mis = context.read<MisReportes>();
    try {
      _reporte.tokenDispositivo = await _notificaciones.solicitarToken();
      if (!mounted) return;
      var creado = await pedido();
      var guardado = false;
      if (_guardarEnCelular) {
        try {
          await mis.guardar(creado.credenciales);
          guardado = true;
        } on Exception {
          // El servidor ya entregó la clave. El comprobante debe seguir disponible.
        }
      }
      final unidad = creado.unidad.isNotEmpty
          ? creado.unidad
          : _reporte.fichaCategoria!.unidadVisible;
      creado = ReporteCreado(
          credenciales: creado.credenciales,
          unidad: unidad,
          esApoyo: creado.esApoyo);
      if (mounted) {
        context.pushReplacement('/enviado', extra: (creado, guardado));
      }
    } on FixaError catch (error) {
      if (mounted) mostrarMensaje(context, error.mensaje);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (contenido, accion, habilitado) = switch (_paso) {
      1 => (
          PasoCategoria(reporte: _reporte, alCambiar: () => setState(() {})),
          () => setState(() => _paso = 2),
          _reporte.categoria != null,
        ),
      2 => (
          PasoFotoLugar(
              reporte: _reporte,
              alCambiar: () => setState(() {}),
              bloqueado: _enviando),
          _continuarDesdeLugar,
          _reporte.foto != null &&
              _reporte.latitud != null &&
              _reporte.longitud != null,
        ),
      _ => (
          _PasoDetalle(
            formulario: _formulario,
            reporte: _reporte,
            guardar: _guardarEnCelular,
            bloqueado: _enviando,
            alCambiarGuardar: (valor) =>
                setState(() => _guardarEnCelular = valor),
            alCambiar: () => setState(() {}),
          ),
          () {
            if (_formulario.currentState!.validate()) {
              _enviar(() => _repo.reportar(_reporte));
            }
          },
          _reporte.descripcion.trim().isNotEmpty,
        ),
    };

    return PopScope(
      canPop: _paso == 1 && !_enviando,
      onPopInvokedWithResult: (salio, _) {
        if (!salio) _atras();
      },
      child: Scaffold(
        appBar: EncabezadoPaso(paso: _paso, onAtras: _atras),
        body: KeyedSubtree(key: ValueKey(_paso), child: contenido),
        bottomNavigationBar: BarraAccion(
          child: BotonPrincipal(
            texto: _paso == 3 ? 'Enviar reporte' : 'Continuar',
            icono: _paso == 3 ? Icons.send_outlined : Icons.arrow_forward,
            cargando: _enviando,
            onPressed: habilitado ? accion : null,
          ),
        ),
      ),
    );
  }
}

class _PasoDetalle extends StatelessWidget {
  const _PasoDetalle({
    required this.formulario,
    required this.reporte,
    required this.guardar,
    required this.bloqueado,
    required this.alCambiarGuardar,
    required this.alCambiar,
  });

  final GlobalKey<FormState> formulario;
  final NuevoReporte reporte;
  final bool guardar;
  final bool bloqueado;
  final ValueChanged<bool> alCambiarGuardar;
  final VoidCallback alCambiar;

  @override
  Widget build(BuildContext context) {
    final categoria = reporte.fichaCategoria!;
    return Form(
      key: formulario,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
        children: [
          Text('Un último detalle', style: tituloFixa(23)),
          const SizedBox(height: 16),
          Text('Descripción obligatoria', style: tituloFixa(15)),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: reporte.descripcion,
            minLines: 4,
            maxLines: 6,
            maxLength: 1000,
            readOnly: bloqueado,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Describe el problema',
              counterText: '',
            ),
            onChanged: (valor) {
              reporte.descripcion = valor;
              alCambiar();
            },
          ),
          const SizedBox(height: 7),
          Text('Describe qué ocurre y cómo afecta el paso.',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          TarjetaFixa(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(iconoDe(categoria.codigo),
                      color: FixaColores.hojaOscura),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(categoria.codigo.etiqueta,
                          style: tituloFixa(16))),
                ]),
                const SizedBox(height: 6),
                Text(reporte.lugarVisible,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 6),
                TextoConIcono(
                    Icons.send_outlined, 'Unidad: ${categoria.unidadVisible}'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ExpansionTile(
            initiallyExpanded:
                (reporte.correo?.isNotEmpty ?? false) || !guardar,
            tilePadding: EdgeInsets.zero,
            title: const Text('Opciones de seguimiento'),
            children: [
              TextFormField(
                initialValue: reporte.correo,
                readOnly: bloqueado,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Correo para avisos (opcional)',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                validator: (valor) {
                  final correo = valor?.trim() ?? '';
                  if (correo.isEmpty) return null;
                  return correo.length <= 120 &&
                          RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(correo)
                      ? null
                      : 'Revisa el correo.';
                },
                onChanged: (valor) => reporte.correo = valor,
              ),
              SwitchListTile(
                value: guardar,
                onChanged: bloqueado ? null : alCambiarGuardar,
                contentPadding: EdgeInsets.zero,
                title: const Text('Guardar en este celular'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
