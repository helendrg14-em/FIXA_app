import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/tema.dart';
import '../../data/mis_reportes.dart';
import '../../data/modelos.dart';
import '../../ui/comunes.dart';

enum _Filtro {
  todos('Todos'),
  curso('En curso'),
  cerrados('Cerrados');

  const _Filtro(this.etiqueta);
  final String etiqueta;

  bool incluye(Seguimiento? seguimiento) => switch (this) {
        todos => true,
        curso => const {Etapa.recibido, Etapa.enRevision, Etapa.programado}
            .contains(seguimiento?.estado.etapa),
        cerrados => seguimiento != null &&
            (seguimiento.estado.cerrado ||
                seguimiento.estado.terminoSinArreglo),
      };
}

class MisReportesScreen extends StatefulWidget {
  const MisReportesScreen({super.key});

  @override
  State<MisReportesScreen> createState() => _MisReportesScreenState();
}

class _MisReportesScreenState extends State<MisReportesScreen> {
  _Filtro _filtro = _Filtro.todos;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _cargar();
    });
  }

  Future<void> _cargar() async {
    final mis = context.read<MisReportes>();
    try {
      if (!mis.cargado) await mis.cargar();
      await mis.actualizar();
    } on Exception {
      if (mounted) {
        mostrarMensaje(
            context, 'No se pudieron cargar tus reportes en este celular.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mis = context.watch<MisReportes>();
    final visibles = mis.guardados
        .where((c) => _filtro.incluye(mis.estadoDe(c.codigo)))
        .toList();
    return Scaffold(
      appBar: AppBar(
          title: const Text('Mis reportes'), automaticallyImplyLeading: false),
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 9, 16, 24),
          children: [
            Text('Reportes guardados en este celular',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('Seguir con código'),
              onPressed: () => context.push('/seguir'),
            ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 8,
              children: [
                for (final filtro in _Filtro.values)
                  FiltroFixa(
                      texto: filtro.etiqueta,
                      activo: _filtro == filtro,
                      onTap: () => setState(() => _filtro = filtro)),
              ],
            ),
            const SizedBox(height: 8),
            if (!mis.cargado)
              const LinearProgressIndicator()
            else if (visibles.isEmpty)
              TarjetaFixa(
                child: Text(
                  mis.guardados.isEmpty
                      ? 'Aquí aparecerán los reportes que guardes en este celular.'
                      : 'No hay reportes para este filtro.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            else
              for (final credenciales in visibles)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _Tarjeta(
                    credenciales: credenciales,
                    seguimiento: mis.estadoDe(credenciales.codigo),
                    error: mis.errorDe(credenciales.codigo),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.credenciales, this.seguimiento, this.error});
  final Credenciales credenciales;
  final Seguimiento? seguimiento;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final detalle = seguimiento;
    final categoriaApi = detalle?.categoria ?? credenciales.categoria ?? '';
    final categoria = categoriaPorNombre(categoriaApi);
    final titulo = categoria?.etiqueta ??
        (categoriaApi.isEmpty ? 'Reporte' : categoriaApi);
    final ultimoCambio = detalle?.ultimaActualizacion ??
        detalle?.fechaCierre ??
        detalle?.fechaRegistro;
    final nota = Theme.of(context).textTheme.bodySmall;
    return TarjetaFixa(
      sombra: true,
      onTap: () =>
          context.push('/reporte/${Uri.encodeComponent(credenciales.codigo)}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(iconoDe(categoria), color: FixaColores.hojaOscura, size: 23),
              const SizedBox(width: 8),
              Expanded(child: Text(titulo, style: tituloFixa(17))),
              const Icon(Icons.chevron_right, color: FixaColores.tinta2),
            ],
          ),
          const SizedBox(height: 4),
          Text(credenciales.codigo, style: nota),
          const SizedBox(height: 5),
          if (detalle != null) ...[
            EstadoFixa(detalle.estado),
            if (detalle.unidad case final unidad? when unidad.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(unidad, style: tituloFixa(13)),
            ],
            if (ultimoCambio != null) ...[
              const SizedBox(height: 5),
              Text(
                  'Actualizado: ${fechaCorta(ultimoCambio, incluirHora: true)}',
                  style: nota),
            ],
            if (detalle.estado.etapa case final etapa?) ...[
              const SizedBox(height: 5),
              BarrasFixa(
                  actual: etapa.index + 1,
                  total: Etapa.values.length,
                  color: EstadoFixa.colorDe(detalle.estado)),
              const SizedBox(height: 5),
              if (detalle.revisionDisponibleHasta case final limite?
                  when detalle.puedeResponderCierre(DateTime.now()) &&
                      detalle.conformidad == null)
                Text('Revisa el cierre hasta el ${fechaCorta(limite)}.',
                    style: nota?.copyWith(color: FixaColores.hojaOscura))
              else
                Text('Recibido · Revisión · Atención · Cierre', style: nota),
            ],
          ] else if (error != null)
            Text(error!, style: nota?.copyWith(color: FixaColores.error))
          else
            const LinearProgressIndicator(minHeight: 3),
        ],
      ),
    );
  }
}
