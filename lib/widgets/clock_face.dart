import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

// Mat dong ho tuong tu (kim ngan = xanh, kim dai = do). Goc tinh bang do, 0 = huong 12 gio, chieu kim dong ho.
// Cham / keo tren mat dong ho: onAngle nhan goc (0..360) cua diem cham so voi tam.
class ClockFace extends StatelessWidget {
  final double size;
  final double? hourAngle; // null = chua co kim
  final double? minuteAngle;
  final bool interactive;
  final void Function(double angle)? onAngle;

  const ClockFace({
    super.key,
    this.size = 220,
    this.hourAngle,
    this.minuteAngle,
    this.interactive = false,
    this.onAngle,
  });

  void _emit(Offset p) {
    final dx = p.dx - size / 2;
    final dy = p.dy - size / 2;
    if (dx * dx + dy * dy < 100) return; // qua gan tam thi bo qua
    var a = atan2(dx, -dy) * 180 / pi;
    if (a < 0) a += 360;
    onAngle?.call(a);
  }

  @override
  Widget build(BuildContext context) {
    final face = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ClockPainter(hourAngle, minuteAngle)),
    );
    if (!interactive) return face;
    // Eager: gianh cu chi ngay de khi keo kim thi danh sach khong bi cuon
    return RawGestureDetector(
      gestures: {
        EagerGestureRecognizer: GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
          () => EagerGestureRecognizer(),
          (g) {},
        ),
      },
      child: Listener(
        onPointerDown: (e) => _emit(e.localPosition),
        onPointerMove: (e) => _emit(e.localPosition),
        child: face,
      ),
    );
  }
}

class _ClockPainter extends CustomPainter {
  final double? hourAngle;
  final double? minuteAngle;
  _ClockPainter(this.hourAngle, this.minuteAngle);

  Offset _pt(Offset c, double deg, double len) {
    final a = deg * pi / 180;
    return Offset(c.dx + len * sin(a), c.dy - len * cos(a));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 3;
    canvas.drawCircle(c, r, Paint()..color = Colors.white);
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = Colors.black87
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    final tick = Paint()
      ..color = Colors.black87
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 60; i++) {
      final big = i % 5 == 0;
      tick.strokeWidth = big ? 2.5 : 1;
      canvas.drawLine(_pt(c, i * 6.0, r - (big ? 11 : 6)), _pt(c, i * 6.0, r - 2), tick);
    }
    for (var n = 1; n <= 12; n++) {
      final tp = TextPainter(
        text: TextSpan(
            text: '$n',
            style: TextStyle(color: Colors.black87, fontSize: r * 0.2, fontWeight: FontWeight.w600)),
        textDirection: TextDirection.ltr,
      )..layout();
      final p = _pt(c, n * 30.0, r * 0.72);
      tp.paint(canvas, Offset(p.dx - tp.width / 2, p.dy - tp.height / 2));
    }
    if (minuteAngle != null) {
      canvas.drawLine(
          c,
          _pt(c, minuteAngle!, r * 0.82),
          Paint()
            ..color = const Color(0xFFD32F2F)
            ..strokeWidth = 5
            ..strokeCap = StrokeCap.round);
    }
    if (hourAngle != null) {
      canvas.drawLine(
          c,
          _pt(c, hourAngle!, r * 0.5),
          Paint()
            ..color = const Color(0xFF1565C0)
            ..strokeWidth = 8
            ..strokeCap = StrokeCap.round);
    }
    canvas.drawCircle(c, 6, Paint()..color = Colors.black87);
  }

  @override
  bool shouldRepaint(covariant _ClockPainter old) =>
      old.hourAngle != hourAngle || old.minuteAngle != minuteAngle;
}
