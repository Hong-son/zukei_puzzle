import 'dart:math';
import 'package:flutter/material.dart';
import '../services/fold_engine.dart';

// Anh xa giua toa do mo hinh (xem FoldEngine) va pixel; dung chung cho ve va cham.
class FoldMap {
  final double xmin, ymax, s, ox, oy;
  FoldMap._(this.xmin, this.ymax, this.s, this.ox, this.oy);

  factory FoldMap(Size size, int unfold, {double pad = 6}) {
    final xmin = unfold >= 2 ? -1.0 : 0.0;
    final ymin = unfold >= 1 ? -1.0 : 0.0;
    const xmax = 1.0, ymax = 1.0;
    final s = min((size.width - 2 * pad) / (xmax - xmin), (size.height - 2 * pad) / (ymax - ymin));
    final ox = (size.width - s * (xmax - xmin)) / 2;
    final oy = (size.height - s * (ymax - ymin)) / 2;
    return FoldMap._(xmin, ymax, s, ox, oy);
  }

  Offset toPx(double x, double y) => Offset(ox + (x - xmin) * s, oy + (ymax - y) * s);
  Offset toModel(Offset p) => Offset(xmin + (p.dx - ox) / s, ymax - (p.dy - oy) / s);
}

// Ve to giay (da gap / mo 1 lan / mo 2 lan), phan gach cheo (cat) va net gap.
class FoldPainter extends CustomPainter {
  final String shape;
  final int unfold; // 0 = da gap, 1 = mo 1 lan, 2 = mo 2 lan
  final Set<int> hatched;
  final bool grid; // ve luoi cac manh (de cham)
  final bool dashH; // net dut ngang (y=0)
  final bool dashV; // net dut dung (x=0)
  final bool foldL; // canh trai la おり目
  final bool foldB; // canh duoi la おり目
  const FoldPainter({
    required this.shape,
    required this.unfold,
    this.hatched = const {},
    this.grid = false,
    this.dashH = false,
    this.dashV = false,
    this.foldL = false,
    this.foldB = false,
  });

  List<Offset> _paperPoly() {
    if (shape == 'sq') {
      final x0 = unfold >= 2 ? -1.0 : 0.0, y0 = unfold >= 1 ? -1.0 : 0.0;
      return [Offset(x0, y0), Offset(1, y0), const Offset(1, 1), Offset(x0, 1)];
    }
    switch (unfold) {
      case 0:
        return const [Offset(0, 0), Offset(1, 0), Offset(0, 1)];
      case 1:
        return const [Offset(0, 1), Offset(0, -1), Offset(1, 0)];
      default:
        return const [Offset(-1, 0), Offset(0, 1), Offset(1, 0), Offset(0, -1)];
    }
  }

  Path _poly(FoldMap m, List<Offset> pts) {
    final p = Path();
    for (var i = 0; i < pts.length; i++) {
      final o = m.toPx(pts[i].dx, pts[i].dy);
      if (i == 0) {
        p.moveTo(o.dx, o.dy);
      } else {
        p.lineTo(o.dx, o.dy);
      }
    }
    p.close();
    return p;
  }

  void _dash(Canvas c, Offset a, Offset b, Paint p) {
    const on = 6.0, off = 4.0;
    final len = (b - a).distance;
    if (len == 0) return;
    final d = (b - a) / len;
    for (var t = 0.0; t < len; t += on + off) {
      c.drawLine(a + d * t, a + d * min(t + on, len), p);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final m = FoldMap(size, unfold);
    final paper = _poly(m, _paperPoly());
    canvas.drawPath(paper, Paint()..color = const Color(0xFFFFF8E1));

    // luoi cac manh
    if (grid) {
      final gp = Paint()
        ..color = const Color(0x33000000)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      for (final c in FoldEngine.sheet(shape, unfold)) {
        canvas.drawPath(_poly(m, FoldEngine.verts(c)), gp);
      }
    }

    // phan gach cheo
    if (hatched.isNotEmpty) {
      final hp = Path();
      for (final c in hatched) {
        hp.addPath(_poly(m, FoldEngine.verts(c)), Offset.zero);
      }
      canvas.drawPath(hp, Paint()..color = const Color(0x293F51B5));
      canvas.save();
      canvas.clipPath(hp);
      final lp = Paint()
        ..color = const Color(0xFF3F51B5)
        ..strokeWidth = 1.5;
      for (var t = -size.height; t < size.width; t += 6) {
        canvas.drawLine(Offset(t, size.height), Offset(t + size.height, 0), lp);
      }
      canvas.restore();
      // vien: chi ve canh khong dung chung giua hai manh cung gach cheo
      final count = <String, int>{};
      final segs = <String, List<Offset>>{};
      String key(Offset a, Offset b) {
        final ka = '${(a.dx * 4).round()},${(a.dy * 4).round()}';
        final kb = '${(b.dx * 4).round()},${(b.dy * 4).round()}';
        return ka.compareTo(kb) < 0 ? '$ka|$kb' : '$kb|$ka';
      }

      for (final c in hatched) {
        final v = FoldEngine.verts(c);
        for (var i = 0; i < 3; i++) {
          final a = v[i], b = v[(i + 1) % 3];
          final k = key(a, b);
          count[k] = (count[k] ?? 0) + 1;
          segs[k] = [a, b];
        }
      }
      final op = Paint()
        ..color = const Color(0xFF283593)
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;
      count.forEach((k, n) {
        if (n == 1) {
          final s = segs[k]!;
          canvas.drawLine(m.toPx(s[0].dx, s[0].dy), m.toPx(s[1].dx, s[1].dy), op);
        }
      });
    }

    // net gap (net dut)
    final dp = Paint()
      ..color = const Color(0xFF455A64)
      ..strokeWidth = 1.4;
    final xmin = unfold >= 2 ? -1.0 : 0.0, ymin = unfold >= 1 ? -1.0 : 0.0;
    if (dashH) _dash(canvas, m.toPx(xmin, 0), m.toPx(1, 0), dp);
    if (dashV) _dash(canvas, m.toPx(0, ymin), m.toPx(0, 1), dp);

    // vien to giay
    canvas.drawPath(
        paper,
        Paint()
          ..color = const Color(0xFF37474F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeJoin = StrokeJoin.round);

    // canh おり目 (cam, dam)
    final ep = Paint()
      ..color = const Color(0xFFEF6C00)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    if (foldL) canvas.drawLine(m.toPx(0, ymin), m.toPx(0, 1), ep);
    if (foldB) canvas.drawLine(m.toPx(0, 0), m.toPx(1, 0), ep);
  }

  @override
  bool shouldRepaint(covariant FoldPainter old) => true;
}

// To giay co the cham de tô / bo tô tung manh tam giac.
class FoldSheet extends StatelessWidget {
  final String shape;
  final int unfold; // 1 hoac 2
  final double unit; // pixel cho 1 don vi mo hinh
  final Set<int> hatched;
  final ValueChanged<int> onTap;
  const FoldSheet({
    super.key,
    required this.shape,
    required this.unfold,
    required this.unit,
    required this.hatched,
    required this.onTap,
  });

  static Size sizeFor(int unfold, double unit) =>
      Size(unit * (unfold >= 2 ? 2 : 1) + 12, unit * (unfold >= 1 ? 2 : 1) + 12);

  @override
  Widget build(BuildContext context) {
    final size = sizeFor(unfold, unit);
    return GestureDetector(
      onTapUp: (d) {
        final m = FoldMap(size, unfold);
        final c = FoldEngine.pieceAt(FoldEngine.sheet(shape, unfold), m.toModel(d.localPosition));
        if (c != null) onTap(c);
      },
      child: CustomPaint(
        size: size,
        painter: FoldPainter(
          shape: shape,
          unfold: unfold,
          hatched: hatched,
          grid: true,
          dashH: unfold >= 1,
          dashV: unfold >= 2,
          foldL: unfold == 1,
        ),
      ),
    );
  }
}
