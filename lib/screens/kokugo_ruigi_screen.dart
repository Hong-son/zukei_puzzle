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

// にた いみの ことば: trong khung co cac tu, chon ra tung cap hai tu dong nghia va xep vao 2 o.
// Thu tu cac dong va thu tu hai o trong mot dong khong quan trong. Moi tu chi dung mot lan.
// Khi sai chi bao sai, khong chi ra dong nao sai.
class KokugoRuigiScreen extends StatefulWidget {
  final KokugoLesson lesson;
  const KokugoRuigiScreen({super.key, required this.lesson});

  @override
  State<KokugoRuigiScreen> createState() => _KokugoRuigiScreenState();
}

class _KokugoRuigiScreenState extends State<KokugoRuigiScreen> {
  late List<List<String>> _cells; // moi dong 2 o ('' = trong)
  int _selRow = 0;
  int _selCol = 0;
  String _hintText = '';
  int _tries = 0;

  List<KokugoItem> get _items => widget.lesson.items;
  // cap tu dung cua dong i
  List<String> _pair(int i) => [_items[i].parts[0].text, _items[i].parts[1].text];

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _cells = List.generate(_items.length, (_) => ['', '']);
    _selRow = 0;
    _selCol = 0;
    _hintText = '';
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 5),
    ));
  }

  bool _used(String w) => _cells.any((r) => r[0] == w || r[1] == w);

  List<int>? _firstEmpty() {
    for (var r = 0; r < _cells.length; r++) {
      for (var c = 0; c < 2; c++) {
        if (_cells[r][c].isEmpty) return [r, c];
      }
    }
    return null;
  }

  void _tapCell(int r, int c) {
    setState(() {
      if (_cells[r][c].isNotEmpty) _cells[r][c] = '';
      _selRow = r;
      _selCol = c;
      _hintText = '';
    });
  }

  void _tapWord(String w) {
    if (_used(w)) return;
    setState(() {
      var r = _selRow, c = _selCol;
      if (r < 0 || _cells[r][c].isNotEmpty) {
        final e = _firstEmpty();
        if (e == null) return;
        r = e[0];
        c = e[1];
      }
      _cells[r][c] = w;
      final e = _firstEmpty();
      _selRow = e == null ? -1 : e[0];
      _selCol = e == null ? -1 : e[1];
      _hintText = '';
    });
  }

  // chi so cap dung tuong ung voi dong r (hoac -1)
  int _matchPair(int r) {
    final a = _cells[r][0], b = _cells[r][1];
    for (var i = 0; i < _items.length; i++) {
      final p = _pair(i);
      if ((a == p[0] && b == p[1]) || (a == p[1] && b == p[0])) return i;
    }
    return -1;
  }

  Future<void> _onCheck() async {
    final lang = context.read<LocaleService>().lang;
    for (final row in _cells) {
      if (row[0].isEmpty || row[1].isEmpty) {
        _snack(lang == 'ja'
            ? 'まだ かいていない ところが あるよ'
            : lang == 'en'
                ? 'Some boxes are still empty'
                : 'Còn ô chưa điền');
        return;
      }
    }
    _tries++;
    final seen = <int>{};
    final bad = <String>[];
    for (var r = 0; r < _cells.length; r++) {
      final m = _matchPair(r);
      if (m < 0 || !seen.add(m)) bad.add(KokugoEngine.circled(r));
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
    _snack(KokugoEngine.withWrong(KokugoEngine.wrongMessage('ruigi', lang), bad, lang));
  }

  void _onHint() {
    final rs = context.read<RewardService>();
    final lang = context.read<LocaleService>().lang;
    showDialog(
      context: context,
      builder: (_) => HintDialog(onSelect: (opt) async {
        final done = <int>{};
        for (var r = 0; r < _cells.length; r++) {
          final m = _matchPair(r);
          if (m >= 0) done.add(m);
        }
        int target = -1;
        for (var i = 0; i < _items.length; i++) {
          if (!done.contains(i)) {
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
        final p = _pair(target);
        setState(() {
          _hintText = lang == 'ja'
              ? '💡 「${p[0]}」と にた いみの ことばを さがそう。「${p[1].substring(0, 1)}」から はじまるよ'
              : lang == 'en'
                  ? '💡 Find the word similar to "${p[0]}". It starts with "${p[1].substring(0, 1)}"'
                  : '💡 Hãy tìm từ đồng nghĩa với "${p[0]}". Từ đó bắt đầu bằng "${p[1].substring(0, 1)}"';
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
        backgroundColor: const Color(0xFF8E24AA),
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                children: [
                  _bank(l.bank),
                  if (_hintText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(_hintText,
                          style: const TextStyle(fontSize: 14, color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                    ),
                  for (var r = 0; r < _items.length; r++) _row(r),
                ],
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          color: Colors.white,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _ToolBtn(icon: Icons.refresh, label: 'リセット', color: Colors.red, onTap: () => setState(_reset)),
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

  // khung net dut chua cac tu de chon
  Widget _bank(List<String> bank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade600, width: 2),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final w in bank)
            GestureDetector(
              onTap: () => _tapWord(w),
              child: Opacity(
                opacity: _used(w) ? 0.35 : 1.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E5F5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF8E24AA), width: 2),
                  ),
                  child: Text(w, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cell(int r, int c) {
    final sel = _selRow == r && _selCol == c;
    return Expanded(
      child: GestureDetector(
        onTap: () => _tapCell(r, c),
        child: Container(
          height: 54,
          alignment: Alignment.center,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: sel ? const Color(0xFFE3F2FD) : Colors.white,
            border: Border.all(color: sel ? const Color(0xFF1565C0) : Colors.black87, width: sel ? 3 : 2),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(_cells[r][c], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(int r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: Row(children: [
        SizedBox(width: 30, child: Text(_items[r].label, style: const TextStyle(fontSize: 20))),
        const Text('{', style: TextStyle(fontSize: 34, color: Colors.black54)),
        _cell(r, 0),
        _cell(r, 1),
      ]),
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
