import 'dart:math' show min;
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

// Man hinh choi 国語:
// - kaki: viet chu Han bang tay vao cac o 田字格, so voi dap an roi tu cham (○ / ✕).
// - yomi: chon hiragana tu bang chu de dien cach doc, may tu cham.
class KokugoGameScreen extends StatefulWidget {
  final KokugoLesson lesson;
  const KokugoGameScreen({super.key, required this.lesson});

  @override
  State<KokugoGameScreen> createState() => _KokugoGameScreenState();
}

class _KokugoGameScreenState extends State<KokugoGameScreen> {
  bool get _isKaki => widget.lesson.kind == 'kaki';

  final Map<String, List<List<Offset>>> _strokes = {};
  late List<int> _mark; // kaki: 0 chua chon, 1 ○, 2 ✕ | yomi: 0 chua cham, 1 dung, 2 sai
  late List<bool> _locked;
  late List<String> _ans;
  final Set<int> _hinted = {};
  final Map<int, String> _hintText = {};
  bool _revealed = false;
  int _tries = 0;

  @override
  void initState() {
    super.initState();
    _resetState();
  }

  void _resetState() {
    final n = widget.lesson.items.length;
    _mark = List<int>.filled(n, 0);
    _locked = List<bool>.filled(n, false);
    _ans = List<String>.filled(n, '');
    _strokes.clear();
    _hinted.clear();
    _hintText.clear();
    _revealed = false;
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 3),
    ));
  }

  Future<void> _success() async {
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
  }

  void _clearItemStrokes(int i) {
    _strokes.removeWhere((k, v) => k.startsWith('${i}_'));
  }

  Future<void> _onMain() async {
    final lang = context.read<LocaleService>().lang;
    final items = widget.lesson.items;
    if (_isKaki) {
      if (!_revealed) {
        setState(() => _revealed = true);
        return;
      }
      for (var i = 0; i < items.length; i++) {
        if (!_locked[i] && _mark[i] == 0) {
          _snack(lang == 'ja'
              ? '○か ✕を えらんでね'
              : lang == 'en'
                  ? 'Choose ○ or ✕ for each one'
                  : 'Hãy chọn ○ hoặc ✕ cho từng câu');
          return;
        }
      }
      _tries++;
      if (_mark.every((m) => m == 1)) {
        await _success();
        return;
      }
      setState(() {
        for (var i = 0; i < items.length; i++) {
          if (_mark[i] == 1) {
            _locked[i] = true;
          } else {
            _clearItemStrokes(i);
            _mark[i] = 0;
            _hinted.remove(i);
          }
        }
        _revealed = false;
      });
      _snack(KokugoEngine.wrongMessage('kaki', lang));
      return;
    }
    // yomi
    _tries++;
    setState(() {
      for (var i = 0; i < items.length; i++) {
        if (_locked[i]) continue;
        final a = _ans[i].trim();
        final ok = a.isNotEmpty && items[i].firstBlank.reads.contains(a);
        _mark[i] = ok ? 1 : 2;
        if (ok) _locked[i] = true;
      }
    });
    if (_mark.every((m) => m == 1)) {
      await _success();
    } else {
      _snack(KokugoEngine.wrongMessage('yomi', lang));
    }
  }

  void _onHint() {
    final rs = context.read<RewardService>();
    final lang = context.read<LocaleService>().lang;
    final items = widget.lesson.items;
    showDialog(
      context: context,
      builder: (_) => HintDialog(onSelect: (opt) async {
        // chon cau dau tien chua xong va chua co goi y
        int target = -1;
        for (var i = 0; i < items.length; i++) {
          if (!_locked[i] && !_hinted.contains(i)) {
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
        setState(() {
          _hinted.add(target);
          if (!_isKaki) {
            final r = items[target].firstBlank.reads.first;
            _hintText[target] = '${r.substring(0, 1)} …';
          }
        });
      }),
    );
  }

  void _onReset() {
    setState(_resetState);
  }

  Future<void> _editAnswer(int i) async {
    if (_locked[i]) return;
    final v = await showDialog<String>(
      context: context,
      builder: (_) => KanaPad(initial: _ans[i]),
    );
    if (v == null) return;
    setState(() {
      _ans[i] = v;
      _mark[i] = 0;
    });
  }

  // ---------- ve tay: bam vao o de mo bang viet lon ----------
  Future<void> _openPad(String key, String? ghost) async {
    final res = await showDialog<List<List<Offset>>>(
      context: context,
      builder: (_) => _WritePad(
        initial: [for (final st in (_strokes[key] ?? const <List<Offset>>[])) List<Offset>.from(st)],
        ghost: ghost,
      ),
    );
    if (res == null) return;
    setState(() => _strokes[key] = res);
  }

  @override
  Widget build(BuildContext context) {
    final stars = context.watch<RewardService>().totalStars;
    final lang = context.watch<LocaleService>().lang;
    final l = widget.lesson;
    final mainLabel = _isKaki
        ? (_revealed ? 'おわり' : 'こたえあわせ')
        : 'こたえる';
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9C4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5C6BC0),
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
                final box = c.maxWidth < 420 ? 46.0 : 58.0;
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  itemCount: l.items.length,
                  itemBuilder: (context, i) =>
                      _isKaki ? _kakiItem(i, l.items[i], box) : _yomiItem(i, l.items[i]),
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
              onPressed: _onMain,
              icon: const Icon(Icons.check_circle, size: 18),
              label: Text(mainLabel, style: const TextStyle(fontSize: 14)),
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

  BoxDecoration _cardDeco(int i) {
    final locked = _locked[i];
    final wrong = !_isKaki && _mark[i] == 2;
    return BoxDecoration(
      color: locked ? const Color(0xFFE8F5E9) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: locked ? Colors.green : (wrong ? Colors.red : Colors.grey.shade300),
        width: 2,
      ),
    );
  }

  // ---------- kaki ----------
  Widget _kakiItem(int i, KokugoItem it, double box) {
    final locked = _locked[i];
    final children = <Widget>[];
    for (var pi = 0; pi < it.parts.length; pi++) {
      final part = it.parts[pi];
      if (!part.blank) {
        children.add(Padding(
          padding: EdgeInsets.only(bottom: box / 2 - 12, left: 2, right: 2),
          child: Text(part.text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        ));
        continue;
      }
      final chars = part.text.characters.toList();
      children.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            for (var ci = 0; ci < chars.length; ci++)
              Column(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
                  height: 16,
                  child: Text(ci < part.reads.length ? part.reads[ci] : '',
                      style: const TextStyle(fontSize: 11, color: Colors.black54)),
                ),
                _HandBox(
                  size: box,
                  strokes: _strokes['${i}_${pi}_$ci'] ?? const [],
                  ghost: _hinted.contains(i) ? chars[ci] : null,
                  enabled: !locked && !_revealed,
                  onTap: () => _openPad('${i}_${pi}_$ci', _hinted.contains(i) ? chars[ci] : null),
                ),
              ]),
          ]),
          if (_revealed || locked)
            Text(part.text,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
        ]),
      ));
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: _cardDeco(i),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          SizedBox(width: 30, child: Text(it.label, style: const TextStyle(fontSize: 20))),
          Expanded(child: Wrap(crossAxisAlignment: WrapCrossAlignment.end, children: children)),
        ]),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          if (locked)
            const Icon(Icons.check_circle, color: Colors.green)
          else if (!_revealed)
            TextButton.icon(
              onPressed: () => setState(() => _clearItemStrokes(i)),
              icon: const Icon(Icons.backspace_outlined, size: 16),
              label: const Text('けす', style: TextStyle(fontSize: 12)),
            )
          else ...[
            _markBtn(i, 1, '○ できた', Colors.green),
            const SizedBox(width: 8),
            _markBtn(i, 2, '✕ もういちど', Colors.red),
          ],
        ]),
      ]),
    );
  }

  Widget _markBtn(int i, int value, String label, Color color) {
    final sel = _mark[i] == value;
    return OutlinedButton(
      onPressed: () => setState(() => _mark[i] = value),
      style: OutlinedButton.styleFrom(
        backgroundColor: sel ? color : Colors.white,
        foregroundColor: sel ? Colors.white : color,
        side: BorderSide(color: color, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }

  // ---------- yomi ----------
  Widget _yomiItem(int i, KokugoItem it) {
    final locked = _locked[i];
    final wrong = _mark[i] == 2;
    final parts = <Widget>[];
    for (final part in it.parts) {
      parts.add(Text(
        part.text,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          decoration: part.blank ? TextDecoration.underline : TextDecoration.none,
          decorationThickness: 2,
        ),
      ));
    }
    final field = GestureDetector(
      onTap: () => _editAnswer(i),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Text('（', style: TextStyle(fontSize: 28)),
        Container(
          width: 110,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: locked ? const Color(0xFFC8E6C9) : (wrong ? Colors.red.shade50 : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: locked ? Colors.green : (wrong ? Colors.red : Colors.grey.shade400)),
          ),
          child: Text(_ans[i], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ),
        const Text('）', style: TextStyle(fontSize: 28)),
      ]),
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: _cardDeco(i),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          SizedBox(width: 46, child: Text(it.label, style: const TextStyle(fontSize: 18))),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 2,
              runSpacing: 6,
              children: [...parts, const SizedBox(width: 12), field],
            ),
          ),
          if (locked) const Icon(Icons.check_circle, color: Colors.green),
        ]),
        if (_hintText[i] != null && !locked)
          Padding(
            padding: const EdgeInsets.only(left: 46, top: 4),
            child: Text('ヒント: ${_hintText[i]}',
                style: const TextStyle(fontSize: 14, color: Colors.deepOrange, fontWeight: FontWeight.bold)),
          ),
      ]),
    );
  }
}

// O viet tay 田字格 (nho): bam vao de mo bang viet lon. Net luu o toa do 0..1.
class _HandBox extends StatelessWidget {
  final double size;
  final List<List<Offset>> strokes;
  final String? ghost;
  final bool enabled;
  final VoidCallback onTap;

  const _HandBox({
    required this.size,
    required this.strokes,
    required this.ghost,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(children: [
          if (ghost != null)
            Positioned.fill(
              child: Center(
                child: Text(ghost!,
                    style: TextStyle(fontSize: size * 0.78, color: Colors.black.withValues(alpha: 0.13))),
              ),
            ),
          Positioned.fill(
            child: CustomPaint(painter: _BoxPainter(strokes, enabled, ghost != null)),
          ),
          if (enabled && strokes.isEmpty)
            Center(child: Icon(Icons.edit, size: size * 0.36, color: Colors.indigo.withValues(alpha: 0.35))),
        ]),
      ),
    );
  }
}

class _BoxPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final bool enabled;
  final bool transparentBg;
  _BoxPainter(this.strokes, this.enabled, this.transparentBg);

  @override
  void paint(Canvas canvas, Size size) {
    if (!transparentBg) {
      canvas.drawRect(Offset.zero & size, Paint()..color = enabled ? Colors.white : const Color(0xFFF5F5F5));
    }
    _paintGuide(canvas, size);
    _paintStrokes(canvas, size, strokes);
  }

  @override
  bool shouldRepaint(covariant _BoxPainter old) => true;
}

void _paintGuide(Canvas canvas, Size size) {
  final guide = Paint()
    ..color = Colors.grey.shade400
    ..strokeWidth = 1;
  final dash = size.width / 14;
  for (double t = 0; t < size.width; t += dash * 2) {
    canvas.drawLine(Offset(t, size.height / 2), Offset(min(t + dash, size.width), size.height / 2), guide);
  }
  for (double t = 0; t < size.height; t += dash * 2) {
    canvas.drawLine(Offset(size.width / 2, t), Offset(size.width / 2, min(t + dash, size.height)), guide);
  }
  canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
}

void _paintStrokes(Canvas canvas, Size size, List<List<Offset>> strokes) {
  final pen = Paint()
    ..color = Colors.black
    ..strokeWidth = size.width / 26 // nua be day net cu (size/13)
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;
  Offset sc(Offset p) => Offset(p.dx * size.width, p.dy * size.height);
  for (final s in strokes) {
    if (s.isEmpty) continue;
    if (s.length == 1) {
      canvas.drawCircle(sc(s.first), pen.strokeWidth / 2, Paint()..color = Colors.black);
      continue;
    }
    final path = Path()..moveTo(sc(s.first).dx, sc(s.first).dy);
    for (var i = 1; i < s.length; i++) {
      path.lineTo(sc(s[i]).dx, sc(s[i]).dy);
    }
    canvas.drawPath(path, pen);
  }
}

// Bang viet lon (de viet bang ngon tay hoac chuot)
class _WritePad extends StatefulWidget {
  final List<List<Offset>> initial;
  final String? ghost;
  const _WritePad({required this.initial, required this.ghost});

  @override
  State<_WritePad> createState() => _WritePadState();
}

class _WritePadState extends State<_WritePad> {
  late List<List<Offset>> _strokes = widget.initial;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;
    final side = min(min(mq.width - 72, mq.height * 0.55), 400.0);
    return Dialog(
      backgroundColor: const Color(0xFFFFF8E1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('ここに かこう', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (e) => setState(() => _strokes.add([_norm(e.localPosition, side)])),
            onPointerMove: (e) {
              if (_strokes.isEmpty) return;
              setState(() => _strokes.last.add(_norm(e.localPosition, side)));
            },
            child: Container(
              width: side,
              height: side,
              color: Colors.white,
              child: Stack(children: [
                if (widget.ghost != null)
                  Positioned.fill(
                    child: Center(
                      child: Text(widget.ghost!,
                          style: TextStyle(fontSize: side * 0.78, color: Colors.black.withValues(alpha: 0.13))),
                    ),
                  ),
                Positioned.fill(child: CustomPaint(painter: _BoxPainter(_strokes, true, true))),
              ]),
            ),
          ),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            OutlinedButton.icon(
              onPressed: _strokes.isEmpty ? null : () => setState(() => _strokes.removeLast()),
              icon: const Icon(Icons.undo, size: 18),
              label: const Text('もどす'),
            ),
            OutlinedButton.icon(
              onPressed: _strokes.isEmpty ? null : () => setState(() => _strokes = []),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('ぜんぶ けす'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, _strokes),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3F51B5), foregroundColor: Colors.white),
              child: const Text('OK', style: TextStyle(fontSize: 16)),
            ),
          ]),
        ]),
      ),
    );
  }

  Offset _norm(Offset p, double side) =>
      Offset((p.dx / side).clamp(0.0, 1.0).toDouble(), (p.dy / side).clamp(0.0, 1.0).toDouble());
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
