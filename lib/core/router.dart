import 'package:go_router/go_router.dart';

import '../data/modelos.dart';
import '../features/inicio/inicio_screen.dart';
import '../features/mapa/mapa_screen.dart';
import '../features/reportar/reportar_screen.dart';
import '../features/seguimiento/detalle_screen.dart';
import '../features/seguimiento/enviado_screen.dart';
import '../features/seguimiento/mis_reportes_screen.dart';
import '../features/seguimiento/seguir_screen.dart';
import '../ui/navegacion_fixa.dart';

GoRouter crearRouter() => GoRouter(
      initialLocation: '/',
      routes: [
        ShellRoute(
          builder: (_, estado, child) =>
              NavegacionFixa(ruta: estado.uri.path, child: child),
          routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => const InicioScreen(),
            ),
            GoRoute(
              path: '/mapa',
              builder: (_, __) => const MapaScreen(),
            ),
            GoRoute(
              path: '/mis-reportes',
              builder: (_, __) => const MisReportesScreen(),
            ),
          ],
        ),
        GoRoute(path: '/reportar', builder: (_, __) => const ReportarScreen()),
        GoRoute(
          path: '/enviado',
          redirect: (_, estado) =>
              estado.extra is (ReporteCreado, bool) ? null : '/',
          builder: (_, estado) {
            final (creado, guardado) = estado.extra! as (ReporteCreado, bool);
            return EnviadoScreen(creado: creado, guardado: guardado);
          },
        ),
        GoRoute(path: '/seguir', builder: (_, __) => const SeguirScreen()),
        GoRoute(
          path: '/reporte/:codigo',
          builder: (_, estado) => DetalleScreen(
              codigo: estado.pathParameters['codigo']!,
              acceso: estado.extra is Credenciales
                  ? estado.extra as Credenciales
                  : null),
        ),
      ],
    );
