import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/elapsed_timer.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/net_lesson.dart';
import '../services/reward_service.dart';
import '../services/locale_service.dart';
import '../services/progress_service.dart';
import '../services/net_engine.dart';
import '../widgets/hint_dialog.dart';
import 'reward_screen.dart';

class NetGameScreen extends StatefulWidget {
  final NetLesson lesson;
  const NetGameScreen({super.key, required this.lesson});

  @override
  State<NetGameScreen> createState() => _NetGameScreenState();
}

class _NetGameScreenState extends State<NetGameScreen> {
  final Set<int> _chosen = {};
  List<int> _wrong = [];
  int _tries = 0;
  bool _hintUnlocked = false;
  int? _hintIdx;
  String _hintText = '';
  late List<bool> _fold;

  @override
  void initState() {
    super.initState();
    _fold = widget.lesson.shapes.map((s) => NetEngine.foldable(s)).toList();
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
    _tries++;
    final missed = <int>[];
    final extra = <int>[];
    for (int i = 0; i < _fold.length; i++) {
      final shouldChoose = !_fold[i];
      if (shouldChoose && !_chosen.contains(i)) missed.add(i);
      if (!shouldChoose && _chosen.contains(i)) extra.add(i);
    }
    if (missed.isEmpty && extra.isEmpty) {
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
      _wrong = [...missed, ...extra];
    });
    if (extra.isNotEmpty) {
      _snack(lang == 'ja'
          ? 'おりまげて さいころに なる かたちが まざって いるよ'
          : lang == 'en'
              ? 'Some chosen shapes CAN be folded into a dice'
              : 'Có hình gấp được thành xúc xắc mà bạn đã chọn nhầm');
    } else {
      _snack(lang == 'ja'
          ? 'まだ さいころに ならない かたちが のこって いるよ'
          : lang == 'en'
              ? 'Some shapes that cannot be folded are still not chosen'
              : 'Còn hình không gấp được mà bạn chưa chọn');
    }
  }

  String _reasonText(String code, String lang) {
    if (code == 'line5') {
      return lang == 'ja'
          ? '5こ ならんだ ところが あるよ。さいころの まわりは 4めん だけ'
          : lang == 'en'
              ? 'There are 5 squares in a row. Only 4 faces fit around a dice'
              : 'Có 5 ô thẳng hàng. Xúc xắc chỉ có 4 mặt xung quanh';
    }
    if (code == 'block2x2') {
      return lang == 'ja'
          ? '2×2の ますが あるよ。おると かさなって しまう'
          : lang == 'en'
              ? 'There is a 2x2 block. Squares would overlap when folded'
              : 'Có khối 2x2. Khi gấp các ô sẽ chồng lên nhau';
    }
    return lang == 'ja'
        ? 'おると おなじ めんに 2まい かさなって しまう'
        : lang == 'en'
            ? 'Two squares land on the same face when folded'
            : 'Khi gấp có 2 ô rơi vào cùng một mặt';
  }

  void _onHint() {
    final rs = context.read<RewardService>();
    final lang = context.read<LocaleService>().lang;
    showDialog(
      context: context,
      builder: (_) => HintDialog(onSelect: (opt) async {
        final ok = await rs.spendStars(opt.cost);
        if (!ok) return;
        final pool = <int>[];
        for (int i = 0; i < _fold.length; i++) {
          if (!_fold[i] && !_chosen.contains(i)) pool.add(i);
        }
        if (pool.isNotEmpty) {
          final pick = pool[Random().nextInt(pool.length)];
          setState(() {
            _hintIdx = pick;
            _hintText = (lang == 'ja' ? 'この かたちは さいころに ならないよ。' :
                lang == 'en' ? 'This shape cannot be folded into a dice. ' :
                'Hình này KHÔNG gấp được thành xúc xắc. ') +
                _reasonText(NetEngine.reasonCode(widget.lesson.shapes[pick]), lang);
          });
          return;
        }
        final wrongChosen = _chosen.where((i) => _fold[i]).toList();
        if (wrongChosen.isNotEmpty) {
          setState(() {
            _hintIdx = wrongChosen.first;
            _hintText = lang == 'ja'
                ? 'この かたちは おりまげると さいころに なるよ'
                : lang == 'en'
                    ? 'This shape CAN be folded into a dice'
                    : 'Hình này gấp ĐƯỢC thành xúc xắc, hãy bỏ chọn';
          });
          return;
        }
        setState(() {
          _hintIdx = null;
          _hintText = lang == 'ja'
              ? 'ぜんぶ えらべて いるよ！こたえるを おそう'
              : lang == 'en'
                  ? 'You found them all! Press Check'
                  : 'Bạn đã chọn đủ rồi, hãy bấm こたえる';
        });
      }),
    );
  }

  void _clearHint() => setState(() {
        _hintIdx = null;
        _hintText = '';
      });

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
        if (_hintText.isNotEmpty)
          GestureDetector(
            onTap: _clearHint,
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
            final cols = max(2, min(4, (cons.maxWidth / 180).floor()));
            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.0,
              ),
              itemCount: l.shapes.length,
              itemBuilder: (context, i) {
                final chosen = _chosen.contains(i);
                final wrong = _wrong.contains(i);
                final hint = _hintIdx == i;
                return GestureDetector(
                  onTap: () => setState(() {
                    if (chosen) {
                      _chosen.remove(i);
                    } else {
                      _chosen.add(i);
                    }
                    _wrong = [];
                    _hintIdx = null;
                    _hintText = '';
                  }),
                  child: Container(
                    decoration: BoxDecoration(
                      color: hint
                          ? const Color(0xFFFFE082)
                          : wrong
                              ? Colors.red.shade50
                              : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: wrong ? Colors.red : Colors.grey.shade400, width: 2),
                    ),
                    child: CustomPaint(
                      painter: _ShapePainter(cells: l.shapes[i], chosen: chosen),
                    ),
                  ),
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
                      _wrong = [];
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

class _ShapePainter extends CustomPainter {
  final List<List<int>> cells;
  final bool chosen;
  _ShapePainter({required this.cells, required this.chosen});

  @override
  void paint(Canvas canvas, Size size) {
    final maxR = cells.map((c) => c[0]).reduce(max) + 1;
    final maxC = cells.map((c) => c[1]).reduce(max) + 1;
    final cs = min((size.width - 24) / maxC, (size.height - 24) / maxR);
    final ox = (size.width - cs * maxC) / 2;
    final oy = (size.height - cs * maxR) / 2;
    final fill = Paint()..color = const Color(0xFFBDBDBD);
    final line = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    for (final c in cells) {
      final r = Rect.fromLTWH(ox + c[1] * cs, oy + c[0] * cs, cs, cs);
      canvas.drawRect(r, fill);
      canvas.drawRect(r, line);
    }
    if (chosen) {
      final circle = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5;
      canvas.drawOval(
          Rect.fromLTWH(4, 4, size.width - 8, size.height - 8), circle);
    }
  }

  @override
  bool shouldRepaint(covariant _ShapePainter old) => true;
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
