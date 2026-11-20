import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/elapsed_timer.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/hide_lesson.dart';
import '../services/reward_service.dart';
import '../services/locale_service.dart';
import '../services/progress_service.dart';
import '../services/hide_engine.dart';
import '../widgets/hint_dialog.dart';
import 'reward_screen.dart';

class HideGameScreen extends StatefulWidget {
  final HideLesson lesson;
  const HideGameScreen({super.key, required this.lesson});

  @override
  State<HideGameScreen> createState() => _HideGameScreenState();
}

class _HideGameScreenState extends State<HideGameScreen> {
  final Set<int> _sel = {};
  bool _wrong = false;
  int _tries = 0;
  bool _hintUnlocked = false;
  int? _hintCell;
  String _hintText = '';
  late List<List<int>> _sols;

  @override
  void initState() {
    super.initState();
    _sols = HideEngine.solutions(widget.lesson.grid);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 3),
    ));
  }

  String _msg(String code, String lang) {
    switch (code) {
      case 'few':
        return lang == 'ja' ? '6この ますを えらんでね' : lang == 'en' ? 'Choose 6 squares' : 'Hãy chọn đủ 6 ô';
      case 'many':
        return lang == 'ja' ? 'えらびすぎです。6こに してね' : lang == 'en' ? 'Too many squares. Choose exactly 6' : 'Chọn quá nhiều, chỉ chọn 6 ô';
      case 'disconnected':
        return lang == 'ja' ? 'ますが つながって いないよ' : lang == 'en' ? 'The squares are not connected' : 'Các ô chưa nối liền nhau';
      case 'notnet':
        return lang == 'ja' ? 'おりまげても さいころに ならない かたちだよ' : lang == 'en' ? 'This shape cannot be folded into a dice' : 'Hình này không gấp được thành xúc xắc';
      case 'dup':
        return lang == 'ja' ? 'おなじ 目が 2つ あるよ。1から6が 1つずつ' : lang == 'en' ? 'The same number appears twice. Need 1 to 6 once each' : 'Có 2 mặt trùng số, cần đủ 1 đến 6 mỗi số một lần';
      default:
        return lang == 'ja' ? 'むかいあう めんの 目の 合計が 7に なっていないよ' : lang == 'en' ? 'Opposite faces must add up to 7' : 'Hai mặt đối nhau chưa có tổng bằng 7';
    }
  }

  Future<void> _onCheck() async {
    final lang = context.read<LocaleService>().lang;
    _tries++;
    final set = _sel.toList()..sort();
    final ok = _sols.any((s) =>
        s.length == set.length &&
        Iterable<int>.generate(set.length).every((i) => s[i] == set[i]));
    if (ok) {
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
    final code = HideEngine.diagnose(set, widget.lesson.grid);
    setState(() {
      _hintUnlocked = true;
      _wrong = true;
      _hintCell = null;
      _hintText = '';
    });
    _snack(_msg(code, lang));
  }

  void _onHint() {
    final rs = context.read<RewardService>();
    final lang = context.read<LocaleService>().lang;
    showDialog(
      context: context,
      builder: (_) => HintDialog(onSelect: (opt) async {
        final ok = await rs.spendStars(opt.cost);
        if (!ok) return;
        if (_sols.isEmpty) {
          setState(() {
            _wrong = false;
            _hintText = lang == 'ja'
                ? 'この もんだいには こたえが みつかりません'
                : lang == 'en'
                    ? 'No answer was found for this puzzle'
                    : 'Không tìm thấy đáp án cho bài này';
          });
          return;
        }
        List<int> best = _sols.first;
        int bestScore = -1;
        for (final s in _sols) {
          final score = s.where((i) => _sel.contains(i)).length;
          if (score > bestScore) {
            bestScore = score;
            best = s;
          }
        }
        final pool = best.where((i) => !_sel.contains(i)).toList();
        if (pool.isEmpty) {
          setState(() {
            _wrong = false;
            _hintText = lang == 'ja'
                ? 'あっている ますを えらんでいるよ'
                : lang == 'en'
                    ? 'You already selected the right squares'
                    : 'Bạn đã chọn đúng các ô rồi';
          });
          return;
        }
        setState(() {
          _wrong = false;
          _hintCell = pool[Random().nextInt(pool.length)];
          _hintText = lang == 'ja'
              ? '💡 オレンジの わくの ますは こたえの 1つだよ'
              : lang == 'en'
                  ? '💡 The square with the orange frame is part of the answer'
                  : '💡 Ô có khung màu cam là một ô thuộc đáp án';
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
          ElapsedTimer(lessonId: widget.lesson.id),
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
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text('${_sel.length} / 6',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        if (_hintText.isNotEmpty)
          GestureDetector(
            onTap: () => setState(() {
              _hintText = '';
              _hintCell = null;
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
                Expanded(
                    child: Text(_hintText,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
              ]),
            ),
          ),
        Expanded(
          child: LayoutBuilder(builder: (context, cons) {
            final cs = min((cons.maxWidth - 24) / l.cols, (cons.maxHeight - 24) / l.rows)
                .clamp(30.0, 110.0);
            return Center(
              child: SizedBox(
                width: cs * l.cols,
                height: cs * l.rows,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: l.cols),
                  itemCount: l.rows * l.cols,
                  itemBuilder: (context, i) {
                    final r = i ~/ l.cols, c = i % l.cols;
                    final on = _sel.contains(i);
                    final hint = _hintCell == i;
                    final bad = on && _wrong;
                    Color bg = Colors.white;
                    Color border = Colors.grey.shade600;
                    double bw = 1;
                    if (on) {
                      bg = const Color(0xFFBBDEFB);
                      border = const Color(0xFF1565C0);
                      bw = 3;
                    }
                    if (bad) {
                      bg = Colors.red.shade100;
                      border = Colors.red;
                    }
                    if (hint) {
                      bg = const Color(0xFFFFE082);
                      border = Colors.deepOrange;
                      bw = 5;
                    }
                    return GestureDetector(
                      onTap: () => setState(() {
                        if (on) {
                          _sel.remove(i);
                        } else {
                          _sel.add(i);
                        }
                        _wrong = false;
                        _hintCell = null;
                        _hintText = '';
                      }),
                      child: Container(
                        decoration: BoxDecoration(
                          color: bg,
                          border: Border.all(color: border, width: bw),
                        ),
                        child: Stack(fit: StackFit.expand, children: [
                          CustomPaint(painter: _DicePainter(l.grid[r][c])),
                          if (hint)
                            const Positioned(
                              top: 1,
                              right: 1,
                              child: Icon(Icons.lightbulb, color: Colors.deepOrange, size: 20),
                            ),
                          if (bad)
                            const Positioned(
                              top: 1,
                              right: 1,
                              child: Icon(Icons.close, color: Colors.red, size: 20),
                            ),
                        ]),
                      ),
                    );
                  },
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
                      _sel.clear();
                      _wrong = false;
                      _hintCell = null;
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

class _DicePainter extends CustomPainter {
  final int code;
  _DicePainter(this.code);

  static const dots = <String, List<List<double>>>{
    '1_0': [[0.5, 0.5]],
    '2_0': [[0.28, 0.28], [0.72, 0.72]],
    '2_1': [[0.72, 0.28], [0.28, 0.72]],
    '3_0': [[0.25, 0.75], [0.5, 0.5], [0.75, 0.25]],
    '3_1': [[0.25, 0.25], [0.5, 0.5], [0.75, 0.75]],
    '4_0': [[0.28, 0.28], [0.72, 0.28], [0.28, 0.72], [0.72, 0.72]],
    '5_0': [[0.25, 0.25], [0.75, 0.25], [0.5, 0.5], [0.25, 0.75], [0.75, 0.75]],
    '6_0': [[0.3, 0.25], [0.7, 0.25], [0.3, 0.5], [0.7, 0.5], [0.3, 0.75], [0.7, 0.75]],
    '6_1': [[0.25, 0.3], [0.5, 0.3], [0.75, 0.3], [0.25, 0.7], [0.5, 0.7], [0.75, 0.7]],
  };

  @override
  void paint(Canvas canvas, Size size) {
    final v = code % 10;
    final o = code ~/ 10;
    final list = dots['${v}_$o'] ?? dots['${v}_0']!;
    final p = Paint()..color = Colors.black;
    for (final d in list) {
      canvas.drawCircle(Offset(d[0] * size.width, d[1] * size.height), size.width * 0.08, p);
    }
  }

  @override
  bool shouldRepaint(covariant _DicePainter old) => old.code != code;
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
