/// Configuración global de la app.
class AppConfig {
  /// Mientras no exista el backend Laravel, la app usa datos en memoria.
  /// Cambiar a `false` cuando la API esté corriendo.
  static const bool usarMock = true;

  /// URL de la API Laravel. Desde el emulador Android, `10.0.2.2`
  /// apunta al `localhost` de tu PC (`php artisan serve` usa el puerto 8000).
  static const String apiBaseUrl = 'http://10.0.2.2:8000/api';

  /// Centro de Santa Cruz de la Sierra (plaza 24 de Septiembre).
  static const double latInicial = -17.7834;
  static const double lngInicial = -63.1821;

  /// Requerido por la política de uso de los tiles de OpenStreetMap.
  static const String userAgent = 'com.fixa.fixa';
}
