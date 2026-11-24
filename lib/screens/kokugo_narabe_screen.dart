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

// ぶんを つくろう: cham cac tu de xep thanh cau co nghia, cuoi cau cham 「。」.
// Cham tu da xep de bo ra. Khi sai chi bao sai, khong chi ra cau nao sai.
// Dap an hop le (nhieu thu tu) nam trong reads cua doan blank dau tien.
class KokugoNarabeScreen extends StatefulWidget {
  final KokugoLesson lesson;
  const KokugoNarabeScreen({super.key, required this.lesson});

  @override
  State<KokugoNarabeScreen> createState() => _KokugoNarabeScreenState();
}

class _KokugoNarabeScreenState extends State<KokugoNarabeScreen> {
  static const _end = '。';
  late List<List<int>> _placed; // chi so cac the da xep, theo thu tu
  int _tries = 0;

  List<KokugoItem> get _items => widget.lesson.items;

  // cac the cua cau: cac tu (thu tu hien thi) + 「。」 o cuoi
  List<String> _tiles(int i) => [
        for (final p in _items[i].parts)
          if (!p.blank) p.text,
        _end,
      ];

  List<String> _order(int i) =>
      [...((_items[i].extra['order'] as List?) ?? const []).map((e) => e as String), _end];

  String _text(int i) => _placed[i].map((k) => _tiles(i)[k]).join();

  bool _isCorrect(int i) => _items[i].firstBlank.reads.contains(_text(i));

  @override
  void initState() {
    super.initState();
    _placed = List.generate(_items.length, (_) => <int>[]);
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
    for (var i = 0; i < _items.length; i++) {
      if (_placed[i].length < _tiles(i).length) {
        _snack(lang == 'ja'
            ? 'まだ ならべていない ことばが あるよ'
            : lang == 'en'
                ? 'Some words are not placed yet'
                : 'Còn từ chưa được xếp');
        return;
      }
    }
    _tries++;
    final bad = <String>[];
    for (var i = 0; i < _items.length; i++) {
      if (!_isCorrect(i)) bad.add(_items[i].label);
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
    _snack(KokugoEngine.withWrong(KokugoEngine.wrongMessage('narabe', lang), bad, lang));
  }

  // Goi y: xep dung them 1 tu cho cau dau tien chua dung
  void _onHint() {
    final rs = context.read<RewardService>();
    final lang = context.read<LocaleService>().lang;
    showDialog(
      context: context,
      builder: (_) => HintDialog(onSelect: (opt) async {
        var target = -1;
        for (var i = 0; i < _items.length; i++) {
          if (!_isCorrect(i)) {
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
        final tiles = _tiles(target);
        final order = _order(target);
        // giu phan dau dang dung theo thu tu chuan, roi them tu tiep theo
        final keep = <int>[];
        final used = <int>{};
        for (var k = 0; k < _placed[target].length && k < order.length; k++) {
          final idx = _placed[target][k];
          if (tiles[idx] != order[k]) break;
          keep.add(idx);
          used.add(idx);
        }
        if (keep.length < order.length) {
          final want = order[keep.length];
          final next = List<int>.generate(tiles.length, (j) => j)
              .firstWhere((j) => tiles[j] == want && !used.contains(j), orElse: () => -1);
          if (next >= 0) keep.add(next);
        }
        setState(() => _placed[target] = keep);
      }),
    );
  }

  void _onReset() {
    setState(() => _placed = List.generate(_items.length, (_) => <int>[]));
  }

  @override
  Widget build(BuildContext context) {
    final stars = context.watch<RewardService>().totalStars;
    final lang = context.watch<LocaleService>().lang;
    final l = widget.lesson;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9C4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E88E5),
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
    final tiles = _tiles(i);
    final placed = _placed[i];
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_items[i].label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        // ここに ならべる
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            border: Border.all(color: Colors.black87, width: 2),
          ),
          child: Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
            for (final k in placed)
              GestureDetector(
                onTap: () => setState(() => placed.remove(k)),
                child: _chip(tiles[k], const Color(0xFFE3F2FD), const Color(0xFF1565C0)),
              ),
          ]),
        ),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (var k = 0; k < tiles.length; k++)
            placed.contains(k)
                ? Opacity(opacity: 0.25, child: _chip(tiles[k], Colors.grey.shade200, Colors.black54))
                : GestureDetector(
                    onTap: () => setState(() => placed.add(k)),
                    child: _chip(tiles[k], const Color(0xFFFFF8E1), Colors.black87),
                  ),
        ]),
      ]),
    );
  }

  Widget _chip(String t, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E88E5), width: 2),
      ),
      child: Text(t, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: fg)),
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
