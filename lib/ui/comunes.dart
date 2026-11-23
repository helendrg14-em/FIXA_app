import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/config.dart';
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
  if (n.contains('bache') || n.contains('vial') || n.contains('calle')) {
    return CodigoCategoria.bache;
  }
  if (n.contains('alumbrado') ||
      n.contains('luz') ||
      n.contains('foco') ||
      n.contains('luminaria')) {
    return CodigoCategoria.alumbrado;
  }
  if (n.contains('basura') || n.contains('residuo')) {
    return CodigoCategoria.residuos;
  }
  return null;
}

String fecha(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Marca de FIXA: el isotipo del logo y el nombre.
class MarcaFixa extends StatelessWidget {
  const MarcaFixa({super.key, this.subtitulo = AppConfig.ciudad});
  final String subtitulo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset('assets/logo_simbolo.png',
            height: 32, excludeFromSemantics: true),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('FIXA', style: tituloFixa(18)),
            Text(subtitulo, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}

class EncabezadoPaso extends StatelessWidget implements PreferredSizeWidget {
  const EncabezadoPaso(
      {super.key, required this.paso, required this.onAtras, this.total = 3});
  final int paso;
  final int total;
  final VoidCallback? onAtras;

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: FixaColores.sistema,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    BackButton(onPressed: onAtras),
                    Expanded(
                        child: Text('Nuevo reporte', style: tituloFixa(16))),
                    Text('$paso de $total',
                        style: const TextStyle(
                            color: FixaColores.tinta2,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(width: 4),
                  ],
                ),
                const SizedBox(height: 7),
                Semantics(
                    label: 'Paso $paso de $total',
                    child: BarrasFixa(actual: paso, total: total)),
              ],
            ),
          ),
        ),
      );
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
        child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10), child: child),
      ),
    );
  }
}

/// Botón principal que muestra que está trabajando y no se puede tocar dos veces.
class BotonPrincipal extends StatelessWidget {
  const BotonPrincipal(
      {super.key,
      required this.texto,
      this.onPressed,
      this.icono,
      this.cargando = false});
  final String texto;
  final VoidCallback? onPressed;
  final IconData? icono;
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    final contenido = cargando
        ? const SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2.5, color: FixaColores.blanco))
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icono != null) ...[
                Icon(icono, size: 22),
                const SizedBox(width: 10)
              ],
              Flexible(child: Text(texto, textAlign: TextAlign.center)),
            ],
          );
    return FilledButton(
      onPressed: cargando ? null : onPressed,
      style: cargando
          ? FilledButton.styleFrom(
              disabledBackgroundColor: FixaColores.hojaOscura)
          : null,
      child: contenido,
    );
  }
}

/// Recuadro de aviso: información (menta), atención (sol) o error (naranja).
enum TipoAviso { info, atencion, error }

class Aviso extends StatelessWidget {
  const Aviso(
      {super.key,
      required this.texto,
      this.tipo = TipoAviso.info,
      this.icono,
      this.titulo});
  final String texto;
  final String? titulo;
  final TipoAviso tipo;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    final (fondo, color, iconoPorDefecto) = switch (tipo) {
      TipoAviso.info => (
          FixaColores.menta,
          FixaColores.hojaOscura,
          Icons.verified_user_outlined
        ),
      TipoAviso.atencion => (
          FixaColores.solClaro.withValues(alpha: 0.45),
          FixaColores.bosque,
          Icons.info_outline
        ),
      TipoAviso.error => (
          FixaColores.naranjaSuave,
          FixaColores.naranjaTexto,
          Icons.error_outline
        ),
    };
    return Semantics(
      liveRegion: tipo == TipoAviso.error,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: fondo, borderRadius: BorderRadius.circular(16)),
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
                    Text(titulo!,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: color,
                            fontSize: 16)),
                  Text(texto,
                      style: TextStyle(
                          color: tipo == TipoAviso.error
                              ? color
                              : FixaColores.tinta,
                          fontSize: 15,
                          height: 1.4)),
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
      return Aviso(
          texto: estado.texto,
          tipo: TipoAviso.atencion,
          icono: Icons.flag_outlined);
    }
    final actual = etapa.index;
    return Semantics(
      label: 'Etapa ${actual + 1} de 4: ${estado.texto}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: FixaColores.papel, borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('ESTADO ACTUAL',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: FixaColores.tinta2)),
                const Spacer(),
                Text('Etapa ${actual + 1} de 4',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: FixaColores.hojaOscura)),
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
                                ? (etapa == Etapa.cerrado
                                    ? FixaColores.hojaViva
                                    : FixaColores.sol)
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

class TarjetaFixa extends StatelessWidget {
  const TarjetaFixa({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.fondo = FixaColores.blanco,
    this.borde = FixaColores.linea,
    this.sombra = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color fondo;
  final Color borde;
  final bool sombra;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final contenido = Padding(padding: padding, child: child);
    return Material(
      color: fondo,
      elevation: sombra ? 2 : 0,
      shadowColor: const Color(0x2A1C334F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side:
            BorderSide(color: borde, width: fondo == FixaColores.menta ? 2 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      child:
          onTap == null ? contenido : InkWell(onTap: onTap, child: contenido),
    );
  }
}

class IconoFixa extends StatelessWidget {
  const IconoFixa(this.icono,
      {super.key,
      this.fondo = FixaColores.menta,
      this.color = FixaColores.hojaOscura,
      this.tamano = 40});

  final IconData icono;
  final Color fondo;
  final Color color;
  final double tamano;

  @override
  Widget build(BuildContext context) => Container(
        width: tamano,
        height: tamano,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: fondo, borderRadius: BorderRadius.circular(12)),
        child: Icon(icono, size: 22, color: color),
      );
}

class FiltroFixa extends StatelessWidget {
  const FiltroFixa(
      {super.key,
      required this.texto,
      required this.activo,
      required this.onTap});

  final String texto;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ChoiceChip(
        label: Text(texto),
        selected: activo,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        labelStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: activo ? FixaColores.hojaOscura : FixaColores.tinta2),
        backgroundColor: FixaColores.blanco,
        selectedColor: FixaColores.menta,
        side: BorderSide(
            color: activo ? FixaColores.hojaOscura : FixaColores.linea),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      );
}

class EstadoFixa extends StatelessWidget {
  const EstadoFixa(this.estado, {super.key});
  final EstadoCaso estado;

  static Color colorDe(EstadoCaso estado) => switch (estado.etapa) {
        Etapa.recibido => FixaColores.naranjaTexto,
        Etapa.enRevision || Etapa.programado => FixaColores.azul,
        Etapa.cerrado => FixaColores.hojaOscura,
        null => FixaColores.tinta2,
      };

  @override
  Widget build(BuildContext context) {
    final (icono, fondo) = switch (estado.etapa) {
      Etapa.recibido => (Icons.schedule, FixaColores.solClaro),
      Etapa.enRevision => (Icons.search, FixaColores.azulSuave),
      Etapa.programado => (Icons.build_outlined, FixaColores.azulSuave),
      Etapa.cerrado => (Icons.check_circle_outline, FixaColores.lima),
      null => (Icons.flag_outlined, FixaColores.papel),
    };
    final color = colorDe(estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, color: color, size: 16),
          const SizedBox(width: 4),
          Flexible(
              child: Text(estado.etapa?.texto ?? estado.texto,
                  style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class BarrasFixa extends StatelessWidget {
  const BarrasFixa(
      {super.key,
      required this.actual,
      required this.total,
      this.color = FixaColores.bosque});
  final int actual;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: i < actual ? color : FixaColores.linea,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ],
      );
}

class TextoConIcono extends StatelessWidget {
  const TextoConIcono(this.icono, this.texto, {super.key});
  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icono, size: 19, color: FixaColores.hojaOscura),
          const SizedBox(width: 9),
          Expanded(
              child: Text(texto, style: Theme.of(context).textTheme.bodySmall)),
        ],
      );
}

String fechaCorta(DateTime fecha, {bool incluirHora = false}) {
  const meses = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic'
  ];
  final local = fecha.toLocal();
  final dia = '${local.day} ${meses[local.month - 1]}';
  if (!incluirHora) return dia;
  final hora = local.hour.toString().padLeft(2, '0');
  final minutos = local.minute.toString().padLeft(2, '0');
  return '$dia ${local.year} · $hora:$minutos';
}
