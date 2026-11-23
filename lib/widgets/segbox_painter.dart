import 'package:flutter/material.dart';

// Hop trong suot hinh chu nhat dung (rong 1, cao 2, sau 1), ben trong dan cac thanh (bou) mau xanh.
// Ve theo phep chieu xien (mat truoc o duoi-trai, chieu sau di len-phai) nhu trong sach.
//
// bars: moi thanh la [loai, a, b, c]
//   [0, x, z, h]  thanh dung  : x 0=trai 1=phai, z 0=truoc 1=sau, h 0=nua tren 1=nua duoi
//   [1, y, z, 0]  thanh ngang theo huong trai-phai : y 0=tren 1=giua 2=duoi, z 0=truoc 1=sau
//   [2, y, x, 0]  thanh ngang theo huong truoc-sau : y 0=tren 1=giua 2=duoi, x 0=trai 1=phai
class SegBoxView extends StatelessWidget {
  final List<List<int>> bars;
  final double width; // chieu rong mat truoc
  final String? label; // chu A, B ... ghi tren mat tren
  const SegBoxView({super.key, required this.bars, this.width = 120, this.label});

  static const double depth = 0.3; // do xien (theo chieu rong)

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width * (1 + depth) + 6,
      height: width * (2 + depth) + 6,
      child: CustomPaint(painter: _SegBoxPainter(bars, width, label)),
    );
  }
}

class _SegBoxPainter extends CustomPainter {
  final List<List<int>> bars;
  final double w;
  final String? label;
  _SegBoxPainter(this.bars, this.w, this.label);

  static const double _t = 0.11; // do day cua thanh

  // [x0,x1,y0,y1,z0,z1] cua thanh
  List<double> _prism(List<int> b) {
    List<double> yr(int y) {
      if (y == 0) return [0, _t];
      if (y == 1) return [1 - _t / 2, 1 + _t / 2];
      return [2 - _t, 2];
    }

    if (b[0] == 0) {
      final x = b[1], z = b[2], h = b[3];
      final xr = x == 0 ? [0.0, _t] : [1 - _t, 1.0];
      final zr = z == 0 ? [0.0, _t] : [1 - _t, 1.0];
      final y0 = h == 0 ? 0.0 : 1.0;
      return [xr[0], xr[1], y0, y0 + 1, zr[0], zr[1]];
    }
    if (b[0] == 1) {
      final y = yr(b[1]);
      final zr = b[2] == 0 ? [0.0, _t] : [1 - _t, 1.0];
      return [0, 1, y[0], y[1], zr[0], zr[1]];
    }
    final y = yr(b[1]);
    final xr = b[2] == 0 ? [0.0, _t] : [1 - _t, 1.0];
    return [xr[0], xr[1], y[0], y[1], 0, 1];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final d = SegBoxView.depth * w;
    Offset p(double x, double y, double z) => Offset(3 + x * w + z * d, 3 + d + y * w - z * d);

    final wire = Paint()
      ..color = const Color(0xFF333333)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    // khung hop: mat sau, mat truoc, 4 canh noi
    for (final z in [1.0, 0.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(p(0, 0, z).dx, p(0, 0, z).dy)
          ..lineTo(p(1, 0, z).dx, p(1, 0, z).dy)
          ..lineTo(p(1, 2, z).dx, p(1, 2, z).dy)
          ..lineTo(p(0, 2, z).dx, p(0, 2, z).dy)
          ..close(),
        wire,
      );
    }
    for (final x in [0.0, 1.0]) {
      for (final y in [0.0, 2.0]) {
        canvas.drawLine(p(x, y, 0), p(x, y, 1), wire);
      }
    }

    // chu tren mat tren
    if (label != null) {
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
              fontSize: w * 0.13, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: Colors.black87),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final c = p(0.5, 0, 0.5);
      tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - tp.height / 2));
    }

    final sorted = List<List<int>>.from(bars);
    double zOf(List<int> b) => _prism(b)[4];
    sorted.sort((a, b) => zOf(b).compareTo(zOf(a))); // xa truoc, gan sau

    final ink = Paint()
      ..color = const Color(0xFF2C3E66)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final topP = Paint()..color = const Color(0xFFB7CCEF);
    final rightP = Paint()..color = const Color(0xFF4F77B5);
    final frontP = Paint()..color = const Color(0xFF7BA0DB);

    Path quad(Offset a, Offset b, Offset c, Offset e) => Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy)
      ..lineTo(c.dx, c.dy)
      ..lineTo(e.dx, e.dy)
      ..close();

    for (final b in sorted) {
      final q = _prism(b);
      final x0 = q[0], x1 = q[1], y0 = q[2], y1 = q[3], z0 = q[4], z1 = q[5];
      final top = quad(p(x0, y0, z0), p(x1, y0, z0), p(x1, y0, z1), p(x0, y0, z1));
      final right = quad(p(x1, y0, z0), p(x1, y0, z1), p(x1, y1, z1), p(x1, y1, z0));
      final front = quad(p(x0, y0, z0), p(x1, y0, z0), p(x1, y1, z0), p(x0, y1, z0));
      canvas.drawPath(top, topP);
      canvas.drawPath(top, ink);
      canvas.drawPath(right, rightP);
      canvas.drawPath(right, ink);
      canvas.drawPath(front, frontP);
      canvas.drawPath(front, ink);
    }
  }

  @override
  bool shouldRepaint(covariant _SegBoxPainter old) => old.bars != bars || old.w != w || old.label != label;
}
