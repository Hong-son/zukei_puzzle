import 'dart:math';
import 'package:flutter/material.dart';
import '../services/stroke_data.dart';

// Ve chu Han tu du lieu net: net duoc chi (target, 1-based) toi dam,
// co mui ten chi vao dau/cuoi net do. numbers = hien so thu tu cac net (goi y).
class StrokeCanvas extends StatelessWidget {
  final String kanji;
  final int target;
  final int p; // 0 = dau net, 1 = cuoi net, -1 = tu chon dau xa tam nhat
  final double? angle; // do; 0 = duoi mui ten o ben phai, 90 = ben duoi
  final bool numbers;
  final double size;

  const StrokeCanvas({
    super.key,
    required this.kanji,
    required this.target,
    this.p = -1,
    this.angle,
    this.numbers = false,
    this.size = 160,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _StrokePainter(kanji, target, p, angle, numbers),
      ),
    );
  }
}

class _StrokePainter extends CustomPainter {
  final String kanji;
  final int target;
  final int p;
  final double? angle;
  final bool numbers;
  _StrokePainter(this.kanji, this.target, this.p, this.angle, this.numbers);

  static const Offset _c = Offset(50, 50);

  Path _pathOf(List<double> f, double k, double o) => strokePathOf(f, k, o);

  Offset _anchor(List<double> f) {
    final a = Offset(f[0], f[1]);
    final b = Offset(f[f.length - 2], f[f.length - 1]);
    if (p == 0) return a;
    if (p == 1) return b;
    return (a - _c).distance > (b - _c).distance ? a : b;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final strokes = kStrokeData[kanji];
    if (strokes == null) return;
    final k = size.width / 160.0;
    final o = 30 * k;

    canvas.drawRect(
        Rect.fromLTWH(o, o, 100 * k, 100 * k),
        Paint()
          ..color = Colors.grey.shade300
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);

    for (var i = 0; i < strokes.length; i++) {
      final hit = i + 1 == target;
      final pen = Paint()
        ..color = hit ? Colors.black : const Color(0xFF8A8A8A)
        ..strokeWidth = 100 * k * (hit ? 0.075 : 0.06)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      canvas.drawPath(_pathOf(strokes[i], k, o), pen);
    }

    if (target >= 1 && target <= strokes.length) {
      final tip = _anchor(strokes[target - 1]);
      double ux, uy;
      if (angle != null) {
        ux = cos(angle! * pi / 180);
        uy = sin(angle! * pi / 180);
      } else {
        var d = tip - _c;
        if (d.distance < 10) d = const Offset(1, -1);
        ux = d.dx / d.distance;
        uy = d.dy / d.distance;
      }
      final head = Offset(o + (tip.dx + ux * 4) * k, o + (tip.dy + uy * 4) * k);
      final tail = Offset(o + (tip.dx + ux * 30) * k, o + (tip.dy + uy * 30) * k);
      final ink = Paint()
        ..color = const Color(0xFF1E1E1E)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(tail, head, ink);
      final ang = atan2(head.dy - tail.dy, head.dx - tail.dx);
      final h = 6.5 * size.width / 160 * 1.6;
      final tri = Path()
        ..moveTo(head.dx, head.dy)
        ..lineTo(head.dx - h * cos(ang - 0.45), head.dy - h * sin(ang - 0.45))
        ..lineTo(head.dx - h * cos(ang + 0.45), head.dy - h * sin(ang + 0.45))
        ..close();
      canvas.drawPath(tri, Paint()..color = const Color(0xFF1E1E1E));
    }

    if (numbers) {
      for (var i = 0; i < strokes.length; i++) {
        final f = strokes[i];
        final tp = TextPainter(
          text: TextSpan(
            text: '${i + 1}',
            style: TextStyle(
              color: Colors.red,
              fontSize: 13 * size.width / 160 * 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(o + f[0] * k - tp.width / 2 - 6 * k, o + f[1] * k - tp.height / 2 - 6 * k));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StrokePainter old) =>
      old.kanji != kanji || old.target != target || old.numbers != numbers || old.p != p || old.angle != angle;
}

// Duong ve cua mot net (toa do 0..100 -> k lan, lech o)
Path strokePathOf(List<double> f, double k, double o) {
  final pts = <Offset>[
    for (var i = 0; i + 1 < f.length; i += 2) Offset(o + f[i] * k, o + f[i + 1] * k),
  ];
  final path = Path()..moveTo(pts.first.dx, pts.first.dy);
  if (pts.length == 2) {
    path.lineTo(pts[1].dx, pts[1].dy);
    return path;
  }
  for (var i = 1; i < pts.length - 1; i++) {
    final a = pts[i] - pts[i - 1];
    final b = pts[i + 1] - pts[i];
    final cosv = (a.dx * b.dx + a.dy * b.dy) / (a.distance * b.distance);
    final turn = acos(cosv.clamp(-1.0, 1.0).toDouble());
    if (turn > 0.9) {
      path.lineTo(pts[i].dx, pts[i].dy);
    } else {
      final mid = Offset((pts[i].dx + pts[i + 1].dx) / 2, (pts[i].dy + pts[i + 1].dy) / 2);
      path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
    }
  }
  path.lineTo(pts.last.dx, pts.last.dy);
  return path;
}


// Ve cac net duoc chon (shown = chi so net, 0-based) cua chu Han: mot buoc viet (dang 'kakijun')
class StrokeStage extends StatelessWidget {
  final String kanji;
  final List<int> shown;
  final double size;
  const StrokeStage({super.key, required this.kanji, required this.shown, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _StagePainter(kanji, shown)),
    );
  }
}

class _StagePainter extends CustomPainter {
  final String kanji;
  final List<int> shown;
  _StagePainter(this.kanji, this.shown);

  @override
  void paint(Canvas canvas, Size size) {
    final strokes = kStrokeData[kanji];
    if (strokes == null) return;
    final k = size.width / 100.0;
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()
          ..color = Colors.grey.shade300
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
    final pen = Paint()
      ..color = Colors.black
      ..strokeWidth = 100 * k * 0.07
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final i in shown) {
      if (i >= 0 && i < strokes.length) canvas.drawPath(strokePathOf(strokes[i], k, 0), pen);
    }
  }

  @override
  bool shouldRepaint(covariant _StagePainter old) => old.kanji != kanji || old.shown.join(',') != shown.join(',');
}
