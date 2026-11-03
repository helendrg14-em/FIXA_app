import 'package:fixa/core/router.dart';
import 'package:fixa/data/incidencias_repository.dart';
import 'package:fixa/features/incidencias/incidencias_provider.dart';
import 'package:fixa/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('La app abre en el mapa, sin pedir login', (tester) async {
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => IncidenciasProvider(MockIncidenciasRepository()),
      child: FixaApp(router: crearRouter()),
    ));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Reportar un problema'), findsOneWidget);
    expect(find.text('Mis reportes (3)'), findsOneWidget);
    expect(find.text('Ingresar'), findsNothing);
  });
}
