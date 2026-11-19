import 'dart:math';
import '../models/half_lesson.dart';

class HalfEngine {
  // Hinh vuong 4x4 = 16 don vi dien tich. Mot nua = 8, gap doi = 16.
  static const int halfDoubleArea = 16;

  static List<List<int>> _rect(int x1, int y1, int x2, int y2) => [
        [x1, y1],
        [x2, y1],
        [x2, y2],
        [x1, y2],
      ];

  static List<List<List<int>>> _checker(int parity) {
    final res = <List<List<int>>>[];
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        if ((r + c) % 2 == parity) res.add(_rect(c, r, c + 1, r + 1));
      }
    }
    return res;
  }

  // Cac hinh mau (tu thiet ke). Dien tich duoc tinh bang code, khong ghi tay.
  static final Map<String, List<List<List<int>>>> templates = {
    // ---- bang mot nua ----
    'top': [_rect(0, 0, 4, 2)],
    'diag': [
      [[0, 0], [4, 0], [0, 4]]
    ],
    'diamond': [
      [[2, 0], [4, 2], [2, 4], [0, 2]]
    ],
    'slant': [
      [[0, 0], [4, 0], [4, 1], [0, 3]]
    ],
    'triDown': [
      [[0, 0], [4, 0], [2, 4]]
    ],
    'bowtie': [
      [[0, 0], [2, 2], [0, 4]],
      [[4, 0], [2, 2], [4, 4]],
    ],
    'arrows': [
      [[0, 0], [2, 2], [0, 4]],
      [[2, 0], [4, 2], [2, 4]],
    ],
    'stripes': [_rect(0, 0, 1, 4), _rect(2, 0, 3, 4)],
    'checker2': [_rect(0, 0, 2, 2), _rect(2, 2, 4, 4)],
    'checker4': _checker(0),
    // ---- khong bang mot nua ----
    'diamondS': [
      [[2, 1], [3, 2], [2, 3], [1, 2]]
    ],
    'quarter': [_rect(0, 0, 2, 2)],
    'triSmall': [
      [[0, 0], [4, 0], [2, 2]]
    ],
    'triBig': [
      [[0, 0], [4, 0], [4, 3]]
    ],
    'lshape': [
      [[0, 0], [4, 0], [4, 1], [1, 1], [1, 4], [0, 4]]
    ],
    'threeQuarter': [
      [[0, 0], [4, 0], [4, 4], [2, 4], [2, 2], [0, 2]]
    ],
    'stripesPlus': [_rect(0, 0, 1, 4), _rect(2, 0, 3, 4), _rect(3, 0, 4, 1)],
    'oneArrow': [
      [[0, 0], [2, 2], [0, 4]]
    ],
  };

  // Dien tich gap doi (tong cac da giac, khong chong len nhau)
  static int area2(List<List<List<int>>> fig) {
    int total = 0;
    for (final poly in fig) {
      int s = 0;
      for (int i = 0; i < poly.length; i++) {
        final a = poly[i];
        final b = poly[(i + 1) % poly.length];
        s += a[0] * b[1] - b[0] * a[1];
      }
      total += s.abs();
    }
    return total;
  }

  static bool isHalf(List<List<List<int>>> fig) => area2(fig) == halfDoubleArea;

  static List<List<List<int>>> transform(List<List<List<int>>> fig, int rot, bool flip) {
    return fig
        .map((poly) => poly.map((p) {
              int x = p[0];
              int y = p[1];
              if (flip) x = 4 - x;
              for (int r = 0; r < rot; r++) {
                final nx = 4 - y;
                final ny = x;
                x = nx;
                y = ny;
              }
              return <int>[x, y];
            }).toList())
        .toList();
  }

  // 8 tam giac nho quanh tam hinh vuong, moi tam giac = 2 don vi dien tich
  static List<List<List<int>>> triSubset(List<int> idx) {
    const k = [
      [0, 0],
      [4, 0],
      [4, 4],
      [0, 4]
    ];
    const m = [
      [2, 0],
      [4, 2],
      [2, 4],
      [0, 2]
    ];
    final res = <List<List<int>>>[];
    for (final t in idx) {
      final i = t ~/ 2;
      final second = t % 2 == 1;
      final List<int> a = second ? m[i] : k[i];
      final List<int> b = second ? k[(i + 1) % 4] : m[i];
      res.add([
        [2, 2],
        [a[0], a[1]],
        [b[0], b[1]],
      ]);
    }
    return res;
  }

  static List<List<List<int>>> randomFigure(Random rng, bool wantHalf) {
    if (rng.nextBool()) {
      final names = templates.keys.where((n) => isHalf(templates[n]!) == wantHalf).toList();
      final name = names[rng.nextInt(names.length)];
      return transform(templates[name]!, rng.nextInt(4), rng.nextBool());
    }
    final nonHalf = [2, 3, 5, 6];
    final k = wantHalf ? 4 : nonHalf[rng.nextInt(nonHalf.length)];
    final idx = List<int>.generate(8, (i) => i)..shuffle(rng);
    return triSubset(idx.sublist(0, k));
  }

  static const Map<String, String> question = {
    'ja': 'ましかくに いろを ぬって、もようを つくりました。ぬった ぶぶんが ましかくの はんぶんの ひろさに なっている もようを ぜんぶ えらんで、( ) に ○を かきましょう。',
    'en': 'Each square is partly coloured. Tap every pattern whose coloured part is exactly half of the square and mark it with ○.',
    'vi': 'Mỗi hình vuông được tô màu một phần. Hãy chọn tất cả hình có phần tô màu đúng bằng một nửa hình vuông và đánh dấu ○.',
  };

  // Bai mau: ghep tu cac hinh mau theo ten
  static HalfLesson fromNames({
    required String id,
    required Map<String, String> title,
    required List<String> names,
    required int difficulty,
  }) {
    return HalfLesson(
      id: id,
      title: title,
      question: question,
      figures: names.map((n) => templates[n]!).toList(),
      difficulty: difficulty,
    );
  }

  static HalfLesson generate({int? level}) {
    final rng = Random();
    final lv = level ?? (1 + rng.nextInt(3));
    final n = lv == 1 ? 6 : (lv == 2 ? 8 : 12);
    final halves = n ~/ 2 + rng.nextInt(3) - 1;
    final flags = List<bool>.generate(n, (i) => i < halves)..shuffle(rng);
    final figs = flags.map((h) => randomFigure(rng, h)).toList();
    return HalfLesson(
      id: 'half_${DateTime.now().millisecondsSinceEpoch}',
      title: {
        'ja': 'はんぶんだけぬる じどう',
        'en': 'Paint Half (auto)',
        'vi': 'Tô một nửa (tự động)',
      },
      question: question,
      figures: figs,
      difficulty: lv,
      isAutoGenerated: true,
    );
  }
}
