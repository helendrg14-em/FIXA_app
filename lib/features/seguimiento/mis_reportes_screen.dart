import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/tema.dart';
import '../../data/mis_reportes.dart';
import '../../data/modelos.dart';
import '../../ui/comunes.dart';
import 'tarjeta_reporte.dart';

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
    final visibles = mis.recientes
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
                style:
                    const TextStyle(fontSize: 14, color: FixaColores.tinta2)),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: FixaColores.hojaOscura,
                  backgroundColor: FixaColores.blanco,
                  side: const BorderSide(color: FixaColores.linea),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.search,
                    color: FixaColores.hojaOscura, size: 22),
                label: const Text('Consultar seguimiento',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: FixaColores.hojaOscura)),
                onPressed: () => context.push('/seguir'),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                for (final filtro in _Filtro.values) ...[
                  FiltroFixa(
                    texto: filtro.etiqueta,
                    activo: _filtro == filtro,
                    onTap: () => setState(() => _filtro = filtro),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 14),
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
                  child: TarjetaReporte(
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
