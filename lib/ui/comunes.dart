import 'package:flutter/material.dart';

import '../core/tema.dart';
import '../data/modelos.dart';

/// Ícono de cada categoría, el mismo en el mapa, el formulario y el historial.
IconData iconoDe(CodigoCategoria? categoria) => switch (categoria) {
      CodigoCategoria.bache => Icons.add_road,
      CodigoCategoria.alumbrado => Icons.lightbulb_outline,
      CodigoCategoria.residuos => Icons.delete_outline,
      null => Icons.place_outlined,
    };

/// Busca la categoría por el nombre que devuelve la API en el seguimiento.
CodigoCategoria? categoriaPorNombre(String nombre) {
  final n = nombre.toLowerCase();
  if (n.contains('bache') || n.contains('vial') || n.contains('calle')) return CodigoCategoria.bache;
  if (n.contains('alumbrado') || n.contains('luz') || n.contains('foco') || n.contains('luminaria')) {
    return CodigoCategoria.alumbrado;
  }
  if (n.contains('basura') || n.contains('residuo')) return CodigoCategoria.residuos;
  return null;
}

String fecha(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Marca de FIXA: el isotipo del logo y el nombre.
class MarcaFixa extends StatelessWidget {
  const MarcaFixa({super.key, this.subtitulo = 'Santa Cruz de la Sierra'});
  final String subtitulo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset('assets/logo_simbolo.png', height: 34, excludeFromSemantics: true),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('FIXA', style: tituloFixa(22)),
            Text(subtitulo, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}

/// Encabezado de los 3 pasos del reporte: volver, título y progreso.
class EncabezadoPaso extends StatelessWidget implements PreferredSizeWidget {
  const EncabezadoPaso({super.key, required this.paso, required this.onAtras, this.total = 3});
  final int paso;
  final int total;
  final VoidCallback onAtras;

  @override
  Size get preferredSize => const Size.fromHeight(104);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 24, 12),
        child: Column(
          children: [
            Row(
              children: [
                BotonRedondo(icono: Icons.arrow_back, etiqueta: 'Volver', onTap: onAtras),
                const SizedBox(width: 12),
                Text('Nuevo reporte',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('Paso $paso de $total',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: FixaColores.tinta2, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 14),
            Semantics(
              label: 'Paso $paso de $total',
              child: Row(
                children: [
                  for (var i = 1; i <= total; i++) ...[
                    if (i > 1) const SizedBox(width: 6),
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 6,
                        decoration: BoxDecoration(
                          color: i <= paso ? FixaColores.hojaOscura : FixaColores.linea,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón circular de 48 px (mínimo táctil de Android) con nombre accesible.
class BotonRedondo extends StatelessWidget {
  const BotonRedondo({super.key, required this.icono, required this.etiqueta, required this.onTap, this.fondo});
  final IconData icono;
  final String etiqueta;
  final VoidCallback onTap;
  final Color? fondo;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fondo ?? FixaColores.blanco,
      shape: const CircleBorder(side: BorderSide(color: FixaColores.linea)),
      child: IconButton(
        tooltip: etiqueta,
        onPressed: onTap,
        icon: Icon(icono, color: FixaColores.tinta),
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      ),
    );
  }
}

/// Barra blanca fija abajo con la acción principal de la pantalla.
class BarraAccion extends StatelessWidget {
  const BarraAccion({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: FixaColores.blanco,
        border: Border(top: BorderSide(color: FixaColores.linea)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(padding: const EdgeInsets.fromLTRB(24, 12, 24, 12), child: child),
      ),
    );
  }
}

/// Botón principal que muestra que está trabajando y no se puede tocar dos veces.
class BotonPrincipal extends StatelessWidget {
  const BotonPrincipal({super.key, required this.texto, this.onPressed, this.icono, this.cargando = false});
  final String texto;
  final VoidCallback? onPressed;
  final IconData? icono;
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    final contenido = cargando
        ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: FixaColores.blanco))
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icono != null) ...[Icon(icono, size: 22), const SizedBox(width: 10)],
              Flexible(child: Text(texto, textAlign: TextAlign.center)),
            ],
          );
    return FilledButton(
      onPressed: cargando ? null : onPressed,
      style: cargando ? FilledButton.styleFrom(disabledBackgroundColor: FixaColores.hojaOscura) : null,
      child: contenido,
    );
  }
}

/// Recuadro de aviso: información (menta), atención (sol) o error (naranja).
enum TipoAviso { info, atencion, error }

class Aviso extends StatelessWidget {
  const Aviso({super.key, required this.texto, this.tipo = TipoAviso.info, this.icono, this.titulo});
  final String texto;
  final String? titulo;
  final TipoAviso tipo;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    final (fondo, color, iconoPorDefecto) = switch (tipo) {
      TipoAviso.info => (FixaColores.menta, FixaColores.hojaOscura, Icons.verified_user_outlined),
      TipoAviso.atencion => (FixaColores.solClaro.withValues(alpha: 0.45), FixaColores.bosque, Icons.info_outline),
      TipoAviso.error => (FixaColores.naranjaSuave, FixaColores.naranjaTexto, Icons.error_outline),
    };
    return Semantics(
      liveRegion: tipo == TipoAviso.error,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(16)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono ?? iconoPorDefecto, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (titulo != null)
                    Text(titulo!, style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 16)),
                  Text(texto, style: TextStyle(color: tipo == TipoAviso.error ? color : FixaColores.tinta, fontSize: 15, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Las 4 etapas del reporte, con nombre en cada una: el color solo refuerza (accesibilidad).
class AvanceEtapas extends StatelessWidget {
  const AvanceEtapas({super.key, required this.estado});
  final EstadoCaso estado;

  @override
  Widget build(BuildContext context) {
    final etapa = estado.etapa;
    if (etapa == null) {
      return Aviso(texto: estado.texto, tipo: TipoAviso.atencion, icono: Icons.flag_outlined);
    }
    final actual = etapa.index;
    return Semantics(
      label: 'Etapa ${actual + 1} de 4: ${estado.texto}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: FixaColores.papel, borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('ESTADO ACTUAL',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: FixaColores.tinta2)),
                const Spacer(),
                Text('Etapa ${actual + 1} de 4',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: FixaColores.hojaOscura)),
              ],
            ),
            const SizedBox(height: 2),
            Text(estado.texto, style: tituloFixa(20, color: FixaColores.tinta)),
            const SizedBox(height: 10),
            Row(
              children: [
                for (var i = 0; i < 4; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: i < actual
                            ? FixaColores.hojaViva
                            : i == actual
                                ? (etapa == Etapa.cerrado ? FixaColores.hojaViva : FixaColores.sol)
                                : FixaColores.linea,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void mostrarMensaje(BuildContext context, String texto) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(texto)));
}
