import 'dart:math';
import 'package:flutter/material.dart';

// Ve xuc xac 3D: 3 mat nhin thay (tren, trai-truoc, phai) theo kieu isometric don gian.
class Dice3DPainter extends CustomPainter {
  final int top;
  final int left;
  final int right;
  Dice3DPainter({required this.top, required this.left, required this.right});

  static const dots = <int, List<List<double>>>{
    1: [[0.5, 0.5]],
    2: [[0.28, 0.28], [0.72, 0.72]],
    3: [[0.25, 0.75], [0.5, 0.5], [0.75, 0.25]],
    4: [[0.28, 0.28], [0.72, 0.28], [0.28, 0.72], [0.72, 0.72]],
    5: [[0.25, 0.25], [0.75, 0.25], [0.5, 0.5], [0.25, 0.75], [0.75, 0.75]],
    6: [[0.3, 0.25], [0.7, 0.25], [0.3, 0.5], [0.7, 0.5], [0.3, 0.75], [0.7, 0.75]],
  };

  void _face(Canvas canvas, Offset o, Offset u, Offset v, Color color, int n) {
    final path = Path()
      ..moveTo(o.dx, o.dy)
      ..lineTo(o.dx + u.dx, o.dy + u.dy)
      ..lineTo(o.dx + u.dx + v.dx, o.dy + u.dy + v.dy)
      ..lineTo(o.dx + v.dx, o.dy + v.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
        path,
        Paint()
          ..color = Colors.black87
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    final r = (u.distance + v.distance) * 0.035;
    final p = Paint()..color = Colors.black;
    for (final d in dots[n]!) {
      final c = Offset(o.dx + u.dx * d[0] + v.dx * d[1], o.dy + u.dy * d[0] + v.dy * d[1]);
      canvas.drawCircle(c, r, p);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = min(size.width, size.height) * 0.42;
    final cx = size.width / 2;
    final top0 = size.height * 0.08;
    final dx = s * 0.9;
    final dy = s * 0.5;
    // mat tren
    _face(canvas, Offset(cx, top0), Offset(dx, dy), Offset(-dx, dy), Colors.white, top);
    // mat trai
    _face(canvas, Offset(cx - dx, top0 + dy), Offset(dx, dy), Offset(0, s), const Color(0xFFF5F5F5), left);
    // mat phai
    _face(canvas, Offset(cx, top0 + 2 * dy), Offset(dx, -dy), Offset(0, s), const Color(0xFFE0E0E0), right);
  }

  @override
  bool shouldRepaint(covariant Dice3DPainter old) =>
      old.top != top || old.left != left || old.right != right;
}

