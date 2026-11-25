import 'package:flutter/material.dart';

import '../../core/tema.dart';

/// Encabezado de Inicio: ilustración de la Catedral de Santa Cruz en la plaza
/// 24 de Septiembre, recortada sin textos.
class PaisajeFixa extends StatelessWidget {
  const PaisajeFixa({super.key});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 1.5,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/catedral_santa_cruz.webp',
                fit: BoxFit.cover,
                semanticLabel:
                    'Catedral de Santa Cruz de la Sierra en la plaza 24 de Septiembre',
                // Mientras se decodifica, un fondo del tono del cielo de la ilustración.
                frameBuilder: (_, imagen, cuadro, sincrona) =>
                    sincrona || cuadro != null
                        ? imagen
                        : const ColoredBox(color: Color(0xFF8FBBD3)),
              ),
              // Velo semitransparente del color de fondo de la app: suaviza la imagen
              // y la funde hacia abajo, para que no le quite protagonismo al resto.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      FixaColores.papel.withValues(alpha: 0.25),
                      FixaColores.papel.withValues(alpha: 0.35),
                      FixaColores.papel.withValues(alpha: 0.75),
                    ],
                    stops: const [0, 0.55, 1],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
