import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/tema.dart';

class PaisajeFixa extends StatelessWidget {
  const PaisajeFixa({super.key});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: AspectRatio(
          aspectRatio: 2.56,
          child:
              CustomPaint(painter: _Paisaje(), child: const SizedBox.expand()),
        ),
      );
}

class _Paisaje extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 320, size.height / 125);
    const area = Rect.fromLTWH(0, 0, 320, 125);
    canvas.drawRect(area, Paint()..color = FixaColores.menta2);
    canvas.drawCircle(
        const Offset(247, 36), 21, Paint()..color = const Color(0xFFF2CC68));

    final horizonte = Path()
      ..moveTo(0, 125)
      ..lineTo(0, 97)
      ..lineTo(46, 97)
      ..lineTo(46, 50)
      ..lineTo(57, 50)
      ..lineTo(57, 62)
      ..lineTo(66, 62)
      ..lineTo(66, 87)
      ..lineTo(86, 87)
      ..lineTo(86, 74)
      ..lineTo(94, 74)
      ..lineTo(94, 60)
      ..lineTo(100, 60)
      ..lineTo(100, 44)
      ..lineTo(107, 44)
      ..lineTo(107, 20)
      ..lineTo(111, 20)
      ..lineTo(111, 44)
      ..lineTo(118, 44)
      ..lineTo(118, 58)
      ..lineTo(123, 58)
      ..lineTo(123, 72)
      ..lineTo(132, 72)
      ..lineTo(132, 94)
      ..lineTo(144, 94)
      ..lineTo(144, 79)
      ..lineTo(160, 67)
      ..lineTo(180, 80)
      ..lineTo(180, 93)
      ..lineTo(210, 93)
      ..lineTo(210, 83)
      ..lineTo(233, 83)
      ..lineTo(233, 125)
      ..close();
    final verdeDorado = const LinearGradient(
        colors: [FixaColores.hojaOscura, Color(0xFFD3B642)]);
    canvas.drawPath(
        horizonte,
        Paint()
          ..shader =
              verdeDorado.createShader(const Rect.fromLTWH(0, 0, 230, 125)));
    for (final (centro, radio) in const [
      (Offset(256, 115), 87.0),
      (Offset(257, 121), 67.0),
      (Offset(260, 135), 39.0)
    ]) {
      canvas.drawArc(
        Rect.fromCircle(center: centro, radius: radio),
        math.pi * 0.94,
        math.pi * 1.08,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 15
          ..shader =
              verdeDorado.createShader(const Rect.fromLTWH(171, 0, 147, 125)),
      );
    }
    _arbol(canvas, const Offset(23, 81), 13, FixaColores.bosque);
    _arbol(canvas, const Offset(61, 92), 9, const Color(0xFFC2B944));
    canvas.restore();
  }

  void _arbol(Canvas canvas, Offset copa, double radio, Color color) {
    canvas.drawRect(Rect.fromLTRB(copa.dx - 2, copa.dy, copa.dx + 2, 125),
        Paint()..color = FixaColores.bosque);
    final pintura = Paint()..color = color;
    canvas.drawCircle(
        copa.translate(-radio * 0.7, radio * 0.27), radio, pintura);
    canvas.drawCircle(copa.translate(0, -radio * 0.7), radio, pintura);
    canvas.drawCircle(copa.translate(radio * 0.7, 0), radio * 1.1, pintura);
  }

  @override
  bool shouldRepaint(_Paisaje oldDelegate) => false;
}
