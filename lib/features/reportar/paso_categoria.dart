import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/tema.dart';
import '../../data/mis_reportes.dart';
import '../../data/modelos.dart';
import '../../data/repositorio.dart';
import '../../ui/comunes.dart';

class PasoCategoria extends StatefulWidget {
  const PasoCategoria(
      {super.key, required this.reporte, required this.alCambiar});
  final NuevoReporte reporte;
  final VoidCallback alCambiar;

  @override
  State<PasoCategoria> createState() => _PasoCategoriaState();
}

class _PasoCategoriaState extends State<PasoCategoria> {
  List<Categoria>? _categorias;
  List<TipoIncidencia>? _tipos;
  String? _errorCategorias;
  String? _errorTipos;

  Repositorio get _repo => context.read<MisReportes>().repositorio;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
    if (widget.reporte.categoria case final categoria?) _cargarTipos(categoria);
  }

  Future<void> _cargarCategorias() async {
    setState(() => _errorCategorias = null);
    try {
      final categorias = await _repo.categorias();
      if (mounted) setState(() => _categorias = categorias);
    } on FixaError catch (error) {
      if (mounted) setState(() => _errorCategorias = error.mensaje);
    }
  }

  Future<void> _cargarTipos(CodigoCategoria codigo) async {
    setState(() {
      _tipos = null;
      _errorTipos = null;
    });
    try {
      final tipos = await _repo.tipos(codigo);
      if (!mounted || widget.reporte.categoria != codigo) return;
      setState(() => _tipos = tipos);
      if (widget.reporte.tipo == null &&
          tipos.where((tipo) => !tipo.esOtro).length == 1) {
        _elegirTipo(tipos.firstWhere((tipo) => !tipo.esOtro));
      }
    } on FixaError catch (error) {
      if (mounted && widget.reporte.categoria == codigo) {
        setState(() => _errorTipos = error.mensaje);
      }
    }
  }

  void _elegirCategoria(Categoria categoria) {
    if (widget.reporte.categoria == categoria.codigo) return;
    widget.reporte
      ..fichaCategoria = categoria
      ..categoria = categoria.codigo
      ..tipo = null
      ..numeroLuminarias = null;
    widget.alCambiar();
    _cargarTipos(categoria.codigo);
  }

  void _elegirTipo(TipoIncidencia tipo) {
    widget.reporte.tipo = tipo;
    if (tipo.esOtro) widget.reporte.numeroLuminarias = null;
    widget.alCambiar();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final reporte = widget.reporte;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
      children: [
        Text('¿Qué problema hay?', style: tituloFixa(23)),
        const SizedBox(height: 14),
        const Text(
            'Elige una categoría. Nosotros lo enviamos a la unidad responsable.',
            style: TextStyle(color: FixaColores.tinta2)),
        const SizedBox(height: 16),
        if (_errorCategorias case final error?) ...[
          Aviso(texto: error, tipo: TipoAviso.error),
          TextButton(
              onPressed: _cargarCategorias,
              child: const Text('Volver a cargar categorías')),
        ] else if (_categorias == null)
          const Center(
              child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator()))
        else if (_categorias!.isEmpty)
          const Aviso(texto: 'No hay categorías disponibles.')
        else
          for (final categoria in _categorias!) ...[
            _OpcionCategoria(
              categoria: categoria,
              elegida: reporte.categoria == categoria.codigo,
              onTap: () => _elegirCategoria(categoria),
            ),
            const SizedBox(height: 8),
          ],
        if (reporte.categoria case final categoria?) ...[
          if (_errorTipos case final error?) ...[
            Aviso(texto: error, tipo: TipoAviso.error),
            TextButton(
                onPressed: () => _cargarTipos(categoria),
                child: const Text('Volver a cargar tipos')),
          ] else if (_tipos == null)
            const LinearProgressIndicator()
          else if (_tipos!.isEmpty)
            const Aviso(texto: 'No hay tipos disponibles para esta categoría.')
          else ...[
            const SizedBox(height: 8),
            Text('Tipo de problema', style: tituloFixa(15)),
            Wrap(
              spacing: 7,
              children: [
                for (final tipo in _tipos!)
                  FiltroFixa(
                      texto: tipo.texto,
                      activo: reporte.tipo?.valor == tipo.valor,
                      onTap: () => _elegirTipo(tipo)),
              ],
            ),
          ],
          if (categoria == CodigoCategoria.alumbrado &&
              reporte.tipo?.esOtro == false) ...[
            const SizedBox(height: 7),
            TarjetaFixa(
              child: Row(
                children: [
                  const Expanded(
                      child: Text('¿Cuántos focos están afectados?')),
                  IconButton(
                    tooltip: 'Uno menos',
                    onPressed: (reporte.numeroLuminarias ?? 0) > 1
                        ? () => _cambiarFocos(-1)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Text(reporte.numeroLuminarias?.toString() ?? '–'),
                  IconButton(
                    tooltip: 'Uno más',
                    onPressed: (reporte.numeroLuminarias ?? 0) < 200
                        ? () => _cambiarFocos(1)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
          ],
        ],
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => _mostrarOtrosCasos(context),
          icon: const Icon(Icons.info_outline),
          label: const Text('¿Es otro problema?'),
        ),
      ],
    );
  }

  void _cambiarFocos(int cambio) {
    final cantidad = (widget.reporte.numeroLuminarias ?? 0) + cambio;
    widget.reporte.numeroLuminarias = cantidad;
    widget.alCambiar();
    setState(() {});
  }

  void _mostrarOtrosCasos(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Si tu problema es otro', style: tituloFixa(23)),
              const SizedBox(height: 10),
              const ListTile(
                  title: Text('CRE'),
                  subtitle: Text(
                      'Cortes de luz en tu domicilio y fallas de la red eléctrica.')),
              const ListTile(
                  title: Text('ABC'),
                  subtitle: Text('Carreteras de la red vial fundamental.')),
              const ListTile(
                  title: Text('Gobernación de Santa Cruz'),
                  subtitle: Text('Asuntos de competencia departamental.')),
              const Aviso(
                tipo: TipoAviso.atencion,
                texto:
                    'FIXA no atiende emergencias. Si hay peligro inmediato, llama al 800125050.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpcionCategoria extends StatelessWidget {
  const _OpcionCategoria(
      {required this.categoria, required this.elegida, required this.onTap});
  final Categoria categoria;
  final bool elegida;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        selected: elegida,
        button: true,
        child: TarjetaFixa(
          fondo: elegida ? FixaColores.menta : FixaColores.blanco,
          borde: elegida ? FixaColores.hojaOscura : FixaColores.linea,
          sombra: true,
          onTap: onTap,
          child: Row(
            children: [
              IconoFixa(
                iconoDe(categoria.codigo),
                fondo: elegida ? FixaColores.hojaOscura : FixaColores.menta,
                color: elegida ? FixaColores.blanco : FixaColores.hojaOscura,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(categoria.codigo.etiqueta, style: tituloFixa(16)),
                    const SizedBox(height: 3),
                    Text(categoria.unidadVisible,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Icon(
                  elegida
                      ? Icons.check_circle_outline
                      : Icons.radio_button_unchecked,
                  color: FixaColores.hojaOscura,
                  size: 22),
            ],
          ),
        ),
      );
}
