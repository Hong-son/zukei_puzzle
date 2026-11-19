import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/dice_lesson.dart';
import '../services/reward_service.dart';
import '../services/locale_service.dart';
import '../services/progress_service.dart';
import '../services/dice_engine.dart';
import '../widgets/hint_dialog.dart';
import 'reward_screen.dart';

class DiceGameScreen extends StatefulWidget {
  final DiceLesson lesson;
  const DiceGameScreen({super.key, required this.lesson});

  @override
  State<DiceGameScreen> createState() => _DiceGameScreenState();
}

class _DiceGameScreenState extends State<DiceGameScreen> {
  final Map<int, int> _answers = {};
  List<int> _wrong = [];
  int _tries = 0;
  bool _hintUnlocked = false;
  List<int> _hintCells = [];
  String _hintText = '';

  void _setAnswer(int slot, int v) {
    setState(() {
      _answers[slot] = v;
      _wrong = [];
      _hintCells = [];
      _hintText = '';
    });
  }

  String _msgWrongOpposite(String lang) => lang == 'ja'
      ? 'むかいあう 面の 目の かずの 合計は 7 だよ'
      : lang == 'en'
          ? 'Opposite faces always add up to 7'
          : 'Hai mặt đối nhau luôn có tổng bằng 7';

  String _msgMissing(String lang) => lang == 'ja'
      ? 'まだ こたえて いない きごうが あります'
      : lang == 'en'
          ? 'Some marks are not answered yet'
          : 'Còn ký hiệu chưa trả lời';

  String _msgDuplicate(String lang) => lang == 'ja'
      ? 'おなじ かずが 2かい つかわれて います。さいころの 目は 1から6が 1つずつです'
      : lang == 'en'
          ? 'The same number is used twice. A dice has 1 to 6 exactly once'
          : 'Có số bị dùng 2 lần. Xúc xắc có đủ 1 đến 6, mỗi số một lần';

  Future<void> _onCheck() async {
    final lang = context.read<LocaleService>().lang;
    final l = widget.lesson;
    _tries++;

    if (_answers.length < l.hiddenIdx.length) {
      setState(() => _hintUnlocked = true);
      _snack(_msgMissing(lang));
      return;
    }

    final full = Map<int, int>.from(l.values);
    for (int s = 0; s < l.hiddenIdx.length; s++) {
      full[l.hiddenIdx[s]] = _answers[s]!;
    }

    if (full.values.toSet().length < 6) {
      setState(() {
        _hintUnlocked = true;
        _wrong = List.generate(l.hiddenIdx.length, (s) => s);
      });
      _snack(_msgDuplicate(lang));
      return;
    }

    final pairs = DiceEngine.oppositePairs(l.cells);
    final bad = <int>[];
    for (final p in pairs) {
      if (full[p[0]]! + full[p[1]]! != 7) {
        for (int s = 0; s < l.hiddenIdx.length; s++) {
          if (l.hiddenIdx[s] == p[0] || l.hiddenIdx[s] == p[1]) bad.add(s);
        }
      }
    }
    if (bad.isNotEmpty) {
      setState(() {
        _hintUnlocked = true;
        _wrong = bad.toSet().toList();
      });
      _snack(_msgWrongOpposite(lang));
      return;
    }

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
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 3),
    ));
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
        final pairs = DiceEngine.oppositePairs(l.cells);

        final candidates = <List<int>>[];
        for (final p in pairs) {
          final aHidden = l.hiddenIdx.contains(p[0]);
          final bHidden = l.hiddenIdx.contains(p[1]);
          if (aHidden || bHidden) candidates.add([p[0], p[1]]);
        }
        if (candidates.isEmpty) return;

        final unanswered = candidates.where((p) {
          for (final idx in p) {
            final slot = l.hiddenIdx.indexOf(idx);
            if (slot >= 0 && _answers[slot] == null) return true;
          }
          return false;
        }).toList();
        final pool = unanswered.isNotEmpty ? unanswered : candidates;
        final pick = pool[Random().nextInt(pool.length)];

        String nameOf(int idx) {
          final slot = l.hiddenIdx.indexOf(idx);
          if (slot >= 0) return l.labels[slot];
          return '${l.values[idx]}';
        }

        final a = nameOf(pick[0]);
        final b = nameOf(pick[1]);
        final aHidden = l.hiddenIdx.contains(pick[0]);
        final bHidden = l.hiddenIdx.contains(pick[1]);

        String text;
        if (aHidden && bHidden) {
          text = lang == 'ja'
              ? '「$a」と「$b」は むかいあう 面。 あわせて 7 になるよ'
              : lang == 'en'
                  ? '"$a" and "$b" are opposite faces. Together they make 7'
                  : '"$a" và "$b" là hai mặt đối nhau. Cộng lại bằng 7';
        } else {
          final known = aHidden ? b : a;
          final mark = aHidden ? a : b;
          text = lang == 'ja'
              ? '「$mark」は 「$known」の 反対がわの 面。 あわせて 7 になるよ'
              : lang == 'en'
                  ? '"$mark" is opposite to "$known". Together they make 7'
                  : '"$mark" đối diện với "$known". Cộng lại bằng 7';
        }

        setState(() {
          _hintCells = [pick[0], pick[1]];
          _hintText = text;
        });
      }),
    );
  }

  Future<void> _pickNumber(int slot) async {
    final v = await showDialog<int>(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text(widget.lesson.labels[slot], textAlign: TextAlign.center),
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: List.generate(6, (i) => i + 1).map((n) {
              return GestureDetector(
                onTap: () => Navigator.pop(context, n),
                child: Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE0B2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Text('$n',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
    if (v != null) _setAnswer(slot, v);
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
        Expanded(
          child: LayoutBuilder(builder: (context, cons) {
            final maxR = l.cells.map((c) => c[0]).reduce(max) + 1;
            final maxC = l.cells.map((c) => c[1]).reduce(max) + 1;
            final cs = min((cons.maxWidth - 40) / maxC, (cons.maxHeight - 130) / maxR)
                .clamp(30.0, 110.0);
            final w = cs * maxC;
            final h = cs * maxR;
            return SingleChildScrollView(
              child: Center(
                child: Column(children: [
                  const SizedBox(height: 10),
                  SizedBox(
                    width: w,
                    height: h,
                    child: CustomPaint(
                      painter: _NetPainter(
                        cells: l.cells,
                        values: l.values,
                        hiddenIdx: l.hiddenIdx,
                        labels: l.labels,
                        cs: cs,
                        hintCells: _hintCells,
                        wrongSlots: _wrong,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_hintText.isNotEmpty)
                    GestureDetector(
                      onTap: () => setState(() {
                        _hintText = '';
                        _hintCells = [];
                      }),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: const BoxConstraints(maxWidth: 520),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange, width: 2),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.lightbulb, color: Colors.orange),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(_hintText,
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                        ]),
                      ),
                    ),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 12,
                    children: List.generate(l.hiddenIdx.length, (s) {
                      final wrong = _wrong.contains(s);
                      return Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(l.labels[s],
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _pickNumber(s),
                          child: Container(
                            width: 64,
                            height: 64,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: wrong ? Colors.red.shade50 : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: wrong ? Colors.red : Colors.grey.shade700, width: 2),
                            ),
                            child: Text(
                              _answers[s] == null ? '' : '${_answers[s]}',
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ]);
                    }),
                  ),
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
                      _answers.clear();
                      _wrong = [];
                      _hintCells = [];
                      _hintText = '';
                    })),
            if (_hintUnlocked)
              _ToolBtn(
                      icon: Icons.lightbulb,
                      label: 'ヒント',
                      color: Colors.amber,
                      onTap: _onHint)
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

class _NetPainter extends CustomPainter {
  final List<List<int>> cells;
  final Map<int, int> values;
  final List<int> hiddenIdx;
  final List<String> labels;
  final double cs;
  final List<int> hintCells;
  final List<int> wrongSlots;

  _NetPainter({
    required this.cells,
    required this.values,
    required this.hiddenIdx,
    required this.labels,
    required this.cs,
    required this.hintCells,
    required this.wrongSlots,
  });

  static const dots = <int, List<List<double>>>{
    1: [[0.5, 0.5]],
    2: [[0.28, 0.28], [0.72, 0.72]],
    3: [[0.25, 0.75], [0.5, 0.5], [0.75, 0.25]],
    4: [[0.28, 0.28], [0.72, 0.28], [0.28, 0.72], [0.72, 0.72]],
    5: [[0.25, 0.25], [0.75, 0.25], [0.5, 0.5], [0.25, 0.75], [0.75, 0.75]],
    6: [[0.3, 0.25], [0.7, 0.25], [0.3, 0.5], [0.7, 0.5], [0.3, 0.75], [0.7, 0.75]],
  };

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < cells.length; i++) {
      final rect = Rect.fromLTWH(cells[i][1] * cs, cells[i][0] * cs, cs, cs);
      final slot = hiddenIdx.indexOf(i);
      Color bg = Colors.white;
      if (hintCells.isNotEmpty && hintCells[0] == i) bg = const Color(0xFFFFCC80);
      if (hintCells.length > 1 && hintCells[1] == i) bg = const Color(0xFFA5D6A7);
      if (slot >= 0 && wrongSlots.contains(slot)) bg = Colors.red.shade50;
      canvas.drawRect(rect, Paint()..color = bg);
      canvas.drawRect(
        rect,
        Paint()
          ..color = Colors.grey.shade800
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
      if (slot >= 0) {
        final tp = TextPainter(
          text: TextSpan(
              text: labels[slot],
              style: TextStyle(
                  fontSize: cs * 0.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(rect.center.dx - tp.width / 2, rect.center.dy - tp.height / 2));
      } else {
        final v = values[i]!;
        final dp = Paint()..color = Colors.black;
        for (final d in dots[v]!) {
          canvas.drawCircle(
              Offset(rect.left + d[0] * cs, rect.top + d[1] * cs), cs * 0.08, dp);
        }
      }
    }
    if (hintCells.length == 2) {
      final a = cells[hintCells[0]];
      final b = cells[hintCells[1]];
      final pa = Offset(a[1] * cs + cs / 2, a[0] * cs + cs / 2);
      final pb = Offset(b[1] * cs + cs / 2, b[0] * cs + cs / 2);
      final linePaint = Paint()
        ..color = Colors.deepOrange
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      final dx = pb.dx - pa.dx;
      final dy = pb.dy - pa.dy;
      final len = sqrt(dx * dx + dy * dy);
      if (len > 0) {
        const dash = 10.0;
        const gap = 7.0;
        double d = 0;
        bool draw = true;
        while (d < len) {
          final e = min(d + (draw ? dash : gap), len);
          if (draw) {
            canvas.drawLine(
              Offset(pa.dx + dx * d / len, pa.dy + dy * d / len),
              Offset(pa.dx + dx * e / len, pa.dy + dy * e / len),
              linePaint,
            );
          }
          d = e;
          draw = !draw;
        }
      }
      final mid = Offset((pa.dx + pb.dx) / 2, (pa.dy + pb.dy) / 2);
      canvas.drawCircle(mid, cs * 0.28, Paint()..color = Colors.deepOrange);
      final tp = TextPainter(
        text: TextSpan(
          text: '=7',
          style: TextStyle(
              fontSize: cs * 0.26,
              fontWeight: FontWeight.bold,
              color: Colors.white),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(mid.dx - tp.width / 2, mid.dy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _NetPainter old) => true;
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
