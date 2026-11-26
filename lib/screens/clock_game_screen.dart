import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/elapsed_timer.dart';
import '../widgets/clock_face.dart';
import '../widgets/hint_dialog.dart';
import '../models/clock_lesson.dart';
import '../services/reward_service.dart';
import '../services/locale_service.dart';
import '../services/progress_service.dart';
import '../services/clock_engine.dart';
import 'reward_screen.dart';

// とけいの はり
// 'set' : 😀 □の じこくを さすように、みじかい はり・ながい はりを うごかす。
// 'draw': ながい はりが ない とけい。みじかい はりを 見て ながい はりを かき、じこくを えらぶ。
// Khi sai chi hien thong bao chung (khong chi ra cau nao sai).
class ClockGameScreen extends StatefulWidget {
  final ClockLesson lesson;
  const ClockGameScreen({super.key, required this.lesson});

  @override
  State<ClockGameScreen> createState() => _ClockGameScreenState();
}

class _ClockGameScreenState extends State<ClockGameScreen> {
  late List<double?> _h; // goc kim ngan
  late List<double?> _m; // goc kim dai
  late List<int> _sel; // kim dang chon: 0 = ngan, 1 = dai (dang 'set')
  late List<int?> _wh; // gio da chon (dang 'draw')
  late List<int?> _wm; // phut da chon (dang 'draw')
  int _tries = 0;

  List<ClockQuestion> get _qs => widget.lesson.questions;
  // co cau nao co phut khac 0/30 khong -> hien du cac phut 0,5,10...55
  bool get _fine => _qs.any((q) => q.minute % 30 != 0);

  @override
  void initState() {
    super.initState();
    final n = _qs.length;
    _h = [
      for (final q in _qs) q.type == 'draw' ? ClockEngine.hourAngle(q.hour, q.minute) : null,
    ];
    _m = List<double?>.filled(n, null);
    _sel = [for (final q in _qs) q.type == 'draw' ? 1 : 0];
    _wh = List<int?>.filled(n, null);
    _wm = List<int?>.filled(n, null);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 3),
    ));
  }

  void _onAngle(int i, double a) {
    final q = _qs[i];
    setState(() {
      if (q.type == 'draw' || _sel[i] == 1) {
        _m[i] = ((a / 30).round() % 12) * 30.0; // kim dai: nhay 5 phut
      } else {
        _h[i] = ((a / 15).round() % 24) * 15.0; // kim ngan: nhay 15 do (ちょうど / はん)
        if (_m[i] == null) _sel[i] = 1; // dat xong kim ngan thi chuyen sang kim dai
      }
    });
  }

  bool _complete(int i) {
    final q = _qs[i];
    if (_m[i] == null) return false;
    if (q.type == 'set') return _h[i] != null;
    return _wh[i] != null && _wm[i] != null;
  }

  bool _ok(int i) {
    final q = _qs[i];
    if (!_complete(i)) return false;
    final minuteOk = _m[i]!.round() % 360 == ClockEngine.minuteAngle(q.minute).round() % 360;
    if (!minuteOk) return false;
    if (q.type == 'set') {
      return ClockEngine.angleDiff(_h[i]!, ClockEngine.hourAngle(q.hour, q.minute)) <= 8;
    }
    return _wh[i] == q.hour && _wm[i] == q.minute;
  }

  Future<void> _onCheck() async {
    final lang = context.read<LocaleService>().lang;
    if (!List.generate(_qs.length, _complete).every((c) => c)) {
      _snack(lang == 'ja'
          ? 'まだ のこって いる ところが あるよ'
          : lang == 'en'
              ? 'Some questions are not finished yet'
              : 'Còn câu chưa làm xong');
      return;
    }
    _tries++;
    if (List.generate(_qs.length, _ok).every((c) => c)) {
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
        ? 'ちがう ところが あるよ。はりの むきを もういちど 見てみよう'
        : lang == 'en'
            ? 'Something is not right. Look at the hands again'
            : 'Có chỗ chưa đúng. Hãy xem lại các kim nhé');
  }

  // 💡 (ton sao): dat san kim dai dung cua cau chua dung + giai thich cach doc
  void _onHint() {
    final rs = context.read<RewardService>();
    final lang = context.read<LocaleService>().lang;
    showDialog(
      context: context,
      builder: (_) => HintDialog(onSelect: (opt) async {
        var target = -1;
        for (var i = 0; i < _qs.length; i++) {
          if (!_ok(i)) {
            target = i;
            break;
          }
        }
        if (target < 0) {
          _snack(lang == 'ja' ? 'ぜんぶ あっているよ！' : (lang == 'en' ? 'All correct!' : 'Đúng hết rồi!'));
          return;
        }
        final ok = await rs.spendStars(opt.cost);
        if (!ok || !mounted) return;
        setState(() => _m[target] = ClockEngine.minuteAngle(_qs[target].minute));
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(lang == 'ja' ? 'ヒント' : (lang == 'en' ? 'Hint' : 'Gợi ý')),
            content: Text(
              lang == 'ja'
                  ? '(${target + 1}) の ながい はりを いれたよ。\nみじかい はりが すうじに ぴったり あって いたら「ちょうど」。ながい はりは 12 を さすよ。\nすうじと すうじの まんなかに あったら「30ぷん」。ながい はりは 6 を さすよ。'
                  : lang == 'en'
                      ? 'I placed the long hand for (${target + 1}).\nIf the short hand points exactly at a number, it is "o\'clock" and the long hand points to 12.\nIf the short hand is halfway between two numbers, it is "30 minutes" and the long hand points to 6.'
                      : 'Đã đặt kim dài cho câu (${target + 1}).\nNếu kim ngắn chỉ đúng vào một con số thì là "giờ đúng", kim dài chỉ số 12.\nNếu kim ngắn nằm giữa hai con số thì là "30 phút", kim dài chỉ số 6.',
              style: const TextStyle(fontSize: 16),
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
        final q = _qs[i];
        _h[i] = q.type == 'draw' ? ClockEngine.hourAngle(q.hour, q.minute) : null;
        _m[i] = null;
        _sel[i] = q.type == 'draw' ? 1 : 0;
        _wh[i] = null;
        _wm[i] = null;
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
        backgroundColor: const Color(0xFFEC407A),
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
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _legend(const Color(0xFF1565C0), lang == 'ja' ? 'みじかい はり（じ）' : (lang == 'en' ? 'Short hand (hour)' : 'Kim ngắn (giờ)')),
            const SizedBox(width: 16),
            _legend(const Color(0xFFD32F2F), lang == 'ja' ? 'ながい はり（ふん）' : (lang == 'en' ? 'Long hand (minute)' : 'Kim dài (phút)')),
          ]),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                itemCount: _qs.length,
                itemBuilder: (context, i) => _card(i, lang),
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

  Widget _legend(Color c, String t) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 22, height: 6, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(t, style: const TextStyle(fontSize: 12)),
      ]);

  Widget _card(int i, String lang) {
    final q = _qs[i];
    final isSet = q.type == 'set';
    final instr = isSet
        ? (lang == 'ja'
            ? '□の じこくを さすように、とけいに はりを かきこみましょう。（はりを えらんで、とけいを タッチ）'
            : lang == 'en'
                ? 'Make the clock show the time in the box. Choose a hand, then touch the clock.'
                : 'Chỉnh đồng hồ cho đúng giờ trong khung. Chọn kim rồi chạm vào mặt đồng hồ.')
        : (lang == 'ja'
            ? 'ながい はりが ない とけい。みじかい はりを 見て、ながい はりを かいて、じこくを えらびましょう。'
            : lang == 'en'
                ? 'The long hand is missing. Look at the short hand, draw the long hand, and choose the time.'
                : 'Kim dài bị mất. Nhìn kim ngắn, vẽ kim dài rồi chọn giờ.');
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('(${i + 1})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(instr, style: const TextStyle(fontSize: 12, color: Colors.black54))),
        ]),
        const SizedBox(height: 6),
        LayoutBuilder(builder: (context, c) {
          final size = (c.maxWidth - 20).clamp(160.0, 240.0).toDouble();
          return ClockFace(
            size: size,
            hourAngle: _h[i],
            minuteAngle: _m[i],
            interactive: true,
            onAngle: (a) => _onAngle(i, a),
          );
        }),
        const SizedBox(height: 8),
        if (isSet) ...[
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _handBtn(i, 0, lang == 'ja' ? 'みじかい はり' : (lang == 'en' ? 'Short hand' : 'Kim ngắn'), const Color(0xFF1565C0)),
            const SizedBox(width: 12),
            _handBtn(i, 1, lang == 'ja' ? 'ながい はり' : (lang == 'en' ? 'Long hand' : 'Kim dài'), const Color(0xFFD32F2F)),
          ]),
          const SizedBox(height: 8),
          Container(
            width: 180,
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(border: Border.all(color: Colors.black87, width: 2)),
            child: Text(ClockEngine.timeText(q.hour, q.minute),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          ),
        ] else ...[
          Wrap(alignment: WrapAlignment.center, spacing: 6, runSpacing: 6, children: [
            for (var h = 1; h <= 12; h++) _chip('${h}じ', _wh[i] == h, () => setState(() => _wh[i] = h)),
          ]),
          const SizedBox(height: 8),
          Wrap(alignment: WrapAlignment.center, spacing: 6, runSpacing: 6, children: [
            for (final m in (_fine ? [for (var k = 0; k < 60; k += 5) k] : const [0, 30]))
              _chip(m == 0 ? 'ちょうど' : ClockEngine.minuteText(m), _wm[i] == m, () => setState(() => _wm[i] = m)),
          ]),
          const SizedBox(height: 8),
          Container(
            width: 220,
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(border: Border.all(color: Colors.black87, width: 2)),
            child: Text(
                _wh[i] == null && _wm[i] == null
                    ? ''
                    : '${_wh[i] ?? '?'}じ${_wm[i] == null ? '?' : (_wm[i] == 0 ? '' : ClockEngine.minuteText(_wm[i]!))}',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          ),
        ],
      ]),
    );
  }

  Widget _handBtn(int i, int hand, String label, Color color) {
    final on = _sel[i] == hand;
    return GestureDetector(
      onTap: () => setState(() => _sel[i] = hand),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: on ? color.withValues(alpha: 0.15) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: on ? 3 : 1.5),
        ),
        child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ),
    );
  }

  Widget _chip(String t, bool on, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: on ? const Color(0xFFFCE4EC) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFEC407A), width: on ? 3 : 1.5),
        ),
        child: Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
