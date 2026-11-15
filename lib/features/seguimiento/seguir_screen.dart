import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/tema.dart';
import '../../data/mis_reportes.dart';
import '../../data/modelos.dart';
import '../../data/repositorio.dart';
import '../../ui/comunes.dart';

/// Seguir un reporte con código y clave (R06), por ejemplo si se envió desde otro celular.
class SeguirScreen extends StatefulWidget {
  const SeguirScreen({super.key});

  @override
  State<SeguirScreen> createState() => _SeguirScreenState();
}

class _SeguirScreenState extends State<SeguirScreen> {
  final _codigo = TextEditingController(text: 'FX-');
  final _clave = TextEditingController();
  bool _buscando = false;
  bool _verClave = false;
  String? _error;

  @override
  void dispose() {
    _codigo.dispose();
    _clave.dispose();
    super.dispose();
  }

  bool get _completo => _codigo.text.trim().length > 4 && _clave.text.trim().length >= 6;

  Future<void> _buscar() async {
    FocusScope.of(context).unfocus();
    final credenciales = Credenciales(
      codigo: _codigo.text.trim().toUpperCase(),
      clave: _clave.text.trim().toUpperCase(),
      guardadoEl: DateTime.now(),
    );
    setState(() {
      _buscando = true;
      _error = null;
    });
    final mis = context.read<MisReportes>();
    try {
      final s = await mis.repositorio.seguimiento(credenciales);
      await mis.guardar(Credenciales(
          codigo: credenciales.codigo, clave: credenciales.clave, categoria: s.categoria, guardadoEl: DateTime.now()));
      await mis.actualizarUno(credenciales);
      if (mounted) context.pushReplacement('/reporte/${credenciales.codigo}');
    } on FixaError catch (e) {
      if (mounted) {
        setState(() => _error = e.credencialesInvalidas ? 'El código o la clave no coinciden. Revisa que estén bien escritos.' : e.mensaje);
      }
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final etiqueta = Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 16);
    return Scaffold(
      appBar: AppBar(title: const Text('Seguir un reporte')),
      body: AutofillGroup(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            Text('Escribe tu código y tu clave', style: tituloFixa(30)),
            const SizedBox(height: 8),
            Text('Solo los necesitas si cambiaste de celular o reportaste desde otro.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: FixaColores.tinta2)),
            const SizedBox(height: 20),
            Text('Código', style: etiqueta),
            const SizedBox(height: 8),
            TextField(
              controller: _codigo,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: 1),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.tag), hintText: 'FX-2026-000418'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Text('Clave', style: etiqueta),
            const SizedBox(height: 8),
            TextField(
              controller: _clave,
              obscureText: !_verClave,
              textCapitalization: TextCapitalization.characters,
              autofillHints: const [AutofillHints.password],
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: 1),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline),
                hintText: '7K2-9QD',
                suffixIcon: IconButton(
                  tooltip: _verClave ? 'Ocultar la clave' : 'Mostrar la clave',
                  onPressed: () => setState(() => _verClave = !_verClave),
                  icon: Icon(_verClave ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                ),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _completo ? _buscar() : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Aviso(texto: _error!, tipo: TipoAviso.error),
            ],
            const SizedBox(height: 16),
            Material(
              color: FixaColores.menta,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.pushReplacement('/mis-reportes'),
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Row(children: [
                    Icon(Icons.smartphone, color: FixaColores.hojaOscura),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text('¿Lo enviaste desde este celular? Ya está en Mis reportes.',
                          style: TextStyle(fontWeight: FontWeight.w700, color: FixaColores.hojaOscura)),
                    ),
                    Icon(Icons.chevron_right, color: FixaColores.hojaOscura),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BarraAccion(
        child: BotonPrincipal(texto: 'Ver mi reporte', cargando: _buscando, onPressed: _completo ? _buscar : null),
      ),
    );
  }
}
