import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/pyramid_lesson.dart';
import '../services/reward_service.dart';
import '../services/locale_service.dart';
import '../services/progress_service.dart';
import '../services/pyramid_engine.dart';
import '../widgets/hint_dialog.dart';
import 'reward_screen.dart';

class PyramidGameScreen extends StatefulWidget {
  final PyramidLesson lesson;
  const PyramidGameScreen({super.key, required this.lesson});

  @override
  State<PyramidGameScreen> createState() => _PyramidGameScreenState();
}

class _PyramidGameScreenState extends State<PyramidGameScreen> {
  late List<List<List<int>>> _sols;
  late Set<String> _fixed;
  // moi "tap" la mot thap nhap tay: key "r_c" -> gia tri
  late List<Map<String, int>> _boards;
  final Set<int> _found = {};
  int _tries = 0;
  bool _hintUnlocked = false;
  Set<String> _wrong = {};
  String? _hintKey;
  int? _hintBoard;
  String _hintText = '';

  @override
  void initState() {
    super.initState();
    final l = widget.lesson;
    _sols = PyramidEngine.solve(l.levels, l.given);
    _fixed = {for (final g in l.given) '${g[0]}_${g[1]}'};
    final count = l.multi ? max(1, _sols.length) : 1;
    _boards = List.generate(count, (_) => <String, int>{});
  }

  int? _valueAt(int b, int r, int c) {
    for (final g in widget.lesson.given) {
      if (g[0] == r && g[1] == c) return g[2];
    }
    return _boards[b]['${r}_$c'];
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 3),
    ));
  }

  Future<void> _enter(int b, int r, int c) async {
    if (_fixed.contains('${r}_$c')) return;
    final cur = _boards[b]['${r}_$c'];
    final ctrl = TextEditingController(text: cur == null ? '' : '$cur');
    final v = await showDialog<int?>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 3,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(counterText: ''),
          onSubmitted: (s) => Navigator.pop(ctx, int.tryParse(s)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, -1), child: const Text('消す')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, int.tryParse(ctrl.text)),
              child: const Text('OK')),
        ],
      ),
    );
    if (v == null) return;
    setState(() {
      if (v == -1) {
        _boards[b].remove('${r}_$c');
      } else {
        _boards[b]['${r}_$c'] = v;
      }
      _wrong = {};
      _hintKey = null;
      _hintBoard = null;
      _hintText = '';
    });
  }

  bool _isFull(int b) {
    for (int r = 0; r < widget.lesson.levels; r++) {
      for (int c = 0; c <= r; c++) {
        if (_valueAt(b, r, c) == null) return false;
      }
    }
    return true;
  }

  List<List<int>> _rowsOf(int b) => List.generate(widget.lesson.levels,
      (r) => List.generate(r + 1, (c) => _valueAt(b, r, c)!));

  // Tra ve null neu dung, nguoc lai ma loi va cac o sai
  String? _validate(int b, Set<String> bad) {
    final l = widget.lesson;
    if (!_isFull(b)) return 'empty';
    final rows = _rowsOf(b);
    for (int r = 0; r < l.levels - 1; r++) {
      for (int c = 0; c <= r; c++) {
        if (rows[r][c] != rows[r + 1][c] + rows[r + 1][c + 1]) {
          bad.add('${r}_$c');
          bad.add('${r + 1}_$c');
          bad.add('${r + 1}_${c + 1}');
        }
      }
    }
    if (bad.isNotEmpty) return 'sum';
    if (l.multi) {
      for (final row in rows) {
        for (final v in row) {
          if (v <= 0) return 'zero';
        }
      }
    }
    return null;
  }

  String _key(List<List<int>> rows) => rows.last.join(',');

  Future<void> _onCheck() async {
    final lang = context.read<LocaleService>().lang;
    final l = widget.lesson;
    _tries++;
    final bad = <String>{};

    if (!l.multi) {
      final err = _validate(0, bad);
      if (err == null) {
        await _finish();
        return;
      }
      _fail(err, bad, lang);
      return;
    }

    final keys = <String>{};
    for (int b = 0; b < _boards.length; b++) {
      if (!_isFull(b)) {
        _fail('empty', bad, lang);
        return;
      }
      final err = _validate(b, bad);
      if (err != null) {
        _fail(err, bad, lang);
        return;
      }
      final k = _key(_rowsOf(b));
      if (!_sols.any((s) => _key(s) == k)) {
        _fail('notmatch', bad, lang);
        return;
      }
      if (!keys.add(k)) {
        _fail('dup', bad, lang);
        return;
      }
    }
    if (keys.length < _sols.length) {
      _fail('missing', bad, lang);
      return;
    }
    await _finish();
  }

  void _fail(String code, Set<String> bad, String lang) {
    setState(() {
      _hintUnlocked = true;
      _wrong = bad;
      _hintKey = null;
      _hintText = '';
    });
    String m;
    switch (code) {
      case 'empty':
        m = lang == 'ja' ? 'まだ かいていない ますが あるよ' : lang == 'en' ? 'Some blocks are still empty' : 'Còn ô chưa điền';
        break;
      case 'sum':
        m = lang == 'ja' ? 'となりの 2つを たした かずが 上の ますと ちがうよ（あかい ます）' : lang == 'en' ? 'Two neighbours do not add up to the block above (red blocks)' : 'Có ô không bằng tổng hai ô bên dưới (các ô đỏ)';
        break;
      case 'zero':
        m = lang == 'ja' ? '0は つかえないよ' : lang == 'en' ? '0 is not allowed' : 'Không được dùng số 0';
        break;
      case 'notmatch':
        m = lang == 'ja' ? 'もんだいの かずと あわない つみ木が あるよ' : lang == 'en' ? 'One tower does not match the given numbers' : 'Có tháp không khớp số đề cho';
        break;
      case 'dup':
        m = lang == 'ja' ? 'おなじ 入れかたが 2つ あるよ' : lang == 'en' ? 'Two towers use the same filling' : 'Có hai tháp điền giống hệt nhau';
        break;
      default:
        m = lang == 'ja' ? 'まだ 入れかたが のこって いるよ（ぜんぶ かこう）' : lang == 'en' ? 'There are still other ways. Find them all' : 'Còn cách điền khác chưa có, hãy tìm đủ';
    }
    _snack(m);
  }

  Future<void> _finish() async {
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
  }

  void _onHint() {
    final rs = context.read<RewardService>();
    final lang = context.read<LocaleService>().lang;
    showDialog(
      context: context,
      builder: (_) => HintDialog(onSelect: (opt) async {
        final ok = await rs.spendStars(opt.cost);
        if (!ok) return;
        if (_sols.isEmpty) return;
        // chon thap chua dien xong va loi giai khop nhat
        int bIdx = 0;
        for (int b = 0; b < _boards.length; b++) {
          if (!_isFull(b) || _validate(b, <String>{}) != null) {
            bIdx = b;
            break;
          }
        }
        List<List<int>> best = _sols.first;
        int bestScore = -1;
        for (final s in _sols) {
          int sc = 0;
          for (int r = 0; r < widget.lesson.levels; r++) {
            for (int c = 0; c <= r; c++) {
              if (_boards[bIdx]['${r}_$c'] == s[r][c]) sc++;
            }
          }
          if (sc > bestScore) {
            bestScore = sc;
            best = s;
          }
        }
        final pool = <List<int>>[];
        for (int r = 0; r < widget.lesson.levels; r++) {
          for (int c = 0; c <= r; c++) {
            if (_fixed.contains('${r}_$c')) continue;
            if (_boards[bIdx]['${r}_$c'] != best[r][c]) pool.add([r, c]);
          }
        }
        if (pool.isEmpty) {
          setState(() => _hintText = lang == 'ja' ? 'この つみ木は あっているよ' : lang == 'en' ? 'This tower is correct' : 'Tháp này đã đúng');
          return;
        }
        // uu tien o suy ra duoc tu 2 o ben duoi da dien
        List<int> pick = pool[Random().nextInt(pool.length)];
        for (final p in pool) {
          final r = p[0], c = p[1];
          if (r + 1 < widget.lesson.levels &&
              _valueAt(bIdx, r + 1, c) != null &&
              _valueAt(bIdx, r + 1, c + 1) != null) {
            pick = p;
            break;
          }
        }
        final r = pick[0], c = pick[1];
        final ans = best[r][c];
        setState(() {
          _hintBoard = bIdx;
          _hintKey = '${r}_$c';
          if (r + 1 < widget.lesson.levels &&
              _valueAt(bIdx, r + 1, c) != null &&
              _valueAt(bIdx, r + 1, c + 1) != null) {
            final a = _valueAt(bIdx, r + 1, c)!;
            final b2 = _valueAt(bIdx, r + 1, c + 1)!;
            _hintText = lang == 'ja'
                ? '💡 オレンジの ますは $a + $b2 = $ans'
                : lang == 'en'
                    ? '💡 The orange block is $a + $b2 = $ans'
                    : '💡 Ô cam bằng $a + $b2 = $ans';
          } else {
            _hintText = lang == 'ja'
                ? '💡 オレンジの ますには $ans が 入るよ'
                : lang == 'en'
                    ? '💡 The orange block should be $ans'
                    : '💡 Ô cam điền số $ans';
          }
        });
      }),
    );
  }

  Widget _tower(int b, double cs) {
    final l = widget.lesson;
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (l.multi)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('${b + 1}', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
          ),
        for (int r = 0; r < l.levels; r++)
          Row(mainAxisSize: MainAxisSize.min, children: [
            for (int c = 0; c <= r; c++) _cell(b, r, c, cs),
          ]),
      ]),
    );
  }

  Widget _cell(int b, int r, int c, double cs) {
    final key = '${r}_$c';
    final fixed = _fixed.contains(key);
    final v = _valueAt(b, r, c);
    final bad = _wrong.contains(key);
    final hint = _hintBoard == b && _hintKey == key;
    Color bg = Colors.white;
    Color border = Colors.grey.shade700;
    double bw = 1.5;
    if (fixed) bg = const Color(0xFFE0E0E0);
    if (bad) {
      bg = Colors.red.shade50;
      border = Colors.red;
      bw = 2.5;
    }
    if (hint) {
      bg = const Color(0xFFFFE082);
      border = Colors.deepOrange;
      bw = 4;
    }
    return GestureDetector(
      onTap: () => _enter(b, r, c),
      child: Container(
        width: cs,
        height: cs * 0.8,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bg, border: Border.all(color: border, width: bw)),
        child: Text(
          v == null ? '' : '$v',
          style: TextStyle(
              fontSize: cs * 0.42,
              fontWeight: FontWeight.bold,
              color: fixed ? Colors.black : const Color(0xFF1565C0)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stars = context.watch<RewardService>().totalStars;
    final lang = context.watch<LocaleService>().lang;
    final l = widget.lesson;
    final filled = l.multi
        ? _boards.where((b) => b.isNotEmpty).length
        : 0;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9C4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8D6E63),
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
        if (l.multi)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              lang == 'ja' ? '入れかた: ${_boards.length}とおり ($filled/${_boards.length} かいた)' : lang == 'en' ? 'Ways to fill: ${_boards.length} ($filled/${_boards.length} started)' : 'Số cách điền: ${_boards.length} (đã bắt đầu $filled/${_boards.length})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        if (_hintText.isNotEmpty)
          GestureDetector(
            onTap: () => setState(() {
              _hintText = '';
              _hintKey = null;
              _hintBoard = null;
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
                Expanded(child: Text(_hintText, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
              ]),
            ),
          ),
        Expanded(
          child: LayoutBuilder(builder: (context, cons) {
            final perRow = l.multi && cons.maxWidth > 700 ? 3 : (l.multi && cons.maxWidth > 420 ? 2 : 1);
            final avail = (cons.maxWidth - 40) / perRow;
            final cs = min(avail / l.levels - 4, 64.0).clamp(28.0, 64.0);
            return SingleChildScrollView(
              child: Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [for (int b = 0; b < _boards.length; b++) _tower(b, cs)],
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
                      for (final b in _boards) {
                        b.clear();
                      }
                      _wrong = {};
                      _hintKey = null;
                      _hintBoard = null;
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
