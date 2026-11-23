import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fixa/core/router.dart';

import 'package:fixa/data/almacen_local.dart';
import 'package:fixa/data/api_repositorio.dart';
import 'package:fixa/data/direccion_osm.dart';
import 'package:fixa/data/mis_reportes.dart';
import 'package:fixa/data/mock_repositorio.dart';
import 'package:fixa/data/modelos.dart';
import 'package:fixa/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

Future<MisReportes> _abrirApp(WidgetTester tester,
    [List<Credenciales> guardados = const []]) async {
  final mis = MisReportes(MockRepositorio(), AlmacenEnMemoria(guardados));
  await tester.pumpWidget(ChangeNotifierProvider.value(
      value: mis, child: FixaApp(router: crearRouter())));
  await tester.pumpAndSettle();
  return mis;
}

void main() {
  group('Etapas del reporte', () {
    test('cada estado de la API cae en una de las 4 etapas del portal', () {
      expect(const EstadoCaso('Recibida').etapa, Etapa.recibido);
      expect(const EstadoCaso('Asignada').etapa, Etapa.enRevision);
      expect(const EstadoCaso('En atención').etapa, Etapa.programado);
      expect(
          const EstadoCaso('Pendiente de validación').etapa, Etapa.programado);
      expect(const EstadoCaso('Cerrada').etapa, Etapa.cerrado);
    });

    test('rechazado, duplicado o derivado no tienen etapa', () {
      expect(const EstadoCaso('Rechazada').terminoSinArreglo, isTrue);
      expect(const EstadoCaso('Derivada a otra entidad').terminoSinArreglo,
          isTrue);
    });

    test('la conformidad solo se puede dar dentro de los 15 días del cierre',
        () {
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

  test('El reporte envía foto WebP, ubicación y token a la API existente',
      () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://fixa.test'));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (solicitud, respuesta) {
      expect(solicitud.path, '/reportes');
      final formulario = solicitud.data as FormData;
      final datos = Map.fromEntries(formulario.fields);
      expect(datos['Categoria'], 'bache');
      expect(datos['Latitud'], '-17.7834');
      expect(datos['Longitud'], '-63.1821');
      expect(datos['Direccion'], 'Av. Cañoto');
      expect(datos['Referencia'], 'Centro');
      expect(datos['TokenDispositivo'], 'token-de-prueba');
      expect(formulario.files.single.key, 'Fotos');
      expect(formulario.files.single.value.filename, 'foto.webp');
      expect(
          formulario.files.single.value.contentType.toString(), 'image/webp');
      respuesta.resolve(Response(
        requestOptions: solicitud,
        statusCode: 201,
        data: {'codigo': 'FX-000001', 'clave': 'ABC-1234'},
      ));
    }));
    final reporte = NuevoReporte(claveIdempotencia: 'idempotencia-prueba')
      ..categoria = CodigoCategoria.bache
      ..tipo = const TipoIncidencia('bache', 'Bache')
      ..descripcion = 'Bache profundo'
      ..latitud = -17.7834
      ..longitud = -63.1821
      ..direccion = const DireccionOsm(
        punto: LatLng(-17.7834, -63.1821),
        titulo: 'Av. Cañoto',
        detalle: 'Centro',
      )
      ..foto = Uint8List.fromList([1, 2, 3])
      ..tokenDispositivo = 'token-de-prueba';
    final creado = await ApiRepositorio(dio: dio).reportar(reporte);
    expect(creado.credenciales.codigo, 'FX-000001');
  });
  testWidgets('La app abre en el inicio, sin pedir cuenta', (tester) async {
    await _abrirApp(tester);
    expect(find.text('Tu ciudad mejora contigo.'), findsOneWidget);
    expect(find.text('Ver mapa'), findsOneWidget);
    expect(find.text('Ingresar'), findsNothing);
  });

  testWidgets('Reportar empieza en el paso 1 con las 3 categorías',
      (tester) async {
    await _abrirApp(tester);
    await tester.tap(find.text('Ver mapa'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Reportar un problema'));
    await tester.tap(find.text('Reportar un problema'));
    await tester.pumpAndSettle();
    expect(find.text('1 de 3'), findsOneWidget);
    for (final c in CodigoCategoria.values) {
      expect(find.text(c.etiqueta), findsOneWidget);
    }
    expect(find.text('Otro'), findsNothing);
    await tester.tap(find.text(CodigoCategoria.alumbrado.etiqueta));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Foto y lugar'), findsOneWidget);
    expect(find.text('2 de 3'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar ubicación'));
    await tester.pumpAndSettle();
    expect(find.text('Ubicación'), findsOneWidget);
  });

  testWidgets('Seguir un reporte con clave equivocada muestra el error',
      (tester) async {
    await _abrirApp(tester);
    await tester.tap(find.text('Seguir reporte'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'FX-2026-999999');
    await tester.enterText(find.byType(TextField).last, 'AAA-BBBB');
    await tester.pump();
    await tester.ensureVisible(find.text('Ver seguimiento'));
    await tester.tap(find.text('Ver seguimiento'));
    await tester.pumpAndSettle();
    expect(find.textContaining('no coinciden'), findsOneWidget);
  });

  testWidgets('Un reporte cerrado pide la conformidad', (tester) async {
    await _abrirApp(tester, [
      const Credenciales(
          codigo: 'FX-2026-000391', clave: 'ABC-1234', categoria: 'Alumbrado')
    ]);
    await tester.tap(find.text('Mis reportes'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Cerrado'), findsOneWidget);
    await tester.tap(find.text('FX-2026-000391'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Sí, quedó bien'), 180);
    expect(find.text('Sí, quedó bien'), findsOneWidget);
    // Deja terminar la consulta simulada que lanza la pantalla al abrirse.
    await tester.pump(const Duration(seconds: 1));
  });
}
