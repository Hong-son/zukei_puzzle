import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../models/fold_lesson.dart';

// たいしょうな かたち (gap giay - cat - mo ra).
//
// Toa do (y huong len): to giay da gap nam o [0,1]x[0,1]; hai canh おり目 (nep gap) la x=0 (trai) va y=0 (duoi).
// Mo lan 1: lat qua y=0 -> [0,1]x[-1,1].  Mo lan 2: lat qua x=0 -> [-1,1]x[-1,1].
// Mat luoi: o vuong canh 0.5; moi o chia 4 manh tam giac (ca hai duong cheo): 0=duoi 1=phai 2=tren 3=trai.
// Ma manh = ((cx+2)*4 + (cy+2))*4 + side   (cx, cy tu -2 den 1)
class FoldEngine {
  static const double cell = 0.5;

  static int code(int cx, int cy, int s) => ((cx + 2) * 4 + (cy + 2)) * 4 + s;
  static int cxOf(int c) => (c ~/ 16) - 2;
  static int cyOf(int c) => ((c ~/ 4) % 4) - 2;
  static int sideOf(int c) => c % 4;

  // doi xung qua y=0 (nep gap nam ngang)
  static int reflY(int c) {
    final s = sideOf(c);
    return code(cxOf(c), -1 - cyOf(c), s == 0 ? 2 : (s == 2 ? 0 : s));
  }

  // doi xung qua x=0 (nep gap thang dung)
  static int reflX(int c) {
    final s = sideOf(c);
    return code(-1 - cxOf(c), cyOf(c), s == 1 ? 3 : (s == 3 ? 1 : s));
  }

  static Set<int> unionY(Set<int> a) => {...a, for (final c in a) reflY(c)};
  static Set<int> unionX(Set<int> a) => {...a, for (final c in a) reflX(c)};

  // cac manh thuoc to giay da gap
  static Set<int> paper(String shape) {
    final r = <int>{};
    for (var cx = 0; cx < 2; cx++) {
      for (var cy = 0; cy < 2; cy++) {
        for (var s = 0; s < 4; s++) {
          if (shape == 'sq') {
            r.add(code(cx, cy, s));
          } else if (cx + cy == 0) {
            r.add(code(cx, cy, s));
          } else if (cx + cy == 1 && (s == 0 || s == 3)) {
            r.add(code(cx, cy, s));
          }
        }
      }
    }
    return r;
  }

  // cac manh thuoc to giay khi mo ra `unfold` lan (0, 1, 2)
  static Set<int> sheet(String shape, int unfold) {
    var p = paper(shape);
    if (unfold >= 1) p = unionY(p);
    if (unfold >= 2) p = unionX(p);
    return p;
  }

  // dap an: cac manh bi cat khi mo ra `unfold` lan
  static Set<int> answer(FoldQuestion q, int unfold) {
    var a = q.cut.toSet();
    if (unfold >= 1) a = unionY(a);
    if (unfold >= 2) a = unionX(a);
    return a;
  }

  static bool isCorrect(FoldQuestion q, Set<int> s1, Set<int> s2) =>
      setEquals(s1, answer(q, 1)) && setEquals(s2, answer(q, 2));

  // dinh (toa do mo hinh) cua manh tam giac
  static List<Offset> verts(int c) {
    final x0 = cxOf(c) * cell, y0 = cyOf(c) * cell;
    final bl = Offset(x0, y0), br = Offset(x0 + cell, y0);
    final tr = Offset(x0 + cell, y0 + cell), tl = Offset(x0, y0 + cell);
    final ct = Offset(x0 + cell / 2, y0 + cell / 2);
    switch (sideOf(c)) {
      case 0:
        return [bl, br, ct];
      case 1:
        return [br, tr, ct];
      case 2:
        return [tr, tl, ct];
      default:
        return [tl, bl, ct];
    }
  }

  // manh nam duoi diem m (toa do mo hinh), chi tinh cac manh trong `valid`
  static int? pieceAt(Set<int> valid, Offset m) {
    final cx = (m.dx / cell).floor(), cy = (m.dy / cell).floor();
    if (cx < -2 || cx > 1 || cy < -2 || cy > 1) return null;
    final u = m.dx - cx * cell - cell / 2, v = m.dy - cy * cell - cell / 2;
    final int s;
    if (u.abs() > v.abs()) {
      s = u > 0 ? 1 : 3;
    } else {
      s = v > 0 ? 2 : 0;
    }
    final c = code(cx, cy, s);
    return valid.contains(c) ? c : null;
  }

  // cac manh ke canh (chung mot canh)
  static List<int> neighbors(int c) {
    final cx = cxOf(c), cy = cyOf(c), s = sideOf(c);
    final r = <int>[code(cx, cy, (s + 1) % 4), code(cx, cy, (s + 3) % 4)];
    switch (s) {
      case 0:
        r.add(code(cx, cy - 1, 2));
        break;
      case 1:
        r.add(code(cx + 1, cy, 3));
        break;
      case 2:
        r.add(code(cx, cy + 1, 0));
        break;
      default:
        r.add(code(cx - 1, cy, 1));
    }
    return r;
  }

  static FoldQuestion _random(Random r, String shape, int pieces) {
    final p = paper(shape);
    final list = p.toList()..sort();
    final cut = <int>{list[r.nextInt(list.length)]};
    var guard = 0;
    while (cut.length < pieces && guard++ < 200) {
      final base = cut.elementAt(r.nextInt(cut.length));
      final nb = [
        for (final n in neighbors(base))
          if (p.contains(n) && !cut.contains(n)) n
      ];
      if (nb.isEmpty) continue;
      cut.add(nb[r.nextInt(nb.length)]);
    }
    return FoldQuestion(shape: shape, cut: cut.toList()..sort());
  }

  static FoldLesson generate({int level = 1, Random? rng}) {
    final r = rng ?? Random();
    final lv = level < 1 ? 1 : (level > 3 ? 3 : level);
    final pieces = lv + 1; // 2, 3, 4 manh
    final shapes = ['sq', 'tri']..shuffle(r);
    return FoldLesson(
      id: 'fd_${DateTime.now().microsecondsSinceEpoch}',
      title: {
        'ja': 'たいしょうな かたち ✨',
        'en': 'Symmetric Shapes ✨',
        'vi': 'Hình đối xứng ✨',
      },
      questions: [for (final s in shapes) _random(r, s, pieces)],
      difficulty: lv,
      isAutoGenerated: true,
    );
  }
}
