import 'dart:math';
import 'package:flutter/material.dart';
import '../services/view_shapes.dart';

// Ve danh sach ShapeOp (toa do 0..100) vao o vuong; k = pixel tren moi don vi.
void paintShapeOps(Canvas canvas, List<ShapeOp> ops, double k, Offset origin) {
  Offset pt(List<double> v, int i) => Offset(origin.dx + v[i] * k, origin.dy + v[i + 1] * k);
  for (final op in ops) {
    final v = op.v;
    final fill = op.fill == 0 ? null : (Paint()..color = Color(op.fill)..style = PaintingStyle.fill);
    final line = op.stroke == 0
        ? null
        : (Paint()
          ..color = Color(op.stroke)
          ..style = PaintingStyle.stroke
          ..strokeWidth = (op.sw * k).clamp(1.0, 100.0).toDouble()
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);
    switch (op.t) {
      case 'p':
      case 'l':
        final path = Path()..moveTo(pt(v, 0).dx, pt(v, 0).dy);
        for (var i = 2; i + 1 < v.length; i += 2) {
          final p = pt(v, i);
          path.lineTo(p.dx, p.dy);
        }
        if (op.t == 'p') path.close();
        if (fill != null && op.t == 'p') canvas.drawPath(path, fill);
        if (line != null) canvas.drawPath(path, line);
        break;
      case 'c':
        final c = Offset(origin.dx + v[0] * k, origin.dy + v[1] * k);
        if (fill != null) canvas.drawCircle(c, v[2] * k, fill);
        if (line != null) canvas.drawCircle(c, v[2] * k, line);
        break;
      case 'e':
        final r = Rect.fromCenter(
          center: Offset(origin.dx + v[0] * k, origin.dy + v[1] * k),
          width: v[2] * 2 * k,
          height: v[3] * 2 * k,
        );
        if (fill != null) canvas.drawOval(r, fill);
        if (line != null) canvas.drawOval(r, line);
        break;
    }
  }
}

// Hinh minh hoa 1 dong ShapeOp (icon vat, hinh binh chua) trong o vuong
class ShapeView extends StatelessWidget {
  final String shape; // khoa trong kShapes
  final double size;
  const ShapeView({super.key, required this.shape, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ShapePainter(kShapes[shape] ?? const [])),
    );
  }
}

class _ShapePainter extends CustomPainter {
  final List<ShapeOp> ops;
  _ShapePainter(this.ops);

  @override
  void paint(Canvas canvas, Size size) {
    paintShapeOps(canvas, ops, size.width / 100, Offset.zero);
  }

  @override
  bool shouldRepaint(covariant _ShapePainter old) => !identical(old.ops, ops);
}

// Khung chua 3 cai bong cua mot vat (ti le khung 1.7 : 1)
class ShadowBox extends StatelessWidget {
  final String obj;
  final double width;
  const ShadowBox({super.key, required this.obj, required this.width});

  static const double aspect = 1.7;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width / aspect,
      child: CustomPaint(painter: _ShadowPainter(obj)),
    );
  }
}

class _ShadowPainter extends CustomPainter {
  final String obj;
  _ShadowPainter(this.obj);

  @override
  void paint(Canvas canvas, Size size) {
    final frame = RRect.fromRectAndRadius(
        Rect.fromLTWH(1.5, 1.5, size.width - 3, size.height - 3), Radius.circular(size.height * 0.1));
    canvas.drawRRect(
        frame,
        Paint()
          ..color = const Color(0xFF444444)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5);
    final views = kShadowViews[obj];
    final layout = kShadowLayout[obj];
    if (views == null || layout == null) return;
    for (var i = 0; i < views.length; i++) {
      final ops = kShapes[views[i]];
      if (ops == null) continue;
      final cx = layout[i][0] * size.width;
      final cy = layout[i][1] * size.height;
      final k = layout[i][2] * size.height / 100;
      paintShapeOps(canvas, ops, k, Offset(cx - 50 * k, cy - 50 * k));
    }
  }

  @override
  bool shouldRepaint(covariant _ShadowPainter old) => old.obj != obj;
}

// Hinh nhin tu tren xuong: cac duong vien (ti le ban kinh so voi khung = 1), to xam vung nuoc.
// kinds: hinh dang tung duong vien (o = tron, s = vuong, h = luc giac, t = tam giac), mac dinh la tron.
// Vung nuoc la hinh k1 ban kinh s1 tru di hinh k0 ban kinh s0.
// Be chua bac thang thang: lin = vi tri cac mep bac (ti le chieu rong), x = ti le chieu rong nuoc phu (dung khi lin != null).
class WaterTopView extends StatelessWidget {
  final List<double> circles;
  final double s0;
  final double s1;
  final String kinds;
  final String k0;
  final String k1;
  final List<double>? lin;
  final double x;
  final double size;
  final bool highlight;
  const WaterTopView({
    super.key,
    this.circles = const [],
    this.s0 = 0,
    this.s1 = 0,
    this.kinds = '',
    this.k0 = 'o',
    this.k1 = 'o',
    this.lin,
    this.x = 0,
    this.size = 110,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _WaterPainter(circles, s0, s1, kinds, k0, k1, lin, x)),
    );
  }
}

class _WaterPainter extends CustomPainter {
  final List<double> circles;
  final double s0;
  final double s1;
  final String kinds;
  final String k0;
  final String k1;
  final List<double>? lin;
  final double x;
  _WaterPainter(this.circles, this.s0, this.s1, this.kinds, this.k0, this.k1, this.lin, this.x);

  // Duong vien hinh dang kind, tam c, ban kinh ngoai tiep r
  static Path _shape(String kind, Offset c, double r) {
    if (kind == 's' || kind == 'h' || kind == 't') {
      final n = kind == 's' ? 4 : (kind == 'h' ? 6 : 3);
      final a0 = kind == 's' ? -pi / 4 : (kind == 'h' ? 0.0 : -pi / 2);
      final p = Path();
      for (var i = 0; i < n; i++) {
        final a = a0 + 2 * pi * i / n;
        final pt = Offset(c.dx + r * cos(a), c.dy + r * sin(a));
        if (i == 0) {
          p.moveTo(pt.dx, pt.dy);
        } else {
          p.lineTo(pt.dx, pt.dy);
        }
      }
      p.close();
      return p;
    }
    return Path()..addOval(Rect.fromCircle(center: c, radius: r));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final R = size.width / 2 - 3;
    final water = Paint()
      ..color = const Color(0xFFD6DCE8)
      ..style = PaintingStyle.fill;
    final ink = Paint()
      ..color = const Color(0xFF444444)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.022
      ..strokeJoin = StrokeJoin.round;

    if (lin != null) {
      final rect = Rect.fromLTRB(c.dx - R, c.dy - 0.62 * R, c.dx + R, c.dy + 0.62 * R);
      canvas.drawRect(Rect.fromLTRB(rect.left, rect.top, rect.left + x * rect.width, rect.bottom), water);
      for (final e in lin!) {
        final px = rect.left + e * rect.width;
        canvas.drawLine(Offset(px, rect.top), Offset(px, rect.bottom), ink);
      }
      canvas.drawRect(rect, ink);
      return;
    }

    final shade = Path()
      ..addPath(_shape(k1, c, s1 * R), Offset.zero)
      ..addPath(_shape(k0, c, s0 * R), Offset.zero)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(shade, water);
    for (var i = 0; i < circles.length; i++) {
      final kind = i < kinds.length ? kinds[i] : 'o';
      canvas.drawPath(_shape(kind, c, circles[i] * R), ink);
    }
  }

  @override
  bool shouldRepaint(covariant _WaterPainter old) =>
      old.s0 != s0 ||
      old.s1 != s1 ||
      old.x != x ||
      old.kinds != kinds ||
      old.k0 != k0 ||
      old.k1 != k1 ||
      old.circles.length != circles.length ||
      old.lin?.length != lin?.length;
}
