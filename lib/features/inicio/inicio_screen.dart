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
                  BotonPrincipal(
                    texto: 'Reportar un problema',
                    icono: Icons.photo_camera_outlined,
                    onPressed: () => context.push('/reportar'),
                  ),
                  const SizedBox(height: 12),
                  // Misma altura para las dos tarjetas aunque un título ocupe dos líneas.
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                            titulo: 'Consultar seguimiento',
                            detalle: 'Con código y clave',
                            icono: Icons.search,
                            onTap: () => context.push('/seguir'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

/// Tarjeta de acceso secundaria de Inicio (Mis reportes y Consultar seguimiento).
class _Acceso extends StatelessWidget {
  const _Acceso(
      {required this.titulo,
      required this.detalle,
      required this.icono,
      required this.onTap});

  final String titulo;
  final String detalle;
  final IconData icono;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => TarjetaFixa(
        sombra: true,
        padding: const EdgeInsets.all(16),
        onTap: onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          IconoFixa(icono, fondo: FixaColores.menta, tamano: 40),
          const SizedBox(height: 10),
          Text(titulo, style: tituloFixa(16)),
          const SizedBox(height: 6),
          Text(detalle,
              style: const TextStyle(fontSize: 13, color: FixaColores.tinta2)),
        ]),
      );
}
