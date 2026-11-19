import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/elapsed_timer.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/dotsquare_lesson.dart';
import '../services/reward_service.dart';
import '../services/locale_service.dart';
import '../services/progress_service.dart';
import '../services/dotsquare_engine.dart';
import '../widgets/hint_dialog.dart';
import 'reward_screen.dart';

class DotSquareGameScreen extends StatefulWidget {
  final DotSquareLesson lesson;
  const DotSquareGameScreen({super.key, required this.lesson});

  @override
  State<DotSquareGameScreen> createState() => _DotSquareGameScreenState();
}

class _DotSquareGameScreenState extends State<DotSquareGameScreen> {
  late List<int> _correct;
  late List<int?> _answers;
  Set<int> _wrong = {};
  final List<List<int>> _segs = [];
  List<int>? _sel;
  List<List<int>>? _hintSq;
  String _hintText = '';
  int _tries = 0;
  bool _hintUnlocked = false;

  @override
  void initState() {
    super.initState();
    final l = widget.lesson;
    _correct = [for (final a in l.areas) DotSquareEngine.count(l.n, l.rows, a)];
    _answers = List<int?>.filled(l.areas.length, null);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 3),
    ));
  }

  int _findSeg(int x1, int y1, int x2, int y2) {
    for (int k = 0; k < _segs.length; k++) {
      final s = _segs[k];
      final same = s[0] == x1 && s[1] == y1 && s[2] == x2 && s[3] == y2;
      final rev = s[0] == x2 && s[1] == y2 && s[2] == x1 && s[3] == y1;
      if (same || rev) return k;
    }
    return -1;
  }

  void _tap(Offset p, double cs, double pad) {
    final cols = widget.lesson.n;
    final rows = widget.lesson.rows;
    int bx = -1;
    int by = -1;
    double bd = double.infinity;
    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        final d = (p - Offset(pad + x * cs, pad + y * cs)).distance;
        if (d < bd) {
          bd = d;
          bx = x;
          by = y;
        }
      }
    }
    if (bx < 0 || bd > max(cs * 0.5, 22.0)) {
      if (_sel != null) setState(() => _sel = null);
      return;
    }
    setState(() {
      final s = _sel;
      if (s == null) {
        _sel = [bx, by];
      } else if (s[0] == bx && s[1] == by) {
        _sel = null;
      } else {
        final k = _findSeg(s[0], s[1], bx, by);
        if (k >= 0) {
          _segs.removeAt(k);
        } else {
          _segs.add([s[0], s[1], bx, by]);
        }
        _sel = null;
      }
      _wrong = {};
    });
  }

  Future<void> _enterNumber(int i) async {
    final cur = _answers[i];
    final ctrl = TextEditingController(text: cur == null ? '' : '$cur');
    final v = await showDialog<int?>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 3,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
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
      _answers[i] = v == -1 ? null : v;
      _wrong = {};
      _hintText = '';
      _hintSq = null;
    });
  }

  Future<void> _onCheck() async {
    final lang = context.read<LocaleService>().lang;
    final l = widget.lesson;
    _tries++;
    final wrong = <int>{};
    bool empty = false;
    for (int i = 0; i < l.areas.length; i++) {
      final a = _answers[i];
      if (a == null) {
        empty = true;
        wrong.add(i);
      } else if (a != _correct[i]) {
        wrong.add(i);
      }
    }
    if (wrong.isEmpty) {
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
      _wrong = wrong;
      _hintUnlocked = true;
      _hintText = '';
      _hintSq = null;
    });
    if (empty && wrong.every((i) => _answers[i] == null)) {
      _snack(lang == 'ja'
          ? 'まだ かいていない ところが あるよ'
          : lang == 'en'
              ? 'Some boxes are still empty'
              : 'Còn ô chưa điền');
    } else {
      _snack(lang == 'ja'
          ? 'ちがう ところが あるよ。ななめの ましかくも わすれずに かぞえよう'
          : lang == 'en'
              ? 'Some answers are wrong. Do not forget the tilted squares'
              : 'Có ô sai. Đừng quên các hình vuông nghiêng');
    }
  }

  void _onHint() {
    final rs = context.read<RewardService>();
    final lang = context.read<LocaleService>().lang;
    showDialog(
      context: context,
      builder: (_) => HintDialog(onSelect: (opt) async {
        final ok = await rs.spendStars(opt.cost);
        if (!ok || !mounted) return;
        final l = widget.lesson;
        for (int i = 0; i < l.areas.length; i++) {
          if (_answers[i] != _correct[i]) {
            final all = DotSquareEngine.allSquares(l.n, l.rows, l.areas[i]);
            final pick = all[Random().nextInt(all.length)];
            final a = l.areas[i];
            setState(() {
              _hintSq = pick;
              _hintText = lang == 'ja'
                  ? '💡 ひろさ $a の ましかくの れいを 1つ みせたよ。おなじ おおきさで ばしょを ずらして かぞえよう。ななめも あるよ'
                  : lang == 'en'
                      ? '💡 Here is one square of area $a. Slide it to other places and count them. Tilted ones count too'
                      : '💡 Đây là một hình vuông diện tích $a. Hãy dịch chuyển nó sang các vị trí khác để đếm. Hình nghiêng cũng tính';
            });
            return;
          }
        }
        setState(() => _hintText = lang == 'ja'
            ? 'ぜんぶ あっているよ！'
            : lang == 'en'
                ? 'All correct!'
                : 'Đúng hết rồi!');
      }),
    );
  }

  Widget _answerRow(int i, String lang) {
    final bad = _wrong.contains(i);
    final v = _answers[i];
    final unit = lang == 'ja' ? 'こ' : (lang == 'en' ? 'pcs' : 'hình');
    final label = lang == 'ja' ? 'ひろさ' : (lang == 'en' ? 'Area' : 'Diện tích');
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text('$label ${widget.lesson.areas[i]} →',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      const SizedBox(width: 8),
      GestureDetector(
        onTap: () => _enterNumber(i),
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bad ? Colors.red.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: bad ? Colors.red : Colors.grey.shade700, width: 2),
          ),
          child: Text(v == null ? '' : '$v',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
        ),
      ),
      const SizedBox(width: 6),
      Text(unit, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final stars = context.watch<RewardService>().totalStars;
    final lang = context.watch<LocaleService>().lang;
    final l = widget.lesson;
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
            onTap: () => setState(() {
              _hintText = '';
              _hintSq = null;
            }),
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
          child: LayoutBuilder(builder: (context, c) {
            final w = min(c.maxWidth - 24, 380.0);
            const pad = 22.0;
            final cs = min((w - pad * 2) / (l.n - 1), 62.0);
            final sideW = cs * (l.n - 1) + pad * 2;
            final sideH = cs * (l.rows - 1) + pad * 2;
            return SingleChildScrollView(
              child: Center(
                child: Column(children: [
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTapDown: (d) => _tap(d.localPosition, cs, pad),
                    child: CustomPaint(
                      size: Size(sideW, sideH),
                      painter: _DotPainter(l.n, l.rows, cs, pad, _segs, _sel, _hintSq),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 20,
                    runSpacing: 10,
                    children: [for (int i = 0; i < l.areas.length; i++) _answerRow(i, lang)],
                  ),
                  const SizedBox(height: 20),
                ]),
              ),
            );
          }),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          color: Colors.white,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _ToolBtn(
                icon: Icons.refresh,
                label: 'リセット',
                color: Colors.red,
                onTap: () => setState(() {
                      _segs.clear();
                      _sel = null;
                      _hintSq = null;
                      _hintText = '';
                      _wrong = {};
                      for (int i = 0; i < _answers.length; i++) {
                        _answers[i] = null;
                      }
                    })),
            _ToolBtn(
                icon: Icons.cleaning_services,
                label: lang == 'ja' ? 'せんを けす' : (lang == 'en' ? 'Clear lines' : 'Xóa nét'),
                color: Colors.blueGrey,
                onTap: () => setState(() {
                      _segs.clear();
                      _sel = null;
                      _hintSq = null;
                    })),
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

class _DotPainter extends CustomPainter {
  final int n; // so cot
  final int rows; // so hang
  final double cs, pad;
  final List<List<int>> segs;
  final List<int>? sel;
  final List<List<int>>? hintSq;
  _DotPainter(this.n, this.rows, this.cs, this.pad, this.segs, this.sel, this.hintSq);

  Offset _p(int x, int y) => Offset(pad + x * cs, pad + y * cs);

  @override
  void paint(Canvas canvas, Size size) {
    final bg = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(14));
    canvas.drawRRect(bg, Paint()..color = Colors.white);
    canvas.drawRRect(
        bg,
        Paint()
          ..color = Colors.grey.shade400
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    final hs = hintSq;
    if (hs != null) {
      final path = Path()..moveTo(_p(hs[0][0], hs[0][1]).dx, _p(hs[0][0], hs[0][1]).dy);
      for (int i = 1; i < hs.length; i++) {
        final q = _p(hs[i][0], hs[i][1]);
        path.lineTo(q.dx, q.dy);
      }
      path.close();
      canvas.drawPath(path, Paint()..color = const Color(0x55FF9800));
      canvas.drawPath(
          path,
          Paint()
            ..color = Colors.deepOrange
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..strokeJoin = StrokeJoin.round);
    }
    final line = Paint()
      ..color = const Color(0xFF1565C0)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (final s in segs) {
      canvas.drawLine(_p(s[0], s[1]), _p(s[2], s[3]), line);
    }
    final dot = Paint()..color = Colors.black;
    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < n; x++) {
        canvas.drawCircle(_p(x, y), 5.5, dot);
      }
    }
    final selDot = sel;
    if (selDot != null) {
      canvas.drawCircle(
          _p(selDot[0], selDot[1]),
          13,
          Paint()
            ..color = Colors.deepOrange
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
    }
  }

  @override
  bool shouldRepaint(covariant _DotPainter old) => true;
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
