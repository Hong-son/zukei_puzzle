import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/elapsed_timer.dart';
import '../models/kokugo_lesson.dart';
import '../services/reward_service.dart';
import '../services/locale_service.dart';
import '../services/progress_service.dart';
import '../services/kokugo_engine.dart';
import '../widgets/hint_dialog.dart';
import '../widgets/word_comic.dart';
import '../services/word_help.dart';
import 'reward_screen.dart';

// ことばを つかって ぶんを つくろう: 2 tu cho san, tu viet cau bang tay (khong co dap an duy nhat).
// Bam 「こたえあわせ」 de xem cau mau, roi tu cham ○ / ✕ cho tung cau (nhu dang viet chu Han).
// Cau mau nam trong reads cua doan blank dau tien; cac tu cho san la cac doan khong blank.
class KokugoBunScreen extends StatefulWidget {
  final KokugoLesson lesson;
  const KokugoBunScreen({super.key, required this.lesson});

  @override
  State<KokugoBunScreen> createState() => _KokugoBunScreenState();
}

class _KokugoBunScreenState extends State<KokugoBunScreen> {
  late List<List<List<Offset>>> _strokes; // net viet cua tung cau (toa do 0..1)
  late List<int> _mark; // 0 chua cham, 1 ○, 2 ✕ (do danh sach kiem tra)
  late List<List<bool>> _chk; // danh sach kiem tra 4 muc cho moi cau
  late List<bool> _locked; // cau da ○ thi khoa
  late List<bool> _typed; // true = go bang ban phim, false = viet tay
  late List<TextEditingController> _ctl;
  bool _revealed = false;
  int _tries = 0;

  List<KokugoItem> get _items => widget.lesson.items;

  @override
  void initState() {
    super.initState();
    _strokes = List.generate(_items.length, (_) => <List<Offset>>[]);
    _mark = List<int>.filled(_items.length, 0);
    _chk = List.generate(_items.length, (_) => List<bool>.filled(4, false));
    _locked = List<bool>.filled(_items.length, false);
    _typed = List<bool>.filled(_items.length, false);
    _ctl = List.generate(_items.length, (_) => TextEditingController());
  }

  @override
  void dispose() {
    for (final c in _ctl) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> _words(int i) => [for (final p in _items[i].parts) if (!p.blank) p.text];

  // Goi y: cho thay cac dang bien doi cua tu + cach noi cau
  void _onHint() {
    final lang = context.read<LocaleService>().lang;
    final rs = context.read<RewardService>();
    showDialog(
      context: context,
      builder: (_) => HintDialog(onSelect: (opt) async {
        final ok = await rs.spendStars(opt.cost);
        if (!ok || !mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(lang == 'ja' ? 'ヒント' : (lang == 'en' ? 'Hint' : 'Gợi ý')),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(
                    lang == 'ja'
                        ? 'ことばは かたちを かえても いいよ。'
                        : lang == 'en'
                            ? 'You may change the form of each word.'
                            : 'Được phép đổi dạng của từ.',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                for (var i = 0; i < _items.length; i++)
                  if (!_locked[i]) ...[
                    Text(_items[i].label, style: const TextStyle(fontWeight: FontWeight.bold)),
                    for (final w in _words(i))
                      WordHelpCard(
                        lang: lang,
                        entry: HelpEntry(
                          w,
                          extra: KokugoEngine.bunForms(w).length > 1
                              ? '${lang == 'ja' ? 'かたち' : (lang == 'en' ? 'Forms' : 'Dạng khác')}: '
                                  '${KokugoEngine.bunForms(w).where((f) => f != w).join('・')}'
                              : '',
                        ),
                      ),
                    const SizedBox(height: 4),
                  ],
                const Divider(),
                Text(
                    lang == 'ja'
                        ? 'ぶんの つくりかた\n① だれが（は）\n② いつ・どこで\n③ どうした（ことばを つかう）\n④ さいごに「。」'
                        : lang == 'en'
                            ? 'How to build the sentence\n1. Who\n2. When / where\n3. What happened (use the words)\n4. End with 「。」'
                            : 'Cách đặt câu\n① Ai (は)\n② Khi nào / ở đâu\n③ Làm gì (dùng từ cho sẵn)\n④ Cuối câu thêm 「。」',
                    style: const TextStyle(fontSize: 15)),
              ]),
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
          ),
        );
      }),
    );
  }

  bool _hasInput(int i) => _typed[i] ? _ctl[i].text.trim().isNotEmpty : _strokes[i].isNotEmpty;

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 4),
    ));
  }

  Future<void> _onMain() async {
    final lang = context.read<LocaleService>().lang;
    if (!_revealed) {
      for (var i = 0; i < _items.length; i++) {
        if (!_locked[i] && !_hasInput(i)) {
          _snack(lang == 'ja'
              ? 'まだ かいていない ぶんが あるよ'
              : lang == 'en'
                  ? 'Some sentences are not written yet'
                  : 'Còn câu chưa viết');
          return;
        }
      }
      setState(() {
        _revealed = true;
        // go phim: tu dong danh dau cac muc da dung (viet tay thi tre tu kiem tra)
        for (var i = 0; i < _items.length; i++) {
          if (_locked[i]) continue;
          _chk[i] = List<bool>.filled(4, false);
          if (!_typed[i]) continue;
          final t = _ctl[i].text.trim();
          final ws = _words(i);
          for (var k = 0; k < 2; k++) {
            _chk[i][k] = KokugoEngine.bunForms(ws[k]).any((f) => t.contains(f));
          }
          _chk[i][2] = t.endsWith('。');
        }
      });
      return;
    }
    for (var i = 0; i < _items.length; i++) {
      if (!_locked[i]) _mark[i] = _chk[i].every((b) => b) ? 1 : 2;
    }
    _tries++;
    if (_mark.every((m) => m == 1)) {
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
      for (var i = 0; i < _items.length; i++) {
        if (_mark[i] == 1) {
          _locked[i] = true;
        } else {
          _strokes[i] = <List<Offset>>[];
          _ctl[i].clear();
          _mark[i] = 0;
          _chk[i] = List<bool>.filled(4, false);
        }
      }
      _revealed = false;
    });
    _snack(lang == 'ja'
        ? 'チェックが ぜんぶ つかなかった ぶんを もういちど かいてみよう'
        : lang == 'en'
            ? 'Try writing again the sentences that did not get every check'
            : 'Hãy viết lại những câu chưa được tick đủ nhé');
  }

  void _onReset() {
    setState(() {
      for (var i = 0; i < _items.length; i++) {
        if (_locked[i]) continue;
        _strokes[i] = <List<Offset>>[];
        _ctl[i].clear();
        _mark[i] = 0;
        _chk[i] = List<bool>.filled(4, false);
      }
      _revealed = false;
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
        backgroundColor: const Color(0xFF1E88E5),
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
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                itemCount: _items.length + 1,
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(l.question[lang] ?? '',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    );
                  }
                  return _item(i - 1, lang);
                },
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
              onPressed: _onMain,
              icon: Icon(_revealed ? Icons.check_circle : Icons.visibility, size: 18),
              label: Text(_revealed ? 'おわり' : 'こたえあわせ', style: const TextStyle(fontSize: 14)),
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

  Widget _item(int i, String lang) {
    final it = _items[i];
    final words = [for (final p in it.parts) if (!p.blank) p.text];
    final locked = _locked[i];
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: locked ? const Color(0xFFE8F5E9) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: locked ? Colors.green : Colors.grey.shade300, width: 2),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(it.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text('【${words.join('・')}】',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
          const Spacer(),
          if (!locked && !_revealed)
            IconButton(
              tooltip: _typed[i] ? 'てがき' : 'キーボード',
              icon: Icon(_typed[i] ? Icons.draw : Icons.keyboard),
              onPressed: () => setState(() => _typed[i] = !_typed[i]),
            ),
          if (!locked && !_revealed && !_typed[i])
            IconButton(
              tooltip: 'もどす',
              icon: const Icon(Icons.undo),
              onPressed: _strokes[i].isEmpty ? null : () => setState(() => _strokes[i].removeLast()),
            ),
          if (!locked && !_revealed && !_typed[i])
            IconButton(
              tooltip: 'けす',
              icon: const Icon(Icons.delete_outline),
              onPressed: _strokes[i].isEmpty ? null : () => setState(() => _strokes[i] = <List<Offset>>[]),
            ),
        ]),
        const SizedBox(height: 6),
        if (_typed[i])
          TextField(
            controller: _ctl[i],
            readOnly: locked || _revealed,
            minLines: 3,
            maxLines: 4,
            style: const TextStyle(fontSize: 22),
            decoration: InputDecoration(
              hintText: lang == 'ja' ? 'ここに ぶんを うとう' : (lang == 'en' ? 'Type your sentence here' : 'Gõ câu vào đây'),
              filled: true,
              fillColor: locked || _revealed ? const Color(0xFFF5F5F5) : Colors.white,
              border: const OutlineInputBorder(borderSide: BorderSide(color: Colors.black87, width: 2)),
            ),
          )
        else
          _Pad(
            strokes: _strokes[i],
            enabled: !locked && !_revealed,
            onChanged: () => setState(() {}),
          ),
        if (_revealed && !locked) ...[
          const SizedBox(height: 8),
          Text(lang == 'ja' ? 'れい' : (lang == 'en' ? 'Examples' : 'Câu mẫu'),
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
          for (final ex in it.firstBlank.reads)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(ex, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
          const Divider(),
          Text(
              lang == 'ja'
                  ? 'じぶんの ぶんを たしかめよう（ぜんぶ チェックで ○）'
                  : lang == 'en'
                      ? 'Check your sentence (all checked = ○)'
                      : 'Tự kiểm tra câu của em (tick đủ cả 4 mục = ○)',
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
          for (var k = 0; k < 4; k++)
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _chk[i][k],
              onChanged: (v) => setState(() => _chk[i][k] = v ?? false),
              title: Text(_checkLabel(k, words, lang), style: const TextStyle(fontSize: 16)),
            ),
        ],
        if (locked)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('○', style: TextStyle(fontSize: 22, color: Colors.green, fontWeight: FontWeight.bold)),
          ),
      ]),
    );
  }

  String _checkLabel(int k, List<String> w, String lang) {
    if (k < 2) {
      return lang == 'ja'
          ? '「${w[k]}」を つかった'
          : lang == 'en'
              ? 'I used 「${w[k]}」'
              : 'Đã dùng từ 「${w[k]}」';
    }
    if (k == 2) {
      return lang == 'ja'
          ? 'ぶんの さいごに「。」を つけた'
          : lang == 'en'
              ? 'I put 「。」 at the end'
              : 'Cuối câu có 「。」';
    }
    return lang == 'ja'
        ? 'よんで みて、いみが よく わかる'
        : lang == 'en'
            ? 'It reads well and makes sense'
            : 'Đọc lên thấy câu có nghĩa, dễ hiểu';
  }
}

// Khung viet tay tu do (2 dong ke). Net luu theo toa do 0..1; but mong.
class _Pad extends StatelessWidget {
  final List<List<Offset>> strokes;
  final bool enabled;
  final VoidCallback onChanged;
  const _Pad({required this.strokes, required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      const h = 150.0;
      Offset norm(Offset p) => Offset((p.dx / w).clamp(0.0, 1.0), (p.dy / h).clamp(0.0, 1.0));
      final pad = SizedBox(
        width: w,
        height: h,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: enabled
              ? (e) {
                  strokes.add([norm(e.localPosition)]);
                  onChanged();
                }
              : null,
          onPointerMove: enabled
              ? (e) {
                  if (strokes.isEmpty) return;
                  strokes.last.add(norm(e.localPosition));
                  onChanged();
                }
              : null,
          child: CustomPaint(painter: _PadPainter(strokes, enabled)),
        ),
      );
      // keo ngon tay trong khung thi khong cuon danh sach
      return RawGestureDetector(
        gestures: {
          EagerGestureRecognizer: GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
            () => EagerGestureRecognizer(),
            (_) {},
          ),
        },
        child: pad,
      );
    });
  }
}

class _PadPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final bool enabled;
  _PadPainter(this.strokes, this.enabled);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = enabled ? Colors.white : const Color(0xFFF5F5F5));
    final guide = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), guide);
    canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = Colors.black87
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    final pen = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    Offset sc(Offset p) => Offset(p.dx * size.width, p.dy * size.height);
    for (final s in strokes) {
      if (s.isEmpty) continue;
      if (s.length == 1) {
        canvas.drawCircle(sc(s.first), 1.5, Paint()..color = Colors.black);
        continue;
      }
      final path = Path()..moveTo(sc(s.first).dx, sc(s.first).dy);
      for (var i = 1; i < s.length; i++) {
        path.lineTo(sc(s[i]).dx, sc(s[i]).dy);
      }
      canvas.drawPath(path, pen);
    }
  }

  @override
  bool shouldRepaint(covariant _PadPainter old) => true;
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
