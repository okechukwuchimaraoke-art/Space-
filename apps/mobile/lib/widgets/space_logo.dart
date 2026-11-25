import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/space_theme.dart';

/// Original SPACE mark: a tilted orbit ring around a glowing core.
class SpaceLogo extends StatelessWidget {
  const SpaceLogo({super.key, this.size = 96});
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'SPACE logo',
        child: CustomPaint(size: Size.square(size), painter: _LogoPainter()),
      );
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final r = s.width / 2;
    const gradient = LinearGradient(
      colors: [SpaceColors.violet, SpaceColors.cyan],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    final rect = Rect.fromCircle(center: c, radius: r);

    canvas.drawCircle(
      c,
      r * 0.34,
      Paint()..shader = gradient.createShader(rect),
    );

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-math.pi / 6);
    final ring = Rect.fromCenter(
        center: Offset.zero, width: s.width * 0.95, height: s.height * 0.5);
    canvas.drawOval(
      ring,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s.width * 0.06
        ..shader = gradient.createShader(rect),
    );
    canvas.drawCircle(Offset(ring.width / 2, 0), s.width * 0.07,
        Paint()..color = SpaceColors.cyan);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
