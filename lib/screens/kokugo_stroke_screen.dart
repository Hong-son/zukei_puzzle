import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/elapsed_timer.dart';
import '../models/kokugo_lesson.dart';
import '../services/reward_service.dart';
import '../services/locale_service.dart';
import '../services/progress_service.dart';
import '../services/kokugo_engine.dart';
import '../widgets/hint_dialog.dart';
import '../widgets/stroke_canvas.dart';
import 'reward_screen.dart';

// ひつじゅん: mui ten chi vao mot net cua chu Han -> do la net thu may?
// Tra loi bang so Han (一, 二, 三...). Khi sai chi bao sai, khong chi ra cau nao sai.
class KokugoStrokeScreen extends StatefulWidget {
  final KokugoLesson lesson;
  const KokugoStrokeScreen({super.key, required this.lesson});

  @override
  State<KokugoStrokeScreen> createState() => _KokugoStrokeScreenState();
}

class _KokugoStrokeScreenState extends State<KokugoStrokeScreen> {
  late List<int> _ans; // 0 = chua tra loi
  final Set<int> _hinted = {};
  int _tries = 0;

  @override
  void initState() {
    super.initState();
    _ans = List<int>.filled(widget.lesson.items.length, 0);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 5),
    ));
  }

  int _target(KokugoItem it) => (it.extra['n'] as num).toInt();

  Future<void> _onCheck() async {
    final lang = context.read<LocaleService>().lang;
    final items = widget.lesson.items;
    if (_ans.any((a) => a == 0)) {
      _snack(lang == 'ja'
          ? 'まだ こたえていない ところが あるよ'
          : lang == 'en'
              ? 'Some circles are still empty'
              : 'Còn hình tròn chưa trả lời');
      return;
    }
    _tries++;
    final bad = <String>[];
    for (var i = 0; i < items.length; i++) {
      if (_ans[i] != _target(items[i])) bad.add(items[i].label);
    }
    final ok = bad.isEmpty;
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
    _snack(KokugoEngine.withWrong(KokugoEngine.wrongMessage('hitsujun', lang), bad, lang));
  }

  void _onHint() {
    final rs = context.read<RewardService>();
    final lang = context.read<LocaleService>().lang;
    final n = widget.lesson.items.length;
    showDialog(
      context: context,
      builder: (_) => HintDialog(onSelect: (opt) async {
        int target = -1;
        for (var i = 0; i < n; i++) {
          if (!_hinted.contains(i)) {
            target = i;
            break;
          }
        }
        if (target < 0) {
          _snack(lang == 'ja' ? 'もう ヒントが ないよ' : (lang == 'en' ? 'No more hints' : 'Hết gợi ý rồi'));
          return;
        }
        final ok = await rs.spendStars(opt.cost);
        if (!ok || !mounted) return;
        setState(() => _hinted.add(target));
      }),
    );
  }

  void _onReset() {
    setState(() {
      _ans = List<int>.filled(widget.lesson.items.length, 0);
      _hinted.clear();
    });
  }

  Future<void> _pick(int i) async {
    final v = await showDialog<int>(
      context: context,
      builder: (_) => _NumeralPad(current: _ans[i]),
    );
    if (v == null) return;
    setState(() => _ans[i] = v);
  }

  @override
  Widget build(BuildContext context) {
    final stars = context.watch<RewardService>().totalStars;
    final lang = context.watch<LocaleService>().lang;
    final l = widget.lesson;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9C4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEF6C00),
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
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: LayoutBuilder(builder: (context, c) {
                final cols = c.maxWidth >= 640 ? 3 : 2;
                final cardW = (c.maxWidth - 24 - (cols - 1) * 10) / cols;
                final canvas = cardW.clamp(120.0, 210.0).toDouble();
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (var i = 0; i < l.items.length; i++) _card(i, l.items[i], cardW, canvas),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          color: Colors.white,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _ToolBtn(icon: Icons.refresh, label: 'リセット', color: Colors.red, onTap: _onReset),
            _ToolBtn(icon: Icons.lightbulb, label: 'ヒント', color: Colors.amber, onTap: _onHint),
            ElevatedButton.icon(
              onPressed: _onCheck,
              icon: const Icon(Icons.check_circle, size: 18),
              label: const Text('こたえる', style: TextStyle(fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3F51B5),
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

  Widget _card(int i, KokugoItem it, double w, double canvas) {
    final ch = it.extra['k'] as String;
    final p = (it.extra['p'] as num?)?.toInt() ?? -1;
    final a = (it.extra['a'] as num?)?.toDouble();
    final v = _ans[i];
    return Container(
      width: w,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(it.label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        StrokeCanvas(
          kanji: ch,
          target: _target(it),
          p: p,
          angle: a,
          numbers: _hinted.contains(i),
          size: canvas,
        ),
        const Text('⋮', style: TextStyle(fontSize: 18, color: Colors.black54)),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          GestureDetector(
            onTap: () => _pick(i),
            child: Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade700, width: 2),
              ),
              child: Text(v == 0 ? '' : KokugoEngine.numerals[v - 1],
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
            ),
          ),
          const SizedBox(width: 6),
          const Text('ばん目', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }
}

// Bang chon so Han 一 ... 十
class _NumeralPad extends StatelessWidget {
  final int current;
  const _NumeralPad({required this.current});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFFF8E1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('なんばん目？', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < KokugoEngine.numerals.length; i++)
                SizedBox(
                  width: 56,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, i + 1),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: current == i + 1 ? const Color(0xFF3F51B5) : Colors.white,
                      foregroundColor: current == i + 1 ? Colors.white : Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(KokugoEngine.numerals[i], style: const TextStyle(fontSize: 26)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context, 0),
            child: const Text('けす'),
          ),
        ]),
      ),
    );
  }
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
