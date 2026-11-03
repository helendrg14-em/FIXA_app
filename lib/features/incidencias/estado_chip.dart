import 'package:flutter/material.dart';

import '../../core/tema.dart';
import '../../data/models/incidencia.dart';

/// Ícono de cada tipo de problema, en el mapa, el formulario y el historial.
IconData iconoDe(Categoria categoria) => switch (categoria) {
      Categoria.bache => Icons.construction,
      Categoria.luminaria => Icons.lightbulb_outline,
      Categoria.residuos => Icons.delete_outline,
      Categoria.otro => Icons.report_gmailerrorred,
    };

/// Etiqueta de color con el estado de una incidencia.
class EstadoChip extends StatelessWidget {
  const EstadoChip(this.estado, {super.key});
  final EstadoIncidencia estado;

  static Color colorDe(EstadoIncidencia estado) => switch (estado) {
        EstadoIncidencia.registrada => FixaColores.naranjaOscuro,
        EstadoIncidencia.enProceso => const Color(0xFF1B6C8C),
        EstadoIncidencia.resuelta => FixaColores.verde,
        EstadoIncidencia.confirmada => FixaColores.pino,
      };

  @override
  Widget build(BuildContext context) {
    final color = colorDe(estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(estado.etiqueta,
          style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}
