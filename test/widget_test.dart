import 'package:fixa/core/router.dart';
import 'package:fixa/core/tema.dart';
import 'package:fixa/data/almacen_local.dart';
import 'package:fixa/data/mis_reportes.dart';
import 'package:fixa/data/mock_repositorio.dart';
import 'package:fixa/data/modelos.dart';
import 'package:fixa/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Future<MisReportes> _abrirApp(WidgetTester tester, [List<Credenciales> guardados = const []]) async {
  final mis = MisReportes(MockRepositorio(), AlmacenEnMemoria(guardados));
  await tester.pumpWidget(ChangeNotifierProvider.value(value: mis, child: FixaApp(router: crearRouter())));
  await tester.pumpAndSettle();
  return mis;
}

void main() {
  setUp(() => usarFuentesDeMarca = false);

  group('Etapas del reporte', () {
    test('cada estado de la API cae en una de las 4 etapas del portal', () {
      expect(const EstadoCaso('Recibida').etapa, Etapa.recibido);
      expect(const EstadoCaso('Asignada').etapa, Etapa.enRevision);
      expect(const EstadoCaso('En atención').etapa, Etapa.programado);
      expect(const EstadoCaso('Pendiente de validación').etapa, Etapa.programado);
      expect(const EstadoCaso('Cerrada').etapa, Etapa.cerrado);
    });

    test('rechazado, duplicado o derivado no tienen etapa', () {
      expect(const EstadoCaso('Rechazada').terminoSinArreglo, isTrue);
      expect(const EstadoCaso('Derivada a otra entidad').terminoSinArreglo, isTrue);
    });

    test('la conformidad solo se puede dar dentro de los 15 días del cierre', () {
      final cierre = DateTime(2026, 11, 10);
      final s = Seguimiento(
        codigo: 'FX-2026-000001',
        estado: const EstadoCaso('Cerrada'),
        categoria: 'Bache',
        fechaRegistro: cierre,
        fechaCierre: cierre,
        revisionDisponibleHasta: cierre.add(const Duration(days: 15)),
      );
      expect(s.puedeResponderCierre(DateTime(2026, 11, 20)), isTrue);
      expect(s.puedeResponderCierre(DateTime(2026, 11, 26)), isFalse);
    });
  });

  test('Mis reportes guarda el código y la clave una sola vez', () async {
    final mis = MisReportes(MockRepositorio(), AlmacenEnMemoria());
    await mis.cargar();
    const c = Credenciales(codigo: 'FX-2026-000418', clave: '7K2-9QD');
    await mis.guardar(c);
    await mis.guardar(c);
    expect(mis.guardados, hasLength(1));
  });

  testWidgets('La app abre en el inicio, sin pedir cuenta', (tester) async {
    await _abrirApp(tester);
    expect(find.text('Tu ciudad mejora contigo.'), findsOneWidget);
    expect(find.text('Crear mi primer reporte'), findsOneWidget);
    expect(find.text('Ingresar'), findsNothing);
  });

  testWidgets('Reportar empieza en el paso 1 con las 3 categorías', (tester) async {
    await _abrirApp(tester);
    await tester.tap(find.text('Crear mi primer reporte'));
    await tester.pumpAndSettle();
    expect(find.text('Paso 1 de 3'), findsOneWidget);
    for (final c in CodigoCategoria.values) {
      expect(find.text(c.etiqueta), findsOneWidget);
    }
    expect(find.text('Otro'), findsNothing);
  });

  testWidgets('Seguir un reporte con clave equivocada muestra el error', (tester) async {
    await _abrirApp(tester);
    await tester.tap(find.text('Seguir un reporte'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'FX-2026-999999');
    await tester.enterText(find.byType(TextField).last, 'AAA-BBBB');
    await tester.pump();
    await tester.tap(find.text('Ver mi reporte'));
    await tester.pumpAndSettle();
    expect(find.textContaining('no coinciden'), findsOneWidget);
  });

  testWidgets('Un reporte cerrado pide la conformidad', (tester) async {
    await _abrirApp(tester, [const Credenciales(codigo: 'FX-2026-000391', clave: 'ABC-1234', categoria: 'Alumbrado')]);
    await tester.tap(find.text('Mis reportes'));
    await tester.pumpAndSettle();
    expect(find.text('Cerrada'), findsOneWidget);
    expect(find.text('Sí, quedó bien'), findsOneWidget);
    // Deja terminar la consulta simulada que lanza la pantalla al abrirse.
    await tester.pump(const Duration(seconds: 1));
  });
}
