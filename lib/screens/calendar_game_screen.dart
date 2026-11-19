import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/elapsed_timer.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/calendar_lesson.dart';
import '../services/reward_service.dart';
import '../services/locale_service.dart';
import '../services/progress_service.dart';
import '../services/calendar_engine.dart';
import '../widgets/hint_dialog.dart';
import 'reward_screen.dart';

class CalendarGameScreen extends StatefulWidget {
  final CalendarLesson lesson;
  const CalendarGameScreen({super.key, required this.lesson});

  @override
  State<CalendarGameScreen> createState() => _CalendarGameScreenState();
}

class _CalendarGameScreenState extends State<CalendarGameScreen> {
  late List<List<int?>> _answers;
  late List<List<int>> _correct;
  Set<String> _wrong = {};
  int _tries = 0;
  bool _hintUnlocked = false;
  bool _showCal = false;
  int _calQ = 0;
  String _hintText = '';
  int? _hintQ;
  int? _hintSlot;

  @override
  void initState() {
    super.initState();
    final qs = widget.lesson.questions;
    _correct = qs.map((q) => CalendarEngine.answer(q)).toList();
    _answers = qs.map((q) => List<int?>.filled(CalendarEngine.slots(q).length, null)).toList();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 3),
    ));
  }

  void _clearFeedback() {
    _wrong = {};
    _hintText = '';
    _hintQ = null;
    _hintSlot = null;
  }

  Future<void> _enterNumber(int q, int s, int maxLen) async {
    final cur = _answers[q][s];
    final ctrl = TextEditingController(text: cur == null ? '' : '$cur');
    final v = await showDialog<int?>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: maxLen,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(counterText: ''),
          onSubmitted: (t) => Navigator.pop(ctx, int.tryParse(t)),
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
      _answers[q][s] = v == -1 ? null : v;
      _clearFeedback();
    });
  }

  Future<void> _pickWeekday(int q, int s) async {
    final v = await showDialog<int>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('よう日', textAlign: TextAlign.center),
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: List.generate(7, (i) {
              final sun = i == 6;
              final sat = i == 5;
              return GestureDetector(
                onTap: () => Navigator.pop(context, i),
                child: Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE0B2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Text(CalendarEngine.weekNames[i],
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: sun ? Colors.red : (sat ? Colors.blue : Colors.black))),
                ),
              );
            }),
          ),
        ],
      ),
    );
    if (v != null) {
      setState(() {
        _answers[q][s] = v;
        _clearFeedback();
      });
    }
  }

  String _slotName(String kind, String lang) {
    switch (kind) {
      case 'm':
        return lang == 'ja' ? 'つき' : lang == 'en' ? 'month' : 'tháng';
      case 'd':
        return lang == 'ja' ? 'ひ' : lang == 'en' ? 'day' : 'ngày';
      case 'w':
        return lang == 'ja' ? 'よう日' : lang == 'en' ? 'weekday' : 'thứ';
      default:
        return lang == 'ja' ? '日かん' : lang == 'en' ? 'days' : 'số ngày';
    }
  }

  Future<void> _onCheck() async {
    final lang = context.read<LocaleService>().lang;
    _tries++;
    final qs = widget.lesson.questions;
    final wrong = <String>{};
    bool empty = false;
    final kinds = <String>{};
    for (int q = 0; q < qs.length; q++) {
      final sl = CalendarEngine.slots(qs[q]);
      for (int s = 0; s < sl.length; s++) {
        final a = _answers[q][s];
        if (a == null) {
          empty = true;
          wrong.add('${q}_$s');
        } else if (a != _correct[q][s]) {
          wrong.add('${q}_$s');
          kinds.add(sl[s]);
        }
      }
    }
    if (wrong.isEmpty) {
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
    setState(() {
      _hintUnlocked = true;
      _wrong = wrong;
      _hintText = '';
      _hintQ = null;
      _hintSlot = null;
    });
    if (empty && kinds.isEmpty) {
      _snack(lang == 'ja' ? 'まだ かいていない ところが あるよ' : lang == 'en' ? 'Some boxes are still empty' : 'Còn ô chưa điền');
    } else {
      final names = kinds.map((k) => _slotName(k, lang)).join(', ');
      _snack(lang == 'ja'
          ? 'ちがう ところが あるよ（$names）。つきの おわりを こえるか かんがえよう'
          : lang == 'en'
              ? 'Some answers are wrong ($names). Check whether you cross the end of a month'
              : 'Có ô sai ($names). Hãy xem có vượt qua cuối tháng không');
    }
  }

  void _onHint() {
    final rs = context.read<RewardService>();
    final lang = context.read<LocaleService>().lang;
    showDialog(
      context: context,
      builder: (_) => HintDialog(onSelect: (opt) async {
        final ok = await rs.spendStars(opt.cost);
        if (!ok) return;
        final qs = widget.lesson.questions;
        for (int q = 0; q < qs.length; q++) {
          final sl = CalendarEngine.slots(qs[q]);
          for (int s = 0; s < sl.length; s++) {
            if (_answers[q][s] != _correct[q][s]) {
              final qq = qs[q];
              final ans = _correct[q][s];
              String t;
              if (qq.type == 'span') {
                t = lang == 'ja'
                    ? '💡 はじめの 日も おわりの 日も ふくめて かぞえよう。「おわり − はじめ + 1」で $ans 日かん'
                    : lang == 'en'
                        ? '💡 Count both the first and last day: last - first + 1 = $ans days'
                        : '💡 Tính cả ngày đầu và ngày cuối: ngày cuối - ngày đầu + 1 = $ans ngày';
              } else if (sl[s] == 'w') {
                t = lang == 'ja'
                    ? '💡 7日で おなじ よう日に もどるよ。こたえは ${CalendarEngine.wk(ans)}よう日'
                    : lang == 'en'
                        ? '💡 Every 7 days returns to the same weekday. The answer is ${CalendarEngine.wk(ans)}'
                        : '💡 Cứ 7 ngày thì quay lại cùng thứ. Đáp án là ${CalendarEngine.wk(ans)}';
              } else if (sl[s] == 'm') {
                t = lang == 'ja'
                    ? '💡 つきの おわりを こえると つぎの つき（まえの つき）に なるよ。こたえは $ans月'
                    : lang == 'en'
                        ? '💡 Crossing the end of a month changes the month. The answer is month $ans'
                        : '💡 Qua cuối tháng thì đổi tháng. Đáp án là tháng $ans';
              } else {
                t = lang == 'ja'
                    ? '💡 ここは $ans日 だよ'
                    : lang == 'en'
                        ? '💡 This box is $ans'
                        : '💡 Ô này là $ans';
              }
              setState(() {
                _hintQ = q;
                _hintSlot = s;
                _hintText = t;
                _calQ = q;
                _showCal = true;
              });
              return;
            }
          }
        }
        setState(() => _hintText = lang == 'ja' ? 'ぜんぶ あっているよ！' : lang == 'en' ? 'All correct!' : 'Đúng hết rồi!');
      }),
    );
  }

  Widget _box(int q, int s, String kind) {
    final v = _answers[q][s];
    final bad = _wrong.contains('${q}_$s');
    final hint = _hintQ == q && _hintSlot == s;
    Color bg = Colors.white;
    Color border = Colors.grey.shade700;
    double bw = 2;
    if (bad) {
      bg = Colors.red.shade50;
      border = Colors.red;
    }
    if (hint) {
      bg = const Color(0xFFFFE082);
      border = Colors.deepOrange;
      bw = 4;
    }
    String label = '';
    if (v != null) {
      label = kind == 'w' ? CalendarEngine.weekNames[v] : '$v';
    }
    return GestureDetector(
      onTap: () => kind == 'w' ? _pickWeekday(q, s) : _enterNumber(q, s, 3),
      child: Container(
        width: 54,
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border, width: bw),
        ),
        child: Text(label, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
      ),
    );
  }

  Widget _unit(String t) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );

  Widget _questionCard(int q, String lang) {
    final qq = widget.lesson.questions[q];
    final sl = CalendarEngine.slots(qq);
    final children = <Widget>[];
    for (int s = 0; s < sl.length; s++) {
      children.add(_box(q, s, sl[s]));
      if (sl[s] == 'm') children.add(_unit('月'));
      if (sl[s] == 'd') children.add(_unit('日'));
      if (sl[s] == 'w') children.add(_unit('よう日'));
      if (sl[s] == 'n') children.add(_unit(lang == 'ja' ? '日かん' : lang == 'en' ? 'days' : 'ngày'));
    }
    return GestureDetector(
      onTap: () => setState(() => _calQ = q),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _calQ == q && _showCal ? Colors.teal : Colors.grey.shade400, width: 2),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('(${q + 1}) ${CalendarEngine.text(qq, lang)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(crossAxisAlignment: WrapCrossAlignment.center, runSpacing: 6, children: children),
        ]),
      ),
    );
  }

  Widget _calendar(String lang) {
    final qq = widget.lesson.questions[_calQ];
    final months = <int>{qq.month};
    if (qq.type == 'span') months.add(qq.month2);
    final ans = _correct[_calQ];
    if (qq.type == 'afterMonth') months.add(ans[0]);
    if (qq.type == 'beforeMonth') months.add(ans[0]);
    final list = months.toList()..sort();
    final hinted = _hintQ == _calQ;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal, width: 2),
      ),
      child: Column(children: [
        for (final m in list) _monthGrid(m, qq, hinted),
      ]),
    );
  }

  Widget _monthGrid(int m, CalendarQuestion qq, bool hinted) {
    final days = CalendarEngine.dim(m, qq.year);
    // thu cua ngay 1: tu thu da cho cua cau hoi, tinh nguoc ve ngay 1
    final base = CalendarEngine.toIndex(qq.month, qq.day, qq.year);
    final first = CalendarEngine.toIndex(m, 1, qq.year);
    final firstWeekday = CalendarEngine.weekdayAfter(qq.weekday, first - base);
    final cells = <Widget>[];
    for (int i = 0; i < 7; i++) {
      cells.add(Center(
          child: Text(CalendarEngine.weekNames[i],
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: i == 6 ? Colors.red : (i == 5 ? Colors.blue : Colors.black)))));
    }
    for (int i = 0; i < firstWeekday; i++) {
      cells.add(const SizedBox());
    }
    for (int d = 1; d <= days; d++) {
      final isStart = qq.month == m && qq.day == d;
      final isEnd = qq.type == 'span' && qq.month2 == m && qq.day2 == d;
      final idx = CalendarEngine.toIndex(m, d, qq.year);
      final lo = qq.type == 'span' ? base : min(base, base + (qq.type.startsWith('before') ? -qq.amount : qq.amount));
      final hi = qq.type == 'span' ? CalendarEngine.toIndex(qq.month2, qq.day2, qq.year) : max(base, base + (qq.type.startsWith('before') ? -qq.amount : qq.amount));
      final inRange = hinted && idx >= lo && idx <= hi;
      cells.add(Container(
        margin: const EdgeInsets.all(1.5),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isStart
              ? const Color(0xFFFFCC80)
              : isEnd
                  ? const Color(0xFFA5D6A7)
                  : inRange
                      ? const Color(0xFFFFF59D)
                      : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
          border: isStart ? Border.all(color: Colors.deepOrange, width: 2) : null,
        ),
        child: Text('$d', style: TextStyle(fontSize: 13, fontWeight: isStart ? FontWeight.bold : FontWeight.normal)),
      ));
    }
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text('$m月', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
      ),
      GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.5,
        children: cells,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final stars = context.watch<RewardService>().totalStars;
    final lang = context.watch<LocaleService>().lang;
    final l = widget.lesson;
    final instr = lang == 'ja'
        ? 'つぎの □に あてはまる かずや よう日を かきましょう。'
        : lang == 'en'
            ? 'Fill in the boxes with the correct numbers and weekdays.'
            : 'Điền số và thứ thích hợp vào các ô.';
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9C4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        title: Text(l.title[lang] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
          child: Text(instr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        ),
        if (l.year != 0)
          Container(
            margin: const EdgeInsets.fromLTRB(12, 4, 12, 2),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: CalendarEngine.isLeap(l.year) ? const Color(0xFFE1F5FE) : const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.teal),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.info_outline, color: Colors.teal, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(CalendarEngine.yearNote(l.year, lang),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ]),
          ),
        if (_hintText.isNotEmpty)
          GestureDetector(
            onTap: () => setState(() {
              _hintText = '';
              _hintQ = null;
              _hintSlot = null;
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
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: ListView(children: [
                for (int q = 0; q < l.questions.length; q++) _questionCard(q, lang),
                if (_showCal) _calendar(lang),
                const SizedBox(height: 20),
              ]),
            ),
          ),
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
                      for (final a in _answers) {
                        for (int i = 0; i < a.length; i++) {
                          a[i] = null;
                        }
                      }
                      _clearFeedback();
                    })),
            _ToolBtn(
                icon: Icons.calendar_month,
                label: 'カレンダー',
                color: Colors.teal,
                onTap: () => setState(() => _showCal = !_showCal)),
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
