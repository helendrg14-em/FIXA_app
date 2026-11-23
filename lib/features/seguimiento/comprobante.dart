import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/tema.dart';
import '../../data/modelos.dart';

class Comprobante {
  static const _canal = MethodChannel('com.fixa.fixa/comprobante');

  Future<bool> guardarImagen(ReporteCreado reporte) async {
    final imagen = await _crearImagen(reporte);
    final codigo =
        reporte.credenciales.codigo.replaceAll(RegExp(r'[^A-Za-z0-9-]'), '_');
    return await _canal.invokeMethod<bool>('guardarImagen', {
          'nombre': 'FIXA-$codigo.png',
          'bytes': imagen,
        }) ??
        false;
  }

  Future<void> abrirCorreo(ReporteCreado reporte) => _canal.invokeMethod<void>(
        'abrirCorreo',
        {
          'asunto': 'Comprobante FIXA',
          'texto': 'Comprobante FIXA\nCódigo: ${reporte.credenciales.codigo}\n'
              'Clave privada: ${reporte.credenciales.clave}\n'
              'Guarda la clave para consultar el avance de tu reporte.',
        },
      );

  Future<Uint8List> _crearImagen(ReporteCreado reporte) async {
    const ancho = 820;
    const margen = 50.0;
    final textos = <(String, TextStyle)>[
      ('FIXA', tituloFixa(40, color: FixaColores.hojaOscura)),
      ('Comprobante de reporte', tituloFixa(46)),
      if (reporte.unidad.isNotEmpty) (reporte.unidad, tituloFixa(29)),
      (
        'Código único',
        const TextStyle(fontSize: 25, color: FixaColores.tinta2)
      ),
      (reporte.credenciales.codigo, tituloFixa(43)),
      (
        'Clave privada',
        const TextStyle(fontSize: 25, color: FixaColores.tinta2)
      ),
      (reporte.credenciales.clave, tituloFixa(43)),
      (
        'Guarda tu clave. No la compartas públicamente.',
        const TextStyle(fontSize: 24, color: FixaColores.tinta2)
      ),
    ];
    final trazos = [
      for (final (texto, estilo) in textos)
        TextPainter(
            text: TextSpan(text: texto, style: estilo),
            textDirection: TextDirection.ltr)
          ..layout(maxWidth: ancho - margen * 2),
    ];
    const espacio = 18.0;
    final alto = (trazos.fold<double>(
        margen * 2, (suma, texto) => suma + texto.height + espacio)).ceil();
    final grabador = ui.PictureRecorder();
    final lienzo = Canvas(grabador);
    lienzo.drawColor(FixaColores.papel, BlendMode.src);
    var y = margen;
    for (final trazo in trazos) {
      trazo.paint(lienzo, Offset(margen, y));
      y += trazo.height + espacio;
      trazo.dispose();
    }
    final dibujo = grabador.endRecording();
    try {
      final imagen = await dibujo.toImage(ancho, alto);
      try {
        final bytes = await imagen.toByteData(format: ui.ImageByteFormat.png);
        if (bytes == null) throw StateError('No se pudo generar la imagen.');
        return bytes.buffer
            .asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
      } finally {
        imagen.dispose();
      }
    } finally {
      dibujo.dispose();
    }
  }
}
