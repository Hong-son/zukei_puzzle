import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/elapsed_timer.dart';
import '../models/kokugo_lesson.dart';
import '../services/reward_service.dart';
import '../services/locale_service.dart';
import '../services/progress_service.dart';
import '../services/kokugo_engine.dart';
import '../widgets/hint_dialog.dart';
import '../widgets/kana_pad.dart';
import 'reward_screen.dart';

// はんたいの いみの かん字: chon chu Han tu bang de ghep thanh tu trai nghia (2 o),
// roi viet cach doc bang hiragana vao ( ). Cac dong khong co thu tu co dinh;
// can du cac tu dung, khong trung. Khi sai chi bao sai, khong chi ra dong nao sai.
class KokugoHantaiScreen extends StatefulWidget {
  final KokugoLesson lesson;
  const KokugoHantaiScreen({super.key, required this.lesson});

  @override
  State<KokugoHantaiScreen> createState() => _KokugoHantaiScreenState();
}

class _KokugoHantaiScreenState extends State<KokugoHantaiScreen> {
  late List<List<String>> _cells; // moi dong 2 o ('' = trong)
  late List<String> _read;
  int _selRow = -1;
  int _selCol = -1;
  String _hintText = '';
  int _tries = 0;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    final n = widget.lesson.items.length;
    _cells = List.generate(n, (_) => ['', '']);
    _read = List<String>.filled(n, '');
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

  // tim o trong dau tien; tra ve null neu het
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

  void _tapTile(String ch) {
    setState(() {
      int r = _selRow, c = _selCol;
      if (r < 0 || _cells[r][c].isNotEmpty) {
        final e = _firstEmpty();
        if (e == null) return;
        r = e[0];
        c = e[1];
      }
      _cells[r][c] = ch;
      final e = _firstEmpty();
      if (e == null) {
        _selRow = -1;
        _selCol = -1;
      } else {
        _selRow = e[0];
        _selCol = e[1];
      }
      _hintText = '';
    });
  }

  Future<void> _editRead(int r) async {
    final v = await showDialog<String>(
      context: context,
      builder: (_) => KanaPad(initial: _read[r]),
    );
    if (v == null) return;
    setState(() => _read[r] = v);
  }

  Map<String, String> get _valid => {
        for (final it in widget.lesson.items) it.firstBlank.text: it.firstBlank.reads.first,
      };

  Future<void> _onCheck() async {
    final lang = context.read<LocaleService>().lang;
    for (var r = 0; r < _cells.length; r++) {
      if (_cells[r][0].isEmpty || _cells[r][1].isEmpty || _read[r].trim().isEmpty) {
        _snack(lang == 'ja'
            ? 'まだ かいていない ところが あるよ'
            : lang == 'en'
                ? 'Some boxes are still empty'
                : 'Còn ô chưa điền');
        return;
      }
    }
    _tries++;
    final valid = _valid;
    final seen = <String>{};
    final bad = <String>[];
    for (var r = 0; r < _cells.length; r++) {
      final w = _cells[r][0] + _cells[r][1];
      if (!valid.containsKey(w) || valid[w] != _read[r].trim() || !seen.add(w)) bad.add(KokugoEngine.circled(r));
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
    _snack(KokugoEngine.withWrong(KokugoEngine.wrongMessage('hantai', lang), bad, lang));
  }

  void _onHint() {
    final rs = context.read<RewardService>();
    final lang = context.read<LocaleService>().lang;
    showDialog(
      context: context,
      builder: (_) => HintDialog(onSelect: (opt) async {
        // chon mot tu chua duoc viet dung o dong nao
        final done = <String>{};
        for (var r = 0; r < _cells.length; r++) {
          final w = _cells[r][0] + _cells[r][1];
          if (_valid[w] != null && _valid[w] == _read[r].trim()) done.add(w);
        }
        final left = [
          for (final it in widget.lesson.items)
            if (!done.contains(it.firstBlank.text)) it
        ];
        if (left.isEmpty) {
          _snack(lang == 'ja' ? 'ぜんぶ あっているよ！' : (lang == 'en' ? 'All correct!' : 'Đúng hết rồi!'));
          return;
        }
        final ok = await rs.spendStars(opt.cost);
        if (!ok || !mounted) return;
        final it = left.first;
        final w = it.firstBlank.text;
        final rd = it.firstBlank.reads.first;
        setState(() {
          _hintText = lang == 'ja'
              ? '💡 「${w.substring(0, 1)}」と はんたいの いみの かん字を くみあわせよう。よみは「${rd.substring(0, 1)}」から はじまるよ'
              : lang == 'en'
                  ? '💡 Pair "${w.substring(0, 1)}" with its opposite kanji. The reading starts with "${rd.substring(0, 1)}"'
                  : '💡 Hãy ghép "${w.substring(0, 1)}" với chữ trái nghĩa của nó. Cách đọc bắt đầu bằng "${rd.substring(0, 1)}"';
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
        backgroundColor: const Color(0xFFAB47BC),
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
                  for (var r = 0; r < l.items.length; r++) _row(r, l.items[r]),
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

  // khung net dut chua cac chu Han de chon
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
          for (final ch in bank)
            GestureDetector(
              onTap: () => _tapTile(ch),
              child: Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFAB47BC), width: 2),
                ),
                child: Text(ch, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cell(int r, int c) {
    final sel = _selRow == r && _selCol == c;
    final v = _cells[r][c];
    return GestureDetector(
      onTap: () => _tapCell(r, c),
      child: Container(
        width: 58,
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFE3F2FD) : Colors.white,
          border: Border.all(color: sel ? const Color(0xFF1565C0) : Colors.black87, width: sel ? 3 : 2),
        ),
        child: Text(v, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _row(int r, KokugoItem it) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: Row(children: [
        SizedBox(width: 30, child: Text(it.label, style: const TextStyle(fontSize: 20))),
        _cell(r, 0),
        _cell(r, 1),
        const SizedBox(width: 12),
        const Text('（', style: TextStyle(fontSize: 28)),
        Expanded(
          child: GestureDetector(
            onTap: () => _editRead(r),
            child: Container(
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Text(_read[r], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        const Text('）', style: TextStyle(fontSize: 28)),
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
