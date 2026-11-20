import 'dart:math';
import '../models/hide_lesson.dart';
import 'dice_engine.dart';

class HideEngine {
  static int valueOf(int code) => code % 10;

  static int _code(int v, Random rng) {
    if (v == 2 || v == 3 || v == 6) return v + 10 * rng.nextInt(2);
    return v;
  }

  static List<List<int>> connectedSets(int rows, int cols) {
    var cur = <String, List<int>>{};
    for (int i = 0; i < rows * cols; i++) {
      cur['$i'] = [i];
    }
    for (int step = 1; step < 6; step++) {
      final next = <String, List<int>>{};
      for (final s in cur.values) {
        for (final idx in s) {
          final r = idx ~/ cols, c = idx % cols;
          for (final d in DiceEngine.dirs.values) {
            final nr = r + d[0], nc = c + d[1];
            if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) continue;
            final nb = nr * cols + nc;
            if (s.contains(nb)) continue;
            final merged = [...s, nb]..sort();
            next[merged.join(',')] = merged;
          }
        }
      }
      cur = next;
    }
    return cur.values.toList();
  }

  static List<List<int>> toCells(List<int> set, int cols) =>
      set.map((i) => [i ~/ cols, i % cols]).toList();

  static bool validRegion(List<int> set, List<List<int>> grid) {
    final cols = grid[0].length;
    final cells = toCells(set, cols);
    if (DiceEngine.fold(cells) == null) return false;
    final vals = cells.map((c) => valueOf(grid[c[0]][c[1]])).toList();
    final sorted = [...vals]..sort();
    for (int i = 0; i < 6; i++) {
      if (sorted[i] != i + 1) return false;
    }
    for (final p in DiceEngine.oppositePairs(cells)) {
      if (vals[p[0]] + vals[p[1]] != 7) return false;
    }
    return true;
  }

  static List<List<int>> solutions(List<List<int>> grid) {
    final rows = grid.length, cols = grid[0].length;
    final out = <List<int>>[];
    for (final s in connectedSets(rows, cols)) {
      if (validRegion(s, grid)) out.add(s);
    }
    return out;
  }

  static String diagnose(List<int> set, List<List<int>> grid) {
    final cols = grid[0].length;
    if (set.length < 6) return 'few';
    if (set.length > 6) return 'many';
    final cells = toCells(set, cols);
    final byKey = {for (final c in cells) '${c[0]}_${c[1]}': true};
    final seen = <String>{};
    final stack = [cells.first];
    seen.add('${cells.first[0]}_${cells.first[1]}');
    while (stack.isNotEmpty) {
      final cur = stack.removeLast();
      for (final d in DiceEngine.dirs.values) {
        final k = '${cur[0] + d[0]}_${cur[1] + d[1]}';
        if (byKey.containsKey(k) && !seen.contains(k)) {
          seen.add(k);
          stack.add([cur[0] + d[0], cur[1] + d[1]]);
        }
      }
    }
    if (seen.length != 6) return 'disconnected';
    if (DiceEngine.fold(cells) == null) return 'notnet';
    final vals = cells.map((c) => valueOf(grid[c[0]][c[1]])).toList();
    if (vals.toSet().length != 6) return 'dup';
    return 'opposite';
  }

  static HideLesson? generate({int? level}) {
    final rng = Random();
    final lv = level ?? (1 + rng.nextInt(3));
    final dims = lv == 1 ? [3, 4] : lv == 2 ? [4, 4] : [4, 5];
    for (int attempt = 0; attempt < 40; attempt++) {
      int rows = dims[0], cols = dims[1];
      if (rng.nextBool()) {
        final t = rows;
        rows = cols;
        cols = t;
      }
      if (lv == 3 && rng.nextBool()) {
        rows = 5;
        cols = 5;
      }
      final sets = connectedSets(rows, cols);
      sets.shuffle(rng);
      List<int>? net;
      for (final s in sets) {
        if (DiceEngine.fold(toCells(s, cols)) != null) {
          net = s;
          break;
        }
      }
      if (net == null) continue;
      final cells = toCells(net, cols);
      final pairs = DiceEngine.oppositePairs(cells);
      final nums = [
        [1, 6],
        [2, 5],
        [3, 4]
      ]..shuffle(rng);
      for (int tryFill = 0; tryFill < 30; tryFill++) {
        final grid = List.generate(
            rows, (_) => List.generate(cols, (_) => _code(1 + rng.nextInt(6), rng)));
        for (int p = 0; p < 3; p++) {
          var x = nums[p][0], y = nums[p][1];
          if (rng.nextBool()) {
            final t = x;
            x = y;
            y = t;
          }
          grid[cells[pairs[p][0]][0]][cells[pairs[p][0]][1]] = _code(x, rng);
          grid[cells[pairs[p][1]][0]][cells[pairs[p][1]][1]] = _code(y, rng);
        }
        if (solutions(grid).length == 1) {
          return HideLesson(
            id: 'hide_${DateTime.now().millisecondsSinceEpoch}',
            title: {
              'ja': 'さいころの かくれんぼ ${rows}x$cols',
              'en': 'Dice Hide and Seek ${rows}x$cols',
              'vi': 'Trốn tìm xúc xắc ${rows}x$cols',
            },
            question: {
              'ja': 'えの 中に、くみ立てると さいころに なる かたちが 1つ かくれています。さがして かこみましょう。',
              'en': 'One net that folds into a dice is hidden here. Find it and select its 6 squares.',
              'vi': 'Có 1 hình khai triển gấp được thành xúc xắc đang ẩn ở đây. Hãy tìm và chọn 6 ô của nó.',
            },
            grid: grid,
            difficulty: lv,
            isAutoGenerated: true,
          );
        }
      }
    }
    return null;
  }
}
