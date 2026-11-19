import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/mark_lesson.dart';
import '../services/reward_service.dart';
import '../services/locale_service.dart';
import '../services/progress_service.dart';
import '../services/mark_engine.dart';
import '../widgets/hint_dialog.dart';
import 'reward_screen.dart';

List<double> _layout(List<List<int>> cells, Size size) {
  final maxR = cells.map((c) => c[0]).reduce(max) + 1;
  final maxC = cells.map((c) => c[1]).reduce(max) + 1;
  final cs = min((size.width - 24) / maxC, (size.height - 24) / maxR);
  return [cs, (size.width - cs * maxC) / 2, (size.height - cs * maxR) / 2];
}

int? _cellAt(List<List<int>> cells, Size size, Offset p) {
  final l = _layout(cells, size);
  for (int i = 0; i < cells.length; i++) {
    final rect = Rect.fromLTWH(l[1] + cells[i][1] * l[0], l[2] + cells[i][0] * l[0], l[0], l[0]);
    if (rect.contains(p)) return i;
  }
  return null;
}

class MarkGameScreen extends StatefulWidget {
  final MarkLesson lesson;
  const MarkGameScreen({super.key, required this.lesson});

  @override
  State<MarkGameScreen> createState() => _MarkGameScreenState();
}

class _MarkGameScreenState extends State<MarkGameScreen> {
  final Map<int, int> _chosen = {};
  Set<int> _wrong = {};
  int _tries = 0;
  bool _hintUnlocked = false;
  int? _hintNet;
  List<int> _hintFaces = [];
  String _hintText = '';
  late List<int> _answers;

  @override
  void initState() {
    super.initState();
    final l = widget.lesson;
    _answers = List.generate(
        l.nets.length, (i) => MarkEngine.oppositeOf(l.nets[i], l.marks[i]));
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 3),
    ));
  }

  void _clearHint() {
    _hintNet = null;
    _hintFaces = [];
    _hintText = '';
  }

  void _tapCell(int net, int cell) {
    if (cell == widget.lesson.marks[net]) return;
    setState(() {
      if (_chosen[net] == cell) {
        _chosen.remove(net);
      } else {
        _chosen[net] = cell;
      }
      _wrong.remove(net);
      _clearHint();
    });
  }

  Future<void> _onCheck() async {
    final lang = context.read<LocaleService>().lang;
    final l = widget.lesson;
    _tries++;
    final missing = <int>[];
    final wrong = <int>[];
    for (int i = 0; i < l.nets.length; i++) {
      final c = _chosen[i];
      if (c == null) {
        missing.add(i);
      } else if (c != _answers[i]) {
        wrong.add(i);
      }
    }
    if (missing.isEmpty && wrong.isEmpty) {
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
    bool nextTo = false;
    for (final i in wrong) {
      if (MarkEngine.adjacent(l.nets[i][_chosen[i]!], l.nets[i][l.marks[i]])) nextTo = true;
    }
    setState(() {
      _hintUnlocked = true;
      _wrong = {...missing, ...wrong};
      _clearHint();
    });
    if (wrong.isEmpty) {
      _snack(lang == 'ja'
          ? 'まだ ◎を かいていない ずが あります'
          : lang == 'en'
              ? 'Some shapes do not have a ◎ yet'
              : 'Còn hình chưa đặt ◎');
    } else if (nextTo) {
      _snack(lang == 'ja'
          ? 'となりあう めんは むかいあう めんでは ないよ'
          : lang == 'en'
              ? 'A face next to the ◎ face is not the opposite face'
              : 'Mặt nằm cạnh mặt ◎ thì không phải mặt đối diện');
    } else {
      _snack(lang == 'ja'
          ? 'まちがい が あります。おりまげて かんがえてみよう'
          : lang == 'en'
              ? 'Some answers are wrong. Imagine folding it'
              : 'Có hình đặt sai. Hãy tưởng tượng gấp lại');
    }
  }

  void _onHint() {
    final rs = context.read<RewardService>();
    final lang = context.read<LocaleService>().lang;
    showDialog(
      context: context,
      builder: (_) => HintDialog(onSelect: (opt) async {
        final ok = await rs.spendStars(opt.cost);
        if (!ok) return;
        final l = widget.lesson;
        final pool = <int>[
          for (int i = 0; i < l.nets.length; i++)
            if (_chosen[i] != _answers[i]) i
        ];
        if (pool.isEmpty) {
          setState(() {
            _hintText = lang == 'ja'
                ? 'ぜんぶ あっているよ！こたえるを おそう'
                : lang == 'en'
                    ? 'All correct! Press Check'
                    : 'Đúng hết rồi, hãy bấm こたえる';
          });
          return;
        }
        final net = pool[Random().nextInt(pool.length)];
        final sides = MarkEngine.sideFaces(l.nets[net], l.marks[net])..shuffle();
        setState(() {
          _hintNet = net;
          _hintFaces = sides.take(2).toList();
          _hintText = lang == 'ja'
              ? '${net + 1}ばんの ずで、あおい ×の めんは ◎の となりの めん。だから こたえでは ないよ'
              : lang == 'en'
                  ? 'In shape ${net + 1}, the blue X faces are next to the ◎ face when folded, so they are not the answer'
                  : 'Ở hình ${net + 1}, hai mặt có dấu X xanh nằm cạnh mặt ◎ khi gấp, nên không phải đáp án';
        });
      }),
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
        backgroundColor: const Color(0xFFFF7043),
        title: Text(l.title[lang] ?? '',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.amber.shade700, borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.star, color: Colors.white, size: 18),
                const SizedBox(width: 4),
                Text('$stars',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ]),
            ),
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Text(l.question[lang] ?? '',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
        ),
        if (_hintText.isNotEmpty)
          GestureDetector(
            onTap: () => setState(_clearHint),
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange, width: 2),
              ),
              child: Row(children: [
                const Icon(Icons.lightbulb, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(_hintText,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
              ]),
            ),
          ),
        Expanded(
          child: LayoutBuilder(builder: (context, cons) {
            final cols = cons.maxWidth < 520 ? 2 : 3;
            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.0,
              ),
              itemCount: l.nets.length,
              itemBuilder: (context, i) {
                final wrong = _wrong.contains(i);
                return Container(
                  decoration: BoxDecoration(
                    color: wrong ? Colors.red.shade50 : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: wrong ? Colors.red : Colors.grey.shade400, width: 2),
                  ),
                  child: LayoutBuilder(builder: (context, c) {
                    final size = c.biggest;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (d) {
                        final cell = _cellAt(l.nets[i], size, d.localPosition);
                        if (cell != null) _tapCell(i, cell);
                      },
                      child: CustomPaint(
                        size: size,
                        painter: _MarkPainter(
                          cells: l.nets[i],
                          mark: l.marks[i],
                          chosen: _chosen[i],
                          hintFaces: _hintNet == i ? _hintFaces : const [],
                          number: i + 1,
                        ),
                      ),
                    );
                  }),
                );
              },
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
                      _chosen.clear();
                      _wrong = {};
                      _clearHint();
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

class _MarkPainter extends CustomPainter {
  final List<List<int>> cells;
  final int mark;
  final int? chosen;
  final List<int> hintFaces;
  final int number;

  _MarkPainter({
    required this.cells,
    required this.mark,
    required this.chosen,
    required this.hintFaces,
    required this.number,
  });

  void _ring(Canvas canvas, Offset c, double cs, Color color) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6;
    canvas.drawCircle(c, cs * 0.34, p);
    canvas.drawCircle(c, cs * 0.18, p);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final l = _layout(cells, size);
    final cs = l[0];
    final line = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    for (int i = 0; i < cells.length; i++) {
      final rect = Rect.fromLTWH(l[1] + cells[i][1] * cs, l[2] + cells[i][0] * cs, cs, cs);
      final isHint = hintFaces.contains(i);
      canvas.drawRect(
          rect, Paint()..color = isHint ? const Color(0xFFBBDEFB) : const Color(0xFFBDBDBD));
      canvas.drawRect(rect, line);
      if (isHint) {
        final x = Paint()
          ..color = const Color(0xFF1565C0)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(rect.topLeft + Offset(cs * 0.2, cs * 0.2),
            rect.bottomRight - Offset(cs * 0.2, cs * 0.2), x);
        canvas.drawLine(rect.topRight + Offset(-cs * 0.2, cs * 0.2),
            rect.bottomLeft + Offset(cs * 0.2, -cs * 0.2), x);
      }
      if (i == mark) _ring(canvas, rect.center, cs, Colors.black);
      if (i == chosen) _ring(canvas, rect.center, cs, const Color(0xFFD32F2F));
    }
    final tp = TextPainter(
      text: TextSpan(
          text: '$number',
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, const Offset(6, 4));
  }

  @override
  bool shouldRepaint(covariant _MarkPainter old) => true;
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
          border: Border.all(color: color),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 20),
          Text(label, style: TextStyle(fontSize: 10, color: color)),
        ]),
      ),
    );
  }
}
