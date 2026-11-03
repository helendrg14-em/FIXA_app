import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/tema.dart';
import '../../data/models/incidencia.dart';
import 'estado_chip.dart';
import 'incidencias_provider.dart';

/// Historial del ciudadano con el estado de cada reporte (trazabilidad).
class MisReportesScreen extends StatelessWidget {
  const MisReportesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<IncidenciasProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Mis reportes')),
      body: RefreshIndicator(
        onRefresh: prov.cargar,
        child: switch ((prov.cargando, prov.error, prov.items.isEmpty)) {
          (true, _, true) => const Center(child: CircularProgressIndicator()),
          (_, final String error, _) => _Aviso(
              icono: Icons.cloud_off,
              titulo: error,
              detalle: 'Desliza hacia abajo para intentar de nuevo.',
            ),
          (_, _, true) => const _Aviso(
              icono: Icons.add_a_photo,
              titulo: 'Aún no reportaste ninguna incidencia',
              detalle: 'Cuando envíes un reporte, aquí verás en qué estado está.',
            ),
          _ => ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: prov.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _TarjetaReporte(prov.items[index]),
            ),
        },
      ),
    );
  }
}

/// Va en una lista para que deslizar hacia abajo siga recargando.
class _Aviso extends StatelessWidget {
  const _Aviso({required this.icono, required this.titulo, required this.detalle});
  final IconData icono;
  final String titulo;
  final String detalle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(32, 96, 32, 32),
      children: [
        Icon(icono, size: 56, color: FixaColores.verde),
        const SizedBox(height: 16),
        Text(titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(detalle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: FixaColores.textoSuave)),
      ],
    );
  }
}

class _TarjetaReporte extends StatelessWidget {
  const _TarjetaReporte(this.incidencia);
  final Incidencia incidencia;

  @override
  Widget build(BuildContext context) {
    final i = incidencia;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FixaColores.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Miniatura(i),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(i.categoria.etiqueta,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('${i.categoria.unidad} · ${i.fechaTexto}',
                        style: const TextStyle(fontSize: 13, color: FixaColores.textoSuave)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              EstadoChip(i.estado),
            ],
          ),
          if (i.descripcion.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(i.descripcion),
          ],
          const SizedBox(height: 14),
          _Avance(i.estado),
        ],
      ),
    );
  }
}

class _Miniatura extends StatelessWidget {
  const _Miniatura(this.incidencia);
  final Incidencia incidencia;

  @override
  Widget build(BuildContext context) {
    final foto = incidencia.fotoUrl;
    final icono = Container(
      width: 48,
      height: 48,
      color: FixaColores.verdeClaro,
      child: Icon(iconoDe(incidencia.categoria), color: FixaColores.verde),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: foto == null
          ? icono
          : foto.startsWith('http')
              ? Image.network(foto,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => icono)
              : Image.file(File(foto),
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => icono),
    );
  }
}

/// Barra con las etapas del reporte: los tramos ya recorridos van en color.
class _Avance extends StatelessWidget {
  const _Avance(this.estado);
  final EstadoIncidencia estado;

  @override
  Widget build(BuildContext context) {
    final color = EstadoChip.colorDe(estado);
    return Semantics(
      label: 'Etapa ${estado.index + 1} de ${EstadoIncidencia.values.length}: ${estado.etiqueta}',
      child: Row(
        children: [
          for (final e in EstadoIncidencia.values) ...[
            if (e.index > 0) const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: e.index <= estado.index ? color : FixaColores.borde,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
