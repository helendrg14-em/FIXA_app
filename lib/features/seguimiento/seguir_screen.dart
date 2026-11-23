import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/tema.dart';
import '../../data/mis_reportes.dart';
import '../../data/modelos.dart';
import '../../data/repositorio.dart';
import '../../ui/comunes.dart';

class SeguirScreen extends StatefulWidget {
  const SeguirScreen({super.key});

  @override
  State<SeguirScreen> createState() => _SeguirScreenState();
}

class _SeguirScreenState extends State<SeguirScreen> {
  final _codigo = TextEditingController();
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

  Future<void> _buscar() async {
    if (_buscando) return;
    FocusScope.of(context).unfocus();
    final codigo = _codigo.text.trim().toUpperCase();
    final clave = _clave.text.trim().toUpperCase();
    if (codigo.length <= 4 || clave.length < 6) {
      setState(
          () => _error = 'Ingresa el código y la clave de tu comprobante.');
      return;
    }
    final credenciales =
        Credenciales(codigo: codigo, clave: clave, guardadoEl: DateTime.now());
    setState(() {
      _buscando = true;
      _error = null;
    });
    final mis = context.read<MisReportes>();
    try {
      final seguimiento = await mis.repositorio.seguimiento(credenciales);
      final datos = Credenciales(
          codigo: codigo,
          clave: clave,
          categoria: seguimiento.categoria,
          guardadoEl: DateTime.now());
      await mis.guardarConsulta(datos, seguimiento);
      if (mounted) {
        context.pushReplacement('/reporte/${Uri.encodeComponent(codigo)}',
            extra: datos);
      }
    } on FixaError catch (error) {
      if (mounted) {
        setState(() => _error = error.credencialesInvalidas
            ? 'El código o la clave no coinciden. Revisa que estén bien escritos.'
            : error.mensaje);
      }
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Seguir un reporte')),
        body: AutofillGroup(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Text('Consulta con tu\ncódigo y clave', style: tituloFixa(26)),
              const SizedBox(height: 16),
              const Text(
                'Los encontrarás en el comprobante que recibiste al enviar tu reporte.',
                style: TextStyle(color: FixaColores.tinta2, fontSize: 14),
              ),
              const SizedBox(height: 22),
              Text('Código único', style: tituloFixa(15)),
              const SizedBox(height: 8),
              TextField(
                controller: _codigo,
                readOnly: _buscando,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
                decoration:
                    const InputDecoration(hintText: 'FX-2026-000418'),
              ),
              const SizedBox(height: 14),
              Text('Clave privada', style: tituloFixa(15)),
              const SizedBox(height: 8),
              TextField(
                controller: _clave,
                readOnly: _buscando,
                obscureText: !_verClave,
                textCapitalization: TextCapitalization.characters,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  suffixIcon: IconButton(
                    tooltip:
                        _verClave ? 'Ocultar la clave' : 'Mostrar la clave',
                    onPressed: () => setState(() => _verClave = !_verClave),
                    icon: Icon(_verClave
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                  ),
                ),
                onSubmitted: (_) => _buscar(),
              ),
              if (_error case final error?) ...[
                const SizedBox(height: 12),
                Aviso(texto: error, tipo: TipoAviso.error),
              ],
              const SizedBox(height: 22),
              BotonPrincipal(
                texto: 'Ver seguimiento',
                icono: Icons.search,
                cargando: _buscando,
                onPressed: _buscar,
              ),
              const SizedBox(height: 22),
              TarjetaFixa(
                padding: const EdgeInsets.all(16),
                onTap: () => context.go('/mis-reportes'),
                child: Row(
                  children: [
                    const Icon(Icons.format_list_bulleted,
                        color: FixaColores.hojaOscura, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('¿Lo enviaste desde este celular?',
                              style: tituloFixa(15)),
                          const SizedBox(height: 3),
                          const Text('Búscalo en Mis reportes.',
                              style: TextStyle(
                                  fontSize: 13, color: FixaColores.tinta2)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: FixaColores.hojaOscura, size: 22),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Row(
                children: [
                  Icon(Icons.verified_user_outlined,
                      size: 20, color: FixaColores.hojaOscura),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tu clave es privada. No la compartas.',
                      style:
                          TextStyle(fontSize: 13, color: FixaColores.tinta2),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}
