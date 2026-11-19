import 'dart:math';
import '../models/lesson.dart';

class Tetro {
  static const Map<String, List<List<int>>> shapes = {
    'I': [[0, 0], [1, 0], [2, 0], [3, 0]],
    'L': [[0, 0], [1, 0], [2, 0], [2, 1]],
    'T': [[0, 0], [0, 1], [0, 2], [1, 1]],
    'Z': [[0, 0], [0, 1], [1, 1], [1, 2]],
    'O': [[0, 0], [0, 1], [1, 0], [1, 1]],
  };

  static PieceShape piece(String id) => PieceShape(id: id, cells: shapes[id]!);

  static List<List<int>> _normalize(List<List<int>> cells) {
    final minR = cells.map((c) => c[0]).reduce(min);
    final minC = cells.map((c) => c[1]).reduce(min);
    final out = cells.map((c) => [c[0] - minR, c[1] - minC]).toList();
    out.sort((a, b) => a[0] != b[0] ? a[0].compareTo(b[0]) : a[1].compareTo(b[1]));
    return out;
  }

  static final Map<String, List<List<List<int>>>> _cache = {};

  static List<List<List<int>>> orientations(String id) {
    return _cache.putIfAbsent(id, () {
      final result = <List<List<int>>>[];
      final seen = <String>{};
      var cur = shapes[id]!;
      for (int flip = 0; flip < 2; flip++) {
        for (int rot = 0; rot < 4; rot++) {
          cur = _normalize(cur.map((c) => [c[1], -c[0]]).toList());
          final key = cur.map((c) => '${c[0]}_${c[1]}').join(',');
          if (seen.add(key)) result.add(cur);
        }
        cur = _normalize(cur.map((c) => [c[0], -c[1]]).toList());
      }
      return result;
    });
  }

  static String? identify(List<List<int>> cells) {
    final key = _normalize(cells).map((c) => '${c[0]}_${c[1]}').join(',');
    for (final id in shapes.keys) {
      for (final o in orientations(id)) {
        if (o.map((c) => '${c[0]}_${c[1]}').join(',') == key) return id;
      }
    }
    return null;
  }
}

class PlacedBlock {
  final String id;
  final List<List<int>> cells;
  PlacedBlock(this.id, this.cells);
}

class PuzzleSolver {
  static List<PlacedBlock>? solve({
    required int rows,
    required int cols,
    required List<List<List<int>>> fixedBlocks,
    required Map<String, int> available,
    Random? rng,
  }) {
    final random = rng ?? Random();
    final grid = List.generate(rows, (_) => List.filled(cols, false));
    for (final b in fixedBlocks) {
      for (final c in b) {
        grid[c[0]][c[1]] = true;
      }
    }
    final remaining = Map<String, int>.from(available);
    final placed = <PlacedBlock>[];
    int steps = 0;

    bool rec() {
      steps++;
      if (steps > 60000) return false;
      int fr = -1, fc = -1;
      for (int r = 0; r < rows && fr < 0; r++) {
        for (int c = 0; c < cols; c++) {
          if (!grid[r][c]) {
            fr = r;
            fc = c;
            break;
          }
        }
      }
      if (fr < 0) return true;
      final ids = remaining.keys.where((k) => remaining[k]! > 0).toList()..shuffle(random);
      for (final id in ids) {
        for (final ori in Tetro.orientations(id)) {
          final ar = ori[0][0];
          final ac = ori[0][1];
          final cells = ori.map((p) => [p[0] - ar + fr, p[1] - ac + fc]).toList();
          final ok = cells.every((p) =>
              p[0] >= 0 && p[0] < rows && p[1] >= 0 && p[1] < cols && !grid[p[0]][p[1]]);
          if (!ok) continue;
          for (final p in cells) {
            grid[p[0]][p[1]] = true;
          }
          remaining[id] = remaining[id]! - 1;
          placed.add(PlacedBlock(id, cells));
          if (rec()) return true;
          placed.removeLast();
          remaining[id] = remaining[id]! + 1;
          for (final p in cells) {
            grid[p[0]][p[1]] = false;
          }
        }
      }
      return false;
    }

    return rec() ? placed : null;
  }

  static Lesson? generate() {
    final random = Random();
    final ids = Tetro.shapes.keys.toList();
    for (int attempt = 0; attempt < 80; attempt++) {
      final rows = 4 + random.nextInt(3);
      final cols = 4 + random.nextInt(5);
      if ((rows * cols) % 4 != 0) continue;
      final total = rows * cols ~/ 4;
      if (total < 4) continue;

      final pool = <String>[];
      final kinds = (ids.toList()..shuffle(random)).take(2 + random.nextInt(4)).toList();
      for (int i = 0; i < total; i++) {
        pool.add(kinds[random.nextInt(kinds.length)]);
      }
      final avail = <String, int>{};
      for (final id in pool) {
        avail[id] = (avail[id] ?? 0) + 1;
      }

      final full = solve(rows: rows, cols: cols, fixedBlocks: [], available: avail);
      if (full == null) continue;

      final order = List<PlacedBlock>.from(full)..shuffle(random);
      final fixedCount = max(1, min(3, total ~/ 3));
      final fixed = order.take(fixedCount).toList();
      final rest = order.skip(fixedCount).toList();
      if (rest.isEmpty) continue;

      final restAvail = <String, int>{};
      for (final b in rest) {
        restAvail[b.id] = (restAvail[b.id] ?? 0) + 1;
      }
      final extra = random.nextInt(3);
      for (int i = 0; i < extra; i++) {
        final id = ids[random.nextInt(ids.length)];
        restAvail[id] = (restAvail[id] ?? 0) + 1;
      }

      final refs = <PieceShape>[];
      restAvail.forEach((id, n) {
        for (int i = 0; i < n; i++) {
          refs.add(Tetro.piece(id));
        }
      });
      refs.sort((a, b) => a.id.compareTo(b.id));

      return Lesson(
        id: 'auto_${DateTime.now().millisecondsSinceEpoch}',
        title: {
          'ja': 'じどうパズル ${rows}x$cols',
          'en': 'Auto Puzzle ${rows}x$cols',
          'vi': 'Bài tự động ${rows}x$cols',
        },
        question: {
          'ja': 'のこりの ブロックを ならべて、さかいめの せんを ひきましょう。',
          'en': 'Tap the edges to outline where the remaining blocks go. Use only the given blocks.',
          'vi': 'Chạm vào các cạnh để vẽ đường bao các khối còn lại. Chỉ dùng các khối đã cho.',
        },
        gridRows: rows,
        gridCols: cols,
        fixedBlocks: fixed.map((b) => b.cells).toList(),
        referencePieces: refs,
        difficulty: 1 + (total > 8 ? 1 : 0) + (kinds.length > 3 ? 1 : 0),
        isAutoGenerated: true,
      );
    }
    return null;
  }
}
