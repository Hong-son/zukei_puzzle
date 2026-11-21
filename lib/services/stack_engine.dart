import 'dart:math';
import '../models/stack_lesson.dart';

// Engine cho 4 dang bai xuc xac xep chong / xep hang.
//
//  stack  : chong 2-4 vien (moi vien huong khac nhau), co the dan tem. Hoi tong cham nhin thay.
//  same   : cac vien cung huong, xep thanh khoi nho. Hoi tong cham nhin thay.
//  line   : xep hang ngang, hai mat cham nhau co so cham bang nhau. Hoi mat nhin tu ben trai / tong cham.
//  around : giong same nhung khoi lon hon (co the co tem).
//
// Luat chung: hai mat doi dien cong lai bang 7. Mat cham san hoac cham vien khac khong nhin thay.
// Moi bai tu sinh duoc kiem tra de dap an LUON suy ra duoc duy nhat chi bang luat "doi dien = 7".
class StackEngine {
  static const List<String> kinds = ['stack', 'same', 'line', 'around'];

  // Chieu nhin: tranh ve dang oblique, chieu sau y ve phia sau di len tren-sang phai (k, -k).
  // Tia tu mat vat ve phia nguoi xem di theo (k, -1, k).
  static const double depthK = 0.42;

  static List<List<int>>? _validCache;
  static List<List<int>>? _relaxedCache;

  // 24 huong hop le cua mot vien xuc xac that (bo ba [tren, truoc, phai]).
  static List<List<int>> validTriples() {
    final cached = _validCache;
    if (cached != null) return cached;
    // trang thai = [tren, truoc, phai, duoi, sau, trai]
    final seen = <String>{};
    final queue = <List<int>>[
      [1, 2, 3, 6, 5, 4]
    ];
    final result = <List<int>>[];
    while (queue.isNotEmpty) {
      final s = queue.removeLast();
      final key = s.join(',');
      if (!seen.add(key)) continue;
      result.add([s[0], s[1], s[2]]);
      // quay quanh truc dung: mat phai ve phia truoc
      queue.add([s[0], s[2], s[4], s[3], s[5], s[1]]);
      // lat ve phia truoc: mat tren xuong phia truoc
      queue.add([s[4], s[0], s[2], s[1], s[3], s[5]]);
    }
    _validCache = result;
    return result;
  }

  // 48 bo ba chi can thoa "3 so khac nhau, khong co 2 so nao doi dien" (bo qua chieu xoay).
  // Dung de kiem tra bai chi giai duoc bang luat "doi dien = 7", khong can biet quy uoc xoay.
  static List<List<int>> relaxedTriples() {
    final cached = _relaxedCache;
    if (cached != null) return cached;
    final res = <List<int>>[];
    for (int a = 1; a <= 6; a++) {
      for (int b = 1; b <= 6; b++) {
        for (int c = 1; c <= 6; c++) {
          if (a == b || a == c || b == c) continue;
          if (a + b == 7 || a + c == 7 || b + c == 7) continue;
          res.add([a, b, c]);
        }
      }
    }
    _relaxedCache = res;
    return res;
  }

  static int _key(int x, int y, int z) => x * 10000 + y * 100 + z;

  static Set<int> cellSet(List<List<int>> cells) {
    final s = <int>{};
    for (final c in cells) {
      s.add(_key(c[0], c[1], c[2]));
    }
    return s;
  }

  // Cac mat lo ra (khong cham san, khong cham vien khac): [tren, truoc, phai, sau, trai]
  static List<bool> exposure(List<int> c, Set<int> set) {
    final x = c[0];
    final y = c[1];
    final z = c[2];
    return [
      !set.contains(_key(x, y, z + 1)),
      !set.contains(_key(x, y - 1, z)),
      !set.contains(_key(x + 1, y, z)),
      !set.contains(_key(x, y + 1, z)),
      !set.contains(_key(x - 1, y, z)),
    ];
  }

  // Tong cham cac mat lo ra cua mot vien co huong t = [tren, truoc, phai]
  static int dieSum(List<int> c, Set<int> set, List<int> t) {
    final e = exposure(c, set);
    int s = 0;
    if (e[0]) s += t[0];
    if (e[1]) s += t[1];
    if (e[2]) s += t[2];
    if (e[3]) s += 7 - t[1];
    if (e[4]) s += 7 - t[2];
    return s;
  }

  static int answer(StackLesson l) {
    if (l.ask == 'left') {
      int best = 0;
      for (int i = 1; i < l.cells.length; i++) {
        if (l.cells[i][0] < l.cells[best][0]) best = i;
      }
      return 7 - l.faces[best][2];
    }
    final set = cellSet(l.cells);
    int total = 0;
    for (int i = 0; i < l.cells.length; i++) {
      total += dieSum(l.cells[i], set, l.faces[i]);
    }
    return total;
  }

  static bool _consistent(List<int> t, List<int> truth, List<bool> visible, List<bool> covered) {
    for (int p = 0; p < 3; p++) {
      if (visible[p] && !covered[p] && t[p] != truth[p]) return false;
    }
    return true;
  }

  // Tap cac dap an co the co, biet chi nhung gi nhin thay (khong tinh mat bi tem) va luat "doi dien = 7".
  // Bai hop le khi tap nay chi co dung 1 phan tu = answer(l).
  static Set<int> possibleAnswers(StackLesson l) {
    final cells = l.cells;
    final n = cells.length;
    final set = cellSet(cells);
    final all = relaxedTriples();
    final visList = <List<bool>>[];
    for (int i = 0; i < n; i++) {
      final e = exposure(cells[i], set);
      visList.add([e[0], e[1], e[2]]);
    }
    final cands = <List<List<int>>>[];
    for (int i = 0; i < n; i++) {
      final list = <List<int>>[];
      for (final t in all) {
        if (_consistent(t, l.faces[i], visList[i], l.covered[i])) list.add(t);
      }
      cands.add(list);
    }

    if (l.kind == 'stack') {
      // moi vien doc lap
      var cur = <int>{0};
      for (int i = 0; i < n; i++) {
        final next = <int>{};
        for (final t in cands[i]) {
          final s = dieSum(cells[i], set, t);
          for (final a in cur) {
            next.add(a + s);
          }
        }
        cur = next;
      }
      return cur;
    }

    final answers = <int>{};
    if (l.kind == 'same' || l.kind == 'around') {
      // moi vien cung mot huong
      for (final t in all) {
        bool ok = true;
        for (int i = 0; i < n; i++) {
          if (!_consistent(t, l.faces[i], visList[i], l.covered[i])) {
            ok = false;
            break;
          }
        }
        if (!ok) continue;
        int total = 0;
        for (int i = 0; i < n; i++) {
          total += dieSum(cells[i], set, t);
        }
        answers.add(total);
      }
      return answers;
    }

    // line: mat phai cua vien i = mat trai cua vien i+1  =>  phai[i+1] = 7 - phai[i]
    final chain = <List<int>>[];
    void dfs(int i) {
      if (i == n) {
        if (l.ask == 'left') {
          answers.add(7 - chain[0][2]);
        } else {
          int total = 0;
          for (int k = 0; k < n; k++) {
            total += dieSum(cells[k], set, chain[k]);
          }
          answers.add(total);
        }
        return;
      }
      for (final t in cands[i]) {
        if (i > 0 && t[2] != 7 - chain[i - 1][2]) continue;
        chain.add(t);
        dfs(i + 1);
        chain.removeLast();
      }
    }

    dfs(0);
    return answers;
  }

  // Moi mat lo ra o huong nhin thay (tren / truoc / phai) phai nhin thay TRON VEN trong hinh,
  // khong bi vien khac che mot phan.
  static bool fullyVisible(List<List<int>> cells) {
    final set = cellSet(cells);
    int maxX = 0;
    int maxZ = 0;
    for (final c in cells) {
      if (c[0] > maxX) maxX = c[0];
      if (c[2] > maxZ) maxZ = c[2];
    }
    const samples = [0.25, 0.75];
    for (final c in cells) {
      final e = exposure(c, set);
      for (int face = 0; face < 3; face++) {
        if (!e[face]) continue;
        for (final u in samples) {
          for (final v in samples) {
            double px;
            double py;
            double pz;
            if (face == 0) {
              px = c[0] + u;
              py = c[1] + v;
              pz = c[2] + 1.0;
            } else if (face == 1) {
              px = c[0] + u;
              py = c[1].toDouble();
              pz = c[2] + v;
            } else {
              px = c[0] + 1.0;
              py = c[1] + u;
              pz = c[2] + v;
            }
            if (_blocked(set, px, py, pz, maxX, maxZ)) return false;
          }
        }
      }
    }
    return true;
  }

  static bool _blocked(Set<int> set, double x0, double y0, double z0, int maxX, int maxZ) {
    for (int step = 1; step < 900; step++) {
      final t = step * 0.01;
      final x = x0 + depthK * t;
      final y = y0 - t;
      final z = z0 + depthK * t;
      if (y < -1.0 || x > maxX + 2.0 || z > maxZ + 2.0) return false;
      if (set.contains(_key(x.floor(), y.floor(), z.floor()))) return true;
    }
    return false;
  }

  // heights[y][x] = so vien xep chong tai cot (x, y); y = 0 la hang truoc.
  static List<List<int>> cellsFromHeights(List<List<int>> h) {
    final cells = <List<int>>[];
    for (int y = 0; y < h.length; y++) {
      for (int x = 0; x < h[y].length; x++) {
        for (int z = 0; z < h[y][x]; z++) {
          cells.add([x, y, z]);
        }
      }
    }
    return cells;
  }

  static bool _connected(List<List<int>> h) {
    final d = h.length;
    final w = h[0].length;
    int start = -1;
    int count = 0;
    for (int y = 0; y < d; y++) {
      for (int x = 0; x < w; x++) {
        if (h[y][x] > 0) {
          count++;
          if (start < 0) start = y * w + x;
        }
      }
    }
    if (count == 0) return false;
    final seen = <int>{start};
    final stack = <int>[start];
    const dirs = [
      [1, 0],
      [-1, 0],
      [0, 1],
      [0, -1]
    ];
    while (stack.isNotEmpty) {
      final cur = stack.removeLast();
      final cy = cur ~/ w;
      final cx = cur % w;
      for (final dir in dirs) {
        final ny = cy + dir[1];
        final nx = cx + dir[0];
        if (ny < 0 || ny >= d || nx < 0 || nx >= w) continue;
        if (h[ny][nx] <= 0) continue;
        if (seen.add(ny * w + nx)) stack.add(ny * w + nx);
      }
    }
    return seen.length == count;
  }

  static List<List<int>>? _randomHeights(Random rng, int minDice, int maxDice) {
    for (int attempt = 0; attempt < 300; attempt++) {
      final w = 1 + rng.nextInt(4);
      final d = 1 + rng.nextInt(3);
      final hmax = 1 + rng.nextInt(3);
      final h = List.generate(d, (_) => List.generate(w, (_) => rng.nextInt(hmax + 1)));
      int total = 0;
      for (final row in h) {
        for (final v in row) {
          total += v;
        }
      }
      if (total < minDice || total > maxDice) continue;
      if (!_connected(h)) continue;
      if (!fullyVisible(cellsFromHeights(h))) continue;
      return h;
    }
    return null;
  }

  static List<int> _randTriple(Random rng) {
    final v = validTriples();
    final t = v[rng.nextInt(v.length)];
    return [t[0], t[1], t[2]];
  }

  // ---------------------------------------------------------------- chu va de bai

  static const Map<String, Map<String, String>> baseNames = {
    'stack': {'ja': 'さいころを つみ上げて', 'en': 'Stacked Dice', 'vi': 'Xếp chồng xúc xắc'},
    'same': {'ja': 'おなじ むきに つむ', 'en': 'Same Direction', 'vi': 'Xếp cùng chiều'},
    'line': {'ja': 'おなじ 目を かさねて ならべる', 'en': 'Matching Faces in a Row', 'vi': 'Xếp hàng mặt giống nhau'},
    'around': {'ja': 'まわりから 見える 目', 'en': 'Visible Pips', 'vi': 'Tổng chấm nhìn thấy'},
  };

  static Map<String, String> titleFor(String kind, int number, int n) {
    final b = baseNames[kind]!;
    return {
      'ja': '${b['ja']} $number（${n}こ）',
      'en': '${b['en']} $number ($n)',
      'vi': '${b['vi']} $number ($n viên)',
    };
  }

  static Map<String, String> questionFor(String kind, String ask, int n, bool sticker) {
    final stJa = sticker ? 'シールが はってあって 見えない 目が あります。シールを はがした ときに ' : '';
    final stEn = sticker ? 'Some faces are covered by stickers; imagine peeling them off. ' : '';
    final stVi = sticker ? 'Một số mặt bị dán tem che; hãy tưởng tượng bóc tem ra. ' : '';
    switch (kind) {
      case 'stack':
        return {
          'ja': 'さいころを ${n}こ つみ上げます。${stJa}まわりから 見える 目を ぜんぶ あわせると いくつに なりますか。',
          'en': 'Stack $n dice. ${stEn}What is the total of all the pips you can see from around the stack?',
          'vi': 'Xếp chồng $n viên xúc xắc. ${stVi}Tổng số chấm nhìn thấy được từ xung quanh là bao nhiêu?',
        };
      case 'same':
        return {
          'ja': 'なんこかの さいころを ぜんぶ おなじ むきに つみ上げます。${stJa}まわりから 見える 目を ぜんぶ あわせると いくつに なりますか。',
          'en': 'Several dice are stacked, all facing the same way. ${stEn}What is the total of all the pips you can see from around?',
          'vi': 'Nhiều viên xúc xắc được xếp chồng, tất cả cùng một chiều. ${stVi}Tổng số chấm nhìn thấy được từ xung quanh là bao nhiêu?',
        };
      case 'line':
        if (ask == 'left') {
          return {
            'ja': 'さいころを ${n}こ、おなじ 目が かさなるように ならべます。左から 見える 目は いくつですか。',
            'en': 'Line up $n dice so that touching faces show the same number of pips. How many pips can you see from the left end?',
            'vi': 'Xếp hàng $n viên xúc xắc sao cho hai mặt chạm nhau có số chấm bằng nhau. Nhìn từ đầu bên trái, thấy mấy chấm?',
          };
        }
        return {
          'ja': 'さいころを ${n}こ、おなじ 目が かさなるように ならべます。${stJa}まわりから 見える 目を ぜんぶ あわせると いくつに なりますか。',
          'en': 'Line up $n dice so that touching faces show the same number of pips. ${stEn}What is the total of all the pips you can see from around?',
          'vi': 'Xếp hàng $n viên xúc xắc sao cho hai mặt chạm nhau có số chấm bằng nhau. ${stVi}Tổng số chấm nhìn thấy được từ xung quanh là bao nhiêu?',
        };
      default:
        return {
          'ja': 'なんこかの さいころを ぜんぶ おなじ むきに つみ上げたり ならべたり します。${stJa}まわりから 見える 目を ぜんぶ あわせると いくつに なりますか。',
          'en': 'Several dice are stacked and lined up, all facing the same way. ${stEn}What is the total of all the pips you can see from around?',
          'vi': 'Nhiều viên xúc xắc được xếp chồng và xếp hàng, tất cả cùng một chiều. ${stVi}Tổng số chấm nhìn thấy được từ xung quanh là bao nhiêu?',
        };
    }
  }

  // ---------------------------------------------------------------- sinh bai

  static StackLesson? _tryGenerate(String kind, int lv, Random rng) {
    List<List<int>> cells;
    final faces = <List<int>>[];
    final covered = <List<bool>>[];
    String ask = 'around';

    if (kind == 'stack') {
      // bai tu sinh: so tang tang theo do kho (bai mau thi theo dung sach: 2 tang)
      final int n = lv == 1 ? 2 : (lv == 2 ? 3 : 2 + rng.nextInt(3));
      cells = [
        for (int z = 0; z < n; z++) [0, 0, z]
      ];
      for (int i = 0; i < n; i++) {
        faces.add(_randTriple(rng));
        covered.add([false, lv >= 2 && rng.nextDouble() < 0.6, lv >= 2 && rng.nextDouble() < 0.6]);
      }
      if (lv >= 2) {
        bool any = false;
        for (final c in covered) {
          if (c.contains(true)) any = true;
        }
        if (!any) covered[0][1] = true;
      }
    } else if (kind == 'same' || kind == 'around') {
      final List<int> range;
      if (kind == 'same') {
        range = lv == 1 ? [2, 4] : (lv == 2 ? [4, 6] : [6, 8]);
      } else {
        range = lv == 1 ? [5, 7] : (lv == 2 ? [7, 9] : [9, 12]);
      }
      final h = _randomHeights(rng, range[0], range[1]);
      if (h == null) return null;
      cells = cellsFromHeights(h);
      final t = _randTriple(rng);
      final stickers = kind == 'around' && lv == 3;
      for (int i = 0; i < cells.length; i++) {
        faces.add([t[0], t[1], t[2]]);
        covered.add([
          stickers && rng.nextDouble() < 0.2,
          stickers && rng.nextDouble() < 0.2,
          stickers && rng.nextDouble() < 0.2,
        ]);
      }
    } else {
      final n = lv == 1 ? 2 : (lv == 2 ? 3 : 4 + rng.nextInt(2));
      ask = (lv == 1 || rng.nextBool()) ? 'left' : 'around';
      cells = [
        for (int i = 0; i < n; i++) [i, 0, 0]
      ];
      final valid = validTriples();
      for (int i = 0; i < n; i++) {
        if (i == 0) {
          faces.add(_randTriple(rng));
        } else {
          final need = 7 - faces[i - 1][2];
          final options = [
            for (final t in valid)
              if (t[2] == need) t
          ];
          final t = options[rng.nextInt(options.length)];
          faces.add([t[0], t[1], t[2]]);
        }
        final last = i == n - 1;
        covered.add([false, rng.nextDouble() < 0.65, last && ask == 'around' && rng.nextDouble() < 0.4]);
      }
    }

    bool sticker = false;
    for (final c in covered) {
      if (c.contains(true)) sticker = true;
    }
    final id = 'stk_${DateTime.now().microsecondsSinceEpoch}';
    return StackLesson(
      id: id,
      title: titleFor(kind, 0, cells.length),
      question: questionFor(kind, ask, cells.length, sticker),
      kind: kind,
      ask: ask,
      cells: cells,
      faces: faces,
      covered: covered,
      difficulty: lv,
      isAutoGenerated: true,
    );
  }

  static StackLesson generate(String kind, {int? level}) {
    final rng = Random();
    final lv = level ?? (1 + rng.nextInt(3));
    for (int i = 0; i < 500; i++) {
      final l = _tryGenerate(kind, lv, rng);
      if (l == null) continue;
      final p = possibleAnswers(l);
      if (p.length == 1 && p.first == answer(l)) return l;
    }
    final s = samples(kind)[0];
    return StackLesson(
      id: 'stk_${DateTime.now().microsecondsSinceEpoch}',
      title: s.title,
      question: s.question,
      kind: s.kind,
      ask: s.ask,
      cells: s.cells,
      faces: s.faces,
      covered: s.covered,
      difficulty: s.difficulty,
      isAutoGenerated: true,
    );
  }

  // ---------------------------------------------------------------- bai mau

  static StackLesson _sample({
    required String id,
    required String kind,
    required int number,
    required String ask,
    required List<List<int>> cells,
    required List<List<int>> faces,
    required List<List<bool>> covered,
    required int difficulty,
  }) {
    bool sticker = false;
    for (final c in covered) {
      if (c.contains(true)) sticker = true;
    }
    return StackLesson(
      id: id,
      title: titleFor(kind, number, cells.length),
      question: questionFor(kind, ask, cells.length, sticker),
      kind: kind,
      ask: ask,
      cells: cells,
      faces: faces,
      covered: covered,
      difficulty: difficulty,
    );
  }

  static List<List<bool>> _noStickers(int n) => [
        for (int i = 0; i < n; i++) [false, false, false]
      ];

  static List<List<int>> _same(int n, List<int> t) => [
        for (int i = 0; i < n; i++) [t[0], t[1], t[2]]
      ];

  static List<StackLesson>? _samplesCache;

  static List<StackLesson> samples(String kind) {
    var all = _samplesCache;
    if (all == null) {
      all = <StackLesson>[
        // Cac bai mau duoi day bam theo 4 to bai tap (moi to 4 bai).
        _sample(
          id: 'ST001',
          kind: 'stack',
          number: 1,
          ask: 'around',
          cells: [[0, 0, 0], [0, 0, 1]],
          faces: [[1, 2, 3], [1, 2, 3]],
          covered: _noStickers(2),
          difficulty: 1,
        ),
        _sample(
          id: 'ST002',
          kind: 'stack',
          number: 2,
          ask: 'around',
          cells: [[0, 0, 0], [0, 0, 1]],
          faces: [[3, 2, 6], [3, 2, 6]],
          covered: _noStickers(2),
          difficulty: 1,
        ),
        _sample(
          id: 'ST003',
          kind: 'stack',
          number: 3,
          ask: 'around',
          cells: [[0, 0, 0], [0, 0, 1]],
          faces: [[4, 2, 1], [5, 3, 6]],
          covered: [[false, true, false], [false, false, true]],
          difficulty: 2,
        ),
        _sample(
          id: 'ST004',
          kind: 'stack',
          number: 4,
          ask: 'around',
          cells: [[0, 0, 0], [0, 0, 1]],
          faces: [[1, 2, 3], [2, 1, 4]],
          covered: [[false, true, true], [false, true, true]],
          difficulty: 2,
        ),
        _sample(
          id: 'SM001',
          kind: 'same',
          number: 1,
          ask: 'around',
          cells: cellsFromHeights([[3]]),
          faces: _same(3, [3, 5, 1]),
          covered: _noStickers(3),
          difficulty: 1,
        ),
        _sample(
          id: 'SM002',
          kind: 'same',
          number: 2,
          ask: 'around',
          cells: cellsFromHeights([[2, 2]]),
          faces: _same(4, [3, 5, 1]),
          covered: _noStickers(4),
          difficulty: 1,
        ),
        _sample(
          id: 'SM003',
          kind: 'same',
          number: 3,
          ask: 'around',
          cells: cellsFromHeights([[1, 2]]),
          faces: _same(3, [3, 5, 1]),
          covered: _noStickers(3),
          difficulty: 1,
        ),
        _sample(
          id: 'SM004',
          kind: 'same',
          number: 4,
          ask: 'around',
          cells: cellsFromHeights([[2, 2, 1]]),
          faces: _same(5, [3, 5, 1]),
          covered: _noStickers(5),
          difficulty: 2,
        ),
        _sample(
          id: 'LN001',
          kind: 'line',
          number: 1,
          ask: 'left',
          cells: [[0, 0, 0], [1, 0, 0]],
          faces: [[1, 4, 2], [1, 3, 5]],
          covered: [[false, false, false], [false, true, false]],
          difficulty: 1,
        ),
        _sample(
          id: 'LN002',
          kind: 'line',
          number: 2,
          ask: 'left',
          cells: [[0, 0, 0], [1, 0, 0]],
          faces: [[1, 2, 3], [1, 5, 4]],
          covered: [[false, true, false], [true, false, false]],
          difficulty: 1,
        ),
        _sample(
          id: 'LN003',
          kind: 'line',
          number: 3,
          ask: 'left',
          cells: [[0, 0, 0], [1, 0, 0], [2, 0, 0], [3, 0, 0], [4, 0, 0]],
          faces: [[1, 3, 5], [4, 6, 2], [1, 3, 5], [3, 1, 2], [1, 3, 5]],
          covered: [[false, true, false], [false, true, false], [false, true, false], [false, true, false], [false, true, false]],
          difficulty: 3,
        ),
        _sample(
          id: 'LN004',
          kind: 'line',
          number: 4,
          ask: 'around',
          cells: [[0, 0, 0], [1, 0, 0], [2, 0, 0]],
          faces: [[1, 2, 3], [2, 1, 4], [6, 5, 3]],
          covered: [[false, true, false], [false, true, false], [false, true, false]],
          difficulty: 2,
        ),
        _sample(
          id: 'AR001',
          kind: 'around',
          number: 1,
          ask: 'around',
          cells: cellsFromHeights([[2, 1, 3]]),
          faces: _same(6, [1, 2, 3]),
          covered: _noStickers(6),
          difficulty: 1,
        ),
        _sample(
          id: 'AR002',
          kind: 'around',
          number: 2,
          ask: 'around',
          cells: cellsFromHeights([[0, 1, 0], [1, 1, 2]]),
          faces: _same(5, [1, 2, 3]),
          covered: _noStickers(5),
          difficulty: 2,
        ),
        _sample(
          id: 'AR003',
          kind: 'around',
          number: 3,
          ask: 'around',
          cells: cellsFromHeights([[1, 2], [2, 1]]),
          faces: _same(6, [1, 2, 3]),
          covered: _noStickers(6),
          difficulty: 2,
        ),
        _sample(
          id: 'AR004',
          kind: 'around',
          number: 4,
          ask: 'around',
          cells: cellsFromHeights([[1, 1, 1], [1, 0, 1], [2, 1, 2]]),
          faces: _same(10, [1, 2, 3]),
          covered: _noStickers(10),
          difficulty: 3,
        ),
      ];
      _samplesCache = all;
    }
    return [
      for (final s in all)
        if (s.kind == kind) s
    ];
  }

  // ---------------------------------------------------------------- goi y

  static String wrongMessage(StackLesson l, String lang) {
    if (l.kind == 'line') {
      return lang == 'ja'
          ? 'ちがうよ。くっついている 面は おなじ 目、むかいあう 面は あわせて 7 だよ'
          : lang == 'en'
              ? 'Not quite. Touching faces are equal; opposite faces add up to 7'
              : 'Chưa đúng. Mặt chạm nhau bằng nhau; hai mặt đối nhau cộng bằng 7';
    }
    return lang == 'ja'
        ? 'ちがうよ。むかいあう 面は あわせて 7。ゆかや となりに くっついている 面は 見えないよ'
        : lang == 'en'
            ? 'Not quite. Opposite faces add up to 7. Faces touching the floor or another die are hidden'
            : 'Chưa đúng. Hai mặt đối nhau cộng bằng 7. Mặt chạm sàn hoặc chạm viên khác thì không thấy';
  }

  static String hint(StackLesson l, String lang, int level) {
    final n = l.cells.length;
    if (l.kind == 'stack') {
      final top = l.faces[n - 1][0];
      if (level <= 1) {
        return lang == 'ja'
            ? '💡 むかいあう 面の 目は あわせて 7。さいころ 1この まわりの 4つの 面は むかいあう 2くみ だから 7 + 7 = 14 だよ'
            : lang == 'en'
                ? '💡 Opposite faces add up to 7. The 4 side faces of one die are 2 opposite pairs, so they make 7 + 7 = 14'
                : '💡 Hai mặt đối nhau cộng bằng 7. 4 mặt bên của một viên là 2 cặp đối nhau nên cộng lại 7 + 7 = 14';
      }
      return lang == 'ja'
          ? '💡 14 × $n（さいころの かず）+ いちばん 上の 面（$top）を けいさんしよう'
          : lang == 'en'
              ? '💡 Work out 14 × $n (number of dice) + the top face ($top)'
              : '💡 Hãy tính 14 × $n (số viên) + mặt trên cùng ($top)';
    }

    if (l.kind == 'line') {
      if (level <= 1) {
        return lang == 'ja'
            ? '💡 となりあって くっついている 面は おなじ 目。1この さいころの 左の 面と 右の 面は あわせて 7 だよ'
            : lang == 'en'
                ? '💡 Faces that touch show the same number. The left and right faces of one die add up to 7'
                : '💡 Hai mặt chạm nhau có số chấm bằng nhau. Mặt trái và mặt phải của một viên cộng bằng 7';
      }
      final rows = <String>[];
      for (int i = 0; i < n; i++) {
        final r = l.faces[i][2];
        final left = 7 - r;
        rows.add(lang == 'ja'
            ? '${i + 1}こめ: 左 $left・右 $r'
            : lang == 'en'
                ? 'die ${i + 1}: left $left, right $r'
                : 'viên ${i + 1}: trái $left, phải $r');
      }
      int tops = 0;
      for (final f in l.faces) {
        tops += f[0];
      }
      const head = '💡 ';
      if (l.ask == 'left') {
        return '$head${rows.join(' / ')}';
      }
      final tail = lang == 'ja'
          ? '。上の 面の ごうけい $tops、まえ + うしろ = 7 × $n'
          : lang == 'en'
              ? '. Tops add up to $tops; front + back = 7 × $n'
              : '. Tổng mặt trên $tops; trước + sau = 7 × $n';
      return '$head${rows.join(' / ')}$tail';
    }

    // same / around
    final t = l.faces[0];
    if (level <= 1) {
      return lang == 'ja'
          ? '💡 ぜんぶ おなじ むき。見えている 面の うらがわの 面（うしろ・左）も まわりから 見えるよ。むかいあう 面は あわせて 7'
          : lang == 'en'
              ? '💡 All dice face the same way. The faces on the back and left sides are also visible from around. Opposite faces add up to 7'
              : '💡 Tất cả cùng một chiều. Mặt sau và mặt trái cũng nhìn thấy được từ xung quanh. Hai mặt đối nhau cộng bằng 7';
    }
    final set = cellSet(l.cells);
    int nt = 0;
    int nf = 0;
    int nr = 0;
    int nb = 0;
    int nl = 0;
    for (final c in l.cells) {
      final e = exposure(c, set);
      if (e[0]) nt++;
      if (e[1]) nf++;
      if (e[2]) nr++;
      if (e[3]) nb++;
      if (e[4]) nl++;
    }
    final names = lang == 'ja'
        ? ['上の 面', '正面', '右の 面', 'うしろの 面', '左の 面']
        : lang == 'en'
            ? ['top', 'front', 'right', 'back', 'left']
            : ['mặt trên', 'mặt trước', 'mặt phải', 'mặt sau', 'mặt trái'];
    final counts = [nt, nf, nr, nb, nl];
    final values = [t[0], t[1], t[2], 7 - t[1], 7 - t[2]];
    final parts = <String>[];
    for (int i = 0; i < 5; i++) {
      if (counts[i] > 0) parts.add('${names[i]} ${counts[i]} × ${values[i]}');
    }
    final tail = lang == 'ja' ? ' を ぜんぶ たそう' : lang == 'en' ? ' — add them all up' : ' — hãy cộng tất cả lại';
    return '💡 ${parts.join(' + ')}$tail';
  }
}
