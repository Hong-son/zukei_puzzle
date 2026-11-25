import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/elapsed_timer.dart';
import '../models/kokugo_lesson.dart';
import '../services/reward_service.dart';
import '../services/locale_service.dart';
import '../services/progress_service.dart';
import '../services/kokugo_engine.dart';
import '../widgets/hint_dialog.dart';
import 'reward_screen.dart';

// こそあど ことば: ──せんの ことば(これ・それ・そこ…)が さす ものを 3つから えらんで ○を つける。
// Cau hoi: cac doan thuong (doan gach chan la tu chi thi); lua chon o extra['opts']; dap an o reads.first cua doan blank.
class KokugoShijiScreen extends StatefulWidget {
  final KokugoLesson lesson;
  const KokugoShijiScreen({super.key, required this.lesson});

  @override
  State<KokugoShijiScreen> createState() => _KokugoShijiScreenState();
}

class _KokugoShijiScreenState extends State<KokugoShijiScreen> {
  late List<int> _sel; // luu chi so lua chon da danh ○ (-1 = chua chon)
  late List<Set<int>> _gone; // cac lua chon da bi loai boi goi y
  int _tries = 0;

  List<KokugoItem> get _items => widget.lesson.items;

  List<String> _opts(int i) => [for (final o in (_items[i].extra['opts'] as List? ?? const [])) o as String];
  String _answer(int i) => _items[i].firstBlank.reads.first;

  @override
  void initState() {
    super.initState();
    _sel = List<int>.filled(_items.length, -1);
    _gone = List.generate(_items.length, (_) => <int>{});
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 5),
    ));
  }

  Future<void> _onCheck() async {
    final lang = context.read<LocaleService>().lang;
    if (_sel.any((v) => v < 0)) {
      _snack(lang == 'ja'
          ? 'まだ ○を つけていない ところが あるよ'
          : lang == 'en'
              ? 'Some questions have no ○ yet'
              : 'Còn câu chưa đánh ○');
      return;
    }
    _tries++;
    final bad = <String>[];
    for (var i = 0; i < _items.length; i++) {
      if (_opts(i)[_sel[i]] != _answer(i)) bad.add(_items[i].label);
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
    _snack(KokugoEngine.withWrong(KokugoEngine.wrongMessage('shiji', lang), bad, lang));
  }

  // Goi y: loai bo 1 lua chon sai cua cau dau tien chua dung + chi cach tim
  void _onHint() {
    final rs = context.read<RewardService>();
    final lang = context.read<LocaleService>().lang;
    showDialog(
      context: context,
      builder: (_) => HintDialog(onSelect: (opt) async {
        var target = -1;
        for (var i = 0; i < _items.length; i++) {
          if (_sel[i] < 0 || _opts(i)[_sel[i]] != _answer(i)) {
            target = i;
            break;
          }
        }
        if (target < 0) {
          _snack(lang == 'ja' ? 'ぜんぶ あっているよ！' : (lang == 'en' ? 'All correct!' : 'Đúng hết rồi!'));
          return;
        }
        final ok = await rs.spendStars(opt.cost);
        if (!ok || !mounted) return;
        final o = _opts(target);
        final wrongs = [for (var k = 0; k < o.length; k++) if (o[k] != _answer(target) && !_gone[target].contains(k)) k];
        setState(() {
          if (wrongs.length > 1 || (wrongs.isNotEmpty && _sel[target] == wrongs.first)) {
            _gone[target].add(wrongs.first);
            if (_sel[target] == wrongs.first) _sel[target] = -1;
          }
        });
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(lang == 'ja' ? 'ヒント' : (lang == 'en' ? 'Hint' : 'Gợi ý')),
            content: Text(
              lang == 'ja'
                  ? '「これ・それ・あれ・どれ」や「ここ・そこ」は、すこし まえに でてきた ことばを さしているよ。\n「それ」の ところに、えらんだ ことばを いれて よんでみよう。いみが とおれば せいかい！\n（まちがいの こたえを 1つ けしたよ）'
                  : lang == 'en'
                      ? 'Words like これ/それ/あれ and ここ/そこ point to something mentioned just before.\nPut your choice in place of the underlined word and read it. If it makes sense, it is right!\n(One wrong choice has been crossed out.)'
                      : 'Các từ như これ・それ・あれ, ここ・そこ chỉ vào thứ vừa được nhắc ở trước đó.\nHãy thay từ gạch chân bằng đáp án em chọn rồi đọc lại. Nếu câu có nghĩa là đúng!\n(Một đáp án sai đã bị gạch bỏ.)',
              style: const TextStyle(fontSize: 16),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
          ),
        );
      }),
    );
  }

  void _onReset() {
    setState(() {
      _sel = List<int>.filled(_items.length, -1);
      for (final g in _gone) {
        g.clear();
      }
    });
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
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                itemCount: _items.length + 1,
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(l.question[lang] ?? '',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    );
                  }
                  return _item(i - 1);
                },
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

  Widget _item(int i) {
    final it = _items[i];
    final opts = _opts(i);
    const circ = ['①', '②', '③', '④'];
    final spans = <InlineSpan>[];
    for (final p in it.parts) {
      if (p.blank) continue;
      spans.add(TextSpan(
        text: p.text,
        style: p.underline
            ? const TextStyle(
                decoration: TextDecoration.underline,
                decorationThickness: 3,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD84315))
            : null,
      ));
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 44, child: Text(it.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          Expanded(
            child: Text.rich(TextSpan(style: const TextStyle(fontSize: 21, height: 1.6, color: Colors.black87), children: spans)),
          ),
        ]),
        const SizedBox(height: 8),
        for (var k = 0; k < opts.length; k++) _option(i, k, circ[k < circ.length ? k : circ.length - 1], opts[k]),
      ]),
    );
  }

  Widget _option(int i, int k, String no, String text) {
    final gone = _gone[i].contains(k);
    final on = _sel[i] == k;
    return GestureDetector(
      onTap: gone ? null : () => setState(() => _sel[i] = on ? -1 : k),
      child: Opacity(
        opacity: gone ? 0.35 : 1,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: on ? const Color(0xFFFFF3E0) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: on ? const Color(0xFFEF6C00) : Colors.grey.shade300, width: 2),
          ),
          child: Row(children: [
            Text(no, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            const Text('（', style: TextStyle(fontSize: 22)),
            Container(
              width: 40,
              height: 36,
              alignment: Alignment.center,
              child: Text(on ? '○' : '',
                  style: const TextStyle(fontSize: 30, color: Color(0xFFD84315), fontWeight: FontWeight.bold)),
            ),
            const Text('）', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w600,
                      decoration: gone ? TextDecoration.lineThrough : TextDecoration.none)),
            ),
          ]),
        ),
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
