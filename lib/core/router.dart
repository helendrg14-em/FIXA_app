import 'package:go_router/go_router.dart';

import '../data/modelos.dart';
import '../features/inicio/inicio_screen.dart';
import '../features/mapa/mapa_screen.dart';
import '../features/reportar/reportar_screen.dart';
import '../features/seguimiento/detalle_screen.dart';
import '../features/seguimiento/enviado_screen.dart';
import '../features/seguimiento/mis_reportes_screen.dart';
import '../features/seguimiento/seguir_screen.dart';

/// Rutas de la app. El ciudadano la usa sin cuenta ni contraseña.
GoRouter crearRouter() => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const InicioScreen()),
        GoRoute(path: '/mapa', builder: (_, _) => const MapaScreen()),
        GoRoute(path: '/reportar', builder: (_, _) => const ReportarScreen()),
        GoRoute(
          path: '/enviado',
          redirect: (_, estado) => estado.extra is (ReporteCreado, bool) ? null : '/',
          builder: (_, estado) {
            final (creado, guardado) = estado.extra! as (ReporteCreado, bool);
            return EnviadoScreen(creado: creado, guardado: guardado);
          },
        ),
        GoRoute(path: '/mis-reportes', builder: (_, _) => const MisReportesScreen()),
        GoRoute(path: '/seguir', builder: (_, _) => const SeguirScreen()),
        GoRoute(path: '/reporte/:codigo', builder: (_, estado) => DetalleScreen(codigo: estado.pathParameters['codigo']!)),
      ],
    );
