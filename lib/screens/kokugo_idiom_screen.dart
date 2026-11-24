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

// かんようく: dien tu chi bo phan co the (hiragana) vao cho trong cua quan dung ngu,
// dua vao phan giai nghia. Khi sai chi bao sai, khong chi ra cau nao sai.
class KokugoIdiomScreen extends StatefulWidget {
  final KokugoLesson lesson;
  const KokugoIdiomScreen({super.key, required this.lesson});

  @override
  State<KokugoIdiomScreen> createState() => _KokugoIdiomScreenState();
}

class _KokugoIdiomScreenState extends State<KokugoIdiomScreen> {
  late List<String> _ans;
  final Map<int, String> _hintText = {};
  int _tries = 0;

  @override
  void initState() {
    super.initState();
    _ans = List<String>.filled(widget.lesson.items.length, '');
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 5),
    ));
  }

  Future<void> _edit(int i) async {
    var v = await showDialog<String>(
      context: context,
      builder: (_) => _AnswerDialog(current: _ans[i]),
    );
    if (v == null) return;
    if (v == _AnswerDialog.kanaMode) {
      if (!mounted) return;
      final isKanji = _furigana(_ans[i]) != null;
      v = await showDialog<String>(
        context: context,
        builder: (_) => KanaPad(initial: isKanji ? '' : _ans[i]),
      );
      if (v == null) return;
    }
    final value = v;
    setState(() {
      _ans[i] = value;
      _hintText.remove(i);
    });
  }

  // neu dap an dang la chu Han thi tra ve cach doc hiragana de ghi nho tren dau
  String? _furigana(String kanji) {
    for (final p in KokugoEngine.bodyParts()) {
      if (p[0] == kanji) return p[1];
    }
    return null;
  }

  bool _isRight(int i) {
    final a = _ans[i].trim();
    return a.isNotEmpty && widget.lesson.items[i].firstBlank.reads.contains(a);
  }

  Future<void> _onCheck() async {
    final lang = context.read<LocaleService>().lang;
    if (_ans.any((a) => a.trim().isEmpty)) {
      _snack(lang == 'ja'
          ? 'まだ かいていない ところが あるよ'
          : lang == 'en'
              ? 'Some boxes are still empty'
              : 'Còn ô chưa điền');
      return;
    }
    _tries++;
    final bad = <String>[];
    for (var i = 0; i < _ans.length; i++) {
      if (!_isRight(i)) bad.add(widget.lesson.items[i].label);
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
    _snack(KokugoEngine.withWrong(KokugoEngine.wrongMessage('kanyou', lang), bad, lang));
  }

  void _onHint() {
    final rs = context.read<RewardService>();
    final lang = context.read<LocaleService>().lang;
    showDialog(
      context: context,
      builder: (_) => HintDialog(onSelect: (opt) async {
        int target = -1;
        for (var i = 0; i < _ans.length; i++) {
          if (!_isRight(i) && !_hintText.containsKey(i)) {
            target = i;
            break;
          }
        }
        if (target < 0) {
          _snack(lang == 'ja' ? 'もう ヒントが ないよ' : (lang == 'en' ? 'No more hints' : 'Hết gợi ý rồi'));
          return;
        }
        final ok = await rs.spendStars(opt.cost);
        if (!ok || !mounted) return;
        final first = widget.lesson.items[target].firstBlank.reads.first;
        setState(() => _hintText[target] = '${first.substring(0, 1)} …');
      }),
    );
  }

  void _onReset() {
    setState(() {
      _ans = List<String>.filled(widget.lesson.items.length, '');
      _hintText.clear();
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
        backgroundColor: const Color(0xFF43A047),
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
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                itemCount: l.items.length,
                itemBuilder: (context, i) => _item(i, l.items[i]),
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

  Widget _answerText(String a) {
    const style = TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF1565C0), height: 1.1);
    final f = _furigana(a);
    if (f == null) {
      return Text(a, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)));
    }
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(f, style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.1)),
      Text(a, style: style),
    ]);
  }

  Widget _item(int i, KokugoItem it) {
    final phrase = <Widget>[];
    for (final part in it.parts) {
      if (part.blank) {
        phrase.add(GestureDetector(
          onTap: () => _edit(i),
          child: Container(
            width: 120,
            height: 88,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border.all(color: Colors.black87, width: 2),
            ),
            child: _answerText(_ans[i]),
          ),
        ));
      } else {
        phrase.add(Text(part.text, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600)));
      }
    }
    final meaning = (it.extra['m'] as String?) ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          SizedBox(width: 44, child: Text(it.label, style: const TextStyle(fontSize: 16))),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: phrase,
            ),
          ),
        ]),
        Padding(
          padding: const EdgeInsets.only(left: 44, top: 6),
          child: Text('（$meaning）', style: const TextStyle(fontSize: 14, color: Colors.black87)),
        ),
        if (_hintText[i] != null)
          Padding(
            padding: const EdgeInsets.only(left: 44, top: 4),
            child: Text('ヒント: ${_hintText[i]}',
                style: const TextStyle(fontSize: 14, color: Colors.deepOrange, fontWeight: FontWeight.bold)),
          ),
      ]),
    );
  }
}

// Chon dap an: bam chu Han (co hiragana nho ghi tren) hoac chuyen sang bang hiragana
class _AnswerDialog extends StatelessWidget {
  static const String kanaMode = '\u0001kana';
  final String current;
  const _AnswerDialog({required this.current});

  @override
  Widget build(BuildContext context) {
    final parts = KokugoEngine.bodyParts();
    return Dialog(
      backgroundColor: const Color(0xFFFFF8E1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 340,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('かん字から えらぼう', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final p in parts)
                      GestureDetector(
                        onTap: () => Navigator.pop(context, p[0]),
                        child: Container(
                          width: 62,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: current == p[0] ? const Color(0xFFC5CAE9) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade500, width: 2),
                          ),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Text(p[1], style: const TextStyle(fontSize: 11, color: Colors.black54)),
                            Text(p[0], style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                          ]),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context, kanaMode),
                icon: const Icon(Icons.keyboard, size: 18),
                label: const Text('ひらがなで かく'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, ''),
                child: const Text('けす'),
              ),
            ]),
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
