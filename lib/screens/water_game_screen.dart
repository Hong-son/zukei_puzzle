import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/elapsed_timer.dart';
import '../models/view_lesson.dart';
import '../services/reward_service.dart';
import '../services/locale_service.dart';
import '../services/progress_service.dart';
import '../services/view_engine.dart';
import '../widgets/hint_dialog.dart';
import '../widgets/shape_painters.dart';
import 'reward_screen.dart';

// 水めんの かたち: nhin tu tren xuong, danh so 1..4 theo luong nuoc nhieu -> it.
// Khi sai chi bao sai, khong chi ra hinh nao sai.
class WaterGameScreen extends StatefulWidget {
  final ViewLesson lesson;
  const WaterGameScreen({super.key, required this.lesson});

  @override
  State<WaterGameScreen> createState() => _WaterGameScreenState();
}

class _WaterGameScreenState extends State<WaterGameScreen> {
  late List<List<int>> _ans; // [cau][hinh] = so, 0 = chua tra loi
  final Set<String> _hinted = {};
  int _tries = 0;

  @override
  void initState() {
    super.initState();
    _ans = [for (final it in widget.lesson.items) List<int>.filled((it.data['tops'] as List).length, 0)];
  }

  List<int> _truth(int i) => (widget.lesson.items[i].data['ans'] as List).map((e) => (e as num).toInt()).toList();

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 3),
    ));
  }

  Future<void> _pick(int i, int j) async {
    if (_hinted.contains('$i-$j')) return;
    final n = (widget.lesson.items[i].data['tops'] as List).length;
    final v = await showDialog<int>(
      context: context,
      builder: (_) => _NumberPad(count: n, current: _ans[i][j]),
    );
    if (v == null) return;
    setState(() => _ans[i][j] = v);
  }

  Future<void> _onCheck() async {
    final lang = context.read<LocaleService>().lang;
    for (final a in _ans) {
      if (a.any((x) => x == 0)) {
        _snack(lang == 'ja'
            ? 'まだ ばんごうを かいていない ところが あるよ'
            : lang == 'en'
                ? 'Some brackets are still empty'
                : 'Còn dấu ngoặc chưa điền số');
        return;
      }
    }
    _tries++;
    var ok = true;
    for (var i = 0; i < _ans.length; i++) {
      final t = _truth(i);
      for (var j = 0; j < t.length; j++) {
        if (_ans[i][j] != t[j]) ok = false;
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
    _snack(ViewEngine.wrongMessage('water', lang));
  }

  // Goi y: dien san dap an dung cho mot hinh chua dung
  void _onHint() {
    final rs = context.read<RewardService>();
    final lang = context.read<LocaleService>().lang;
    showDialog(
      context: context,
      builder: (_) => HintDialog(onSelect: (opt) async {
        int ti = -1, tj = -1;
        for (var i = 0; i < _ans.length && ti < 0; i++) {
          final t = _truth(i);
          for (var j = 0; j < t.length; j++) {
            if (_ans[i][j] != t[j]) {
              ti = i;
              tj = j;
              break;
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
          _ans[ti][tj] = _truth(ti)[tj];
          _hinted.add('$ti-$tj');
        });
      }),
    );
  }

  void _onReset() {
    setState(() {
      _ans = [for (final a in _ans) List<int>.filled(a.length, 0)];
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
        backgroundColor: const Color(0xFF29B6F6),
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
    final pic = it.data['pic'] as String;
    final tops = (it.data['tops'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: LayoutBuilder(builder: (context, c) {
        final topSize = ((c.maxWidth - 8 * tops.length) / tops.length).clamp(60.0, 140.0).toDouble();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Text(l.question[lang] ?? '',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            ShapeView(shape: 'pic_$pic', size: 130),
          ]),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            for (var j = 0; j < tops.length; j++) _topCell(i, j, tops[j], topSize),
          ]),
        ]);
      }),
    );
  }

  Widget _topCell(int i, int j, Map<String, dynamic> t, double size) {
    final lin = (t['lin'] as List?)?.map((e) => (e as num).toDouble()).toList();
    final circles = ((t['c'] as List?) ?? const []).map((e) => (e as num).toDouble()).toList();
    final v = _ans[i][j];
    final hinted = _hinted.contains('$i-$j');
    return Column(mainAxisSize: MainAxisSize.min, children: [
      WaterTopView(
        circles: circles,
        s0: ((t['s0'] as num?) ?? 0).toDouble(),
        s1: ((t['s1'] as num?) ?? 0).toDouble(),
        kinds: (t['k'] as String?) ?? '',
        k0: (t['k0'] as String?) ?? 'o',
        k1: (t['k1'] as String?) ?? 'o',
        lin: lin,
        x: ((t['x'] as num?) ?? 0).toDouble(),
        size: size,
      ),
      const SizedBox(height: 4),
      GestureDetector(
        onTap: () => _pick(i, j),
        child: Container(
          width: 64,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: hinted ? const Color(0xFFE3F2FD) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: hinted ? const Color(0xFF1565C0) : Colors.grey.shade600, width: 2),
          ),
          child: Text(v == 0 ? '（　）' : '（$v）',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
        ),
      ),
    ]);
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
          const Text('なんばん目？', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
