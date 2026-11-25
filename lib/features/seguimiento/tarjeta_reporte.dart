import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/tema.dart';
import '../../data/modelos.dart';
import '../../ui/comunes.dart';

/// Un reporte guardado en el celular: categoría, código, estado y avance. Se usa en
/// «Mis reportes» y en «Consultar seguimiento».
class TarjetaReporte extends StatelessWidget {
  const TarjetaReporte(
      {super.key, required this.credenciales, this.seguimiento, this.error});
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
    return TarjetaFixa(
      sombra: false,
      padding: const EdgeInsets.all(16),
      onTap: () =>
          context.push('/reporte/${Uri.encodeComponent(credenciales.codigo)}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(iconoDe(categoria), color: FixaColores.hojaOscura, size: 24),
              const SizedBox(width: 10),
              Expanded(child: Text(titulo, style: tituloFixa(17))),
              const Icon(Icons.chevron_right,
                  color: FixaColores.tinta2, size: 20),
            ],
          ),
          const SizedBox(height: 4),
          Text(credenciales.codigo,
              style: const TextStyle(fontSize: 13, color: FixaColores.tinta2)),
          const SizedBox(height: 8),
          if (detalle != null) ...[
            EstadoFixa(detalle.estado),
            if (detalle.unidad case final unidad? when unidad.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(unidad, style: tituloFixa(14)),
            ],
            if (ultimoCambio != null) ...[
              const SizedBox(height: 4),
              Text(
                'Actualizado: ${fechaCorta(ultimoCambio, incluirHora: true)}',
                style: const TextStyle(fontSize: 13, color: FixaColores.tinta2),
              ),
            ],
            if (detalle.estado.etapa case final etapa?) ...[
              const SizedBox(height: 8),
              BarrasFixa(
                actual: etapa.index + 1,
                total: Etapa.values.length,
                color: EstadoFixa.colorDe(detalle.estado),
              ),
              const SizedBox(height: 6),
              if (detalle.revisionDisponibleHasta case final limite?
                  when detalle.puedeResponderCierre(DateTime.now()) &&
                      detalle.conformidad == null)
                Text('Revisa el cierre hasta el ${fechaCorta(limite)}.',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: FixaColores.hojaOscura))
              else
                const Text('Recibido · Revisión · Atención · Cierre',
                    style: TextStyle(fontSize: 12, color: FixaColores.tinta2)),
            ],
          ] else if (error != null)
            Text(error!,
                style: const TextStyle(color: FixaColores.error, fontSize: 13))
          else
            const LinearProgressIndicator(minHeight: 3),
        ],
      ),
    );
  }
}
