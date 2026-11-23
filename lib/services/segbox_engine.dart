import 'dart:math';
import '../models/view_lesson.dart';

// とうめいな はこ: hop trong suot co dan cac thanh (bou). Nhin tu mot huong thi cac thanh
// tao thanh chu so kieu 7 doan (a=tren, b=tren-phai, c=duoi-phai, d=duoi, e=duoi-trai, f=tren-trai, g=giua).
//
// Thanh (bars): [loai, a, b, c]
//   [0, x, z, h]  thanh dung  : x 0=trai 1=phai, z 0=truoc 1=sau, h 0=nua tren 1=nua duoi
//   [1, y, z, 0]  thanh ngang trai-phai : y 0=tren 1=giua 2=duoi
//   [2, y, x, 0]  thanh ngang truoc-sau : y 0=tren 1=giua 2=duoi
// Huong nhin: F = tu mat truoc (正めん), R = tu ben phai, B = tu phia sau, L = tu ben trai.
//   F: trai nguoi nhin = x0.  B: trai nguoi nhin = x1.
//   R: trai nguoi nhin = z0 (truoc), phai = z1 (sau).  L: trai nguoi nhin = z1, phai = z0.
// Huong hop khi dat vao 〈入れもの〉 (nhin tu tren): 0 = dung nguyen (F), 1 = mat phai quay ra truoc (R),
// 2 = quay nguoc (B), 3 = mat trai quay ra truoc (L). Chu cai tren mat hop xoay theo 90 do * chi so.
class SegBoxEngine {
  static const List<String> views = ['F', 'R', 'B', 'L'];
  static const List<String> _hseg = ['a', 'g', 'd'];
  // Chu so -> cac doan (da sap theo thu tu chu cai). 7 theo sach co nhip nho o ben trai (abcf).
  static const List<String> segOf = [
    'abcdef', 'bc', 'abdeg', 'abcdg', 'bcfg', 'acdfg', 'acdefg', 'abcf', 'abcdefg', 'abcdfg',
  ];

  static List<int> bV(int x, int z, int h) => [0, x, z, h];
  static List<int> bX(int y, int z) => [1, y, z, 0];
  static List<int> bZ(int y, int x) => [2, y, x, 0];

  static List<List<int>> barsOf(dynamic raw) =>
      (raw as List).map((e) => (e as List).map((n) => (n as num).toInt()).toList()).toList();

  static String segs(List<List<int>> bars, String view) {
    final s = <String>{};
    for (final b in bars) {
      if (b[0] == 1) {
        if (view == 'F' || view == 'B') s.add(_hseg[b[1]]);
      } else if (b[0] == 2) {
        if (view == 'R' || view == 'L') s.add(_hseg[b[1]]);
      } else {
        final x = b[1], z = b[2], h = b[3];
        final bool left = view == 'F'
            ? x == 0
            : view == 'B'
                ? x == 1
                : view == 'R'
                    ? z == 0
                    : z == 1;
        s.add(left ? (h == 0 ? 'f' : 'e') : (h == 0 ? 'b' : 'c'));
      }
    }
    final l = s.toList()..sort();
    return l.join();
  }

  // Chu so nhin thay tu huong view (null neu khong thanh chu so)
  static int? digit(List<List<int>> bars, String view) {
    final s = segs(bars, view);
    final i = segOf.indexOf(s);
    return i < 0 ? null : i;
  }

  static Map<String, int?> digitMap(List<List<int>> bars) => {for (final v in views) v: digit(bars, v)};

  static Set<int> digitSet(List<List<int>> bars) {
    final r = <int>{};
    for (final v in views) {
      final d = digit(bars, v);
      if (d != null) r.add(d);
    }
    return r;
  }

  // Cac nam sinh co the lap duoc tu 4 hop (moi hop xoay tuy y), trong khoang 1930-2010
  static List<int> validYears(List<List<List<int>>> boxes) {
    final ds = [for (final b in boxes) digitSet(b).toList()];
    final ys = <int>{};
    for (final a in ds[0]) {
      for (final b in ds[1]) {
        for (final c in ds[2]) {
          for (final d in ds[3]) {
            final y = a * 1000 + b * 100 + c * 10 + d;
            if (y >= 1930 && y <= 2010) ys.add(y);
          }
        }
      }
    }
    return ys.toList()..sort();
  }

  // Nam sinh can tim: 'mother' = nam sau (tre hon), 'father' = nam truoc (lon tuoi hon)
  static int yearAnswer(List<List<List<int>>> boxes, String ask) {
    final ys = validYears(boxes);
    return ask == 'father' ? ys.first : ys.last;
  }

  // Cac huong (chi so 0..3) cua hop cho ra chu so d
  static List<int> orientsFor(List<List<int>> bars, int d) =>
      [for (var i = 0; i < 4; i++) if (digit(bars, views[i]) == d) i];

  // ---------------- tu sinh bai ----------------

  static final List<List<int>> _allV = [
    for (final x in [0, 1])
      for (final z in [0, 1])
        for (final h in [0, 1]) [x, z, h],
  ];

  static bool _sameSet<T>(Set<T> a, Set<T> b) => a.length == b.length && a.containsAll(b);

  static bool _has(List<List<int>> bars, List<int> c) =>
      bars.any((b) => b[0] == c[0] && b[1] == c[1] && b[2] == c[2] && b[3] == c[3]);

  static bool _sameDigits(Map<String, int?> a, Map<String, int?> b) {
    for (final v in views) {
      if (a[v] != b[v]) return false;
    }
    return true;
  }

  // Tao hop sao cho tu moi huong trong want hien ra dung chu so; them vai thanh "nhieu" khong lam doi ket qua
  static List<List<int>>? makeBox(Random r, Map<String, int> want, int decoys) {
    Set<String>? xh;
    Set<String>? zh;
    for (final e in want.entries) {
      final hz = {for (final c in segOf[e.value].split('')) if ('agd'.contains(c)) c};
      if (e.key == 'F' || e.key == 'B') {
        if (xh != null && !_sameSet(xh, hz)) return null;
        xh = hz;
      } else {
        if (zh != null && !_sameSet(zh, hz)) return null;
        zh = hz;
      }
    }
    final bars = <List<int>>[];
    for (var lv = 0; lv < 3; lv++) {
      final ch = _hseg[lv];
      if (xh != null && xh.contains(ch)) bars.add(bX(lv, r.nextInt(2)));
      if (zh != null && zh.contains(ch)) bars.add(bZ(lv, r.nextInt(2)));
    }
    final opts = <List<List<int>>>[];
    for (var m = 0; m < 256; m++) {
      final vs = <List<int>>[
        for (var i = 0; i < 8; i++) if (((m >> i) & 1) == 1) _allV[i],
      ];
      var ok = true;
      for (final e in want.entries) {
        final s = segOf[e.value];
        final left = <int>{};
        final right = <int>{};
        for (final c in s.split('')) {
          if (c == 'f') left.add(0);
          if (c == 'e') left.add(1);
          if (c == 'b') right.add(0);
          if (c == 'c') right.add(1);
        }
        final l = <int>{};
        final rr = <int>{};
        for (final v in vs) {
          final x = v[0], z = v[1], h = v[2];
          final bool isLeft = e.key == 'F'
              ? x == 0
              : e.key == 'B'
                  ? x == 1
                  : e.key == 'R'
                      ? z == 0
                      : z == 1;
          (isLeft ? l : rr).add(h);
        }
        if (!_sameSet(l, left) || !_sameSet(rr, right)) {
          ok = false;
          break;
        }
      }
      if (ok) opts.add(vs);
    }
    if (opts.isEmpty) return null;
    for (final v in opts[r.nextInt(opts.length)]) {
      bars.add(bV(v[0], v[1], v[2]));
    }
    final base = digitMap(bars);
    final cand = <List<int>>[
      for (var l = 0; l < 3; l++) ...[
        bX(l, 0), bX(l, 1), bZ(l, 0), bZ(l, 1),
      ],
      for (final v in _allV) bV(v[0], v[1], v[2]),
    ]..shuffle(r);
    var n = 0;
    for (final c in cand) {
      if (n >= decoys) break;
      if (_has(bars, c)) continue;
      final nb = [...bars, c];
      if (_sameDigits(digitMap(nb), base)) {
        bars.add(c);
        n++;
      }
    }
    return bars;
  }

  static bool _only(List<List<int>> bars, List<int> ds) => _sameSet(digitSet(bars), ds.toSet());

  // Cau hoi "nhin tu huong nay thanh so may": 1 hoac 2 huong tren cung mot hop
  static ViewItem? viewItem(Random r, int no, int nViews, int maxDecoys) {
    for (var t = 0; t < 200; t++) {
      List<String> vs;
      if (nViews == 1) {
        vs = [views[r.nextInt(4)]];
      } else {
        const pairs = [
          ['F', 'R'], ['F', 'L'], ['B', 'R'], ['B', 'L'],
        ];
        vs = pairs[r.nextInt(pairs.length)];
      }
      final want = {for (final v in vs) v: r.nextInt(10)};
      final b = makeBox(r, want, r.nextInt(maxDecoys + 1));
      if (b == null) continue;
      final dm = digitMap(b);
      if (want.entries.any((e) => dm[e.key] != e.value)) continue;
      return ViewItem(label: '（${no + 1}）', data: {
        't': 'view',
        'bars': b,
        'qs': [
          for (final v in vs) [v, want[v]!],
        ],
      });
    }
    return null;
  }

  // Bai nam sinh: 4 hop A-D, hop thu tu co 2 chu so (nam bo / nam me khac nhau 1 chu so cuoi)
  static ViewItem? yearItem(Random r, int no, {bool trick = false, int maxDecoys = 3, String? ask}) {
    for (var t = 0; t < 500; t++) {
      final y = 1960 + r.nextInt(30);
      final u = y % 10;
      if (u == 9) continue;
      final m = y + 1 + r.nextInt(9 - u);
      final dy = y.toString().split('').map(int.parse).toList();
      final dm = m.toString().split('').map(int.parse).toList();
      final boxes = <List<List<int>>>[];
      var ok = true;
      for (var i = 0; i < 3 && ok; i++) {
        List<List<int>>? got;
        if (i == 0 && trick) {
          const vp = [
            ['F', 'L'], ['B', 'R'], ['F', 'R'], ['B', 'L'],
          ];
          final p = vp[r.nextInt(vp.length)];
          for (var k = 0; k < 40 && got == null; k++) {
            final b = makeBox(r, {p[0]: 0, p[1]: 1}, r.nextInt(3));
            if (b != null && _only(b, [0, 1])) got = b;
          }
        } else {
          for (var k = 0; k < 40 && got == null; k++) {
            final b = makeBox(r, {views[r.nextInt(4)]: dy[i]}, r.nextInt(maxDecoys + 1));
            if (b != null && _only(b, [dy[i]])) got = b;
          }
        }
        if (got == null) {
          ok = false;
        } else {
          boxes.add(got);
        }
      }
      if (!ok) continue;
      List<List<int>>? last;
      const pairs = [
        ['F', 'B'], ['R', 'L'], ['F', 'R'], ['F', 'L'], ['B', 'R'], ['B', 'L'],
      ];
      for (var k = 0; k < 60 && last == null; k++) {
        final p = pairs[r.nextInt(pairs.length)];
        final swap = r.nextBool();
        final v1 = swap ? p[1] : p[0];
        final v2 = swap ? p[0] : p[1];
        final b = makeBox(r, {v1: dy[3], v2: dm[3]}, r.nextInt(maxDecoys + 1));
        if (b != null && _only(b, [dy[3], dm[3]])) last = b;
      }
      if (last == null) continue;
      boxes.add(last);
      final ys = validYears(boxes);
      if (ys.length != 2 || ys[0] != y || ys[1] != m) continue;
      final who = ask ?? (r.nextBool() ? 'mother' : 'father');
      return ViewItem(label: '（${no + 1}）', data: {
        't': 'year',
        'boxes': boxes,
        'ask': who,
        'pre': false,
        'q': yearQuestion(who),
      });
    }
    return null;
  }

  // ---------------- van ban ----------------

  static Map<String, String> viewName(String v) {
    switch (v) {
      case 'R':
        return {'ja': '← 右から', 'en': '← From the right', 'vi': '← Nhìn từ bên phải'};
      case 'L':
        return {'ja': '左から →', 'en': 'From the left →', 'vi': 'Nhìn từ bên trái →'};
      case 'B':
        return {'ja': 'うしろから', 'en': 'From the back', 'vi': 'Nhìn từ phía sau'};
      default:
        return {'ja': '正めんから', 'en': 'From the front', 'vi': 'Nhìn từ chính diện'};
    }
  }

  static Map<String, String> intro() => {
        'ja':
            'とうめいな はこの 中に ぼうが はりつけて あります。この はこを ある むきから 見ると、すう字に 見えることが あります。（7は 左上に ちいさな ぼうが ある かたちです）',
        'en':
            'Bars are attached inside a transparent box. Seen from a certain direction, they can look like a digit. (A 7 has a small bar at the upper left.)',
        'vi':
            'Bên trong hộp trong suốt có dán các thanh. Nhìn từ một hướng nào đó có thể thấy hình chữ số. (Số 7 có một thanh nhỏ ở góc trên bên trái.)',
      };

  static Map<String, String> viewQuestion() => {
        'ja': 'つぎの はこを やじるしの むきから 見ると、どの すう字に 見えますか。（7は 左上に ちいさな ぼうが ある かたちです）',
        'en': 'Seen from the direction shown, which digit does each box look like? (A 7 has a small bar at the upper left.)',
        'vi': 'Nhìn hộp từ hướng được chỉ, ta thấy chữ số nào? (Số 7 có một thanh nhỏ ở góc trên bên trái.)',
      };

  static Map<String, String> yearQuestion(String ask) {
    final ja = ask == 'father' ? 'おとうさん' : 'おかあさん';
    final en = ask == 'father' ? "father's" : "mother's";
    final vi = ask == 'father' ? 'bố' : 'mẹ';
    return {
      'ja':
          '左から A B C Dの じゅんに 〈入れもの〉に はこを 入れます。はこは 上下さかさまには 入れません。いろいろな むきで はこを 入れて 〈入れもの〉を まえから 見ると、おとうさんと おかあさんが 生まれた 年を それぞれ つくることが できました。おとうさんの ほうが 年上です。$jaが 生まれた 年は なん年ですか。また、〈入れもの〉を 上から 見ると、はこの むきは どうなっていますか。A〜Dの もじを タップして むきを かえましょう。',
      'en':
          'Boxes A, B, C, D are put in the container from the left, never upside down, each facing any direction. Looking at the container from the front, we can make the birth years of the father and the mother. The father is older. What is the $en birth year? Seen from above, which way does each box face? Tap the letters A–D to turn them.',
      'vi':
          'Lần lượt đặt các hộp A, B, C, D từ trái sang phải vào khay, không đặt ngược đầu, mỗi hộp có thể quay hướng tùy ý. Nhìn khay từ phía trước, ta tạo được năm sinh của bố và của mẹ. Bố lớn tuổi hơn. Năm sinh của $vi là năm nào? Nhìn từ trên xuống thì mỗi hộp quay hướng nào? Chạm vào các chữ A–D để xoay hướng.',
    };
  }

  static String wrongMessage(String lang) => lang == 'ja'
      ? 'ちがう ところが あるよ。ぼうが どの むきに ならんで いるか、よく 見てみよう'
      : lang == 'en'
          ? 'Something is wrong. Look carefully at which direction the bars line up'
          : 'Có chỗ chưa đúng. Hãy nhìn kỹ xem các thanh xếp theo hướng nào';

  // ---------------- bai mau (dung nhu sach) ----------------

  static List<ViewLesson> samples() {
    // Hinh vi du (trang 7): nhin tu chinh dien thanh 3
    final ex = [bX(0, 1), bV(1, 1, 0), bX(1, 0), bZ(1, 1), bV(1, 0, 1), bX(2, 0)];
    // (1) nhin tu ben phai -> 4
    final p1 = [bV(0, 1, 0), bV(0, 1, 1), bV(1, 0, 0), bZ(1, 1)];
    // (2) tu chinh dien -> 7, tu ben trai -> 3
    final p2 = [bX(0, 0), bZ(0, 0), bV(0, 0, 0), bZ(1, 0), bV(1, 0, 0), bV(1, 0, 1), bZ(2, 1)];
    // Bai 2: bon hop A B C D
    final a = [bX(0, 0), bX(2, 0), bV(0, 0, 0), bV(0, 0, 1), bV(1, 0, 0), bV(1, 0, 1)];
    final b = [bV(0, 0, 0), bZ(0, 0), bZ(1, 0), bV(1, 1, 0), bV(1, 1, 1), bX(2, 0), bZ(2, 1)];
    final c = [bV(0, 0, 0), bZ(0, 0), bZ(1, 0), bV(1, 0, 1), bV(1, 1, 0), bV(1, 1, 1), bZ(2, 1)];
    final d = [bX(0, 0), bZ(0, 1), bV(1, 0, 0), bX(1, 1), bV(0, 1, 1), bX(2, 1)];
    return [
      ViewLesson(
        id: 'TB001',
        title: {'ja': 'とうめいな はこ 1', 'en': 'Transparent Box 1', 'vi': 'Hộp trong suốt 1'},
        question: viewQuestion(),
        kind: 'segbox',
        difficulty: 1,
        items: [
          ViewItem(label: '見本', data: {
            't': 'example',
            'bars': ex,
            'qs': [
              ['F', 3],
            ],
          }),
          ViewItem(label: '（1）', data: {
            't': 'view',
            'bars': p1,
            'qs': [
              ['R', 4],
            ],
          }),
          ViewItem(label: '（2）', data: {
            't': 'view',
            'bars': p2,
            'qs': [
              ['F', 7],
              ['L', 3],
            ],
          }),
        ],
      ),
      ViewLesson(
        id: 'TB002',
        title: {'ja': 'とうめいな はこ 2', 'en': 'Transparent Box 2', 'vi': 'Hộp trong suốt 2'},
        question: intro(),
        kind: 'segbox',
        difficulty: 3,
        items: [
          ViewItem(label: '２', data: {
            't': 'year',
            'boxes': [a, b, c, d],
            'ask': 'mother', // dap an 1985 (bo 1982). A: trai(1) B: phai(9) C: trai/phai(8) D: sau(5)
            'pre': true, // sach da ghi san so dau "1" va huong cua A
            'q': yearQuestion('mother'),
          }),
        ],
      ),
    ];
  }

  // ---------------- tu sinh ----------------

  static ViewLesson generate({int level = 1, Random? rng}) {
    final r = rng ?? Random();
    final lv = level < 1 ? 1 : (level > 3 ? 3 : level);
    final items = <ViewItem>[];
    if (lv == 1) {
      // 2 cau, moi cau 1 huong, it thanh nhieu
      for (var i = 0; i < 2; i++) {
        final it = viewItem(r, i, 1, 1);
        if (it != null) items.add(it);
      }
    } else if (lv == 2) {
      // 1 cau nhin tu 2 huong (nhu cau (2) trong sach) + 1 cau 1 huong (co the tu phia sau)
      final a = viewItem(r, 0, 2, 2);
      final b = viewItem(r, 1, 1, 3);
      if (a != null) items.add(a);
      if (b != null) items.add(b);
    } else {
      final y = yearItem(r, 0, trick: r.nextBool(), maxDecoys: 3);
      if (y != null) items.add(y);
    }
    if (items.isEmpty) {
      // du phong (hiem khi xay ra): dung bai mau (1)
      items.add(samples().first.items[1]);
    }
    return ViewLesson(
      id: 'vw_${DateTime.now().microsecondsSinceEpoch}',
      title: {
        'ja': 'とうめいな はこ ✨',
        'en': 'Transparent Box ✨',
        'vi': 'Hộp trong suốt ✨',
      },
      question: lv == 3 ? intro() : viewQuestion(),
      kind: 'segbox',
      difficulty: lv,
      isAutoGenerated: true,
      items: items,
    );
  }
}
