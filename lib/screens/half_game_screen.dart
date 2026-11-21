import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/elapsed_timer.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/half_lesson.dart';
import '../services/reward_service.dart';
import '../services/locale_service.dart';
import '../services/progress_service.dart';
import '../services/half_engine.dart';
import '../widgets/hint_dialog.dart';
import 'reward_screen.dart';

class HalfGameScreen extends StatefulWidget {
  final HalfLesson lesson;
  const HalfGameScreen({super.key, required this.lesson});

  @override
  State<HalfGameScreen> createState() => _HalfGameScreenState();
}

class _HalfGameScreenState extends State<HalfGameScreen> {
  final Set<int> _marked = {};
  Set<int> _wrong = {};
  int _tries = 0;
  bool _hintUnlocked = false;
  int? _hintIdx;
  String _hintText = '';

  Set<int> get _truth => {
        for (int i = 0; i < widget.lesson.figures.length; i++)
          if (HalfEngine.isHalf(widget.lesson.figures[i])) i
      };

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 3),
    ));
  }

  void _toggle(int i) {
    setState(() {
      if (!_marked.add(i)) _marked.remove(i);
      _wrong = {};
      _hintIdx = null;
      _hintText = '';
    });
  }

  Future<void> _onCheck() async {
    final lang = context.read<LocaleService>().lang;
    if (_marked.isEmpty) {
      _snack(lang == 'ja'
          ? '○を つけてね'
          : lang == 'en'
              ? 'Mark the patterns with ○'
              : 'Hãy đánh dấu ○ vào các hình');
      return;
    }
    _tries++;
    final truth = _truth;
    final extra = _marked.difference(truth);
    final missing = truth.difference(_marked);
    if (extra.isEmpty && missing.isEmpty) {
      final stars = RewardService.calcStars(_tries);
      final rs = context.read<RewardService>();
      final ps = context.read<ProgressService>();
      await rs.addReward(stars);
      await ps.markCompleted(widget.lesson.id);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => RewardScreen(tries: _tries, starsEarned: stars)),
      );
      return;
    }
    setState(() {
      _hintUnlocked = true;
      _hintIdx = null;
      _hintText = '';
    });
    final parts = <String>[];
    if (extra.isNotEmpty) {
      parts.add(lang == 'ja'
          ? 'はんぶん ではない ずに ○が ついているよ'
          : lang == 'en'
              ? 'Some marked patterns are not exactly half'
              : 'Có hình được đánh dấu nhưng không phải một nửa');
    }
    if (missing.isNotEmpty) {
      parts.add(lang == 'ja'
          ? 'まだ ○を つけていない ずが あるよ'
          : lang == 'en'
              ? 'There are still patterns you have not marked'
              : 'Vẫn còn hình chưa đánh dấu');
    }
    _snack(parts.join(' / '));
  }

  void _onHint() {
    final rs = context.read<RewardService>();
    final lang = context.read<LocaleService>().lang;
    showDialog(
      context: context,
      builder: (_) => HintDialog(onSelect: (opt) async {
        final ok = await rs.spendStars(opt.cost);
        if (!ok || !mounted) return;
        final figs = widget.lesson.figures;
        final truth = _truth;
        for (int i = 0; i < figs.length; i++) {
          if (_marked.contains(i) != truth.contains(i)) {
            final a2 = HalfEngine.area2(figs[i]);
            final a = a2.isEven ? '${a2 ~/ 2}' : '${a2 / 2}';
            final half = truth.contains(i);
            final no = i + 1;
            setState(() {
              _hintIdx = i;
              _hintText = lang == 'ja'
                  ? '💡 $no ばんめの ず: ぜんたいを 16こに わけると、ぬった ところは $a こぶん。はんぶんは 8こぶん だから、${half ? '○を つけよう' : '○は つけないよ'}'
                  : lang == 'en'
                      ? '💡 Pattern $no: the square is 16 small units; the coloured part is $a. Half is 8, so ${half ? 'mark it ○' : 'do not mark it'}'
                      : '💡 Hình số $no: hình vuông gồm 16 ô nhỏ, phần tô màu là $a. Một nửa là 8, nên ${half ? 'đánh dấu ○' : 'không đánh dấu'}';
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

  Widget _card(int i, double s) {
    final fig = widget.lesson.figures[i];
    final marked = _marked.contains(i);
    final bad = _wrong.contains(i);
    final hint = _hintIdx == i;
    return GestureDetector(
      onTap: () => _toggle(i),
      child: SizedBox(
        width: s,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: s,
            height: s,
            decoration: BoxDecoration(
              border: Border.all(
                  color: bad ? Colors.red : (hint ? Colors.deepOrange : Colors.transparent),
                  width: 4),
            ),
            child: CustomPaint(painter: _FigPainter(fig, hint)),
          ),
          const SizedBox(height: 6),
          Text('（ ${marked ? '○' : '　'} ）',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: bad ? Colors.red : const Color(0xFF1565C0))),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stars = context.watch<RewardService>().totalStars;
    final lang = context.watch<LocaleService>().lang;
    final l = widget.lesson;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9C4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFAB47BC),
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
              _hintIdx = null;
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
            final w = c.maxWidth;
            final cols = w >= 700 ? 4 : 3;
            const gap = 10.0;
            final s = min((w - 24 - gap * (cols - 1)) / cols, 190.0);
            return SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Wrap(
                  spacing: gap,
                  runSpacing: gap + 4,
                  alignment: WrapAlignment.center,
                  children: [
                    for (int i = 0; i < l.figures.length; i++) _card(i, s),
                  ],
                ),
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
                      _marked.clear();
                      _wrong = {};
                      _hintIdx = null;
                      _hintText = '';
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

class _FigPainter extends CustomPainter {
  final List<List<List<int>>> fig;
  final bool showGrid;
  _FigPainter(this.fig, this.showGrid);

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 4.0;
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    final fill = Paint()..color = const Color(0xFFBDBDBD);
    final edge = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final poly in fig) {
      final path = Path()..moveTo(poly[0][0] * u, poly[0][1] * u);
      for (int i = 1; i < poly.length; i++) {
        path.lineTo(poly[i][0] * u, poly[i][1] * u);
      }
      path.close();
      canvas.drawPath(path, fill);
      canvas.drawPath(path, edge);
    }
    if (showGrid) {
      final g = Paint()
        ..color = const Color(0x99FF5722)
        ..strokeWidth = 1;
      for (int i = 1; i < 4; i++) {
        canvas.drawLine(Offset(i * u, 0), Offset(i * u, size.height), g);
        canvas.drawLine(Offset(0, i * u), Offset(size.width, i * u), g);
      }
    }
    final frame = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRect(Offset.zero & size, frame);
    final t = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;
    final len = size.width * 0.05;
    final mid = size.width / 2;
    canvas.drawLine(Offset(mid, 0), Offset(mid, len), t);
    canvas.drawLine(Offset(mid, size.height), Offset(mid, size.height - len), t);
    canvas.drawLine(Offset(0, mid), Offset(len, mid), t);
    canvas.drawLine(Offset(size.width, mid), Offset(size.width - len, mid), t);
  }

  @override
  bool shouldRepaint(covariant _FigPainter old) => old.fig != fig || old.showGrid != showGrid;
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
