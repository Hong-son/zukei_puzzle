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

// とうめいな はこと ボール: hop trong suot co bong, nhin tu cac huong -> danh dau o thay bong.
// Khi sai chi bao sai, khong chi ra o nao sai.
class BoxGameScreen extends StatefulWidget {
  final ViewLesson lesson;
  const BoxGameScreen({super.key, required this.lesson});

  @override
  State<BoxGameScreen> createState() => _BoxGameScreenState();
}

class _BoxGameScreenState extends State<BoxGameScreen> {
  late List<List<List<bool>>> _ans; // [cau][huong nhin][o 0..3]
  final Set<String> _hinted = {}; // 'cau-huong-o'
  int _tries = 0;

  List<List<int>> _balls(int i) => (widget.lesson.items[i].data['balls'] as List)
      .map((b) => (b as List).map((e) => (e as num).toInt()).toList())
      .toList();

  List<String> _views(int i) =>
      (widget.lesson.items[i].data['views'] as List).map((e) => e as String).toList();

  List<bool> _truth(int i, int v) => ViewEngine.boxView(_balls(i), _views(i)[v]);

  @override
  void initState() {
    super.initState();
    _ans = [
      for (var i = 0; i < widget.lesson.items.length; i++)
        [for (var v = 0; v < _views(i).length; v++) List<bool>.filled(4, false)],
    ];
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 3),
    ));
  }

  void _toggle(int i, int v, int c) {
    if (_hinted.contains('$i-$v-$c')) return;
    setState(() => _ans[i][v][c] = !_ans[i][v][c]);
  }

  Future<void> _onCheck() async {
    final lang = context.read<LocaleService>().lang;
    for (final q in _ans) {
      for (final g in q) {
        if (!g.any((x) => x)) {
          _snack(lang == 'ja'
              ? 'まだ ○を つけていない ところが あるよ'
              : lang == 'en'
                  ? 'Some grids have no ○ yet'
                  : 'Còn bảng chưa đánh ○');
          return;
        }
      }
    }
    _tries++;
    var ok = true;
    for (var i = 0; i < _ans.length; i++) {
      for (var v = 0; v < _ans[i].length; v++) {
        final t = _truth(i, v);
        for (var c = 0; c < 4; c++) {
          if (_ans[i][v][c] != t[c]) ok = false;
        }
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
    _snack(ViewEngine.wrongMessage('box', lang));
  }

  // Goi y: lam dung san mot o chua dung va khoa lai
  void _onHint() {
    final rs = context.read<RewardService>();
    final lang = context.read<LocaleService>().lang;
    showDialog(
      context: context,
      builder: (_) => HintDialog(onSelect: (opt) async {
        int ti = -1, tv = -1, tc = -1;
        for (var i = 0; i < _ans.length && ti < 0; i++) {
          for (var v = 0; v < _ans[i].length && ti < 0; v++) {
            final t = _truth(i, v);
            for (var c = 0; c < 4; c++) {
              if (_ans[i][v][c] != t[c]) {
                ti = i;
                tv = v;
                tc = c;
                break;
              }
            }
          }
        }
        if (ti < 0) {
          _snack(lang == 'ja' ? 'ぜんぶ あっているよ！' : (lang == 'en' ? 'All correct!' : 'Đúng hết rồi!'));
          return;
        }
        final ok = await rs.spendStars(opt.cost);
        if (!ok || !mounted) return;
        setState(() {
          _ans[ti][tv][tc] = _truth(ti, tv)[tc];
          _hinted.add('$ti-$tv-$tc');
        });
      }),
    );
  }

  void _onReset() {
    setState(() {
      _ans = [
        for (final q in _ans) [for (final g in q) List<bool>.filled(4, false)],
      ];
      _hinted.clear();
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
        backgroundColor: const Color(0xFF26A69A),
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
                  for (var i = 0; i < l.items.length; i++) _question(i, l, lang),
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

  Widget _question(int i, ViewLesson l, String lang) {
    final it = l.items[i];
    final views = _views(i);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: LayoutBuilder(builder: (context, c) {
        final box = (c.maxWidth * 0.62).clamp(150.0, 240.0).toDouble();
        final grid = ((c.maxWidth - 16 * views.length) / views.length).clamp(76.0, 130.0).toDouble();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(it.label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Center(child: BoxBallsView(balls: _balls(i), size: box)),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (var v = 0; v < views.length; v++)
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text(ViewEngine.boxViewNames[views[v]]![lang] ?? '',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                _grid(i, v, grid),
              ]),
          ]),
        ]);
      }),
    );
  }

  Widget _grid(int i, int v, double size) {
    final cell = size / 2;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(border: Border.all(color: Colors.black87, width: 2)),
      child: Column(children: [
        for (var r = 0; r < 2; r++)
          Expanded(
            child: Row(children: [
              for (var c = 0; c < 2; c++) Expanded(child: _cell(i, v, r * 2 + c, cell)),
            ]),
          ),
      ]),
    );
  }

  Widget _cell(int i, int v, int idx, double cell) {
    final on = _ans[i][v][idx];
    final hinted = _hinted.contains('$i-$v-$idx');
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _toggle(i, v, idx),
      child: Container(
        decoration: BoxDecoration(
          color: hinted ? const Color(0xFFE3F2FD) : Colors.transparent,
          border: Border.all(color: Colors.black54, width: 1),
        ),
        alignment: Alignment.center,
        child: on
            ? Container(
                width: cell * 0.62,
                height: cell * 0.62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: hinted ? const Color(0xFF1565C0) : const Color(0xFFD84315), width: 3),
                ),
              )
            : (hinted
                ? Text('×', style: TextStyle(fontSize: cell * 0.5, color: Colors.black38))
                : null),
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
