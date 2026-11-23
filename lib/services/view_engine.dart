import 'dart:math';
import '../models/view_lesson.dart';
import 'view_shapes.dart';
import 'segbox_engine.dart';

// 水めんのかたち (water): nhin tu tren xuong, xep 4 hinh theo luong nuoc nhieu -> it (1 = nhieu nhat).
// かげの正たい (shadow): tu 3 cai bong (nhin tu 3 huong) doan ra vat.
// とうめいなはことボール (box): hop trong suot 2x2x2 co bong -> danh dau o thay bong khi nhin tu tren/phai/truoc.
// つみ木のおきかた (blocks): luoi thap khoi -> dem so khoi nhin thay theo huong mui ten.
class ViewEngine {
  static const List<String> kinds = ['water', 'shadow', 'box', 'segbox', 'blocks'];

  static const Map<String, Map<String, String>> baseNames = {
    'water': {'ja': '水めんの かたち', 'en': 'Water Surface Shapes', 'vi': 'Hình dạng mặt nước'},
    'shadow': {'ja': 'かげの 正たい', 'en': 'Whose Shadow?', 'vi': 'Bóng của vật nào?'},
    'box': {'ja': 'とうめいな はこと ボール', 'en': 'Transparent Box and Balls', 'vi': 'Hộp trong suốt và quả bóng'},
    'segbox': {'ja': 'とうめいな はこ', 'en': 'Transparent Box', 'vi': 'Hộp trong suốt (chữ số)'},
    'blocks': {'ja': 'つみ木の おきかた', 'en': 'Stacking Blocks', 'vi': 'Cách xếp khối gỗ'},
  };

  // Cac vat de chon, theo thu tu ① ... ⑥ trong sach
  static const List<String> objects = ['cheese', 'ball', 'can', 'kit', 'cake', 'tissue'];
  static const List<String> circled = ['①', '②', '③', '④', '⑤', '⑥'];

  // Cac vat bo sung (chi dung cho bai tu sinh). Moi vat co 3 hinh bong rieng, khong trung nhau.
  static const List<String> extraObjects = [
    'dice', 'hat', 'pyramid', 'egg', 'cup', 'pencil', 'house', 'tent', 'bottle', 'donut', 'hourglass', 'bowl',
  ];

  static const Map<String, Map<String, String>> objectNames = {
    'dice': {'ja': 'さいころ', 'en': 'Dice', 'vi': 'Con xúc xắc'},
    'hat': {'ja': 'とんがりぼうし', 'en': 'Party hat', 'vi': 'Mũ chóp nhọn'},
    'pyramid': {'ja': 'ピラミッド', 'en': 'Pyramid', 'vi': 'Kim tự tháp'},
    'egg': {'ja': 'たまご', 'en': 'Egg', 'vi': 'Quả trứng'},
    'cup': {'ja': 'コップ', 'en': 'Paper cup', 'vi': 'Cốc giấy'},
    'pencil': {'ja': 'えんぴつ', 'en': 'Pencil', 'vi': 'Bút chì'},
    'house': {'ja': 'おうち', 'en': 'House', 'vi': 'Ngôi nhà'},
    'tent': {'ja': 'テント', 'en': 'Tent', 'vi': 'Cái lều'},
    'bottle': {'ja': 'ペットボトル', 'en': 'Bottle', 'vi': 'Chai nước'},
    'donut': {'ja': 'ドーナツ', 'en': 'Donut', 'vi': 'Bánh donut'},
    'hourglass': {'ja': 'すなどけい', 'en': 'Hourglass', 'vi': 'Đồng hồ cát'},
    'bowl': {'ja': 'おわん', 'en': 'Bowl', 'vi': 'Cái bát'},
    'cheese': {'ja': 'チーズ', 'en': 'Cheese', 'vi': 'Phô mai'},
    'ball': {'ja': 'やきゅうボール', 'en': 'Baseball', 'vi': 'Bóng chày'},
    'can': {'ja': 'おちゃの つつ', 'en': 'Tea canister', 'vi': 'Hộp trà'},
    'kit': {'ja': 'きゅうきゅうばこ', 'en': 'First-aid box', 'vi': 'Hộp cứu thương'},
    'cake': {'ja': 'ケーキ', 'en': 'Cake', 'vi': 'Bánh kem'},
    'tissue': {'ja': 'ティッシュの はこ', 'en': 'Tissue box', 'vi': 'Hộp khăn giấy'},
  };

  // Ten mau cua cac loai khoi (cao 1..5)
  static const List<Map<String, String>> blockColorNames = [
    {'ja': '赤いろ', 'en': 'red', 'vi': 'đỏ'},
    {'ja': '青いろ', 'en': 'blue', 'vi': 'xanh dương'},
    {'ja': 'きいろ', 'en': 'yellow', 'vi': 'vàng'},
    {'ja': 'みどりいろ', 'en': 'green', 'vi': 'xanh lá'},
    {'ja': 'むらさきいろ', 'en': 'purple', 'vi': 'tím'},
  ];

  // De bai dang tu mau: khoi duoc phan biet bang mau (do 1 khoi, xanh 2 khoi, ...)
  static Map<String, String> colorBlocksQuestion(int n) {
    final names = blockColorNames;
    final ja = StringBuffer('おなじ 大きさの さいころの かたちをした つみ木が たくさんあります。');
    for (var h = 1; h <= n; h++) {
      if (h == 1) {
        ja.write('${names[0]['ja']}は そのままですが、');
      } else if (h < n) {
        ja.write('${names[h - 1]['ja']}は $hこずつ、');
      } else {
        ja.write('${names[h - 1]['ja']}は $hこずつ ');
      }
    }
    ja.write('のりで はりあわせて、下の ${n * n}この ブロックを よういしました。');
    ja.write('この ${n * n}この ブロックを つぎの 〈ます目〉の 上に ぜんぶ おいて、それぞれの やじるしの むきから その れつに 見える ブロックを かぞえます。ブロックは 1ますに 1こしか おけません。また、おなじ れつに おなじ いろは おけません。');
    final en = StringBuffer('There are many cube-shaped blocks. ${names[0]['en']![0].toUpperCase()}${names[0]['en']!.substring(1)} is a single cube');
    final vi = StringBuffer('Có nhiều khối lập phương. Màu ${names[0]['vi']} là 1 khối');
    for (var h = 2; h <= n; h++) {
      en.write(', ${names[h - 1]['en']} is $h cubes glued together');
      vi.write(', màu ${names[h - 1]['vi']} dán $h khối');
    }
    en.write('. We prepared $n of each color (${n * n} blocks). Place all of them on the grid and count the blocks that can be seen along each line from the direction of its arrow. Only 1 block fits in each square, and the same color cannot appear twice in one row or column.');
    vi.write('. Mỗi màu chuẩn bị $n khối (tổng ${n * n} khối). Đặt hết lên bảng ô rồi đếm số khối nhìn thấy trên từng hàng/cột theo hướng mũi tên. Mỗi ô chỉ đặt 1 khối, và trong cùng một hàng hay một cột không có hai khối cùng màu.');
    return {'ja': ja.toString(), 'en': en.toString(), 'vi': vi.toString()};
  }

  // De tung cau trong bai tu mau: dem (mode count) hoac danh dau o co khoi mau t (mode place)
  static Map<String, String> colorBlocksSub(String mode, int t) {
    final nm = blockColorNames[t - 1];
    if (mode == 'place') {
      return {
        'ja': 'ブロックを おいて、それぞれの やじるしの むきから その れつに 見える ブロックの かずを かきました。${nm['ja']}の ブロックを おいた ます ぜんぶに ○を つけましょう。',
        'en': 'Blocks were placed and the number visible along each arrow was written. Mark ○ on every square where a ${nm['en']} block was placed.',
        'vi': 'Các khối được đặt rồi ghi số khối nhìn thấy theo từng mũi tên. Hãy đánh ○ vào tất cả các ô có đặt khối màu ${nm['vi']}.',
      };
    }
    return {
      'ja': 'つぎのように ブロックを おきました。それぞれの やじるしの むきから その れつに 見える ブロックの かずを えらびましょう。',
      'en': 'Blocks were placed as shown. Choose how many blocks can be seen along each line from the direction of its arrow.',
      'vi': 'Các khối được đặt như hình. Chọn số khối nhìn thấy trên từng hàng/cột theo hướng mũi tên.',
    };
  }

  static Map<String, String> questionFor(String kind, {int n = 4, bool color = false}) {
    if (kind == 'segbox') return SegBoxEngine.viewQuestion();
    if (kind == 'box') {
      return {
        'ja': 'とうめいな はこの 中に ボールが 入っています。これを いろいろな むきから 見たとき、どのように 見えますか。ボールが 見える ところを タップして ○を つけましょう。',
        'en': 'Balls are inside a transparent box. How do they look from each direction? Tap the squares where a ball can be seen to mark them with ○.',
        'vi': 'Trong hộp trong suốt có các quả bóng. Khi nhìn từ từng hướng thì thấy thế nào? Chạm vào những ô nhìn thấy bóng để đánh ○.',
      };
    }
    if (kind == 'blocks' && color) return colorBlocksQuestion(n);
    if (kind == 'blocks') {
      final c = circled[n - 1];
      return {
        'ja': 'おなじ 大きさの さいころの かたちをした つみ木を のりで はりあわせて、①〜$cの ブロックを $nこずつ つくりました。①〜$cの ${n * n}この ブロックを つぎの 〈ます目〉の 上に ぜんぶ おきました。それぞれの やじるしの むきから その れつに 見える ブロックを かぞえます。見える ブロックの かずを □に えらびましょう。',
        'en': 'Cube-shaped blocks were glued together to make $n of each block ①–$c. All ${n * n} blocks were placed on the grid below. Count the blocks that can be seen along each line from the direction of its arrow, and choose the numbers for the boxes.',
        'vi': 'Các khối lập phương được dán thành $n khối mỗi loại ①–$c. Cả ${n * n} khối được đặt hết lên bảng ô bên dưới. Đếm số khối nhìn thấy trên từng hàng/cột theo hướng mũi tên rồi chọn số điền vào ô.',
      };
    }
    if (kind == 'water') {
      return {
        'ja': '右のような 入れものに 水を 入れながら、ま上から 見ました。下の 4つの えは、この 入れものを ま上から 見た ようすです。水が たくさん 入っている じゅんに、（　）に ばんごうを かきましょう。',
        'en': 'Water is poured into the container shown, looking straight down from above. The four pictures show the container seen from directly above. Write numbers in the ( ) in order from the most water (1) to the least.',
        'vi': 'Đổ nước vào bình như hình và nhìn thẳng từ trên xuống. 4 hình dưới là cảnh nhìn từ trên. Điền số vào ( ) theo thứ tự nước từ nhiều nhất (1) đến ít nhất.',
      };
    }
    return {
      'ja': 'かげの 正たいを 見やぶり、ばんごうを かきましょう。',
      'en': 'Work out what made the shadows and write its number.',
      'vi': 'Đoán xem các cái bóng này là của vật nào và viết số của vật đó.',
    };
  }

  static String wrongMessage(String kind, String lang) {
    if (kind == 'segbox') return SegBoxEngine.wrongMessage(lang);
    if (kind == 'box') {
      return lang == 'ja'
          ? 'ちがう ところが あるよ。ボールが どこに あるか、よく かんがえよう'
          : lang == 'en'
              ? 'Something is wrong. Think carefully about where each ball is'
              : 'Có chỗ chưa đúng. Hãy nghĩ kỹ xem mỗi quả bóng nằm ở đâu';
    }
    if (kind == 'blocks') {
      return lang == 'ja'
          ? 'ちがう ところが あるよ。ひくい ブロックは、たかい ブロックの うしろに かくれるよ'
          : lang == 'en'
              ? 'Something is wrong. A low block is hidden behind a taller one'
              : 'Có chỗ chưa đúng. Khối thấp bị khối cao che khuất phía sau';
    }
    if (kind == 'water') {
      return lang == 'ja'
          ? 'ちがう ところが あるよ。水が ふえると、水めんは どう かわるかな？'
          : lang == 'en'
              ? 'Something is wrong. How does the water surface change as the water rises?'
              : 'Có chỗ chưa đúng. Khi nước dâng lên, mặt nước thay đổi thế nào?';
    }
    return lang == 'ja'
        ? 'ちがう ところが あるよ。いろいろな むきから 見た かたちを かんがえよう'
        : lang == 'en'
            ? 'Something is wrong. Think about the shapes seen from different directions'
            : 'Có chỗ chưa đúng. Hãy nghĩ về hình dạng khi nhìn từ các hướng khác nhau';
  }

  // ---- 水めん ----

  // hang 1 = nhieu nhat
  static List<int> _ranks(List<double> amounts) =>
      [for (final a in amounts) 1 + amounts.where((b) => b > a).length];

  // binh hinh non (hoac bat, hoac chop da giac): vanh ngoai 1.0, mieng non 0.78, mat nuoc rw
  // kind: o = tron, s = vuong, h = luc giac, t = tam giac
  static Map<String, dynamic> _coneTop(double rw, [String kind = 'o']) => {
        'c': [1.0, 0.78, rw],
        'k': 'o$kind$kind',
        's0': 0.0,
        'k0': 'o',
        's1': rw,
        'k1': kind,
      };

  // binh bac thang: state = muc nuoc nam trong tang state (0 = tang duoi cung); state = n -> ngap het
  // Moi tang co the co hinh dang mat cat khac nhau (kStairKinds), khung ngoai la kStairOuter.
  static Map<String, dynamic> _stairTop(String key, int state) {
    final r = kStairRadii[key]!;
    final n = r.length;
    final kinds = kStairKinds[key] ?? ('o' * n);
    final outer = kStairOuter[key] ?? 'o';
    if (state >= n) {
      return {'c': [1.0], 'k': outer, 's0': 0.0, 'k0': 'o', 's1': 1.0, 'k1': outer};
    }
    return {
      'c': [1.0, for (var j = state; j < n; j++) r[j]],
      'k': outer + kinds.substring(state),
      's0': r[state],
      'k0': kinds[state],
      's1': 1.0,
      'k1': outer,
    };
  }

  // be chua bac thang thang (hoac mat doc): nuoc phu tu trai den x (ti le chieu rong)
  static Map<String, dynamic> _linearTop(List<double> edges, double x) => {
        'lin': edges,
        'x': x,
      };

  static ViewItem _waterItem(String label, String pic, List<Map<String, dynamic>> tops, List<double> amounts) {
    return ViewItem(label: label, data: {'pic': pic, 'tops': tops, 'ans': _ranks(amounts)});
  }

  static ViewItem _stairItem(String key, List<int> states) {
    return _waterItem('', key, [for (final s in states) _stairTop(key, s)], [for (final s in states) s.toDouble()]);
  }

  static ViewItem _coneItem(String pic, List<double> rws) {
    final kind = kConeKinds[pic] ?? 'o';
    return _waterItem('', pic, [for (final w in rws) _coneTop(w, kind)], rws);
  }

  // key: 'ramp' (mat doc) hoac khoa trong kLinearEdges; xs = ti le nuoc phu cua 4 hinh
  static ViewItem _linearItem(String key, List<double> xs) {
    final edges = kLinearEdges[key] ?? const <double>[];
    return _waterItem('', key, [for (final x in xs) _linearTop(edges, x)], xs);
  }

  // ---- かげ ----
  static ViewItem _shadowItem(int no, String obj) =>
      ViewItem(label: '（${no + 1}）', data: {'obj': obj});

  // ---- とうめいなはことボール ----
  // balls: [x, y, z, toi]; x 0=trai 1=phai, y 0=tren 1=duoi, z 0=truoc 1=sau
  static const Map<String, Map<String, String>> boxViewNames = {
    'top': {'ja': '上から', 'en': 'From above', 'vi': 'Nhìn từ trên'},
    'right': {'ja': '右から', 'en': 'From the right', 'vi': 'Nhìn từ bên phải'},
    'front': {'ja': '前から', 'en': 'From the front', 'vi': 'Nhìn từ phía trước'},
  };

  // Luoi 2x2 (chi so hang * 2 + cot): o nao thay bong
  static List<bool> boxView(List<List<int>> balls, String view) {
    final r = List<bool>.filled(4, false);
    for (final b in balls) {
      final x = b[0], y = b[1], z = b[2];
      int row, col;
      if (view == 'top') {
        row = 1 - z; // phia sau o hang tren
        col = x;
      } else if (view == 'right') {
        row = y;
        col = z; // phia truoc o ben trai
      } else {
        row = y;
        col = x;
      }
      r[row * 2 + col] = true;
    }
    return r;
  }

  static ViewItem _boxItem(int no, List<List<int>> balls, List<String> views) =>
      ViewItem(label: '（${no + 1}）', data: {'balls': balls, 'views': views});

  // ---- つみ木のおきかた ----
  // So khoi nhin thay khi di tu gan ra xa: dem cac cot cao hon moi cot truoc do
  static int visibleCount(List<int> nearToFar) {
    var best = 0;
    var cnt = 0;
    for (final h in nearToFar) {
      if (h > best) {
        best = h;
        cnt++;
      }
    }
    return cnt;
  }

  // Mui ten ben phai: nhin tu cot phai sang trai tren tung hang
  static List<int> blockRows(List<List<int>> g) =>
      [for (final row in g) visibleCount(row.reversed.toList())];

  // Mui ten ben duoi: nhin tu hang duoi len tren tren tung cot
  static List<int> blockCols(List<List<int>> g) => [
        for (var c = 0; c < g.length; c++) visibleCount([for (var r = g.length - 1; r >= 0; r--) g[r][c]]),
      ];

  static ViewItem _blocksItem(List<List<int>> g) =>
      ViewItem(label: '', data: {'n': g.length, 'grid': g});

  // Cau dem (mode count) dung mau: o hien mau thay vi so
  static ViewItem _blocksColorItem(int no, List<List<int>> g) => ViewItem(
        label: '（${no + 1}）',
        data: {'n': g.length, 'grid': g, 'mode': 'count', 'color': true, 'q': colorBlocksSub('count', g.length)},
      );

  // Cau dat khoi (mode place): cho san so khoi nhin thay o ca 8 mui ten, danh dau cac o co khoi cao t
  // pos: vi tri (hang * n + cot) cua cac o dap an
  static ViewItem _blocksPlaceItem(int no, int n, List<int> rows, List<int> cols, int t, List<int> pos) => ViewItem(
        label: '（${no + 1}）',
        data: {
          'n': n,
          'mode': 'place',
          'color': true,
          'rows': rows,
          'cols': cols,
          'target': t,
          'pos': pos,
          'q': colorBlocksSub('place', t),
        },
      );

  static List<int> _positions(List<List<int>> g, int t) {
    final n = g.length;
    return [
      for (var r = 0; r < n; r++)
        for (var c = 0; c < n; c++)
          if (g[r][c] == t) r * n + c,
    ];
  }

  static bool _sameList(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // Tat ca luoi Latin n x n co so khoi nhin thay khop voi rows (mui ten phai) va cols (mui ten duoi)
  static List<List<List<int>>> _solveBlocks(int n, List<int> rows, List<int> cols, {int limit = 3000}) {
    final perms = <List<int>>[];
    void gen(List<int> cur) {
      if (cur.length == n) {
        perms.add(List<int>.from(cur));
        return;
      }
      for (var v = 1; v <= n; v++) {
        if (cur.contains(v)) continue;
        cur.add(v);
        gen(cur);
        cur.removeLast();
      }
    }

    gen(<int>[]);
    final byRow = [
      for (var i = 0; i < n; i++)
        [for (final p in perms) if (visibleCount(p.reversed.toList()) == rows[i]) p],
    ];
    final out = <List<List<int>>>[];
    final g = <List<int>>[];
    void rec(int r) {
      if (out.length >= limit) return;
      if (r == n) {
        for (var c = 0; c < n; c++) {
          if (visibleCount([for (var k = n - 1; k >= 0; k--) g[k][c]]) != cols[c]) return;
        }
        out.add([for (final row in g) List<int>.from(row)]);
        return;
      }
      for (final p in byRow[r]) {
        var ok = true;
        for (var c = 0; c < n && ok; c++) {
          for (var k = 0; k < r; k++) {
            if (g[k][c] == p[c]) {
              ok = false;
              break;
            }
          }
        }
        if (!ok) continue;
        g.add(p);
        rec(r + 1);
        g.removeLast();
      }
    }

    rec(0);
    return out;
  }

  // Sinh cau dat khoi: dap an (vi tri khoi cao t) phai duy nhat voi cac so da cho
  static ViewItem? _randomPlaceItem(Random r, int n, int no) {
    for (var attempt = 0; attempt < 40; attempt++) {
      final g = _latin(r, n);
      final rows = blockRows(g);
      final cols = blockCols(g);
      final sols = _solveBlocks(n, rows, cols);
      if (sols.isEmpty || sols.length >= 3000) continue;
      final order = [n, 1, ...List<int>.generate(n - 2, (i) => i + 2)];
      for (final t in order) {
        final base = _positions(sols.first, t);
        if (sols.every((s) => _sameList(_positions(s, t), base))) {
          return _blocksPlaceItem(no, n, rows, cols, t, base);
        }
      }
    }
    return null;
  }

  // Luoi vuong n x n moi hang/cot co du 1..n (ngau nhien, quay lui)
  static List<List<int>> _latin(Random r, int n) {
    final g = List<List<int>>.generate(n, (_) => List<int>.filled(n, 0));
    bool fill(int pos) {
      if (pos == n * n) return true;
      final row = pos ~/ n, col = pos % n;
      final cand = List<int>.generate(n, (i) => i + 1)..shuffle(r);
      for (final v in cand) {
        var ok = true;
        for (var k = 0; k < col && ok; k++) {
          if (g[row][k] == v) ok = false;
        }
        for (var k = 0; k < row && ok; k++) {
          if (g[k][col] == v) ok = false;
        }
        if (!ok) continue;
        g[row][col] = v;
        if (fill(pos + 1)) return true;
        g[row][col] = 0;
      }
      return false;
    }

    fill(0);
    return g;
  }

  static List<ViewLesson>? _cache;

  static List<ViewLesson> samples(String kind) {
    _cache ??= _build();
    return _cache!.where((l) => l.kind == kind).toList();
  }

  static List<ViewLesson> _build() {
    return [
      // 水めん: dung nhu sach. Thu tu hinh nhu trong sach.
      ViewLesson(
        id: 'WT001',
        title: {'ja': '水めんの かたち 1', 'en': 'Water Surface 1', 'vi': 'Mặt nước 1'},
        question: questionFor('water'),
        kind: 'water',
        difficulty: 1,
        items: [
          _coneItem('cone', [0.42, 0.69, 0.22, 0.55]), // dap an 3,1,4,2
        ],
      ),
      ViewLesson(
        id: 'WT002',
        title: {'ja': '水めんの かたち 2', 'en': 'Water Surface 2', 'vi': 'Mặt nước 2'},
        question: questionFor('water'),
        kind: 'water',
        difficulty: 2,
        items: [
          _stairItem('st3a', [3, 2, 0, 1]), // dap an 1,2,4,3
        ],
      ),
      // かげ: 4 cau trong sach chia 2 bai; dap an (1)④ (2)③ (3)⑤ (4)②
      ViewLesson(
        id: 'SH001',
        title: {'ja': 'かげの 正たい 1', 'en': 'Whose Shadow? 1', 'vi': 'Bóng của vật nào? 1'},
        question: questionFor('shadow'),
        kind: 'shadow',
        difficulty: 2,
        items: [_shadowItem(0, 'kit'), _shadowItem(1, 'can')],
        bank: objects,
      ),
      ViewLesson(
        id: 'SH002',
        title: {'ja': 'かげの 正たい 2', 'en': 'Whose Shadow? 2', 'vi': 'Bóng của vật nào? 2'},
        question: questionFor('shadow'),
        kind: 'shadow',
        difficulty: 2,
        items: [_shadowItem(2, 'cake'), _shadowItem(3, 'ball')],
        bank: objects,
      ),
      // とうめいなはことボール: dung nhu sach (2 cau)
      ViewLesson(
        id: 'BX001',
        title: {'ja': 'とうめいな はこと ボール 1', 'en': 'Transparent Box 1', 'vi': 'Hộp trong suốt 1'},
        question: questionFor('box'),
        kind: 'box',
        difficulty: 2,
        items: [
          _boxItem(0, [
            [0, 0, 1, 0],
            [1, 0, 0, 1],
            [0, 1, 1, 0],
          ], ['top', 'right']),
          _boxItem(1, [
            [0, 0, 0, 1],
            [0, 1, 1, 0],
            [1, 1, 1, 0],
          ], ['top', 'right']),
        ],
      ),
      // つみ木のおきかた: dung nhu sach (luoi 4x4)
      ViewLesson(
        id: 'BK001',
        title: {'ja': 'つみ木の おきかた 1', 'en': 'Stacking Blocks 1', 'vi': 'Cách xếp khối gỗ 1'},
        question: questionFor('blocks', n: 4),
        kind: 'blocks',
        difficulty: 2,
        items: [
          _blocksItem([
            [3, 2, 4, 1],
            [1, 4, 2, 3],
            [4, 1, 3, 2],
            [2, 3, 1, 4],
          ]),
        ],
      ),
      // つみ木のおきかた (いろ): dung nhu sach. do = 1, xanh duong = 2, vang = 3, xanh la = 4.
      // (1) dem: dap an phai 2,1,3,2 / duoi 2,4,1,2; (2) dat khoi xanh la: o (1,1) (2,3) (3,2) (4,4)
      ViewLesson(
        id: 'BK002',
        title: {'ja': 'つみ木の おきかた 2', 'en': 'Stacking Blocks 2', 'vi': 'Cách xếp khối gỗ 2'},
        question: questionFor('blocks', n: 4, color: true),
        kind: 'blocks',
        difficulty: 3,
        items: [
          _blocksColorItem(0, [
            [1, 4, 2, 3],
            [2, 3, 1, 4],
            [4, 2, 3, 1],
            [3, 1, 4, 2],
          ]),
          _blocksPlaceItem(1, 4, [4, 2, 3, 1], [2, 2, 3, 1], 4, [0, 6, 9, 15]),
        ],
      ),
      // とうめいな はこ (すう字): 2 bai mau theo sach (trang 7-8)
      ...SegBoxEngine.samples(),
    ];
  }

  static List<List<int>> _randomBalls(Random r, int count) {
    final cells = List<int>.generate(8, (i) => i)..shuffle(r);
    final chosen = cells.take(count).toList();
    final dark = r.nextInt(count);
    return [
      for (var i = 0; i < chosen.length; i++)
        [chosen[i] & 1, (chosen[i] >> 1) & 1, (chosen[i] >> 2) & 1, i == dark ? 1 : 0],
    ];
  }

  static const List<String> _coneKeys = ['cone', 'bowl', 'cone_sq', 'cone_hx', 'cone_tr'];

  static ViewItem _randomCone(Random r) {
    final pool = <double>[0.14, 0.26, 0.38, 0.50, 0.62, 0.74]..shuffle(r);
    final rws = [
      for (final x in pool.take(4)) double.parse((x + (r.nextDouble() - 0.5) * 0.04).toStringAsFixed(2)),
    ];
    return _coneItem(_coneKeys[r.nextInt(_coneKeys.length)], rws);
  }

  static const List<String> _linearKeys = ['ls3a', 'ls3b', 'ls4a', 'ramp'];

  static ViewItem _randomLinear(Random r) {
    final key = _linearKeys[r.nextInt(_linearKeys.length)];
    if (key == 'ramp') {
      final pool = <double>[0.16, 0.30, 0.44, 0.58, 0.72, 0.86]..shuffle(r);
      final xs = [
        for (final x in pool.take(4)) double.parse((x + (r.nextDouble() - 0.5) * 0.04).toStringAsFixed(2)),
      ];
      return _linearItem(key, xs);
    }
    final edges = kLinearEdges[key]!;
    final n = edges.length;
    final states = List<int>.generate(n + 1, (i) => i)..shuffle(r);
    return _linearItem(key, [for (final s in states.take(4)) s < n ? edges[s] : 1.0]);
  }

  static ViewItem _randomStairs(Random r, int n) {
    final keys = [for (final k in kStairRadii.keys) if (kStairRadii[k]!.length == n) k];
    final key = keys[r.nextInt(keys.length)];
    final states = List<int>.generate(n + 1, (i) => i)..shuffle(r);
    return _stairItem(key, states.take(4).toList());
  }

  static ViewLesson generate(String kind, {int level = 1, Random? rng}) {
    final r = rng ?? Random();
    final int lv = level < 1 ? 1 : (level > 3 ? 3 : level);
    final id = 'vw_${DateTime.now().microsecondsSinceEpoch}';
    final title = {
      for (final e in baseNames[kind]!.entries) e.key: '${e.value} ✨',
    };
    if (kind == 'water') {
      // muc 1: non/bat/chop da giac; muc 2: 3 tang (tron, da giac, hon hop) hoac be bac thang thang/mat doc;
      // muc 3: 2 cau (4 tang + mot dang khac)
      ViewItem mid(Random q) => q.nextBool() ? _randomStairs(q, 3) : _randomLinear(q);
      final items = <ViewItem>[
        if (lv == 1) _randomCone(r),
        if (lv == 2) mid(r),
        if (lv == 3) ...[
          _randomStairs(r, 4),
          [_randomCone, _randomLinear, mid][r.nextInt(3)](r),
        ],
      ];
      return ViewLesson(
        id: id,
        title: title,
        question: questionFor('water'),
        kind: 'water',
        difficulty: lv,
        isAutoGenerated: true,
        items: items,
      );
    }
    if (kind == 'segbox') return SegBoxEngine.generate(level: lv, rng: r);
    if (kind == 'box') {
      // muc 1: 1 cau 2 bong; muc 2: 2 cau 3 bong; muc 3: 2 cau 4 bong, them huong nhin tu truoc
      final views = lv == 3 ? ['top', 'right', 'front'] : ['top', 'right'];
      final nItems = lv == 1 ? 1 : 2;
      final nBalls = lv + 1;
      return ViewLesson(
        id: id,
        title: title,
        question: questionFor('box'),
        kind: 'box',
        difficulty: lv,
        isAutoGenerated: true,
        items: [for (var i = 0; i < nItems; i++) _boxItem(i, _randomBalls(r, nBalls), views)],
      );
    }
    if (kind == 'blocks') {
      // muc 1: 3x3; muc 2: 4x4 (nhu sach); muc 3: 5x5.
      // Mot nua so bai la dang so (dem khoi), nua con lai la dang mau (dem khoi roi dat khoi theo so da cho)
      final n = lv + 2;
      if (r.nextBool()) {
        return ViewLesson(
          id: id,
          title: title,
          question: questionFor('blocks', n: n),
          kind: 'blocks',
          difficulty: lv,
          isAutoGenerated: true,
          items: [_blocksItem(_latin(r, n))],
        );
      }
      final place = _randomPlaceItem(r, n, 1);
      return ViewLesson(
        id: id,
        title: title,
        question: questionFor('blocks', n: n, color: true),
        kind: 'blocks',
        difficulty: lv,
        isAutoGenerated: true,
        items: [
          _blocksColorItem(0, _latin(r, n)),
          if (place != null) place,
        ],
      );
    }
    final count = lv == 1 ? 2 : (lv == 2 ? 3 : 4);
    // Chon 6 vat tu toan bo kho (vat cua bai mau + vat bo sung), roi chon cac vat can doan trong 6 vat do
    final all = [...objects, ...extraObjects]..shuffle(r);
    final bank = all.take(6).toList();
    final pick = List<String>.from(bank)..shuffle(r);
    return ViewLesson(
      id: id,
      title: title,
      question: questionFor('shadow'),
      kind: 'shadow',
      difficulty: lv,
      isAutoGenerated: true,
      items: [for (var i = 0; i < count; i++) _shadowItem(i, pick[i])],
      bank: bank,
    );
  }
}
