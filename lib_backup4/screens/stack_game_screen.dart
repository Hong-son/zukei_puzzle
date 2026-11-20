import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../widgets/elapsed_timer.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/stack_lesson.dart';
import '../services/reward_service.dart';
import '../services/locale_service.dart';
import '../services/progress_service.dart';
import '../services/stack_engine.dart';
import '../widgets/hint_dialog.dart';
import 'reward_screen.dart';

// Man hinh choi 4 dang bai xuc xac xep chong / xep hang:
// stack (tsumiagete), same (onaji muki), line (onaji me), around (mawari kara mieru me).
class StackGameScreen extends StatefulWidget {
  final StackLesson lesson;
  const StackGameScreen({super.key, required this.lesson});

  @override
  State<StackGameScreen> createState() => _StackGameScreenState();
}

class _StackGameScreenState extends State<StackGameScreen> {
  late int _correct;
  int? _answer;
  bool _wrong = false;
  int _tries = 0;
  bool _hintUnlocked = false;
  int _hintLevel = 0;
  String _hintText = '';

  @override
  void initState() {
    super.initState();
    _correct = StackEngine.answer(widget.lesson);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 3),
    ));
  }

  Future<void> _enterNumber() async {
    final ctrl = TextEditingController(text: _answer == null ? '' : '$_answer');
    final v = await showDialog<int?>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 3,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(counterText: ''),
          onSubmitted: (t) => Navigator.pop(ctx, int.tryParse(t)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, -1), child: const Text('消す')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, int.tryParse(ctrl.text)),
              child: const Text('OK')),
        ],
      ),
    );
    if (v == null) return;
    setState(() {
      _answer = v == -1 ? null : v;
      _wrong = false;
    });
  }

  Future<void> _onCheck() async {
    final lang = context.read<LocaleService>().lang;
    final l = widget.lesson;
    final a = _answer;
    if (a == null) {
      _snack(lang == 'ja'
          ? 'こたえを かいてね'
          : lang == 'en'
              ? 'Please write your answer'
              : 'Hãy điền đáp án');
      return;
    }
    _tries++;
    if (a == _correct) {
      final stars = RewardService.calcStars(_tries);
      final rs = context.read<RewardService>();
      final ps = context.read<ProgressService>();
      await rs.addReward(stars);
      await ps.markCompleted(l.id);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => RewardScreen(tries: _tries, starsEarned: stars)),
      );
      return;
    }
    setState(() {
      _wrong = true;
      _hintUnlocked = true;
    });
    _snack(StackEngine.wrongMessage(l, lang));
  }

  void _onHint() {
    final rs = context.read<RewardService>();
    final lang = context.read<LocaleService>().lang;
    showDialog(
      context: context,
      builder: (_) => HintDialog(onSelect: (opt) async {
        final ok = await rs.spendStars(opt.cost);
        if (!ok || !mounted) return;
        setState(() {
          _hintLevel++;
          _hintText = StackEngine.hint(widget.lesson, lang, _hintLevel);
        });
      }),
    );
  }

  void _onReset() {
    setState(() {
      _answer = null;
      _wrong = false;
      _hintText = '';
      _hintLevel = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final stars = context.watch<RewardService>().totalStars;
    final lang = context.watch<LocaleService>().lang;
    final l = widget.lesson;
    final leftLabel = lang == 'ja' ? '左' : (lang == 'en' ? 'Left' : 'Trái');
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9C4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF42A5F5),
        title: Text(l.title[lang] ?? '',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          ElapsedTimer(lessonId: widget.lesson.id),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.amber.shade700, borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.star, color: Colors.white, size: 18),
                const SizedBox(width: 4),
                Text('$stars', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ]),
            ),
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Text(l.question[lang] ?? '',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        ),
        if (_hintText.isNotEmpty)
          GestureDetector(
            onTap: () => setState(() => _hintText = ''),
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepOrange, width: 2),
              ),
              child: Row(children: [
                const Icon(Icons.lightbulb, color: Colors.deepOrange),
                const SizedBox(width: 8),
                Expanded(child: Text(_hintText, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
              ]),
            ),
          ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade400, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LayoutBuilder(builder: (context, c) {
                return CustomPaint(
                  size: Size(c.maxWidth, c.maxHeight),
                  painter: _StackPainter(
                    cells: l.cells,
                    faces: l.faces,
                    covered: l.covered,
                    showLeft: l.kind == 'line',
                    leftLabel: leftLabel,
                  ),
                );
              }),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(
              lang == 'ja' ? 'こたえ' : (lang == 'en' ? 'Answer' : 'Đáp án'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _enterNumber,
              child: Container(
                width: 96,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _wrong ? Colors.red.shade50 : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _wrong ? Colors.red : Colors.grey.shade700, width: 2),
                ),
                child: Text(_answer == null ? '' : '$_answer',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
              ),
            ),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          color: Colors.white,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _ToolBtn(icon: Icons.refresh, label: 'リセット', color: Colors.red, onTap: _onReset),
            if (_hintUnlocked)
              _ToolBtn(icon: Icons.lightbulb, label: 'ヒント', color: Colors.amber, onTap: _onHint)
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .scale(),
            ElevatedButton.icon(
              onPressed: _onCheck,
              icon: const Icon(Icons.check_circle, size: 18),
              label: const Text('こたえる', style: TextStyle(fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _StackPainter extends CustomPainter {
  final List<List<int>> cells;
  final List<List<int>> faces;
  final List<List<bool>> covered;
  final bool showLeft;
  final String leftLabel;

  _StackPainter({
    required this.cells,
    required this.faces,
    required this.covered,
    required this.showLeft,
    required this.leftLabel,
  });

  static const double k = StackEngine.depthK;

  // vi tri cham tren mat vuong don vi (0..1)
  static const Map<int, List<List<double>>> _pips = {
    1: [
      [0.5, 0.5]
    ],
    2: [
      [0.28, 0.28],
      [0.72, 0.72]
    ],
    3: [
      [0.25, 0.25],
      [0.5, 0.5],
      [0.75, 0.75]
    ],
    4: [
      [0.28, 0.28],
      [0.72, 0.28],
      [0.28, 0.72],
      [0.72, 0.72]
    ],
    5: [
      [0.27, 0.27],
      [0.73, 0.27],
      [0.5, 0.5],
      [0.27, 0.73],
      [0.73, 0.73]
    ],
    6: [
      [0.28, 0.22],
      [0.28, 0.5],
      [0.28, 0.78],
      [0.72, 0.22],
      [0.72, 0.5],
      [0.72, 0.78]
    ],
  };

  void _face(Canvas canvas, Offset o, Offset u, Offset v, int pips, bool cov, Color fill) {
    final path = Path()
      ..moveTo(o.dx, o.dy)
      ..lineTo((o + u).dx, (o + u).dy)
      ..lineTo((o + u + v).dx, (o + u + v).dy)
      ..lineTo((o + v).dx, (o + v).dy)
      ..close();
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
        path,
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeJoin = StrokeJoin.round);
    canvas.save();
    canvas.transform(Float64List.fromList([
      u.dx, u.dy, 0, 0, //
      v.dx, v.dy, 0, 0, //
      0, 0, 1, 0, //
      o.dx, o.dy, 0, 1,
    ]));
    if (cov) {
      final r = RRect.fromRectAndRadius(const Rect.fromLTWH(0.1, 0.1, 0.8, 0.8), const Radius.circular(0.06));
      canvas.drawRRect(r, Paint()..color = const Color(0xFFCFD8DC));
      canvas.drawRRect(
          r,
          Paint()
            ..color = const Color(0xFF78909C)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.03);
      final peel = Path()
        ..moveTo(0.62, 0.9)
        ..lineTo(0.9, 0.62)
        ..lineTo(0.9, 0.9)
        ..close();
      canvas.drawPath(peel, Paint()..color = const Color(0xFFF5F5F5));
      canvas.drawPath(
          peel,
          Paint()
            ..color = const Color(0xFF78909C)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.025);
    } else {
      final dot = Paint()..color = Colors.black;
      for (final p in _pips[pips] ?? const <List<double>>[]) {
        canvas.drawCircle(Offset(p[0], p[1]), 0.092, dot);
      }
    }
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (cells.isEmpty) return;
    int maxX = 0;
    int maxY = 0;
    int maxZ = 0;
    for (final c in cells) {
      maxX = max(maxX, c[0]);
      maxY = max(maxY, c[1]);
      maxZ = max(maxZ, c[2]);
    }
    final w = maxX + 1;
    final d = maxY + 1;
    final h = maxZ + 1;
    const m = 0.5;
    final extraLeft = showLeft ? 1.3 : 0.0;

    final minU = -m - k * m - extraLeft;
    final maxU = (w + m) + k * (d + m);
    final minV = -k * m;
    final maxV = max(h + k * d, k * (d + m));
    final bw = maxU - minU;
    final bh = maxV - minV;
    const pad = 12.0;
    final s = min(min((size.width - pad * 2) / bw, (size.height - pad * 2) / bh), 90.0);
    final left = (size.width - s * bw) / 2;
    final top = (size.height - s * bh) / 2;
    final ox = left - s * minU;
    final oy = top + s * maxV;

    Offset p(double x, double y, double z) => Offset(ox + s * (x + k * y), oy - s * (z + k * y));

    // tham san
    final mat = Path()
      ..moveTo(p(-m, -m, 0).dx, p(-m, -m, 0).dy)
      ..lineTo(p(w + m, -m, 0).dx, p(w + m, -m, 0).dy)
      ..lineTo(p(w + m, d + m, 0).dx, p(w + m, d + m, 0).dy)
      ..lineTo(p(-m, d + m, 0).dx, p(-m, d + m, 0).dy)
      ..close();
    canvas.drawPath(mat, Paint()..color = const Color(0xFF616161));
    canvas.drawPath(
        mat,
        Paint()
          ..color = const Color(0xFF424242)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    // ve tu xa den gan: xa = x nho, y lon, z thap
    final order = List<int>.generate(cells.length, (i) => i);
    order.sort((a, b) {
      final ka = cells[a][0] - cells[a][1] + cells[a][2];
      final kb = cells[b][0] - cells[b][1] + cells[b][2];
      if (ka != kb) return ka.compareTo(kb);
      return cells[a][1] != cells[b][1] ? cells[b][1].compareTo(cells[a][1]) : 0;
    });
    final sd = Offset(s * k, -s * k);
    for (final i in order) {
      final c = cells[i];
      final f = faces[i];
      final cv = covered[i];
      final x = c[0].toDouble();
      final y = c[1].toDouble();
      final z = c[2].toDouble();
      // mat tren
      _face(canvas, p(x, y, z + 1), Offset(s, 0), sd, f[0], cv[0], Colors.white);
      // mat truoc
      _face(canvas, p(x, y, z + 1), Offset(s, 0), Offset(0, s), f[1], cv[1], const Color(0xFFFAFAFA));
      // mat phai
      _face(canvas, p(x + 1, y, z + 1), sd, Offset(0, s), f[2], cv[2], const Color(0xFFE6E6E6));
    }

    if (showLeft) {
      final a = p(-1.2, 0, 0.5);
      final b = p(-0.3, 0, 0.5);
      final arrow = Paint()
        ..color = const Color(0xFFD84315)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(a, b, arrow);
      canvas.drawLine(b, b + const Offset(-10, -8), arrow);
      canvas.drawLine(b, b + const Offset(-10, 8), arrow);
      final tp = TextPainter(
        text: TextSpan(
            text: leftLabel,
            style: const TextStyle(color: Color(0xFFD84315), fontSize: 20, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(a.dx, a.dy - tp.height - 4));
    }
  }

  @override
  bool shouldRepaint(covariant _StackPainter old) => true;
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ToolBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 20),
          Text(label, style: TextStyle(fontSize: 10, color: color)),
        ]),
      ),
    );
  }
}
