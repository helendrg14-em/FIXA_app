import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/config.dart';
import 'core/router.dart';
import 'core/tema.dart';
import 'data/api_client.dart';
import 'data/incidencias_repository.dart';
import 'features/incidencias/incidencias_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final IncidenciasRepository repo = AppConfig.usarMock
      ? MockIncidenciasRepository()
      : ApiIncidenciasRepository(ApiClient());

  runApp(ChangeNotifierProvider(
    create: (_) => IncidenciasProvider(repo),
    child: FixaApp(router: crearRouter()),
  ));
}

class FixaApp extends StatelessWidget {
  const FixaApp({super.key, required this.router});
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FIXA',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: crearTema(),
    );
  }
}
