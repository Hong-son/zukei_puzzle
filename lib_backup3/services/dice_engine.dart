import 'dart:math';
import '../models/dice_lesson.dart';

class DiceEngine {
  static const dirs = <String, List<int>>{
    'N': [-1, 0],
    'S': [1, 0],
    'W': [0, -1],
    'E': [0, 1],
  };
  static const opp = <String, String>{
    'top': 'bottom',
    'bottom': 'top',
    'N': 'S',
    'S': 'N',
    'W': 'E',
    'E': 'W',
  };

  static Map<String, String> _roll(Map<String, String> o, String d) {
    if (d == 'E') {
      return {'bottom': o['E']!, 'E': o['top']!, 'top': o['W']!, 'W': o['bottom']!, 'N': o['N']!, 'S': o['S']!};
    }
    if (d == 'W') {
      return {'bottom': o['W']!, 'W': o['top']!, 'top': o['E']!, 'E': o['bottom']!, 'N': o['N']!, 'S': o['S']!};
    }
    if (d == 'N') {
      return {'bottom': o['N']!, 'N': o['top']!, 'top': o['S']!, 'S': o['bottom']!, 'W': o['W']!, 'E': o['E']!};
    }
    return {'bottom': o['S']!, 'S': o['top']!, 'top': o['N']!, 'N': o['bottom']!, 'W': o['W']!, 'E': o['E']!};
  }

  // Gap hinh khai trien: tra ve face cua tung o (index theo cells), null neu khong hop le.
  static List<String>? fold(List<List<int>> cells) {
    final index = <String, int>{};
    for (int i = 0; i < cells.length; i++) {
      index['${cells[i][0]}_${cells[i][1]}'] = i;
    }
    final start = {for (final k in ['top', 'bottom', 'N', 'S', 'W', 'E']) k: k};
    final state = <int, Map<String, String>>{0: start};
    final faces = <int, String>{0: start['bottom']!};
    final queue = <int>[0];
    while (queue.isNotEmpty) {
      final cur = queue.removeAt(0);
      for (final e in dirs.entries) {
        final nr = cells[cur][0] + e.value[0];
        final nc = cells[cur][1] + e.value[1];
        final nb = index['${nr}_$nc'];
        if (nb != null && !state.containsKey(nb)) {
          state[nb] = _roll(state[cur]!, e.key);
          faces[nb] = state[nb]!['bottom']!;
          queue.add(nb);
        }
      }
    }
    if (faces.length != 6 || faces.values.toSet().length != 6) return null;
    return List.generate(6, (i) => faces[i]!);
  }

  // Cac cap chi so o la hai mat doi nhau.
  static List<List<int>> oppositePairs(List<List<int>> cells) {
    final faces = fold(cells);
    if (faces == null) return [];
    final byFace = {for (int i = 0; i < 6; i++) faces[i]: i};
    final seen = <int>{};
    final out = <List<int>>[];
    for (int i = 0; i < 6; i++) {
      if (seen.contains(i)) continue;
      final j = byFace[opp[faces[i]]]!;
      seen.add(i);
      seen.add(j);
      out.add([i, j]);
    }
    return out;
  }

  static List<List<int>> _normalize(List<List<int>> cells) {
    final minR = cells.map((c) => c[0]).reduce(min);
    final minC = cells.map((c) => c[1]).reduce(min);
    final out = cells.map((c) => [c[0] - minR, c[1] - minC]).toList();
    out.sort((a, b) => a[0] != b[0] ? a[0].compareTo(b[0]) : a[1].compareTo(b[1]));
    return out;
  }

  static String _key(List<List<int>> cells) =>
      cells.map((c) => '${c[0]}_${c[1]}').join(',');

  static List<List<List<int>>> _variants(List<List<int>> cells) {
    final fs = <List<int> Function(int, int)>[
      (r, c) => [r, c],
      (r, c) => [r, -c],
      (r, c) => [-r, c],
      (r, c) => [-r, -c],
      (r, c) => [c, r],
      (r, c) => [c, -r],
      (r, c) => [-c, r],
      (r, c) => [-c, -r],
    ];
    return fs.map((f) => _normalize(cells.map((p) => f(p[0], p[1])).toList())).toList();
  }

  static List<List<List<int>>>? _cache;

  // Sinh tat ca hexomino, loc ra 11 dang khai trien hop le.
  static List<List<List<int>>> nets() {
    if (_cache != null) return _cache!;
    var current = <String, List<List<int>>>{
      '0_0': [[0, 0]]
    };
    for (int step = 0; step < 5; step++) {
      final next = <String, List<List<int>>>{};
      for (final shape in current.values) {
        final set = shape.map((c) => '${c[0]}_${c[1]}').toSet();
        for (final c in shape) {
          for (final d in dirs.values) {
            final nb = [c[0] + d[0], c[1] + d[1]];
            if (set.contains('${nb[0]}_${nb[1]}')) continue;
            final grown = _normalize([...shape, nb]);
            final canon = _variants(grown).map(_key).reduce((a, b) => a.compareTo(b) <= 0 ? a : b);
            next.putIfAbsent(canon, () => grown);
          }
        }
      }
      current = next;
    }
    final result = <List<List<int>>>[];
    for (final shape in current.values) {
      if (fold(shape) != null) result.add(shape);
    }
    _cache = result;
    return result;
  }

  // Gan so 1-6 cho 6 mat sao cho mat doi co tong bang 7.
  static Map<int, int> assignValues(List<List<int>> cells, Random rng) {
    final pairs = oppositePairs(cells);
    final nums = [
      [1, 6],
      [2, 5],
      [3, 4]
    ]..shuffle(rng);
    final values = <int, int>{};
    for (int p = 0; p < 3; p++) {
      final pair = nums[p].toList()..shuffle(rng);
      values[pairs[p][0]] = pair[0];
      values[pairs[p][1]] = pair[1];
    }
    return values;
  }

  static const katakana = ['ア', 'イ', 'ウ', 'エ', 'オ'];

  static DiceLesson generate({int? level}) {
    final rng = Random();
    final all = nets();
    final lv = level ?? (1 + rng.nextInt(3));
    final net = all[rng.nextInt(all.length)];
    final cells = net.map((c) => c.toList()).toList();
    final values = assignValues(cells, rng);
    final hiddenCount = min(5, lv + 1);
    final idx = List.generate(6, (i) => i)..shuffle(rng);
    final hidden = idx.take(hiddenCount).toList()..sort();
    return DiceLesson(
      id: 'dice_${DateTime.now().millisecondsSinceEpoch}',
      title: {
        'ja': 'さいころ じどう',
        'en': 'Auto Dice',
        'vi': 'Xúc xắc tự động',
      },
      question: {
        'ja': 'かたちを おりまげて さいころを つくります。きごうの ところの 目の かずは いくつですか。',
        'en': 'Fold the net into a dice. What number is on each marked face?',
        'vi': 'Gấp hình khai triển thành xúc xắc. Mặt có ký hiệu mang số mấy?',
      },
      cells: cells,
      values: values,
      hiddenIdx: hidden,
      labels: katakana.take(hiddenCount).toList(),
      difficulty: lv,
      isAutoGenerated: true,
    );
  }
}
