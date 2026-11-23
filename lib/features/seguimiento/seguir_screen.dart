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
            padding: const EdgeInsets.fromLTRB(15, 12, 15, 24),
            children: [
              Text('Consulta con tu\ncódigo y clave', style: tituloFixa(28)),
              const SizedBox(height: 22),
              const Text(
                  'Los encontrarás en el comprobante que recibiste al enviar tu reporte.',
                  style: TextStyle(color: FixaColores.tinta2)),
              const SizedBox(height: 24),
              Text('Código único', style: tituloFixa(16)),
              const SizedBox(height: 8),
              TextField(
                controller: _codigo,
                readOnly: _buscando,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
                decoration:
                    const InputDecoration(hintText: 'Código de tu comprobante'),
              ),
              const SizedBox(height: 10),
              Text('Clave privada', style: tituloFixa(16)),
              const SizedBox(height: 8),
              TextField(
                controller: _clave,
                readOnly: _buscando,
                obscureText: !_verClave,
                textCapitalization: TextCapitalization.characters,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  hintText: 'Clave de tu comprobante',
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
                const SizedBox(height: 10),
                Aviso(texto: error, tipo: TipoAviso.error),
              ],
              const SizedBox(height: 24),
              BotonPrincipal(
                  texto: 'Ver seguimiento',
                  icono: Icons.search,
                  cargando: _buscando,
                  onPressed: _buscar),
              const SizedBox(height: 22),
              TarjetaFixa(
                onTap: () => context.go('/mis-reportes'),
                child: Row(
                  children: [
                    const Icon(Icons.format_list_bulleted,
                        color: FixaColores.hojaOscura),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('¿Lo enviaste desde este celular?',
                              style: tituloFixa(14)),
                          const SizedBox(height: 4),
                          Text('Búscalo en Mis reportes.',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: FixaColores.hojaOscura),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const TextoConIcono(Icons.verified_user_outlined,
                  'Tu clave es privada. No la compartas.'),
            ],
          ),
        ),
      );
}
