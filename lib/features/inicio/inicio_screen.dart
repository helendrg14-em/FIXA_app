import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/tema.dart';
import '../../data/mis_reportes.dart';
import '../../ui/comunes.dart';

/// Inicio: qué hacer y los reportes guardados en este celular.
class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final mis = context.read<MisReportes>();
      if (!mis.cargado) await mis.cargar();
      await mis.actualizar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mis = context.watch<MisReportes>();
    final cantidad = mis.guardados.length;
    final porConfirmar = mis.porConfirmar;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            const MarcaFixa(),
            const SizedBox(height: 32),
            Text('Tu ciudad mejora contigo.', style: tituloFixa(36)),
            const SizedBox(height: 10),
            Text('Reporta un bache, un foco apagado o basura acumulada. No necesitas crear una cuenta.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: FixaColores.tinta2)),
            if (porConfirmar.isNotEmpty) ...[
              const SizedBox(height: 20),
              _TarjetaAcceso(
                icono: Icons.lightbulb_outline,
                titulo: 'Tu reporte ya se cerró',
                detalle: '¿Quedó bien? Responde aquí',
                destacado: true,
                onTap: () => context.push('/reporte/${porConfirmar.first.codigo}'),
              ),
            ],
            const SizedBox(height: 28),
            Text('Tus reportes', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _TarjetaAcceso(
              icono: Icons.campaign_outlined,
              titulo: 'Mis reportes',
              detalle: cantidad == 0
                  ? 'Aún no tienes reportes en este celular.'
                  : cantidad == 1
                      ? '1 reporte guardado en este celular.'
                      : '$cantidad reportes guardados en este celular.',
              onTap: () => context.push('/mis-reportes'),
            ),
            const SizedBox(height: 12),
            _TarjetaAcceso(
              icono: Icons.search,
              titulo: 'Seguir un reporte',
              detalle: 'Consulta con tu código y clave.',
              onTap: () => context.push('/seguir'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BarraAccion(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BotonPrincipal(
              texto: cantidad == 0 ? 'Crear mi primer reporte' : 'Reportar un problema',
              icono: Icons.photo_camera_outlined,
              onPressed: () => context.push('/reportar'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => context.push('/mapa'),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Explorar el mapa'),
            ),
            const SizedBox(height: 8),
            const Text('Baches · Alumbrado · Basura',
                style: TextStyle(color: FixaColores.tinta2, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _TarjetaAcceso extends StatelessWidget {
  const _TarjetaAcceso({
    required this.icono,
    required this.titulo,
    required this.detalle,
    required this.onTap,
    this.destacado = false,
  });
  final IconData icono;
  final String titulo;
  final String detalle;
  final VoidCallback onTap;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: destacado ? FixaColores.solClaro.withValues(alpha: 0.45) : FixaColores.blanco,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: destacado ? BorderSide.none : const BorderSide(color: FixaColores.linea),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: destacado ? FixaColores.sol : FixaColores.menta,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icono, color: destacado ? FixaColores.bosque : FixaColores.hojaOscura, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: tituloFixa(19, color: FixaColores.tinta)),
                    const SizedBox(height: 2),
                    Text(detalle, style: const TextStyle(color: FixaColores.tinta2, fontSize: 15)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, color: FixaColores.hojaOscura),
            ],
          ),
        ),
      ),
    );
  }
}
