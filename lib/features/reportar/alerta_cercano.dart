import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/tema.dart';
import '../../data/modelos.dart';
import '../../ui/comunes.dart';

Future<bool?> mostrarAlertaCercano(
  BuildContext context,
  CasoCercano caso,
  Categoria categoria, {
  String? direccion,
  Uint8List? fotoFallback,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: FixaColores.blanco,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (contexto) => SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text(
                  'Reporte cercano',
                  style: TextStyle(
                    color: FixaColores.hojaOscura,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.pop(contexto),
                  icon: const Icon(Icons.close, color: FixaColores.tinta2),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('¿Es el mismo problema?', style: tituloFixa(22)),
            const SizedBox(height: 6),
            Text(
              'Ya hay un reporte abierto a ${caso.distanciaMetros > 0 ? caso.distanciaMetros : 40} m. Puedes apoyarlo para evitar duplicarlo.',
              style: const TextStyle(color: FixaColores.tinta2, fontSize: 14),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 2.2,
                child: fotoFallback != null
                    ? Image.memory(fotoFallback, fit: BoxFit.cover)
                    : Container(
                        color: FixaColores.menta,
                        child: Center(
                          child: Icon(
                            iconoDe(categoria.codigo),
                            size: 40,
                            color: FixaColores.hojaOscura,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(categoria.codigo.etiqueta, style: tituloFixa(17)),
                      const SizedBox(height: 4),
                      Text(
                        '${direccion ?? "Av. Cañoto"} · ${categoria.unidadVisible}',
                        style: const TextStyle(
                            color: FixaColores.tinta2, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        caso.desde != null
                            ? 'Actualizado: ${fechaCorta(caso.desde!)}'
                            : 'Actualizado: 21 nov 2026',
                        style: const TextStyle(
                            color: FixaColores.tinta2, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                EstadoFixa(
                  EstadoCaso(caso.estado.isNotEmpty
                      ? caso.estado
                      : 'en_revision'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            BotonPrincipal(
              texto: 'Sí, apoyar reporte',
              icono: Icons.add,
              onPressed: () => Navigator.pop(contexto, true),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(contexto, false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: FixaColores.hojaOscura,
                  side: const BorderSide(color: FixaColores.linea),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'No, crear otro reporte',
                  style: TextStyle(
                    color: FixaColores.hojaOscura,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
