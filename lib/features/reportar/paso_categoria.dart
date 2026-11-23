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
  String? _errorCategorias;

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
    try {
      final tipos = await _repo.tipos(codigo);
      if (!mounted || widget.reporte.categoria != codigo) return;
      if (tipos.isNotEmpty) {
        final tipoValido =
            tipos.where((tipo) => !tipo.esOtro).firstOrNull ?? tipos.first;
        _elegirTipo(tipoValido);
      }
    } on FixaError {
      // La asignación por defecto ya está lista.
    }
  }

  void _elegirCategoria(Categoria categoria) {
    widget.reporte
      ..fichaCategoria = categoria
      ..categoria = categoria.codigo
      ..tipo = TipoIncidencia(categoria.codigo.name, categoria.nombre)
      ..numeroLuminarias =
          categoria.codigo == CodigoCategoria.alumbrado ? 1 : null;
    widget.alCambiar();
    setState(() {});
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
            const SizedBox(height: 12),
          ],
        const SizedBox(height: 16),
        Center(
          child: TextButton.icon(
            onPressed: () => _mostrarOtrosCasos(context),
            icon: const Icon(Icons.info_outline, color: FixaColores.hojaOscura),
            label: const Text('¿Es otro problema?',
                style: TextStyle(
                    color: FixaColores.hojaOscura,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
          ),
        ),
      ],
    );
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          sombra: false,
          onTap: onTap,
          child: Row(
            children: [
              IconoFixa(
                iconoDe(categoria.codigo),
                fondo: elegida
                    ? FixaColores.hojaOscura
                    : const Color(0xFFE8F3EC),
                color: elegida ? FixaColores.blanco : FixaColores.hojaOscura,
                tamano: 44,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(categoria.codigo.etiqueta,
                        style: tituloFixa(16, color: FixaColores.tinta)),
                    const SizedBox(height: 3),
                    Text(
                      categoria.unidadVisible,
                      style: const TextStyle(
                          fontSize: 13,
                          color: FixaColores.tinta2,
                          fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                elegida ? Icons.check_circle : Icons.radio_button_unchecked,
                color: elegida ? FixaColores.hojaOscura : FixaColores.tinta,
                size: 24,
              ),
            ],
          ),
        ),
      );
}
