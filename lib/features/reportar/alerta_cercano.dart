import 'package:flutter/material.dart';

import '../../core/tema.dart';
import '../../data/modelos.dart';
import '../../ui/comunes.dart';

Future<bool?> mostrarAlertaCercano(
    BuildContext context, CasoCercano caso, Categoria categoria) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: FixaColores.blanco,
    builder: (contexto) => SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Reporte cercano',
                      style: TextStyle(
                          color: FixaColores.hojaOscura,
                          fontWeight: FontWeight.w700)),
                ),
                IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.pop(contexto),
                    icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 5),
            Text('¿Es el mismo problema?', style: tituloFixa(24)),
            const SizedBox(height: 7),
            Text(
              'Ya hay un reporte abierto a ${caso.distanciaMetros} m. Puedes apoyarlo para evitar duplicarlo.',
              style: const TextStyle(color: FixaColores.tinta2),
            ),
            const SizedBox(height: 12),
            TarjetaFixa(
              fondo: FixaColores.papel,
              child: Row(
                children: [
                  IconoFixa(iconoDe(categoria.codigo), tamano: 46),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(categoria.codigo.etiqueta, style: tituloFixa(17)),
                        if (caso.tipo.isNotEmpty)
                          Text(caso.tipo,
                              style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 6),
                        EstadoFixa(EstadoCaso(caso.estado)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(categoria.unidadVisible,
                style: Theme.of(context).textTheme.bodySmall),
            if (caso.desde case final desde?)
              Text('Registrado: ${fecha(desde)}',
                  style: Theme.of(context).textTheme.bodySmall),
            Text(
              caso.vecinosQueReportaron == 1
                  ? 'Lo reportó 1 vecino'
                  : 'Lo reportaron ${caso.vecinosQueReportaron} vecinos',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            BotonPrincipal(
              texto: 'Sí, apoyar reporte',
              icono: Icons.add,
              onPressed: () => Navigator.pop(contexto, true),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
                onPressed: () => Navigator.pop(contexto, false),
                child: const Text('No, crear otro reporte')),
          ],
        ),
      ),
    ),
  );
}
