import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/elapsed_timer.dart';
import '../models/view_lesson.dart';
import '../services/reward_service.dart';
import '../services/locale_service.dart';
import '../services/progress_service.dart';
import '../services/view_engine.dart';
import '../widgets/hint_dialog.dart';
import '../widgets/box_painters.dart';
import 'reward_screen.dart';

// つみ木の おきかた: luoi thap khoi.
// - Dang so: so tren o = so khoi chong; dang mau: moi mau la mot chieu cao (do 1, xanh duong 2, vang 3, xanh la 4...).
// - Cau dem (count): dem so khoi nhin thay theo huong mui ten (ben phai: nhin sang trai, ben duoi: nhin len).
// - Cau dat khoi (place): cho san so khoi nhin thay, danh dau o co khoi mau chi dinh.
// Khi sai chi bao sai, khong chi ra mui ten hay o nao sai.
class BlocksGameScreen extends StatefulWidget {
  final ViewLesson lesson;
  const BlocksGameScreen({super.key, required this.lesson});

  @override
  State<BlocksGameScreen> createState() => _BlocksGameScreenState();
}

class _BlocksGameScreenState extends State<BlocksGameScreen> {
  late List<List<int>> _rows; // [cau][hang], 0 = chua chon (cau dem)
  late List<List<int>> _cols;
  late List<List<bool>> _marks; // [cau][hang * n + cot] (cau dat khoi)
  final Set<String> _hinted = {}; // 'i:r2', 'i:c1', 'i:m5'
  int _tries = 0;

  Map<String, dynamic> _d(int i) => widget.lesson.items[i].data;
  bool _isPlace(int i) => (_d(i)['mode'] as String?) == 'place';
  bool _isColor(int i) => (_d(i)['color'] as bool?) ?? false;
  int _n(int i) => (_d(i)['n'] as num).toInt();

  List<List<int>> _grid(int i) =>
      (_d(i)['grid'] as List).map((r) => (r as List).map((e) => (e as num).toInt()).toList()).toList();

  List<int> _ints(String key, int i) => (_d(i)[key] as List).map((e) => (e as num).toInt()).toList();

  // Dap an: so khoi nhin thay o mui ten ben phai / ben duoi
  List<int> _clueRows(int i) => _isPlace(i) ? _ints('rows', i) : ViewEngine.blockRows(_grid(i));
  List<int> _clueCols(int i) => _isPlace(i) ? _ints('cols', i) : ViewEngine.blockCols(_grid(i));

  // O dap an cua cau dat khoi
  Set<int> _targetPos(int i) => _ints('pos', i).toSet();

  @override
  void initState() {
    super.initState();
    final k = widget.lesson.items.length;
    _rows = [for (var i = 0; i < k; i++) List<int>.filled(_n(i), 0)];
    _cols = [for (var i = 0; i < k; i++) List<int>.filled(_n(i), 0)];
    _marks = [for (var i = 0; i < k; i++) List<bool>.filled(_n(i) * _n(i), false)];
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 3),
    ));
  }

  Future<void> _pick(int i, bool isRow, int k) async {
    if (_hinted.contains('$i:${isRow ? 'r' : 'c'}$k')) return;
    final v = await showDialog<int>(
      context: context,
      builder: (_) => _NumberPad(count: _n(i), current: isRow ? _rows[i][k] : _cols[i][k]),
    );
    if (v == null) return;
    setState(() {
      if (isRow) {
        _rows[i][k] = v;
      } else {
        _cols[i][k] = v;
      }
    });
  }

  void _toggle(int i, int idx) {
    if (_hinted.contains('$i:m$idx')) return;
    setState(() => _marks[i][idx] = !_marks[i][idx]);
  }

  bool _itemEmpty(int i) {
    if (_isPlace(i)) return !_marks[i].any((x) => x);
    return _rows[i].any((x) => x == 0) || _cols[i].any((x) => x == 0);
  }

  bool _itemCorrect(int i) {
    if (_isPlace(i)) {
      final t = _targetPos(i);
      for (var k = 0; k < _marks[i].length; k++) {
        if (_marks[i][k] != t.contains(k)) return false;
      }
      return true;
    }
    final tr = _clueRows(i);
    final tc = _clueCols(i);
    for (var k = 0; k < _n(i); k++) {
      if (_rows[i][k] != tr[k] || _cols[i][k] != tc[k]) return false;
    }
    return true;
  }

  Future<void> _onCheck() async {
    final lang = context.read<LocaleService>().lang;
    final cnt = widget.lesson.items.length;
    for (var i = 0; i < cnt; i++) {
      if (_itemEmpty(i)) {
        _snack(lang == 'ja'
            ? 'まだ こたえていない ところが あるよ'
            : lang == 'en'
                ? 'Some answers are still empty'
                : 'Còn chỗ chưa trả lời');
        return;
      }
    }
    _tries++;
    var ok = true;
    for (var i = 0; i < cnt; i++) {
      if (!_itemCorrect(i)) ok = false;
    }
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
    _snack(ViewEngine.wrongMessage('blocks', lang));
  }

  // Goi y: lam dung san mot cho chua dung va khoa lai
  void _onHint() {
    final rs = context.read<RewardService>();
    final lang = context.read<LocaleService>().lang;
    showDialog(
      context: context,
      builder: (_) => HintDialog(onSelect: (opt) async {
        String key = '';
        for (var i = 0; i < widget.lesson.items.length && key.isEmpty; i++) {
          if (_isPlace(i)) {
            final t = _targetPos(i);
            final n2 = _marks[i].length;
            for (var k = 0; k < n2 && key.isEmpty; k++) {
              if (t.contains(k) && !_marks[i][k]) key = '$i:m$k';
            }
            for (var k = 0; k < n2 && key.isEmpty; k++) {
              if (!t.contains(k) && _marks[i][k]) key = '$i:m$k';
            }
          } else {
            final tr = _clueRows(i);
            final tc = _clueCols(i);
            for (var k = 0; k < _n(i) && key.isEmpty; k++) {
              if (_rows[i][k] != tr[k]) key = '$i:r$k';
            }
            for (var k = 0; k < _n(i) && key.isEmpty; k++) {
              if (_cols[i][k] != tc[k]) key = '$i:c$k';
            }
          }
        }
        if (key.isEmpty) {
          _snack(lang == 'ja' ? 'ぜんぶ あっているよ！' : (lang == 'en' ? 'All correct!' : 'Đúng hết rồi!'));
          return;
        }
        final ok = await rs.spendStars(opt.cost);
        if (!ok || !mounted) return;
        final parts = key.split(':');
        final i = int.parse(parts[0]);
        final kind = parts[1][0];
        final k = int.parse(parts[1].substring(1));
        setState(() {
          if (kind == 'r') {
            _rows[i][k] = _clueRows(i)[k];
          } else if (kind == 'c') {
            _cols[i][k] = _clueCols(i)[k];
          } else {
            _marks[i][k] = _targetPos(i).contains(k);
          }
          _hinted.add(key);
        });
      }),
    );
  }

  void _onReset() {
    setState(() {
      final cnt = widget.lesson.items.length;
      _rows = [for (var i = 0; i < cnt; i++) List<int>.filled(_n(i), 0)];
      _cols = [for (var i = 0; i < cnt; i++) List<int>.filled(_n(i), 0)];
      _marks = [for (var i = 0; i < cnt; i++) List<bool>.filled(_n(i) * _n(i), false)];
      _hinted.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final stars = context.watch<RewardService>().totalStars;
    final lang = context.watch<LocaleService>().lang;
    final l = widget.lesson;
    final colorMode = _isColor(0);
    final multi = l.items.length > 1;
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
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(l.question[lang] ?? '',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                  _legend(lang, _n(0), colorMode),
                  const SizedBox(height: 8),
                  _example(lang, colorMode),
                  const SizedBox(height: 8),
                  for (var i = 0; i < l.items.length; i++) ...[
                    _puzzle(i, lang, multi),
                    const SizedBox(height: 8),
                  ],
                ],
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

  // Cac loai khoi 1..n va so luong moi loai
  Widget _legend(String lang, int n, bool color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: 14,
        runSpacing: 8,
        children: [
          for (var h = 1; h <= n; h++)
            Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
              if (!color) ...[
                Text(ViewEngine.circled[h - 1], style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 4),
              ],
              BlockStackView(h: h, unit: 18, color: color ? kBlockColors[h - 1] : null),
              const SizedBox(width: 4),
              Text(lang == 'ja' ? 'が$nこ' : '×$n', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ]),
        ],
      ),
    );
  }

  // れい: luoi 2x2 co dap an san
  Widget _example(String lang, bool color) {
    const g = [
      [2, 4],
      [3, 1],
    ];
    final tr = ViewEngine.blockRows(g);
    final tc = ViewEngine.blockCols(g);
    final text = lang == 'ja'
        ? 'やじるしの かずは その れつに 見える ブロックの かずです。'
        : lang == 'en'
            ? 'The number by each arrow is how many blocks can be seen in that line.'
            : 'Số ở mũi tên là số khối nhìn thấy trên hàng/cột đó.';
    const cs = 38.0;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade500, width: 2),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(lang == 'ja' ? 'れい' : (lang == 'en' ? 'Example' : 'Ví dụ'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(text, style: const TextStyle(fontSize: 13)),
          ]),
        ),
        const SizedBox(width: 10),
        Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (var r = 0; r < 2; r++)
            Row(mainAxisSize: MainAxisSize.min, children: [
              for (var c = 0; c < 2; c++) _cell(g[r][c], cs, color, fs: 20),
              const SizedBox(width: 6),
              const Text('←', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Text('${tr[r]}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
          const SizedBox(height: 2),
          Row(mainAxisSize: MainAxisSize.min, children: [
            for (var c = 0; c < 2; c++)
              SizedBox(
                width: cs,
                child: Column(children: [
                  const Text('↑', style: TextStyle(fontSize: 16)),
                  Text('${tc[c]}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ]),
              ),
          ]),
        ]),
      ]),
    );
  }

  // O co khoi cao h: dang so hien so tron, dang mau hien o mau
  Widget _cell(int h, double size, bool color, {double fs = 26}) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color ? kBlockColors[h - 1] : const Color(0xFFFFFDE7),
        border: Border.all(color: Colors.black87, width: 1.5),
      ),
      child: color ? null : Text(ViewEngine.circled[h - 1], style: TextStyle(fontSize: fs)),
    );
  }

  // O trong cua cau dat khoi: cham de danh dau/ bo ○
  Widget _markCell(int i, int idx, double size) {
    final on = _marks[i][idx];
    final hinted = _hinted.contains('$i:m$idx');
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _toggle(i, idx),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: hinted ? const Color(0xFFE3F2FD) : Colors.white,
          border: Border.all(color: Colors.black87, width: 1.5),
        ),
        child: on
            ? Container(
                width: size * 0.62,
                height: size * 0.62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: hinted ? const Color(0xFF1565C0) : const Color(0xFFD84315), width: 3),
                ),
              )
            : (hinted ? Text('×', style: TextStyle(fontSize: size * 0.5, color: Colors.black38)) : null),
      ),
    );
  }

  Widget _puzzle(int i, String lang, bool multi) {
    final n = _n(i);
    final place = _isPlace(i);
    final color = _isColor(i);
    final g = place ? null : _grid(i);
    final cr = place ? _clueRows(i) : null;
    final cc = place ? _clueCols(i) : null;
    final it = widget.lesson.items[i];
    final q = (_d(i)['q'] as Map?)?[lang] as String?;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: LayoutBuilder(builder: (context, c) {
        // ben phai: mui ten + o tra loi
        final cs = ((c.maxWidth - 8 - 22 - 6) / (n + 1)).clamp(36.0, 64.0).toDouble();
        final bs = cs.clamp(38.0, 50.0).toDouble();
        Widget rightPart(int r) {
          if (place) {
            return SizedBox(
              width: 22 + 2 + bs,
              child: Row(children: [
                const SizedBox(width: 22, child: Center(child: Text('←', style: TextStyle(fontSize: 18)))),
                const SizedBox(width: 2),
                SizedBox(
                  width: bs,
                  child: Center(
                    child: Text('${cr![r]}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                  ),
                ),
              ]),
            );
          }
          return Row(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(width: 22, child: Center(child: Text('←', style: TextStyle(fontSize: 18)))),
            const SizedBox(width: 2),
            _answerBox(i, true, r, bs),
          ]);
        }

        Widget bottomPart(int k) {
          return SizedBox(
            width: cs,
            child: Column(children: [
              const Text('↑', style: TextStyle(fontSize: 18)),
              if (place)
                SizedBox(
                  height: bs - 6,
                  child: Center(
                    child: Text('${cc![k]}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                  ),
                )
              else
                _answerBox(i, false, k, bs),
            ]),
          );
        }

        return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (multi || q != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('${it.label} ${q ?? ''}'.trim(),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              for (var r = 0; r < n; r++)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  for (var k = 0; k < n; k++)
                    place ? _markCell(i, r * n + k, cs) : _cell(g![r][k], cs, color, fs: cs * 0.6),
                  const SizedBox(width: 6),
                  rightPart(r),
                ]),
              const SizedBox(height: 4),
              // o duoi: mui ten huong len; chen can phai cho thang hang voi cac cot
              Row(mainAxisSize: MainAxisSize.min, children: [
                for (var k = 0; k < n; k++) bottomPart(k),
                SizedBox(width: 6 + 22 + 2 + bs),
              ]),
            ]),
          ),
        ]);
      }),
    );
  }

  Widget _answerBox(int i, bool isRow, int k, double size) {
    final v = isRow ? _rows[i][k] : _cols[i][k];
    final hinted = _hinted.contains('$i:${isRow ? 'r' : 'c'}$k');
    return GestureDetector(
      onTap: () => _pick(i, isRow, k),
      child: Container(
        width: size,
        height: size - 6,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: hinted ? const Color(0xFFE3F2FD) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: hinted ? const Color(0xFF1565C0) : Colors.grey.shade700, width: 2),
        ),
        child: Text(v == 0 ? '' : '$v',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
      ),
    );
  }
}

class _NumberPad extends StatelessWidget {
  final int count;
  final int current;
  const _NumberPad({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFFF8E1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('いくつ 見える？', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var n = 1; n <= count; n++)
                SizedBox(
                  width: 60,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, n),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: current == n ? const Color(0xFF3F51B5) : Colors.white,
                      foregroundColor: current == n ? Colors.white : Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('$n', style: const TextStyle(fontSize: 28)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextButton(onPressed: () => Navigator.pop(context, 0), child: const Text('けす')),
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
