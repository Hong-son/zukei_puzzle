import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/back_lesson.dart';
import '../services/reward_service.dart';
import '../services/locale_service.dart';
import '../services/progress_service.dart';
import '../widgets/hint_dialog.dart';
import 'reward_screen.dart';

class _DieFront extends CustomPainter {
  final int n;
  final Color bg;
  _DieFront(this.n, this.bg);

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
    final r = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10));
    canvas.drawRRect(r, Paint()..color = bg);
    canvas.drawRRect(
        r,
        Paint()
          ..color = Colors.black87
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5);
    final p = Paint()..color = Colors.black;
    for (final d in dots[n]!) {
      canvas.drawCircle(Offset(d[0] * size.width, d[1] * size.height), size.width * 0.08, p);
    }
  }

  @override
  bool shouldRepaint(covariant _DieFront old) => old.n != n || old.bg != bg;
}

class BackGameScreen extends StatefulWidget {
  final BackLesson lesson;
  const BackGameScreen({super.key, required this.lesson});

  @override
  State<BackGameScreen> createState() => _BackGameScreenState();
}

class _BackGameScreenState extends State<BackGameScreen> {
  final TextEditingController _ctrl = TextEditingController();
  bool _wrong = false;
  int _tries = 0;
  bool _hintUnlocked = false;
  String _hintText = '';
  int _hintCount = 0;

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
    final v = int.tryParse(_ctrl.text.trim());
    if (v == null) {
      _snack(lang == 'ja' ? 'かずを かいてね' : lang == 'en' ? 'Please write a number' : 'Hãy nhập một số');
      return;
    }
    if (v == widget.lesson.answer) {
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
      _wrong = true;
      _hintUnlocked = true;
    });
    _snack(lang == 'ja'
        ? 'むかいあう 目を あわせると 7に なるよ。うしろの 目は 7 − まえの 目'
        : lang == 'en'
            ? 'Opposite faces add up to 7. The back face = 7 - the front face'
            : 'Hai mặt đối nhau cộng bằng 7. Mặt sau = 7 - mặt trước');
  }

  void _onHint() {
    final rs = context.read<RewardService>();
    final lang = context.read<LocaleService>().lang;
    showDialog(
      context: context,
      builder: (_) => HintDialog(onSelect: (opt) async {
        final ok = await rs.spendStars(opt.cost);
        if (!ok) return;
        final f = widget.lesson.fronts;
        if (_hintCount >= f.length) _hintCount = 0;
        final i = _hintCount;
        _hintCount++;
        setState(() {
          _hintText = lang == 'ja'
              ? '💡 ${i + 1}こめ: まえが ${f[i]} だから、うしろは 7 − ${f[i]} = ${7 - f[i]}'
              : lang == 'en'
                  ? '💡 Die ${i + 1}: front ${f[i]}, back 7 - ${f[i]} = ${7 - f[i]}'
                  : '💡 Xúc xắc ${i + 1}: trước ${f[i]}, sau 7 - ${f[i]} = ${7 - f[i]}';
        });
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stars = context.watch<RewardService>().totalStars;
    final lang = context.watch<LocaleService>().lang;
    final l = widget.lesson;
    final size = l.fronts.length <= 4 ? 72.0 : (l.fronts.length <= 8 ? 56.0 : 44.0);
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9C4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF7043),
        title: Text(l.title[lang] ?? '',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
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
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.arrow_downward, color: Colors.blueGrey),
                  Text(lang == 'ja' ? 'うしろ' : lang == 'en' ? 'Back' : 'Phía sau',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 2,
                    runSpacing: 6,
                    children: [
                      for (final f in l.fronts)
                        SizedBox(width: size, height: size, child: CustomPaint(painter: _DieFront(f, Colors.white))),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.arrow_upward, color: Colors.blueGrey),
                  Text(lang == 'ja' ? 'まえ（見える 目）' : lang == 'en' ? 'Front (visible faces)' : 'Phía trước (mặt nhìn thấy)',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 6),
                Text(
                    lang == 'ja'
                        ? 'まえから 見える 目の ごうけい: ${l.fronts.fold(0, (s, f) => s + f)}'
                        : lang == 'en'
                            ? 'Total seen from the front: ${l.fronts.fold(0, (s, f) => s + f)}'
                            : 'Tổng nhìn từ phía trước: ${l.fronts.fold(0, (s, f) => s + f)}',
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 18),
                Text(lang == 'ja' ? 'うしろから 見える 目の ごうけいは？' : lang == 'en' ? 'Total seen from behind?' : 'Tổng nhìn từ phía sau?',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _ctrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 3,
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: _wrong ? Colors.red.shade50 : Colors.white,
                      border: OutlineInputBorder(
                          borderSide: BorderSide(color: _wrong ? Colors.red : Colors.grey.shade700, width: 2)),
                    ),
                    onChanged: (_) => setState(() => _wrong = false),
                  ),
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
