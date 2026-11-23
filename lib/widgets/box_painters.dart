import 'package:flutter/material.dart';

// Hop trong suot 2x2x2 chua cac qua bong, ve theo phep chieu xien (nhu trong sach).
// balls: moi phan tu [x, y, z, toi]
//   x: 0 = trai, 1 = phai
//   y: 0 = tren, 1 = duoi
//   z: 0 = truoc (gan nguoi nhin), 1 = sau
//   toi: 1 = qua bong mau toi
class BoxBallsView extends StatelessWidget {
  final List<List<int>> balls;
  final double size;
  const BoxBallsView({super.key, required this.balls, this.size = 200});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _BoxPainter(balls)),
    );
  }
}

class _BoxPainter extends CustomPainter {
  final List<List<int>> balls;
  _BoxPainter(this.balls);

  static const double _d = 0.34; // do xien cua moi lop (theo canh o)

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / (2 + 2 * _d); // canh 1 o
    final dd = _d * s;
    // goc tren-trai cua mat truoc
    final ox = 0.0;
    final oy = 2 * dd;

    Offset pt(double gx, double gy, double depth) =>
        Offset(ox + gx * s + depth * dd, oy + gy * s - depth * dd);

    final plane = Paint()
      ..color = const Color(0xFF3A3A3A)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final edge = Paint()
      ..color = const Color(0xFF3A3A3A)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    void drawPlane(double depth) {
      for (var i = 0; i <= 2; i++) {
        canvas.drawLine(pt(i.toDouble(), 0, depth), pt(i.toDouble(), 2, depth), plane);
        canvas.drawLine(pt(0, i.toDouble(), depth), pt(2, i.toDouble(), depth), plane);
      }
    }

    void drawBalls(int z) {
      for (final b in balls) {
        if (b[2] != z) continue;
        final c = pt(b[0] + 0.5, b[1] + 0.5, z + 0.5);
        final r = s * 0.49;
        final dark = b.length > 3 && b[3] == 1;
        final colors = dark
            ? const [Color(0xFF9A9A9A), Color(0xFF4A4A4A), Color(0xFF1C1C1C)]
            : const [Color(0xFFFFFFFF), Color(0xFFD6D6D6), Color(0xFF8E8E8E)];
        final paint = Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.35, -0.4),
            radius: 0.95,
            colors: colors,
            stops: const [0.0, 0.55, 1.0],
          ).createShader(Rect.fromCircle(center: c, radius: r));
        canvas.drawCircle(c, r, paint);
      }
    }

    // canh noi chieu sau (9 diem luoi)
    for (var i = 0; i <= 2; i++) {
      for (var j = 0; j <= 2; j++) {
        canvas.drawLine(pt(i.toDouble(), j.toDouble(), 0), pt(i.toDouble(), j.toDouble(), 2), edge);
      }
    }
    drawPlane(2);
    drawBalls(1);
    drawPlane(1);
    drawBalls(0);
    drawPlane(0);
  }

  @override
  bool shouldRepaint(covariant _BoxPainter old) => old.balls != balls;
}

// Mau cua cac loai khoi theo chieu cao 1..5 (do, xanh duong, vang, xanh la, tim)
const List<Color> kBlockColors = [
  Color(0xFFD32F2F),
  Color(0xFF2F6FCB),
  Color(0xFFF2C21B),
  Color(0xFF1E8E3E),
  Color(0xFF8E44AD),
];

// Cot khoi lap phuong xep chong h khoi (nhu hinh minh hoa 1~4 khoi trong sach)
class BlockStackView extends StatelessWidget {
  final int h;
  final double unit; // canh 1 khoi
  final Color? color; // null = mau xam
  const BlockStackView({super.key, required this.h, this.unit = 18, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: unit * 1.4,
      height: unit * (h + 0.4),
      child: CustomPaint(painter: _StackPainter(h, unit, color)),
    );
  }
}

class _StackPainter extends CustomPainter {
  final int h;
  final double u;
  final Color? color;
  _StackPainter(this.h, this.u, this.color);

  static Color _shade(Color c, double d) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness + d).clamp(0.0, 1.0).toDouble()).toColor();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final dx = u * 0.35;
    final ink = Paint()
      ..color = const Color(0xFF2B2B2B)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final front = Paint()..color = color ?? const Color(0xFFB8B8B8);
    final top = Paint()..color = color == null ? const Color(0xFFE2E2E2) : _shade(color!, 0.16);
    final side = Paint()..color = color == null ? const Color(0xFF8C8C8C) : _shade(color!, -0.14);
    final bottom = size.height;
    for (var k = 0; k < h; k++) {
      final y1 = bottom - k * u; // day cua khoi
      final y0 = y1 - u; // dinh cua khoi
      final f = Rect.fromLTRB(0, y0, u, y1);
      final sidePath = Path()
        ..moveTo(u, y0)
        ..lineTo(u + dx, y0 - dx)
        ..lineTo(u + dx, y1 - dx)
        ..lineTo(u, y1)
        ..close();
      final topPath = Path()
        ..moveTo(0, y0)
        ..lineTo(dx, y0 - dx)
        ..lineTo(u + dx, y0 - dx)
        ..lineTo(u, y0)
        ..close();
      canvas.drawPath(sidePath, side);
      canvas.drawPath(topPath, top);
      canvas.drawRect(f, front);
      canvas.drawPath(sidePath, ink);
      canvas.drawPath(topPath, ink);
      canvas.drawRect(f, ink);
    }
  }

  @override
  bool shouldRepaint(covariant _StackPainter old) => old.h != h || old.u != u || old.color != color;
}
