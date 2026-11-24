import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/tema.dart';
import '../../data/mis_reportes.dart';
import '../../data/modelos.dart';
import '../../data/repositorio.dart';
import '../../ui/comunes.dart';
import 'tarjeta_reporte.dart';

class SeguirScreen extends StatefulWidget {
  const SeguirScreen({super.key});

  @override
  State<SeguirScreen> createState() => _SeguirScreenState();
}

class _SeguirScreenState extends State<SeguirScreen> {
  /// Más que esto alarga la pantalla; el resto queda en «Mis reportes».
  static const _maximoEnLista = 5;

  final _codigo = TextEditingController();
  final _clave = TextEditingController();
  bool _buscando = false;
  bool _verClave = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Muestra los reportes guardados con su estado actual, sin que el vecino escriba nada.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final mis = context.read<MisReportes>();
      try {
        await mis.cargar();
        await mis.actualizar();
      } on Exception {
        // Si falla, la lista se muestra sin estado y los campos siguen disponibles.
      }
    });
  }

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
  Widget build(BuildContext context) {
    final mis = context.watch<MisReportes>();
    final guardados = mis.recientes;
    return Scaffold(
      appBar: AppBar(title: const Text('Seguir un reporte')),
      body: AutofillGroup(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            if (guardados.isNotEmpty) ...[
              Text('Tus reportes en este celular', style: tituloFixa(20)),
              const SizedBox(height: 4),
              const Text(
                  'Toca uno para ver cómo va. Primero los que siguen abiertos.',
                  style: TextStyle(color: FixaColores.tinta2, fontSize: 14)),
              const SizedBox(height: 14),
              for (final credenciales in guardados.take(_maximoEnLista))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TarjetaReporte(
                    credenciales: credenciales,
                    seguimiento: mis.estadoDe(credenciales.codigo),
                    error: mis.errorDe(credenciales.codigo),
                  ),
                ),
              if (guardados.length > _maximoEnLista)
                TextButton(
                  onPressed: () => context.go('/mis-reportes'),
                  child: Text('Ver los ${guardados.length} en Mis reportes'),
                ),
              const SizedBox(height: 18),
              Text('¿Tienes otro código?', style: tituloFixa(20)),
            ] else
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
              decoration: const InputDecoration(hintText: 'FX-2026-000418'),
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
                  tooltip: _verClave ? 'Ocultar la clave' : 'Mostrar la clave',
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
            const Row(
              children: [
                Icon(Icons.verified_user_outlined,
                    size: 20, color: FixaColores.hojaOscura),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tu clave es privada. No la compartas.',
                    style: TextStyle(fontSize: 13, color: FixaColores.tinta2),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
