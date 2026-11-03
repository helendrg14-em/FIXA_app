import 'package:go_router/go_router.dart';

import '../features/incidencias/mapa_screen.dart';
import '../features/incidencias/mis_reportes_screen.dart';
import '../features/incidencias/reportar_screen.dart';

/// Rutas de la app. El ciudadano la usa sin cuenta ni contraseña.
GoRouter crearRouter() => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const MapaScreen()),
        GoRoute(path: '/reportar', builder: (_, _) => const ReportarScreen()),
        GoRoute(path: '/mis-reportes', builder: (_, _) => const MisReportesScreen()),
      ],
    );
