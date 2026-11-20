import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/elapsed_timer.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/pick_lesson.dart';
import '../services/reward_service.dart';
import '../services/locale_service.dart';
import '../services/progress_service.dart';
import '../services/dice3d_engine.dart';
import '../widgets/dice3d_painter.dart';
import '../widgets/hint_dialog.dart';
import 'reward_screen.dart';

class PickGameScreen extends StatefulWidget {
  final PickLesson lesson;
  const PickGameScreen({super.key, required this.lesson});

  @override
  State<PickGameScreen> createState() => _PickGameScreenState();
}

class _PickGameScreenState extends State<PickGameScreen> {
  int? _chosen;
  final Set<int> _wrong = {};
  final Set<int> _removed = {};
  int _tries = 0;
  bool _hintUnlocked = false;
  String _hintText = '';
  late Map<String, int> _orient;

  @override
  void initState() {
    super.initState();
    _orient = Dice3DEngine.orient(widget.lesson.cells, widget.lesson.values) ?? {};
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 3),
    ));
  }

  Future<void> _onCheck() async {
    final lang = context.read<LocaleService>().lang;
    final l = widget.lesson;
    if (_chosen == null) {
      _snack(lang == 'ja' ? 'さいころを えらんでね' : lang == 'en' ? 'Choose a dice' : 'Hãy chọn một xúc xắc');
      return;
    }
    _tries++;
    final good = _orient.isNotEmpty && Dice3DEngine.matches(_orient, l.options[_chosen!]);
    if (good) {
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
    final t = l.options[_chosen!];
    final fromSwap = Dice3DEngine.matches(_orient, [t[0], t[2], t[1]]);
    setState(() {
      _wrong.add(_chosen!);
      _hintUnlocked = true;
      _hintText = '';
    });
    _snack(fromSwap
        ? (lang == 'ja'
            ? 'おなじ 目でも ならびかたが ぎゃくだよ'
            : lang == 'en'
                ? 'The same faces but in the opposite arrangement'
                : 'Cùng các số nhưng sắp xếp theo chiều ngược lại')
        : (lang == 'ja'
            ? 'この さいころは つくれないよ。むかいあう 目を あわせると 7に なるか たしかめよう'
            : lang == 'en'
                ? 'This dice cannot be made. Check that opposite faces add up to 7'
                : 'Không tạo được xúc xắc này. Hãy kiểm tra các mặt đối nhau cộng bằng 7'));
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
        final cands = <int>[
          for (int i = 0; i < l.options.length; i++)
            if (!_removed.contains(i) &&
                !(_orient.isNotEmpty && Dice3DEngine.matches(_orient, l.options[i])))
              i
        ];
        if (cands.isEmpty) {
          setState(() => _hintText = lang == 'ja' ? 'のこりの 1つが こたえだよ' : lang == 'en' ? 'The last one is the answer' : 'Chỉ còn một đáp án');
          return;
        }
        final pick = cands[Random().nextInt(cands.length)];
        setState(() {
          _removed.add(pick);
          if (_chosen == pick) _chosen = null;
          _hintText = lang == 'ja'
              ? '💡 ${String.fromCharCode(0x30A2 + pick * 2)}は ちがうよ（グレーに なったよ）'
              : lang == 'en'
                  ? '💡 Option ${pick + 1} is wrong (it turned grey)'
                  : '💡 Lựa chọn ${pick + 1} sai (đã chuyển xám)';
        });
      }),
    );
  }

  String _label(int i) => const ['ア', 'イ', 'ウ', 'エ', 'オ', 'カ', 'キ'][i];

  Widget _netView(PickLesson l) {
    final maxR = l.cells.map((c) => c[0]).reduce(max) + 1;
    final maxC = l.cells.map((c) => c[1]).reduce(max) + 1;
    const cs = 38.0;
    return SizedBox(
      width: cs * maxC,
      height: cs * maxR,
      child: CustomPaint(painter: _NetViewPainter(l.cells, l.values, cs)),
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
          child: SingleChildScrollView(
            child: Center(
              child: Column(children: [
                const SizedBox(height: 8),
                _netView(l),
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (int i = 0; i < l.options.length; i++)
                      GestureDetector(
                        onTap: _removed.contains(i)
                            ? null
                            : () => setState(() {
                                  _chosen = i;
                                  _wrong.remove(i);
                                  _hintText = '';
                                }),
                        child: Opacity(
                          opacity: _removed.contains(i) ? 0.3 : 1,
                          child: Column(children: [
                            Text(_label(i), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: _wrong.contains(i)
                                    ? Colors.red.shade50
                                    : (_chosen == i ? const Color(0xFFBBDEFB) : Colors.white),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: _wrong.contains(i)
                                        ? Colors.red
                                        : (_chosen == i ? const Color(0xFF1565C0) : Colors.grey.shade500),
                                    width: _chosen == i ? 4 : 2),
                              ),
                              child: CustomPaint(
                                  painter: Dice3DPainter(
                                      left: l.options[i][0], right: l.options[i][1], top: l.options[i][2])),
                            ),
                          ]),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          color: Colors.white,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            if (_hintUnlocked)
              GestureDetector(
                onTap: _onHint,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber)),
                  child: const Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.lightbulb, color: Colors.amber, size: 20),
                    Text('ヒント', style: TextStyle(fontSize: 10, color: Colors.amber)),
                  ]),
                ),
              ).animate().fadeIn(duration: 500.ms).scale(),
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

class _NetViewPainter extends CustomPainter {
  final List<List<int>> cells;
  final List<int> values;
  final double cs;
  _NetViewPainter(this.cells, this.values, this.cs);

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
    final line = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final dot = Paint()..color = Colors.black;
    for (int i = 0; i < cells.length; i++) {
      final rect = Rect.fromLTWH(cells[i][1] * cs, cells[i][0] * cs, cs, cs);
      canvas.drawRect(rect, Paint()..color = Colors.white);
      canvas.drawRect(rect, line);
      for (final d in dots[values[i]]!) {
        canvas.drawCircle(Offset(rect.left + d[0] * cs, rect.top + d[1] * cs), cs * 0.08, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NetViewPainter old) => true;
}
