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

// 正しい かきじゅん: ア・イ 2つの かきかた (1ばん目から じゅんに ふえていく ようす) から
// 正しい ほうを えらんで ○を つける。Khi sai chi ra cau nao sai (kokugo).
class KokugoKakijunScreen extends StatefulWidget {
  final KokugoLesson lesson;
  const KokugoKakijunScreen({super.key, required this.lesson});

  @override
  State<KokugoKakijunScreen> createState() => _KokugoKakijunScreenState();
}

class _KokugoKakijunScreenState extends State<KokugoKakijunScreen> {
  late List<int> _ans; // -1 = chua chon, 0 = ア, 1 = イ
  int _tries = 0;

  List<KokugoItem> get _items => widget.lesson.items;

  @override
  void initState() {
    super.initState();
    _ans = List<int>.filled(_items.length, -1);
  }

  // extra['c'] -> [cach viet][buoc][chi so net]
  List<List<List<int>>> _choices(KokugoItem it) => [
        for (final ch in (it.extra['c'] as List))
          [
            for (final st in (ch as List)) [for (final e in (st as List)) (e as num).toInt()],
          ],
      ];

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 5),
    ));
  }

  Future<void> _onCheck() async {
    final lang = context.read<LocaleService>().lang;
    if (_ans.any((a) => a < 0)) {
      _snack(lang == 'ja'
          ? 'まだ えらんでいない ところが あるよ'
          : lang == 'en'
              ? 'Some questions are not answered yet'
              : 'Còn câu chưa chọn');
      return;
    }
    _tries++;
    final bad = <String>[];
    for (var i = 0; i < _items.length; i++) {
      if (_ans[i] != (_items[i].extra['i'] as num).toInt()) bad.add(_items[i].label);
    }
    if (bad.isEmpty) {
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
    _snack(KokugoEngine.withWrong(KokugoEngine.wrongMessage('kakijun', lang), bad, lang));
  }

  // 💡 (ton sao): hien chu Han co danh so thu tu net dung cua cau chua dung
  void _onHint() {
    final rs = context.read<RewardService>();
    final lang = context.read<LocaleService>().lang;
    showDialog(
      context: context,
      builder: (_) => HintDialog(onSelect: (opt) async {
        var target = -1;
        for (var i = 0; i < _items.length; i++) {
          if (_ans[i] != (_items[i].extra['i'] as num).toInt()) {
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
        final it = _items[target];
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('${it.label} ${lang == 'ja' ? 'かきじゅん' : (lang == 'en' ? 'Stroke order' : 'Thứ tự nét')}'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              StrokeCanvas(kanji: it.extra['k'] as String, target: 0, numbers: true, size: 200),
              const SizedBox(height: 6),
              Text(
                  lang == 'ja'
                      ? '赤い すうじの じゅんに かくよ。'
                      : lang == 'en'
                          ? 'Write the strokes in the order of the red numbers.'
                          : 'Viết các nét theo thứ tự số đỏ.',
                  style: const TextStyle(fontSize: 14)),
            ]),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
          ),
        );
      }),
    );
  }

  void _onReset() => setState(() => _ans = List<int>.filled(_items.length, -1));

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
              constraints: const BoxConstraints(maxWidth: 700),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                itemCount: _items.length,
                itemBuilder: (context, i) => _item(i, _items[i]),
              ),
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

  Widget _item(int i, KokugoItem it) {
    final ch = it.extra['k'] as String;
    final choices = _choices(it);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(it.label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        for (var c = 0; c < choices.length; c++) _choice(i, c, ch, choices[c]),
      ]),
    );
  }

  Widget _choice(int i, int c, String ch, List<List<int>> stages) {
    final sel = _ans[i] == c;
    const kana = ['ア', 'イ'];
    return GestureDetector(
      onTap: () => setState(() => _ans[i] = c),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFE3F2FD) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? const Color(0xFF1565C0) : Colors.grey.shade400, width: sel ? 3 : 1.5),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text(kana[c], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade700, width: 2),
              ),
              child: sel
                  ? const Text('○', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)))
                  : null,
            ),
          ]),
          const SizedBox(width: 10),
          Expanded(
            child: LayoutBuilder(builder: (context, cons) {
              final n = stages.length;
              final w = ((cons.maxWidth - (n - 1) * 6) / n).clamp(34.0, 64.0).toDouble();
              return Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [for (final st in stages) StrokeStage(kanji: ch, shown: st, size: w)],
              );
            }),
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
