import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/tema.dart';
import '../../data/mis_reportes.dart';
import '../../data/modelos.dart';
import '../../ui/comunes.dart';
import 'conformidad.dart';

/// Reportes guardados en este celular, con su estado actual (R06) y la conformidad (R12).
class MisReportesScreen extends StatefulWidget {
  const MisReportesScreen({super.key});

  @override
  State<MisReportesScreen> createState() => _MisReportesScreenState();
}

class _MisReportesScreenState extends State<MisReportesScreen> {
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
    return Scaffold(
      appBar: AppBar(title: const Text('Mis reportes')),
      body: RefreshIndicator(
        onRefresh: mis.actualizar,
        child: mis.guardados.isEmpty
            ? ListView(
                padding: const EdgeInsets.fromLTRB(32, 80, 32, 32),
                children: [
                  const Icon(Icons.campaign_outlined, size: 56, color: FixaColores.hojaOscura),
                  const SizedBox(height: 16),
                  Text('Aún no tienes reportes en este celular', textAlign: TextAlign.center, style: tituloFixa(22)),
                  const SizedBox(height: 8),
                  const Text('Cuando envíes uno, aquí verás en qué etapa está. Si lo enviaste desde otro celular, '
                      'búscalo con tu código y clave.',
                      textAlign: TextAlign.center, style: TextStyle(color: FixaColores.tinta2)),
                  const SizedBox(height: 20),
                  OutlinedButton(onPressed: () => context.push('/seguir'), child: const Text('Seguir con código y clave')),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: mis.guardados.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (_, i) => _Tarjeta(credenciales: mis.guardados[i]),
              ),
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.credenciales});
  final Credenciales credenciales;

  @override
  Widget build(BuildContext context) {
    final mis = context.watch<MisReportes>();
    final estado = mis.estadoDe(credenciales.codigo);
    final error = mis.errorDe(credenciales.codigo);
    final categoria = estado?.categoria ?? credenciales.categoria ?? 'Reporte';

    return Material(
      color: FixaColores.blanco,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: FixaColores.linea)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/reporte/${credenciales.codigo}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: FixaColores.menta, borderRadius: BorderRadius.circular(14)),
                    child: Icon(iconoDe(categoriaPorNombre(categoria)), color: FixaColores.hojaOscura),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(categoria, style: tituloFixa(18, color: FixaColores.tinta)),
                        Text('Código · ${credenciales.codigo}', style: const TextStyle(color: FixaColores.tinta2, fontSize: 14)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: FixaColores.tinta2),
                ],
              ),
              const SizedBox(height: 14),
              if (estado != null)
                AvanceEtapas(estado: estado.estado)
              else if (error != null)
                Aviso(texto: error, tipo: TipoAviso.error)
              else
                const LinearProgressIndicator(),
              if (estado != null && estado.puedeResponderCierre(DateTime.now()) && estado.conformidad == null) ...[
                const SizedBox(height: 14),
                BloqueConformidad(credenciales: credenciales, seguimiento: estado),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
