import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/elapsed_timer.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/lesson.dart';
import '../services/reward_service.dart';
import '../services/locale_service.dart';
import '../services/progress_service.dart';
import '../services/puzzle_solver.dart';
import '../widgets/hint_dialog.dart';
import 'reward_screen.dart';

class Edge {
  final int r1, c1, r2, c2;
  Edge(int ra, int ca, int rb, int cb)
      : r1 = (ra < rb || (ra == rb && ca < cb)) ? ra : rb,
        c1 = (ra < rb || (ra == rb && ca < cb)) ? ca : cb,
        r2 = (ra < rb || (ra == rb && ca < cb)) ? rb : ra,
        c2 = (ra < rb || (ra == rb && ca < cb)) ? cb : ca;

  @override
  bool operator ==(Object other) =>
      other is Edge && r1 == other.r1 && c1 == other.c1 && r2 == other.r2 && c2 == other.c2;

  @override
  int get hashCode => Object.hash(r1, c1, r2, c2);

  Offset start(double cs) => Offset(c1 * cs, r1 * cs);
  Offset end(double cs) => Offset(c2 * cs, r2 * cs);
}

Set<Edge> boundaryOf(List<List<int>> cells) {
  final s = cells.map((c) => '${c[0]}_${c[1]}').toSet();
  final e = <Edge>{};
  for (final c in cells) {
    final r = c[0], col = c[1];
    if (!s.contains('${r - 1}_$col')) e.add(Edge(r, col, r, col + 1));
    if (!s.contains('${r + 1}_$col')) e.add(Edge(r + 1, col, r + 1, col + 1));
    if (!s.contains('${r}_${col - 1}')) e.add(Edge(r, col, r + 1, col));
    if (!s.contains('${r}_${col + 1}')) e.add(Edge(r, col + 1, r + 1, col + 1));
  }
  return e;
}

class CheckResult {
  final bool ok;
  final String message;
  final List<List<int>> badCells;
  CheckResult(this.ok, this.message, [this.badCells = const []]);
}

class DrawOutlineGameScreen extends StatefulWidget {
  final Lesson lesson;
  const DrawOutlineGameScreen({super.key, required this.lesson});

  @override
  State<DrawOutlineGameScreen> createState() => _DrawOutlineGameScreenState();
}

class _DrawOutlineGameScreenState extends State<DrawOutlineGameScreen> {
  static const double _pad = 24;

  final Set<Edge> _selected = {};
  late Set<Edge> _fixedEdges;
  bool _hintUnlocked = false;
  int _tries = 0;
  double _cs = 40;
  final _key = GlobalKey();
  bool? _dragAdd;

  List<List<int>> _hintCells = [];
  List<List<int>> _badCells = [];

  @override
  void initState() {
    super.initState();
    _fixedEdges = {};
    for (final b in widget.lesson.fixedBlocks) {
      _fixedEdges.addAll(boundaryOf(b));
    }
  }

  Edge? _hit(Offset p) {
    final rows = widget.lesson.gridRows;
    final cols = widget.lesson.gridCols;
    final cs = _cs;
    Edge? best;
    double bd = double.infinity;
    final r0 = (p.dy / cs).floor();
    final c0 = (p.dx / cs).floor();
    for (int r = r0 - 1; r <= r0 + 1; r++) {
      for (int c = c0 - 1; c <= c0 + 1; c++) {
        final cand = <Edge>[];
        if (r >= 0 && r <= rows && c >= 0 && c < cols) cand.add(Edge(r, c, r, c + 1));
        if (r >= 0 && r < rows && c >= 0 && c <= cols) cand.add(Edge(r, c, r + 1, c));
        for (final e in cand) {
          final mid = Offset((e.c1 + e.c2) / 2 * cs, (e.r1 + e.r2) / 2 * cs);
          final d = (p - mid).distance;
          if (d < bd) {
            bd = d;
            best = e;
          }
        }
      }
    }
    return bd < cs * 0.55 ? best : null;
  }

  void _touch(Offset global, {required bool start}) {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(global) - const Offset(_pad, _pad);
    final e = _hit(local);
    if (e == null) return;
    if (_fixedEdges.contains(e)) return;
    setState(() {
      _badCells = [];
      if (start) _dragAdd = !_selected.contains(e);
      if (_dragAdd == true) {
        _selected.add(e);
      } else {
        _selected.remove(e);
      }
    });
  }

  CheckResult _validate() {
    final rows = widget.lesson.gridRows;
    final cols = widget.lesson.gridCols;
    final all = {..._selected, ..._fixedEdges};
    for (int c = 0; c < cols; c++) {
      all.add(Edge(0, c, 0, c + 1));
      all.add(Edge(rows, c, rows, c + 1));
    }
    for (int r = 0; r < rows; r++) {
      all.add(Edge(r, 0, r + 1, 0));
      all.add(Edge(r, cols, r + 1, cols));
    }

    final fixedSet = widget.lesson.fixedCells.map((c) => '${c[0]}_${c[1]}').toSet();
    final free = <List<int>>[];
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (!fixedSet.contains('${r}_$c')) free.add([r, c]);
      }
    }
    final freeSet = free.map((c) => '${c[0]}_${c[1]}').toSet();
    final seen = <String>{};
    final regions = <List<List<int>>>[];

    for (final cell in free) {
      final k = '${cell[0]}_${cell[1]}';
      if (seen.contains(k)) continue;
      final region = <List<int>>[];
      final stack = [cell];
      seen.add(k);
      while (stack.isNotEmpty) {
        final cur = stack.removeLast();
        region.add(cur);
        final r = cur[0], c = cur[1];
        final nbrs = <List<Object>>[
          [r - 1, c, Edge(r, c, r, c + 1)],
          [r + 1, c, Edge(r + 1, c, r + 1, c + 1)],
          [r, c - 1, Edge(r, c, r + 1, c)],
          [r, c + 1, Edge(r, c + 1, r + 1, c + 1)],
        ];
        for (final n in nbrs) {
          final nr = n[0] as int, nc = n[1] as int;
          final nk = '${nr}_$nc';
          if (!freeSet.contains(nk) || seen.contains(nk)) continue;
          if (all.contains(n[2] as Edge)) continue;
          seen.add(nk);
          stack.add([nr, nc]);
        }
      }
      regions.add(region);
    }

    // 1. Vung chua duoc chia thanh block 4 o (lap day chua du / chia sai)
    final tooBig = regions.where((r) => r.length > 4).toList();
    if (tooBig.isNotEmpty) {
      return CheckResult(
          false,
          'incomplete',
          tooBig.expand((r) => r).toList());
    }
    final tooSmall = regions.where((r) => r.length < 4).toList();
    if (tooSmall.isNotEmpty) {
      return CheckResult(false, 'small', tooSmall.expand((r) => r).toList());
    }

    // 2. Hinh dang khong hop le
    final used = <String, int>{};
    final avail = widget.lesson.available;
    for (final reg in regions) {
      final id = Tetro.identify(reg);
      if (id == null) {
        return CheckResult(false, 'shape', reg);
      }
      used[id] = (used[id] ?? 0) + 1;
    }

    // 3. Dung qua so luong cho phep
    for (final id in used.keys) {
      if (used[id]! > (avail[id] ?? 0)) {
        final over = regions.where((r) => Tetro.identify(r) == id).expand((r) => r).toList();
        return CheckResult(false, 'over:$id:${avail[id] ?? 0}', over);
      }
    }
    return CheckResult(true, 'ok');
  }

  String _msg(String code, String lang) {
    if (code == 'incomplete') {
      return lang == 'ja'
          ? 'まだ ブロックに わけられていない ばしょが あります'
          : lang == 'en'
              ? 'Some areas are not yet divided into blocks of 4 cells'
              : 'Còn vùng chưa được chia thành block 4 ô';
    }
    if (code == 'small') {
      return lang == 'ja'
          ? '4マスより ちいさい ブロックが あります'
          : lang == 'en'
              ? 'There is an area smaller than 4 cells'
              : 'Có vùng nhỏ hơn 4 ô';
    }
    if (code == 'shape') {
      return lang == 'ja'
          ? 'つかえない かたちの ブロックが あります'
          : lang == 'en'
              ? 'There is a shape that is not an allowed block'
              : 'Có hình dạng không phải block hợp lệ';
    }
    if (code.startsWith('over:')) {
      final p = code.split(':');
      return lang == 'ja'
          ? '${p[1]}ブロックは ${p[2]}こまでです'
          : lang == 'en'
              ? 'Only ${p[2]} block(s) of type ${p[1]} are available'
              : 'Block loại ${p[1]} chỉ có ${p[2]} cái, bạn đã dùng quá số lượng';
    }
    return '';
  }

  Future<void> _onCheck() async {
    final lang = context.read<LocaleService>().lang;
    _tries++;
    final res = _validate();
    if (res.ok) {
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
    } else {
      if (!_hintUnlocked) _hintUnlocked = true;
      setState(() => _badCells = res.badCells);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_msg(res.message, lang)),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ));
    }
  }

  void _onHint() {
    final rs = context.read<RewardService>();
    showDialog(
      context: context,
      builder: (_) => HintDialog(onSelect: (opt) async {
        final ok = await rs.spendStars(opt.cost);
        if (!ok) return;

        final current = {..._selected, ..._fixedEdges};
        List<PlacedBlock>? bestSol;
        int bestScore = -1;
        final rng = Random();
        for (int i = 0; i < 12; i++) {
          final sol = PuzzleSolver.solve(
            rows: widget.lesson.gridRows,
            cols: widget.lesson.gridCols,
            fixedBlocks: widget.lesson.fixedBlocks,
            available: widget.lesson.available,
            rng: rng,
          );
          if (sol == null) continue;
          int score = 0;
          for (final b in sol) {
            for (final e in boundaryOf(b.cells)) {
              if (current.contains(e)) score++;
            }
          }
          if (score > bestScore) {
            bestScore = score;
            bestSol = sol;
          }
        }
        if (bestSol == null || bestSol.isEmpty) return;

        final candidates = bestSol.where((b) {
          final edges = boundaryOf(b.cells);
          return !edges.every((e) => current.contains(e));
        }).toList();

        if (candidates.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('ぜんぶ あっているよ！こたえるを おしてみよう'),
            backgroundColor: Colors.green,
          ));
          return;
        }

        candidates.sort((a, b) {
          int sa = 0, sb = 0;
          for (final e in boundaryOf(a.cells)) {
            if (current.contains(e)) sa++;
          }
          for (final e in boundaryOf(b.cells)) {
            if (current.contains(e)) sb++;
          }
          return sb.compareTo(sa);
        });
        final pick = candidates.first;

        setState(() {
          _hintCells = pick.cells;
        });
        Future.delayed(const Duration(milliseconds: 3000), () {
          if (mounted) setState(() => _hintCells = []);
        });
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stars = context.watch<RewardService>().totalStars;
    final lang = context.watch<LocaleService>().lang;
    final lesson = widget.lesson;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9C4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        title: Text(lesson.title[lang] ?? '',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          ElapsedTimer(lessonId: widget.lesson.id),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.amber.shade700, borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.star, color: Colors.white, size: 18),
                const SizedBox(width: 4),
                Text('$stars',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ]),
            ),
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Text(lesson.question[lang] ?? '',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
        ),
        Expanded(
          child: LayoutBuilder(builder: (context, outer) {
            final rows = lesson.gridRows;
            final cols = lesson.gridCols;
            const gap = 8.0;
            final maxW = outer.maxWidth;
            final maxH = outer.maxHeight;

            // Man hinh dung (dien thoai): luoi o tren, cac block o duoi.
            // Man hinh ngang: luoi ben trai, panel block ben phai (30% chieu rong).
            final portrait = maxW < maxH;
            final double panelW = portrait
                ? maxW - gap * 2
                : (maxW * 0.30).clamp(90.0, 340.0).toDouble();
            final double gridAreaW =
                portrait ? maxW - gap * 2 : maxW - panelW - gap * 4 - 2;
            final double gridAreaH = portrait ? maxH * 0.58 : maxH - gap * 2;

            _cs = min((gridAreaW - _pad * 2) / cols,
                    (gridAreaH - _pad * 2) / rows)
                .clamp(18.0, 120.0)
                .toDouble();
            final gw = _cs * cols + _pad * 2;
            final gh = _cs * rows + _pad * 2;

            // Kich thuoc o cua block trong panel: ti le theo o luoi
            final double pieceCs = portrait
                ? (_cs * 0.7).clamp(14.0, 44.0).toDouble()
                : (_cs * 0.55).clamp(12.0, 40.0).toDouble();

            final gridWidget = GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => _touch(d.globalPosition, start: true),
              onPanStart: (d) => _touch(d.globalPosition, start: true),
              onPanUpdate: (d) => _touch(d.globalPosition, start: false),
              child: SizedBox(
                width: gw,
                height: gh,
                child: CustomPaint(
                  key: _key,
                  size: Size(gw, gh),
                  painter: _Painter(
                    rows: rows,
                    cols: cols,
                    cs: _cs,
                    pad: _pad,
                    fixedCells: lesson.fixedCells,
                    fixedEdges: _fixedEdges,
                    selected: _selected,
                    hintCells: _hintCells,
                    badCells: _badCells,
                  ),
                ),
              ),
            );

            final panelWidget = Container(
              width: panelW,
              margin: const EdgeInsets.all(gap),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: pieceCs * 0.9,
                  runSpacing: pieceCs * 0.7,
                  alignment: WrapAlignment.start,
                  children: lesson.referencePieces.map((p) {
                    final maxR = p.cells.map((c) => c[0]).reduce(max);
                    final maxC = p.cells.map((c) => c[1]).reduce(max);
                    return SizedBox(
                      width: (maxC + 1) * pieceCs,
                      height: (maxR + 1) * pieceCs,
                      child: CustomPaint(painter: _PiecePainter(p.cells, pieceCs)),
                    );
                  }).toList(),
                ),
              ),
            );

            if (portrait) {
              return Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(gap, gap, gap, 0),
                  child: gridWidget,
                ),
                Expanded(child: panelWidget),
              ]);
            }

            return Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topCenter,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(gap),
                      child: gridWidget,
                    ),
                    SizedBox(height: gh + gap * 2, child: panelWidget),
                  ],
                ),
              ),
            );
          }),
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
                      _selected.clear();
                      _hintCells = [];
                      _badCells = [];
                    })),
            if (_hintUnlocked)
              _ToolBtn(
                      icon: Icons.lightbulb,
                      label: 'ヒント',
                      color: Colors.amber,
                      onTap: _onHint)
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

class _Painter extends CustomPainter {
  final int rows, cols;
  final double cs, pad;
  final List<List<int>> fixedCells, hintCells, badCells;
  final Set<Edge> fixedEdges, selected;

  _Painter({
    required this.rows,
    required this.cols,
    required this.cs,
    required this.pad,
    required this.fixedCells,
    required this.fixedEdges,
    required this.selected,
    required this.hintCells,
    required this.badCells,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(pad, pad);

    canvas.drawRect(Rect.fromLTWH(0, 0, cols * cs, rows * cs), Paint()..color = Colors.white);

    final bad = Paint()..color = Colors.red.withValues(alpha: 0.25);
    for (final c in badCells) {
      canvas.drawRect(Rect.fromLTWH(c[1] * cs, c[0] * cs, cs, cs), bad);
    }

    final fill = Paint()..color = const Color(0xFFD6D6D6);
    for (final c in fixedCells) {
      canvas.drawRect(Rect.fromLTWH(c[1] * cs, c[0] * cs, cs, cs), fill);
    }

    final hintFill = Paint()..color = const Color(0xFFFFB300).withValues(alpha: 0.55);
    for (final c in hintCells) {
      canvas.drawRect(Rect.fromLTWH(c[1] * cs, c[0] * cs, cs, cs), hintFill);
    }

    final grid = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.8;
    for (int r = 0; r <= rows; r++) {
      canvas.drawLine(Offset(0, r * cs), Offset(cols * cs, r * cs), grid);
    }
    for (int c = 0; c <= cols; c++) {
      canvas.drawLine(Offset(c * cs, 0), Offset(c * cs, rows * cs), grid);
    }

    final thick = Paint()
      ..color = Colors.grey.shade800
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    for (final e in fixedEdges) {
      canvas.drawLine(e.start(cs), e.end(cs), thick);
    }

    if (hintCells.isNotEmpty) {
      final hp = Paint()
        ..color = const Color(0xFFE65100)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      for (final e in boundaryOf(hintCells)) {
        canvas.drawLine(e.start(cs), e.end(cs), hp);
      }
    }

    final sel = Paint()
      ..color = const Color(0xFF1565C0)
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    for (final e in selected) {
      canvas.drawLine(e.start(cs), e.end(cs), sel);
    }

    canvas.drawRect(
      Rect.fromLTWH(0, 0, cols * cs, rows * cs),
      Paint()
        ..color = Colors.grey.shade700
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final dot = Paint()..color = Colors.grey.shade400;
    for (int r = 0; r <= rows; r++) {
      for (int c = 0; c <= cols; c++) {
        canvas.drawCircle(Offset(c * cs, r * cs), 1.8, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _Painter old) => true;
}

class _PiecePainter extends CustomPainter {
  final List<List<int>> cells;
  final double cs;
  _PiecePainter(this.cells, this.cs);

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = const Color(0xFFD6D6D6);
    final thin = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;
    for (final c in cells) {
      final rect = Rect.fromLTWH(c[1] * cs, c[0] * cs, cs, cs);
      canvas.drawRect(rect, fill);
      canvas.drawRect(rect, thin);
    }
    final thick = Paint()
      ..color = Colors.grey.shade800
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final e in boundaryOf(cells)) {
      canvas.drawLine(e.start(cs), e.end(cs), thick);
    }
  }

  @override
  bool shouldRepaint(covariant _PiecePainter old) => false;
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
          border: Border.all(color: color),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 20),
          Text(label, style: TextStyle(fontSize: 10, color: color)),
        ]),
      ),
    );
  }
}
