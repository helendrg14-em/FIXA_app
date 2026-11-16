import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/config.dart';
import 'core/router.dart';
import 'core/tema.dart';
import 'data/almacen_local.dart';
import 'data/api_repositorio.dart';
import 'data/mis_reportes.dart';
import 'data/mock_repositorio.dart';
import 'data/repositorio.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final Repositorio repositorio = AppConfig.usarMock ? MockRepositorio() : ApiRepositorio();
  if (repositorio is ApiRepositorio) repositorio.despertar();

  runApp(ChangeNotifierProvider(
    create: (_) => MisReportes(repositorio, AlmacenLocal())..cargar(),
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
