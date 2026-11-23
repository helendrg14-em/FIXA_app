import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/tema.dart';
import '../../ui/comunes.dart';
import 'paisaje_fixa.dart';

class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                children: [
                  const MarcaFixa(),
                  const SizedBox(height: 25),
                  const PaisajeFixa(),
                  const SizedBox(height: 12),
                  Text('Tu ciudad mejora contigo.', style: tituloFixa(23)),
                  const SizedBox(height: 24),
                  _Acceso(
                    titulo: 'Ver mapa',
                    detalle: 'Explora y reporta un problema',
                    icono: Icons.map_outlined,
                    onTap: () => context.go('/mapa'),
                    destacado: true,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _Acceso(
                          titulo: 'Mis reportes',
                          detalle: 'En este celular',
                          icono: Icons.format_list_bulleted,
                          onTap: () => context.go('/mis-reportes'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Acceso(
                          titulo: 'Seguir reporte',
                          detalle: 'Con código y clave',
                          icono: Icons.search,
                          onTap: () => context.push('/seguir'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _Acceso extends StatelessWidget {
  const _Acceso(
      {required this.titulo,
      required this.detalle,
      required this.icono,
      required this.onTap,
      this.destacado = false});

  final String titulo;
  final String detalle;
  final IconData icono;
  final VoidCallback onTap;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final textos = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo,
            style: tituloFixa(destacado ? 17 : 16,
                color: destacado ? FixaColores.blanco : FixaColores.tinta)),
        const SizedBox(height: 6),
        Text(detalle,
            style: TextStyle(
                fontSize: 13,
                color: destacado ? FixaColores.blanco : FixaColores.tinta2)),
      ],
    );
    final insignia = IconoFixa(icono,
        fondo: destacado ? FixaColores.lima : FixaColores.menta,
        tamano: destacado ? 46 : 40);
    return TarjetaFixa(
      fondo: destacado ? FixaColores.bosque : FixaColores.blanco,
      borde: destacado ? FixaColores.bosque : FixaColores.linea,
      sombra: !destacado,
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: destacado
          ? Row(children: [
              insignia,
              const SizedBox(width: 12),
              Expanded(child: textos),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, color: FixaColores.blanco),
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              insignia,
              const SizedBox(height: 10),
              textos,
            ]),
    );
  }
}
