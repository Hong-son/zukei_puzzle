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

// Hinh nhin tu tren xuong: cac vong tron ban kinh (ti le so voi ban kinh binh = 1), to xam vanh [s0, s1]
class WaterTopView extends StatelessWidget {
  final List<double> circles;
  final double s0;
  final double s1;
  final double size;
  final bool highlight;
  const WaterTopView({
    super.key,
    required this.circles,
    required this.s0,
    required this.s1,
    this.size = 110,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _WaterPainter(circles, s0, s1)),
    );
  }
}

class _WaterPainter extends CustomPainter {
  final List<double> circles;
  final double s0;
  final double s1;
  _WaterPainter(this.circles, this.s0, this.s1);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final R = size.width / 2 - 3;
    final water = Paint()
      ..color = const Color(0xFFD6DCE8)
      ..style = PaintingStyle.fill;
    final shade = Path()
      ..addOval(Rect.fromCircle(center: c, radius: s1 * R))
      ..addOval(Rect.fromCircle(center: c, radius: s0 * R))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(shade, water);
    final ink = Paint()
      ..color = const Color(0xFF444444)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.022;
    for (final r in circles) {
      canvas.drawCircle(c, r * R, ink);
    }
  }

  @override
  bool shouldRepaint(covariant _WaterPainter old) =>
      old.s0 != s0 || old.s1 != s1 || old.circles.length != circles.length;
}
