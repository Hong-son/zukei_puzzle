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

// じこくと じかん
// 'until': とけいの じこくから おひる(12じ)までは あと なんじかん なんぷん？ (□に かずを かく)
// 'rate' : おなじ はやさで つづけると ぜんぶで なんページ？
// 'mirror': かがみに うつった とけいを 見て、じこくを かく (mat dong ho duoc lat guong)
// Khi sai chi hien thong bao chung (khong chi ra cau nao sai).
class ClockSpanScreen extends StatefulWidget {
  final ClockLesson lesson;
  const ClockSpanScreen({super.key, required this.lesson});

  @override
  State<ClockSpanScreen> createState() => _ClockSpanScreenState();
}

class _ClockSpanScreenState extends State<ClockSpanScreen> {
  late List<int?> _h; // so "じかん" (dang 'until') hoac so trang (dang 'rate')
  late List<int?> _m; // so "ふん/ぷん" (dang 'until')
  int _tries = 0;

  List<ClockQuestion> get _qs => widget.lesson.questions;

  // Dap an dung: [gio, phut] voi 'until'; [trang, 0] voi 'rate'
  List<int> _answer(int i) {
    final q = _qs[i];
    if (q.type == 'rate') return [ClockEngine.rateAnswer(q), 0];
    if (q.type == 'mirror') return [q.hour, q.minute];
    final t = ClockEngine.untilMinutes(q);
    return [t ~/ 60, t % 60];
  }

  // Cac o can dien: 'until' chi hien o co trong dap an (nhu sach); 'rate' chi 1 o
  bool _needH(int i) => _qs[i].type == 'rate' || _answer(i)[0] > 0;
  bool _needM(int i) => (_qs[i].type == 'until' || _qs[i].type == 'mirror') && _answer(i)[1] > 0;

  @override
  void initState() {
    super.initState();
    _h = List<int?>.filled(_qs.length, null);
    _m = List<int?>.filled(_qs.length, null);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 3),
    ));
  }

  bool _complete(int i) => (!_needH(i) || _h[i] != null) && (!_needM(i) || _m[i] != null);

  bool _ok(int i) {
    if (!_complete(i)) return false;
    final a = _answer(i);
    if (_needH(i) && _h[i] != a[0]) return false;
    if (_needM(i) && _m[i] != a[1]) return false;
    return true;
  }

  Future<void> _enterNumber(bool hour, int i) async {
    final cur = hour ? _h[i] : _m[i];
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
          onSubmitted: (t) => Navigator.pop(ctx, int.tryParse(t)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, -1), child: const Text('消す')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, int.tryParse(ctrl.text)), child: const Text('OK')),
        ],
      ),
    );
    if (v == null) return;
    setState(() {
      if (hour) {
        _h[i] = v == -1 ? null : v;
      } else {
        _m[i] = v == -1 ? null : v;
      }
    });
  }

  Future<void> _onCheck() async {
    final lang = context.read<LocaleService>().lang;
    if (!List.generate(_qs.length, _complete).every((c) => c)) {
      _snack(lang == 'ja'
          ? 'まだ かいていない ところが あるよ'
          : lang == 'en'
              ? 'Some boxes are still empty'
              : 'Còn ô chưa điền');
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
        ? 'ちがう ところが あるよ。もういちど かんがえて みよう'
        : lang == 'en'
            ? 'Something is not right. Think about it again'
            : 'Có chỗ chưa đúng. Hãy suy nghĩ lại nhé');
  }

  // 💡 (ton sao): giai thich cach tinh cua cau chua dung dau tien (khong noi dap an cuoi)
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
        if (_qs[target].type == 'mirror') {
          final q = _qs[target];
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(lang == 'ja' ? 'ヒント' : (lang == 'en' ? 'Hint' : 'Gợi ý')),
              content: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    lang == 'ja'
                        ? '(${target + 1}) かがみの 中では ひだりと みぎが ぎゃくに なるよ。ほんとうの とけいは こう 見えるよ。みじかい はりと ながい はりを よんで みよう。'
                        : lang == 'en'
                            ? '(${target + 1}) In a mirror, left and right are swapped. This is how the real clock looks. Read the short and long hands.'
                            : '(${target + 1}) Trong gương, trái và phải bị đảo ngược. Đồng hồ thật trông như thế này. Hãy đọc kim ngắn và kim dài.',
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  ClockFace(
                    size: 190,
                    hourAngle: ClockEngine.hourAngle(q.hour, q.minute),
                    minuteAngle: ClockEngine.minuteAngle(q.minute),
                  ),
                ]),
              ),
              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
            ),
          );
          return;
        }
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(lang == 'ja' ? 'ヒント' : (lang == 'en' ? 'Hint' : 'Gợi ý')),
            content: SingleChildScrollView(
              child: Text(_hintText(target, lang), style: const TextStyle(fontSize: 16, height: 1.5)),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
          ),
        );
      }),
    );
  }

  String _hintText(int i, String lang) {
    final q = _qs[i];
    final no = '(${i + 1})';
    if (q.type == 'rate') {
      final unit = q.extra[0] - q.hour;
      final lines = StringBuffer();
      for (var t = q.hour; t < q.extra[2]; t += unit) {
        lines.writeln(lang == 'ja'
            ? '${t}じ → ${t + unit}じ:  ${q.extra[1]}ページ'
            : lang == 'en'
                ? '$t → ${t + unit} o\'clock:  ${q.extra[1]} pages'
                : '$t giờ → ${t + unit} giờ:  ${q.extra[1]} trang');
      }
      final head = lang == 'ja'
          ? '$no おなじ はやさ だから、おなじ じかんの あいだに おなじ ページ ずつ すすむよ。\n'
          : lang == 'en'
              ? '$no Same speed, so you do the same number of pages in the same length of time.\n'
              : '$no Cùng tốc độ nên trong cùng khoảng thời gian sẽ làm được số trang bằng nhau.\n';
      final tail = lang == 'ja'
          ? '\nぜんぶ たすか、かけざんで もとめよう。'
          : lang == 'en'
              ? '\nAdd them all up (or multiply).'
              : '\nHãy cộng tất cả lại (hoặc dùng phép nhân).';
      return head + lines.toString() + tail;
    }
    final to = q.extra[0];
    final h = q.hour, m = q.minute;
    final now = ClockEngine.timeText(h, m);
    if (m == 0) {
      return lang == 'ja'
          ? '$no いまは ${h}じ。${to}じまで、${h}じ → ${to}じ。なんじかん すすむかな？ ${to} − $h を けいさんしよう。'
          : lang == 'en'
              ? '$no It is $h o\'clock now. From $h to $to o\'clock: how many hours? Calculate $to − $h.'
              : '$no Bây giờ là $h giờ. Từ $h giờ đến $to giờ là mấy tiếng? Hãy tính $to − $h.';
    }
    final first = 60 - m;
    final restH = to - (h + 1);
    return lang == 'ja'
        ? '$no いまは $now。\nまず ${h + 1}じまで あと $first ぷん(ふん)。\nそれから ${h + 1}じ → ${to}じは $restH じかん。\nじかんと ふんを わけて かこう。'
        : lang == 'en'
            ? '$no It is ${h}:${m.toString().padLeft(2, '0')} now.\nFirst, $first minutes until ${h + 1} o\'clock.\nThen ${h + 1} → $to o\'clock is $restH hours.\nWrite hours and minutes separately.'
            : '$no Bây giờ là $h giờ $m phút.\nTrước hết còn $first phút nữa là đến ${h + 1} giờ.\nSau đó từ ${h + 1} giờ đến $to giờ là $restH tiếng.\nHãy viết riêng số giờ và số phút.';
  }

  void _onReset() => setState(() {
        _h = List<int?>.filled(_qs.length, null);
        _m = List<int?>.filled(_qs.length, null);
      });

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
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
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

  Widget _numBox(bool hour, int i, String unit, {bool minuteUnit = false}) {
    final v = hour ? _h[i] : _m[i];
    final shown = minuteUnit ? (v == null ? 'ふん・ぷん' : (v % 10 == 5 ? 'ふん' : 'ぷん')) : unit;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      GestureDetector(
        onTap: () => _enterNumber(hour, i),
        child: Container(
          width: 90,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border.all(color: Colors.black87, width: 2),
          ),
          child: Text(v == null ? '' : '$v',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
        ),
      ),
      const SizedBox(width: 6),
      Text(shown, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _card(int i, String lang) {
    final q = _qs[i];
    final isRate = q.type == 'rate';
    final children = <Widget>[];
    if (isRate) {
      children.add(Text(ClockEngine.rateText(q, lang),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.5)));
      children.add(const SizedBox(height: 10));
      children.add(_numBox(true, i, 'ページ'));
    } else if (q.type == 'mirror') {
      children.add(Text(
          lang == 'ja'
              ? 'かがみに うつった とけいを 見て、その じこくを かきましょう。'
              : lang == 'en'
                  ? 'Read the time of the clock reflected in the mirror.'
                  : 'Nhìn đồng hồ phản chiếu trong gương và viết giờ.',
          style: const TextStyle(fontSize: 13, color: Colors.black54)));
      children.add(const SizedBox(height: 6));
      children.add(Text(lang == 'ja' ? 'かがみに うつった とけい' : (lang == 'en' ? 'Clock in the mirror' : 'Đồng hồ trong gương'),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)));
      children.add(const SizedBox(height: 4));
      children.add(LayoutBuilder(builder: (context, c) {
        final size = (c.maxWidth - 50).clamp(140.0, 200.0).toDouble();
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF424242), width: 4),
          ),
          // lat ngang ca mat dong ho (chu so va kim) giong anh trong guong
          child: Transform.flip(
            flipX: true,
            child: ClockFace(
              size: size,
              hourAngle: ClockEngine.hourAngle(q.hour, q.minute),
              minuteAngle: ClockEngine.minuteAngle(q.minute),
            ),
          ),
        );
      }));
      children.add(const SizedBox(height: 10));
      children.add(Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, spacing: 16, runSpacing: 8, children: [
        _numBox(true, i, 'じ'),
        if (_needM(i)) _numBox(false, i, '', minuteUnit: true),
      ]));
    } else {
      final to = q.extra[0];
      final dest = to == 12 ? 'おひる(12じ)' : '${to}じ';
      children.add(Text(
          lang == 'ja'
              ? 'とけいの じこくから $destまでは、あと なんじかん なんぷん ありますか。'
              : lang == 'en'
                  ? 'How many hours and minutes are there from the time on the clock until ${to == 12 ? 'noon (12:00)' : '$to o\'clock'}?'
                  : 'Từ giờ trên đồng hồ đến ${to == 12 ? 'trưa (12 giờ)' : '$to giờ'} còn bao nhiêu giờ, bao nhiêu phút?',
          style: const TextStyle(fontSize: 13, color: Colors.black54)));
      children.add(const SizedBox(height: 6));
      children.add(LayoutBuilder(builder: (context, c) {
        final size = (c.maxWidth - 20).clamp(150.0, 210.0).toDouble();
        return ClockFace(
          size: size,
          hourAngle: ClockEngine.hourAngle(q.hour, q.minute),
          minuteAngle: ClockEngine.minuteAngle(q.minute),
        );
      }));
      children.add(const SizedBox(height: 10));
      children.add(Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, spacing: 16, runSpacing: 8, children: [
        if (_needH(i)) _numBox(true, i, 'じかん'),
        if (_needM(i)) _numBox(false, i, '', minuteUnit: true),
      ]));
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text('(${i + 1})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        ...children,
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
