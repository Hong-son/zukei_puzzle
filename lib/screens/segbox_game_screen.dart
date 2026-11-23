import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/elapsed_timer.dart';
import '../models/view_lesson.dart';
import '../services/reward_service.dart';
import '../services/locale_service.dart';
import '../services/progress_service.dart';
import '../services/segbox_engine.dart';
import '../services/view_engine.dart';
import '../widgets/hint_dialog.dart';
import '../widgets/segbox_painter.dart';
import 'reward_screen.dart';

// とうめいな はこ (すう字): hop trong suot co thanh (bou) -> nhin tu huong chi dinh thanh chu so nao;
// bai nam sinh: 4 hop A-D, tim nam sinh va huong cua tung hop khi nhin tu tren.
// Khi sai chi bao sai, khong chi ra cho sai.
class SegBoxGameScreen extends StatefulWidget {
  final ViewLesson lesson;
  const SegBoxGameScreen({super.key, required this.lesson});

  @override
  State<SegBoxGameScreen> createState() => _SegBoxGameScreenState();
}

class _SegBoxGameScreenState extends State<SegBoxGameScreen> {
  final Map<String, int?> _digit = {}; // 'i-q' -> chu so chon cho cau view
  final Map<int, List<int?>> _year = {}; // item -> 4 chu so cua nam
  final Map<int, List<int>> _orient = {}; // item -> huong 4 hop (0 F, 1 R, 2 B, 3 L)
  final Map<int, int> _sel = {}; // item -> o nam dang chon
  final Set<String> _locked = {};
  int _tries = 0;

  List<ViewItem> get _items => widget.lesson.items;
  String _type(int i) => _items[i].data['t'] as String;
  List<List<int>> _bars(int i) => SegBoxEngine.barsOf(_items[i].data['bars']);
  List<List<dynamic>> _qs(int i) =>
      (_items[i].data['qs'] as List).map((e) => List<dynamic>.from(e as List)).toList();
  List<List<List<int>>> _boxes(int i) =>
      (_items[i].data['boxes'] as List).map((e) => SegBoxEngine.barsOf(e)).toList();
  String _ask(int i) => _items[i].data['ask'] as String;
  int _answerYear(int i) => SegBoxEngine.yearAnswer(_boxes(i), _ask(i));
  List<int> _answerDigits(int i) => _answerYear(i).toString().split('').map(int.parse).toList();

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < _items.length; i++) {
      if (_type(i) == 'year') {
        _year[i] = List<int?>.filled(4, null);
        _orient[i] = List<int>.filled(4, 0);
        _sel[i] = 0;
        if (_items[i].data['pre'] == true) {
          // sach da ghi san so dau va huong cua hop A
          final ad = _answerDigits(i);
          _year[i]![0] = ad[0];
          _locked.add('y-$i-0');
          final os = SegBoxEngine.orientsFor(_boxes(i)[0], ad[0]);
          if (os.isNotEmpty) {
            _orient[i]![0] = os.first;
            _locked.add('o-$i-0');
          }
          _sel[i] = 1;
        }
      }
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 3),
    ));
  }

  bool _viewCorrect(int i, int q) => _digit['$i-$q'] == (_qs(i)[q][1] as num).toInt();

  bool _orientOk(int i, int b) {
    final d = SegBoxEngine.digit(_boxes(i)[b], SegBoxEngine.views[_orient[i]![b]]);
    return d != null && d == _answerDigits(i)[b];
  }

  bool _yearCorrect(int i) {
    final y = _year[i]!;
    final ad = _answerDigits(i);
    for (var s = 0; s < 4; s++) {
      if (y[s] != ad[s]) return false;
    }
    for (var b = 0; b < 4; b++) {
      if (!_orientOk(i, b)) return false;
    }
    return true;
  }

  bool _complete() {
    for (var i = 0; i < _items.length; i++) {
      final t = _type(i);
      if (t == 'view') {
        for (var q = 0; q < _qs(i).length; q++) {
          if (_digit['$i-$q'] == null) return false;
        }
      } else if (t == 'year') {
        if (_year[i]!.any((e) => e == null)) return false;
      }
    }
    return true;
  }

  Future<void> _onCheck() async {
    final lang = context.read<LocaleService>().lang;
    if (!_complete()) {
      _snack(lang == 'ja'
          ? 'まだ こたえて いない ところが あるよ'
          : lang == 'en'
              ? 'Some answers are still empty'
              : 'Còn chỗ chưa trả lời');
      return;
    }
    _tries++;
    var ok = true;
    for (var i = 0; i < _items.length; i++) {
      final t = _type(i);
      if (t == 'view') {
        for (var q = 0; q < _qs(i).length; q++) {
          if (!_viewCorrect(i, q)) ok = false;
        }
      } else if (t == 'year') {
        if (!_yearCorrect(i)) ok = false;
      }
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
    _snack(ViewEngine.wrongMessage('segbox', lang));
  }

  // Goi y: dien dung san mot cho chua dung va khoa lai
  void _onHint() {
    final rs = context.read<RewardService>();
    final lang = context.read<LocaleService>().lang;
    showDialog(
      context: context,
      builder: (_) => HintDialog(onSelect: (opt) async {
        // tim cho sai dau tien
        String? target;
        for (var i = 0; i < _items.length && target == null; i++) {
          final t = _type(i);
          if (t == 'view') {
            for (var q = 0; q < _qs(i).length; q++) {
              if (!_viewCorrect(i, q)) {
                target = 'v-$i-$q';
                break;
              }
            }
          } else if (t == 'year') {
            final ad = _answerDigits(i);
            for (var s = 0; s < 4; s++) {
              if (_year[i]![s] != ad[s]) {
                target = 'y-$i-$s';
                break;
              }
            }
            if (target == null) {
              for (var b = 0; b < 4; b++) {
                if (!_orientOk(i, b)) {
                  target = 'o-$i-$b';
                  break;
                }
              }
            }
          }
        }
        if (target == null) {
          _snack(lang == 'ja' ? 'ぜんぶ あっているよ！' : (lang == 'en' ? 'All correct!' : 'Đúng hết rồi!'));
          return;
        }
        final ok = await rs.spendStars(opt.cost);
        if (!ok || !mounted) return;
        final p = target.split('-');
        final i = int.parse(p[1]);
        final k = int.parse(p[2]);
        setState(() {
          if (p[0] == 'v') {
            _digit['$i-$k'] = (_qs(i)[k][1] as num).toInt();
          } else if (p[0] == 'y') {
            _year[i]![k] = _answerDigits(i)[k];
          } else {
            final os = SegBoxEngine.orientsFor(_boxes(i)[k], _answerDigits(i)[k]);
            if (os.isNotEmpty) _orient[i]![k] = os.first;
          }
          _locked.add(target!);
        });
      }),
    );
  }

  void _onReset() {
    setState(() {
      _digit.clear();
      _locked.clear();
      for (final i in _year.keys.toList()) {
        _year[i] = List<int?>.filled(4, null);
        _orient[i] = List<int>.filled(4, 0);
        _sel[i] = 0;
        if (_items[i].data['pre'] == true) {
          final ad = _answerDigits(i);
          _year[i]![0] = ad[0];
          _locked.add('y-$i-0');
          final os = SegBoxEngine.orientsFor(_boxes(i)[0], ad[0]);
          if (os.isNotEmpty) {
            _orient[i]![0] = os.first;
            _locked.add('o-$i-0');
          }
          _sel[i] = 1;
        }
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
        backgroundColor: const Color(0xFF3F7FD8),
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
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                children: [
                  for (var i = 0; i < _items.length; i++) _card(i, lang),
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

  Widget _card(int i, String lang) {
    final t = _type(i);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: LayoutBuilder(builder: (context, c) {
        if (t == 'year') return _yearCard(i, c.maxWidth, lang);
        return _viewCard(i, c.maxWidth, lang, example: t == 'example');
      }),
    );
  }

  // ---- cau "nhin tu huong nay thanh so may" ----
  Widget _viewCard(int i, double maxW, String lang, {required bool example}) {
    final it = _items[i];
    final qs = _qs(i);
    final fw = (maxW * 0.3).clamp(90.0, 150.0).toDouble();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(it.label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SegBoxView(bars: _bars(i), width: fw),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (var q = 0; q < qs.length; q++) ...[
              Text(SegBoxEngine.viewName(qs[q][0] as String)[lang] ?? '',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              if (example)
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green, width: 2),
                  ),
                  child: Text('${qs[q][1]}',
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.green)),
                )
              else
                _pad(selected: _digit['$i-$q'], locked: _locked.contains('v-$i-$q'), onTap: (d) {
                  setState(() => _digit['$i-$q'] = d);
                }),
              const SizedBox(height: 10),
            ],
          ]),
        ),
      ]),
    ]);
  }

  // ---- bai nam sinh ----
  Widget _yearCard(int i, double maxW, String lang) {
    final boxes = _boxes(i);
    final fw = (((maxW - 8) / 4 - 6) / (1 + SegBoxView.depth)).clamp(44.0, 100.0).toDouble();
    final q = (_items[i].data['q'] as Map?)?.map((k, v) => MapEntry(k as String, v as String));
    final y = _year[i]!;
    final sel = _sel[i] ?? 0;
    final tileSize = ((maxW - 40) / 4).clamp(48.0, 78.0).toDouble();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_items[i].label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      if (q != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(q[lang] ?? '', style: const TextStyle(fontSize: 13)),
        ),
      const SizedBox(height: 4),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        for (var b = 0; b < 4; b++) SegBoxView(bars: boxes[b], width: fw, label: String.fromCharCode(65 + b)),
      ]),
      const SizedBox(height: 4),
      Center(
        child: Text(
          lang == 'ja'
              ? '↓ 左から A B C D の じゅんに 〈入れもの〉へ ↓'
              : lang == 'en'
                  ? '↓ Put them in the container in order A B C D from the left ↓'
                  : '↓ Đặt vào khay theo thứ tự A B C D từ trái sang ↓',
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ),
      const SizedBox(height: 10),
      // 上から 見ると
      Text(lang == 'ja' ? '上から 見ると' : (lang == 'en' ? 'Seen from above' : 'Nhìn từ trên xuống'),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        for (var b = 0; b < 4; b++) _tile(i, b, tileSize),
      ]),
      const SizedBox(height: 4),
      Center(
        child: Text(
          lang == 'ja'
              ? '（もじを タップすると むきが かわるよ）'
              : lang == 'en'
                  ? '(Tap a letter to turn it)'
                  : '(Chạm vào chữ để xoay hướng)',
          style: const TextStyle(fontSize: 11, color: Colors.black45),
        ),
      ),
      const SizedBox(height: 12),
      Row(children: [
        for (var s = 0; s < 4; s++)
          GestureDetector(
            onTap: () => setState(() => _sel[i] = s),
            child: Container(
              width: 46,
              height: 54,
              margin: const EdgeInsets.only(right: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _locked.contains('y-$i-$s') ? const Color(0xFFE3F2FD) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: s == sel ? const Color(0xFF3F51B5) : Colors.black54, width: s == sel ? 3 : 1.5),
              ),
              child: Text(y[s] == null ? '' : '${y[s]}',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            ),
          ),
        Text(lang == 'ja' ? '年' : (lang == 'en' ? 'yr' : 'năm'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 8),
      _pad(
        selected: y[sel],
        locked: _locked.contains('y-$i-$sel'),
        onTap: (d) {
          setState(() {
            y[sel] = d;
            if (sel < 3) _sel[i] = sel + 1;
          });
        },
      ),
    ]);
  }

  Widget _tile(int i, int b, double size) {
    final o = _orient[i]![b];
    final locked = _locked.contains('o-$i-$b');
    return GestureDetector(
      onTap: locked ? null : () => setState(() => _orient[i]![b] = (o + 1) % 4),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: locked ? const Color(0xFFE3F2FD) : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.black87, width: 2),
        ),
        child: Transform.rotate(
          angle: o * pi / 2,
          child: Text(String.fromCharCode(65 + b),
              style: TextStyle(fontSize: size * 0.55, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }

  // Ban chon chu so 0-9
  Widget _pad({required int? selected, required bool locked, required void Function(int) onTap}) {
    return Wrap(spacing: 6, runSpacing: 6, children: [
      for (var d = 0; d < 10; d++)
        GestureDetector(
          onTap: locked ? null : () => onTap(d),
          child: Container(
            width: 34,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected == d ? (locked ? const Color(0xFF1565C0) : const Color(0xFFFFB74D)) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black45),
            ),
            child: Text('$d',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: selected == d && locked ? Colors.white : Colors.black87)),
          ),
        ),
    ]);
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
