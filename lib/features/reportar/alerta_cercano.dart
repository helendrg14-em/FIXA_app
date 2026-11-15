import 'package:flutter/material.dart';

import '../../core/tema.dart';
import '../../data/modelos.dart';
import '../../ui/comunes.dart';

/// "¿Es este tu reporte?" (R13/R14): si ya hay un caso igual cerca, el vecino puede apoyarlo
/// en lugar de duplicarlo. Devuelve true (apoyar), false (es otro) o null (cerró la hoja).
Future<bool?> mostrarAlertaCercano(BuildContext context, CasoCercano caso, CodigoCategoria categoria) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: FixaColores.blanco,
    builder: (contexto) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Es este tu reporte?', style: tituloFixa(28)),
            const SizedBox(height: 6),
            const Text('Si es el mismo problema, apóyalo para evitar duplicados. Recibirás tu propio código y clave.',
                style: TextStyle(color: FixaColores.tinta2, fontSize: 16)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: FixaColores.menta, borderRadius: BorderRadius.circular(18)),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(color: FixaColores.bosque, borderRadius: BorderRadius.circular(14)),
                    child: Icon(iconoDe(categoria), color: FixaColores.lima),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(caso.tipo.isEmpty ? categoria.etiqueta : caso.tipo, style: tituloFixa(19, color: FixaColores.tinta)),
                        Text('${caso.distanciaMetros < 10 ? 'Aquí mismo' : 'A ${caso.distanciaMetros} m'} · ${caso.estado}',
                            style: const TextStyle(fontWeight: FontWeight.w700, color: FixaColores.hojaOscura)),
                        Text(
                          caso.vecinosQueReportaron == 1
                              ? 'Lo reportó 1 vecino'
                              : 'Lo reportaron ${caso.vecinosQueReportaron} vecinos',
                          style: const TextStyle(color: FixaColores.tinta2, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            BotonPrincipal(texto: 'Sí, apoyar ese reporte', icono: Icons.group_add_outlined, onPressed: () => Navigator.pop(contexto, true)),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: () => Navigator.pop(contexto, false), child: const Text('No, es otro problema')),
          ],
        ),
      ),
    ),
  );
}
