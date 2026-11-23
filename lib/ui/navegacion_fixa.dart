import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/tema.dart';

class NavegacionFixa extends StatelessWidget {
  const NavegacionFixa({super.key, required this.ruta, required this.child});

  final String ruta;
  final Widget child;

  static const _destinos = [
    ('/', 'Inicio', Icons.home_outlined),
    ('/mapa', 'Mapa', Icons.map_outlined),
    ('/mis-reportes', 'Mis reportes', Icons.format_list_bulleted),
  ];

  @override
  Widget build(BuildContext context) {
    if (ruta == '/') return child;
    return Scaffold(
      body: child,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: FixaColores.blanco,
          border: Border(top: BorderSide(color: FixaColores.linea)),
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(10, 7, 10, 6),
          child: Row(
            children: [
              for (final (rutaDestino, etiqueta, icono) in _destinos)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _Destino(
                      etiqueta: etiqueta,
                      icono: icono,
                      seleccionado: ruta == rutaDestino,
                      onTap: () {
                        if (ruta != rutaDestino) context.go(rutaDestino);
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Destino extends StatelessWidget {
  const _Destino(
      {required this.etiqueta,
      required this.icono,
      required this.seleccionado,
      required this.onTap});

  final String etiqueta;
  final IconData icono;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = seleccionado ? FixaColores.hojaOscura : FixaColores.tinta2;
    return Semantics(
      selected: seleccionado,
      button: true,
      child: Material(
        color: seleccionado ? FixaColores.menta : FixaColores.blanco,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icono, color: color, size: 23),
                const SizedBox(height: 4),
                Text(etiqueta,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
