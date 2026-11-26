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

// しゅご・じゅつご: 文を 文節に わけて ならべ、しゅごを ○(だえん)、じゅつごを □で かこむ。
// Moi doan (KokugoPart) la 1 van tiet; doan blank co reads ['s'] = chu ngu, ['j'] = vi ngu.
class KokugoShugoScreen extends StatefulWidget {
  final KokugoLesson lesson;
  const KokugoShugoScreen({super.key, required this.lesson});

  @override
  State<KokugoShugoScreen> createState() => _KokugoShugoScreenState();
}

class _KokugoShugoScreenState extends State<KokugoShugoScreen> {
  late List<int> _s; // chi so van tiet duoc khoanh tron (chu ngu), -1 = chua chon
  late List<int> _j; // chi so van tiet duoc khoanh vuong (vi ngu)
  int _tool = 0; // 0 = ○ (しゅご), 1 = □ (じゅつご)
  int _tries = 0;

  List<KokugoItem> get _items => widget.lesson.items;

  int _find(int i, String role) {
    final parts = _items[i].parts;
    for (var k = 0; k < parts.length; k++) {
      if (parts[k].blank && parts[k].reads.first == role) return k;
    }
    return -1;
  }

  @override
  void initState() {
    super.initState();
    _s = List<int>.filled(_items.length, -1);
    _j = List<int>.filled(_items.length, -1);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 5),
    ));
  }

  void _tapChunk(int i, int k) {
    setState(() {
      if (_tool == 0) {
        _s[i] = _s[i] == k ? -1 : k;
        if (_j[i] == k) _j[i] = -1;
      } else {
        _j[i] = _j[i] == k ? -1 : k;
        if (_s[i] == k) _s[i] = -1;
      }
    });
  }

  Future<void> _onCheck() async {
    final lang = context.read<LocaleService>().lang;
    if (_s.any((v) => v < 0) || _j.any((v) => v < 0)) {
      _snack(lang == 'ja'
          ? 'まだ ○か □が ついていない ところが あるよ'
          : lang == 'en'
              ? 'Some sentences still need a ○ or a □'
              : 'Còn câu chưa có ○ hoặc □');
      return;
    }
    _tries++;
    final bad = <String>[];
    for (var i = 0; i < _items.length; i++) {
      if (_s[i] != _find(i, 's') || _j[i] != _find(i, 'j')) bad.add(_items[i].label);
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
    _snack(KokugoEngine.withWrong(KokugoEngine.wrongMessage('shugo', lang), bad, lang));
  }

  // 💡 (ton sao): tu dong khoanh vi ngu cua cau chua dung + chi cach tim chu ngu
  void _onHint() {
    final rs = context.read<RewardService>();
    final lang = context.read<LocaleService>().lang;
    showDialog(
      context: context,
      builder: (_) => HintDialog(onSelect: (opt) async {
        var target = -1;
        for (var i = 0; i < _items.length; i++) {
          if (_s[i] != _find(i, 's') || _j[i] != _find(i, 'j')) {
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
        setState(() {
          _j[target] = _find(target, 'j');
          if (_s[target] == _j[target]) _s[target] = -1;
        });
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(lang == 'ja' ? 'ヒント' : (lang == 'en' ? 'Hint' : 'Gợi ý')),
            content: Text(
              lang == 'ja'
                  ? '${_items[target].label} の じゅつごに □を つけたよ。\n（じゅつご＝「どうする」「どんなだ」「なんだ」に あたる ことば）\nつぎに「だれが」「なにが」その じゅつごを するのか かんがえよう。その ことばが しゅごだよ。'
                  : lang == 'en'
                      ? 'I boxed the predicate of ${_items[target].label}.\n(Predicate = the word that says what someone does, what it is like, or what it is.)\nNow ask: who or what does it? That word is the subject.'
                      : 'Đã khoanh vuông □ vị ngữ của ${_items[target].label}.\n(Vị ngữ = từ chỉ "làm gì", "như thế nào" hoặc "là cái gì".)\nTiếp theo hãy hỏi: "ai / cái gì" làm việc đó? Từ ấy chính là chủ ngữ.',
              style: const TextStyle(fontSize: 16),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
          ),
        );
      }),
    );
  }

  void _onReset() => setState(() {
        _s = List<int>.filled(_items.length, -1);
        _j = List<int>.filled(_items.length, -1);
      });

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
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Text(l.question[lang] ?? '',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        ),
        _example(lang),
        // chon dung cu: ○ hay □
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _toolChip(0, 'しゅご', true),
            const SizedBox(width: 12),
            _toolChip(1, 'じゅつご', false),
          ]),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
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

  // 〈れい〉 (sach: trang 4) -- mac dinh gap lai
  Widget _example(String lang) {
    Widget box(String t, bool oval) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: oval ? Colors.blue : Colors.red, width: 2.5),
            borderRadius: BorderRadius.circular(oval ? 24 : 2),
          ),
          child: Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 8),
          title: Text(lang == 'ja' ? '〈れい〉を みる' : (lang == 'en' ? 'See the example' : 'Xem ví dụ'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          collapsedBackgroundColor: Colors.white,
          backgroundColor: Colors.white,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
                  const Text('小さい ', style: TextStyle(fontSize: 18)),
                  box('男の子が', true),
                  const Text(' そとで ', style: TextStyle(fontSize: 18)),
                  box('あそんでいる', false),
                  const Text('。', style: TextStyle(fontSize: 18)),
                ]),
                const SizedBox(height: 6),
                Text(
                  lang == 'ja'
                      ? 'じゅつごを さいしょに さがしましょう。この ばあいは「あそんでいる」ですね。そして、それに あう しゅご、つまり「だれが」あそんでいるのかを かんがえれば、しゅごは「男の子が」だと わかります。'
                      : lang == 'en'
                          ? 'Find the predicate first: here it is 「あそんでいる」. Then ask who is playing: the subject is 「男の子が」.'
                          : 'Hãy tìm vị ngữ trước: ở đây là 「あそんでいる」. Rồi hỏi "ai" đang chơi: chủ ngữ là 「男の子が」.',
                  style: const TextStyle(fontSize: 13),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolChip(int t, String label, bool oval) {
    final on = _tool == t;
    final color = oval ? Colors.blue : Colors.red;
    return GestureDetector(
      onTap: () => setState(() => _tool = t),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: on ? color.withValues(alpha: 0.15) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: on ? 3 : 1.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: oval ? 26 : 20,
            height: 18,
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 2.5),
              borderRadius: BorderRadius.circular(oval ? 10 : 1),
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ]),
      ),
    );
  }

  Widget _item(int i, KokugoItem it) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        SizedBox(width: 44, child: Text(it.label, style: const TextStyle(fontSize: 16))),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 10,
            children: [for (var k = 0; k < it.parts.length; k++) _chunk(i, k, it.parts[k].text)],
          ),
        ),
      ]),
    );
  }

  Widget _chunk(int i, int k, String text) {
    final isS = _s[i] == k;
    final isJ = _j[i] == k;
    return GestureDetector(
      onTap: () => _tapChunk(i, k),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isS
              ? Colors.blue.withValues(alpha: 0.08)
              : (isJ ? Colors.red.withValues(alpha: 0.08) : Colors.transparent),
          borderRadius: BorderRadius.circular(isS ? 26 : 2),
          border: Border.all(
            color: isS ? Colors.blue : (isJ ? Colors.red : Colors.transparent),
            width: 3,
          ),
        ),
        child: Text(text, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
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
