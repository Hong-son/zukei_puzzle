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

// かげの 正たい: 3 cai bong -> chon vat (so ①..⑥). Khi sai chi bao sai, khong chi cau nao sai.
class ShadowGameScreen extends StatefulWidget {
  final ViewLesson lesson;
  const ShadowGameScreen({super.key, required this.lesson});

  @override
  State<ShadowGameScreen> createState() => _ShadowGameScreenState();
}

class _ShadowGameScreenState extends State<ShadowGameScreen> {
  late List<int> _ans; // 0 = chua chon, 1..6 = vat
  final Set<int> _hinted = {};
  int _tries = 0;

  List<String> get _bank => widget.lesson.bank.isEmpty ? ViewEngine.objects : widget.lesson.bank;

  @override
  void initState() {
    super.initState();
    _ans = List<int>.filled(widget.lesson.items.length, 0);
  }

  int _truth(int i) => _bank.indexOf(widget.lesson.items[i].data['obj'] as String) + 1;

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 3),
    ));
  }

  Future<void> _pick(int i) async {
    if (_hinted.contains(i)) return;
    final v = await showDialog<int>(
      context: context,
      builder: (_) => _ObjectPad(bank: _bank, current: _ans[i]),
    );
    if (v == null) return;
    setState(() => _ans[i] = v);
  }

  Future<void> _onCheck() async {
    final lang = context.read<LocaleService>().lang;
    if (_ans.any((a) => a == 0)) {
      _snack(lang == 'ja'
          ? 'まだ ばんごうを えらんでいない ところが あるよ'
          : lang == 'en'
              ? 'Some boxes are still empty'
              : 'Còn ô chưa chọn');
      return;
    }
    _tries++;
    var ok = true;
    for (var i = 0; i < _ans.length; i++) {
      if (_ans[i] != _truth(i)) ok = false;
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
    _snack(ViewEngine.wrongMessage('shadow', lang));
  }

  // Goi y: dien san dap an cua mot cau chua dung
  void _onHint() {
    final rs = context.read<RewardService>();
    final lang = context.read<LocaleService>().lang;
    showDialog(
      context: context,
      builder: (_) => HintDialog(onSelect: (opt) async {
        int t = -1;
        for (var i = 0; i < _ans.length; i++) {
          if (_ans[i] != _truth(i)) {
            t = i;
            break;
          }
        }
        if (t < 0) {
          _snack(lang == 'ja' ? 'ぜんぶ あっているよ！' : (lang == 'en' ? 'All correct!' : 'Đúng hết rồi!'));
          return;
        }
        final ok = await rs.spendStars(opt.cost);
        if (!ok || !mounted) return;
        setState(() {
          _ans[t] = _truth(t);
          _hinted.add(t);
        });
      }),
    );
  }

  void _onReset() {
    setState(() {
      _ans = List<int>.filled(widget.lesson.items.length, 0);
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
        backgroundColor: const Color(0xFF6D4C41),
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
              child: LayoutBuilder(builder: (context, c) {
                final cols = c.maxWidth >= 620 ? 2 : 1;
                final w = (c.maxWidth - 24 - (cols - 1) * 12) / cols;
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                  child: Column(children: [
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: [for (var i = 0; i < l.items.length; i++) _card(i, l.items[i], w)],
                    ),
                    const SizedBox(height: 14),
                    _bankRow(lang),
                  ]),
                );
              }),
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

  Widget _card(int i, ViewItem it, double w) {
    final obj = it.data['obj'] as String;
    final v = _ans[i];
    final hinted = _hinted.contains(i);
    return Container(
      width: w,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(it.label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Center(child: ShadowBox(obj: obj, width: w - 20)),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () => _pick(i),
            child: Container(
              width: 70,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: hinted ? const Color(0xFFE3F2FD) : Colors.grey.shade100,
                border: Border.all(color: hinted ? const Color(0xFF1565C0) : Colors.black87, width: 2),
              ),
              child: Text(v == 0 ? '' : ViewEngine.circled[v - 1],
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _bankRow(String lang) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var k = 0; k < _bank.length; k++)
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text(ViewEngine.circled[k], style: const TextStyle(fontSize: 20)),
            ShapeView(shape: 'icon_${_bank[k]}', size: 72),
          ]),
      ],
    );
  }
}

// Bang chon vat: icon + so ①..⑥
class _ObjectPad extends StatelessWidget {
  final List<String> bank;
  final int current;
  const _ObjectPad({required this.bank, required this.current});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFFF8E1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 360,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('どれかな？', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (var k = 0; k < bank.length; k++)
                      GestureDetector(
                        onTap: () => Navigator.pop(context, k + 1),
                        child: Container(
                          width: 96,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: current == k + 1 ? const Color(0xFFC5CAE9) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade500, width: 2),
                          ),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Text(ViewEngine.circled[k], style: const TextStyle(fontSize: 22)),
                            ShapeView(shape: 'icon_${bank[k]}', size: 70),
                          ]),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: () => Navigator.pop(context, 0), child: const Text('けす')),
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
