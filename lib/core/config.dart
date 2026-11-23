/// Configuración global de la app. Los valores se pueden cambiar al compilar, sin tocar el código:
/// `flutter run --dart-define=FIXA_MOCK=false --dart-define=FIXA_API=https://...`
class AppConfig {
  /// Con `true` la app usa datos de ejemplo en memoria y no llama a la API.
  static const bool usarMock =
      bool.fromEnvironment('FIXA_MOCK', defaultValue: false);

  /// API .NET de FIXA (Fixa_API) desplegada en Render. Para probar con la API de tu PC:
  /// `--dart-define=FIXA_API=http://10.0.2.2:5112/api/v1/publico` (10.0.2.2 es tu PC vista desde el emulador).
  static const String apiBaseUrl = String.fromEnvironment('FIXA_API',
      defaultValue: 'https://fixa-api-nhua.onrender.com/api/v1/publico');

  /// Centro de Santa Cruz de la Sierra (plaza 24 de Septiembre).
  static const double latInicial = -17.7834;
  static const double lngInicial = -63.1821;

  /// Requerido por la política de uso de los tiles de OpenStreetMap.
  static const String userAgent = 'com.fixa.fixa';

  static const ciudad = 'Santa Cruz de la Sierra';
  static const tilesOsm = String.fromEnvironment(
    'FIXA_OSM_TILES',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );
  static const geocodificadorOsm = String.fromEnvironment(
    'FIXA_OSM_GEOCODER',
    defaultValue: 'https://nominatim.openstreetmap.org',
  );
}
