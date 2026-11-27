import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../widgets/elapsed_timer.dart';
import '../widgets/fold_painter.dart';
import '../widgets/hint_dialog.dart';
import '../models/fold_lesson.dart';
import '../services/reward_service.dart';
import '../services/locale_service.dart';
import '../services/progress_service.dart';
import '../services/fold_engine.dart';
import 'reward_screen.dart';

// たいしょうな かたち: 4つに おって きった あとを ひらいて、きられた ところを ▨で ぬる。
// 各もん: 1かいひらく / 2かいひらく の 2まいを ぬる。ちがうときは「ちがう ところが ある」だけ しらせる。
class FoldGameScreen extends StatefulWidget {
  final FoldLesson lesson;
  const FoldGameScreen({super.key, required this.lesson});

  @override
  State<FoldGameScreen> createState() => _FoldGameScreenState();
}

class _FoldGameScreenState extends State<FoldGameScreen> {
  late List<Set<int>> _s1; // 1かいひらく
  late List<Set<int>> _s2; // 2かいひらく
  int _tries = 0;

  List<FoldQuestion> get _qs => widget.lesson.questions;

  @override
  void initState() {
    super.initState();
    _s1 = List.generate(_qs.length, (_) => <int>{});
    _s2 = List.generate(_qs.length, (_) => <int>{});
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 4),
    ));
  }

  void _toggle(Set<int> s, int c) {
    setState(() {
      if (!s.add(c)) s.remove(c);
    });
  }

  Future<void> _onCheck() async {
    final lang = context.read<LocaleService>().lang;
    for (var i = 0; i < _qs.length; i++) {
      if (_s1[i].isEmpty || _s2[i].isEmpty) {
        _snack(lang == 'ja'
            ? 'まだ ぬっていない ところが あるよ'
            : lang == 'en'
                ? 'Some sheets are still empty'
                : 'Còn hình chưa tô');
        return;
      }
    }
    _tries++;
    var ok = true;
    for (var i = 0; i < _qs.length; i++) {
      if (!FoldEngine.isCorrect(_qs[i], _s1[i], _s2[i])) ok = false;
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
    _snack(lang == 'ja'
        ? 'ちがう ところが あるよ。おり目を さかいに、かがみに うつしたように おなじ かたちが はんたいがわにも できるよ'
        : lang == 'en'
            ? 'Something is wrong. The cut shape is mirrored on the other side of each fold line'
            : 'Có chỗ chưa đúng. Hình bị cắt sẽ được lật đối xứng như trong gương qua nếp gấp');
  }

  // Goi y: dien dung to giay sai dau tien (1 to moi lan)
  void _onHint() {
    final rs = context.read<RewardService>();
    final lang = context.read<LocaleService>().lang;
    showDialog(
      context: context,
      builder: (_) => HintDialog(onSelect: (opt) async {
        var qi = -1, step = 0;
        for (var i = 0; i < _qs.length && qi < 0; i++) {
          if (!setEquals(_s1[i], FoldEngine.answer(_qs[i], 1))) {
            qi = i;
            step = 1;
          } else if (!setEquals(_s2[i], FoldEngine.answer(_qs[i], 2))) {
            qi = i;
            step = 2;
          }
        }
        if (qi < 0) {
          _snack(lang == 'ja' ? 'ぜんぶ あっているよ！' : (lang == 'en' ? 'All correct!' : 'Đúng hết rồi!'));
          return;
        }
        final ok = await rs.spendStars(opt.cost);
        if (!ok || !mounted) return;
        setState(() {
          if (step == 1) {
            _s1[qi] = FoldEngine.answer(_qs[qi], 1);
          } else {
            _s2[qi] = FoldEngine.answer(_qs[qi], 2);
          }
        });
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(lang == 'ja' ? 'ヒント' : (lang == 'en' ? 'Hint' : 'Gợi ý')),
            content: Text(
              lang == 'ja'
                  ? 'ひらくと、おり目を さかいに かがみに うつしたように おなじ かたちが はんたいがわに できるよ。\n1かいめは よこの てんせんを さかいに うえと した、2かいめは たての てんせんを さかいに ひだりと みぎ。\n（${qi + 1}もんめの ${step}かいひらくを ぬったよ）'
                  : lang == 'en'
                      ? 'When you unfold, the same shape appears on the other side of the fold line, like a mirror.\nFirst unfold: top and bottom of the horizontal dotted line. Second unfold: left and right of the vertical dotted line.\n(Sheet ${step} of question ${qi + 1} has been filled in.)'
                      : 'Khi mở ra, hình sẽ xuất hiện đối xứng như trong gương ở phía bên kia nếp gấp.\nLần mở 1: trên và dưới đường chấm ngang. Lần mở 2: trái và phải đường chấm dọc.\n(Đã tô hình mở lần $step của câu ${qi + 1}.)',
              style: const TextStyle(fontSize: 15),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
          ),
        );
      }),
    );
  }

  void _onReset() {
    setState(() {
      for (var i = 0; i < _qs.length; i++) {
        _s1[i] = <int>{};
        _s2[i] = <int>{};
      }
    });
  }

  String _t(String lang, String ja, String en, String vi) => lang == 'ja' ? ja : (lang == 'en' ? en : vi);

  @override
  Widget build(BuildContext context) {
    final stars = context.watch<RewardService>().totalStars;
    final lang = context.watch<LocaleService>().lang;
    final l = widget.lesson;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9C4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00897B),
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
                    child: Text(
                      _t(
                          lang,
                          'かみを 4つに おって はさみで ▨の ぶぶんを きります。1かいずつ ひらいたときに きられている ぶぶんを ▨で かきましょう。（さんかくを タッチすると ぬれるよ）',
                          'Fold the paper into 4 and cut off the ▨ part with scissors. Each time you unfold it once, draw ▨ on the parts that were cut. (Tap a triangle to paint it.)',
                          'Gấp tờ giấy làm 4 rồi dùng kéo cắt phần ▨. Mỗi lần mở ra một lần, hãy tô ▨ vào phần đã bị cắt. (Chạm vào tam giác để tô.)'),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  for (var i = 0; i < _qs.length; i++) _question(i, lang),
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

  Widget _question(int i, String lang) {
    final q = _qs[i];
    const circ = ['①', '②', '③', '④'];
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: LayoutBuilder(builder: (context, c) {
        final u = ((c.maxWidth - 36) / 3).clamp(56.0, 130.0).toDouble();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(circ[i < circ.length ? i : circ.length - 1],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          // おりかた: ひろげた かみ → はんぶん → 4つに おった かたち (きるところ)
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                CustomPaint(
                    size: const Size(72, 72), painter: FoldPainter(shape: q.shape, unfold: 2, dashV: true)),
                const Text('➡', style: TextStyle(fontSize: 18)),
                CustomPaint(
                    size: const Size(38, 72),
                    painter: FoldPainter(shape: q.shape, unfold: 1, dashH: true, foldL: true)),
                const Text('➡', style: TextStyle(fontSize: 18)),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  CustomPaint(
                      size: const Size(88, 88),
                      painter: FoldPainter(
                          shape: q.shape, unfold: 0, hatched: q.cut.toSet(), foldL: true, foldB: true)),
                  Text(_t(lang, '〈きるところ〉', '(cut here)', '(chỗ cắt)'), style: const TextStyle(fontSize: 12)),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(children: [
            Container(width: 24, height: 4, color: const Color(0xFFEF6C00)),
            const SizedBox(width: 6),
            Text(_t(lang, '＝ おり目（おってある ところ）', '= fold edge', '= cạnh nếp gấp'),
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ]),
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Column(children: [
              Text(_t(lang, '1かいひらく', 'Unfold once', 'Mở 1 lần'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              FoldSheet(shape: q.shape, unfold: 1, unit: u, hatched: _s1[i], onTap: (c) => _toggle(_s1[i], c)),
            ]),
            const SizedBox(width: 12),
            Column(children: [
              Text(_t(lang, '2かいひらく', 'Unfold twice', 'Mở 2 lần'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              FoldSheet(shape: q.shape, unfold: 2, unit: u, hatched: _s2[i], onTap: (c) => _toggle(_s2[i], c)),
            ]),
          ]),
        ]);
      }),
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
