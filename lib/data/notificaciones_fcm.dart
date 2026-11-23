import 'package:flutter/services.dart';

class NotificacionesFcm {
  static const _canal = MethodChannel('com.fixa.fixa/notificaciones');

  Future<bool> disponibles() async {
    try {
      return await _canal.invokeMethod<bool>('disponibles') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<String?> solicitarToken() async {
    try {
      final token = await _canal.invokeMethod<String>('solicitarToken');
      return token != null && token.isNotEmpty && token.length <= 255
          ? token
          : null;
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
