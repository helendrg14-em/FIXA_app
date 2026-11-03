import 'package:dio/dio.dart';

import '../core/config.dart';

/// Cliente HTTP hacia Laravel. El ciudadano no tiene cuenta,
/// así que las peticiones no llevan token.
class ApiClient {
  final Dio dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    headers: {'Accept': 'application/json'},
  ));
}
