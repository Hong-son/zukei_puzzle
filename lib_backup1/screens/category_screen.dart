import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/locale_service.dart';
import '../services/progress_service.dart';
import '../services/puzzle_solver.dart';
import '../models/lesson.dart';
import 'draw_outline_game_screen.dart';

class CategoryScreen extends StatefulWidget {
  final Map<String, dynamic> category;
  const CategoryScreen({super.key, required this.category});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  bool _busy = false;

  static List<List<int>> _xy(List<List<int>> c) =>
      c.map((p) => [p[1] - 1, p[0] - 1]).toList();

  static List<PieceShape> get _refPieces => ['I', 'L', 'T', 'Z', 'O']
      .expand((id) => [Tetro.piece(id), Tetro.piece(id)])
      .toList();

  static const Map<String, String> _q = {
    'ja': '10この ブロックを かさならないように ならべます。のこりの ブロックの さかいめを なぞって せんを ひきましょう。',
    'en': 'Tap the edges to outline where the remaining blocks go. All 10 blocks fill the rectangle without overlapping.',
    'vi': 'Chạm vào các cạnh để vẽ đường bao các khối còn lại. 10 khối lấp đầy hình chữ nhật, không chồng lên nhau.',
  };

  static Lesson get _lesson1 => Lesson(
        id: 'ZP001',
        title: const {'ja': 'ずけいパズル 1', 'en': 'Shape Puzzle 1', 'vi': 'Xếp Hình 1'},
        question: _q,
        gridRows: 5,
        gridCols: 8,
        fixedBlocks: [
          _xy([[1, 3], [2, 3], [3, 3], [3, 2]]),
          _xy([[5, 3], [6, 3], [6, 4], [7, 4]]),
          _xy([[6, 2], [7, 2], [8, 2], [7, 3]]),
        ],
        referencePieces: _refPieces,
        difficulty: 1,
      );

  static Lesson get _lesson2 => Lesson(
        id: 'ZP002',
        title: const {'ja': 'ずけいパズル 2', 'en': 'Shape Puzzle 2', 'vi': 'Xếp Hình 2'},
        question: _q,
        gridRows: 5,
        gridCols: 8,
        fixedBlocks: [
          _xy([[3, 2], [3, 3], [4, 3], [4, 4]]),
          _xy([[6, 1], [7, 1], [8, 1], [7, 2]]),
          _xy([[8, 2], [8, 3], [8, 4], [8, 5]]),
        ],
        referencePieces: _refPieces,
        difficulty: 2,
      );

  Future<void> _addGenerated() async {
    if (_busy) return;
    setState(() => _busy = true);
    await Future.delayed(const Duration(milliseconds: 50));
    final l = PuzzleSolver.generate();
    if (!mounted) return;
    setState(() => _busy = false);
    if (l == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not generate. Try again.')));
      return;
    }
    await context.read<ProgressService>().addGenerated(l);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleService>().lang;
    final progress = context.watch<ProgressService>();
    final cat = widget.category;
    final catName = (cat['name'] as Map<String, String>)[lang] ?? '';
    final lessons = [_lesson1, _lesson2, ...progress.generated];
    final doneLabel = lang == 'ja' ? 'かいクリア' : lang == 'en' ? 'times cleared' : 'lần hoàn thành';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9C4),
      appBar: AppBar(
        backgroundColor: cat['color'] as Color,
        title: Text(catName,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _addGenerated,
        backgroundColor: const Color(0xFF4CAF50),
        icon: _busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.auto_awesome, color: Colors.white),
        label: Text(
            lang == 'ja' ? 'あたらしい もんだい' : lang == 'en' ? 'New puzzle' : 'Bài mới',
            style: const TextStyle(color: Colors.white)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        itemCount: lessons.length,
        itemBuilder: (context, index) {
          final lesson = lessons[index];
          final n = progress.completions(lesson.id);
          final done = n > 0;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: done ? const Color(0xFFE8F5E9) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: CircleAvatar(
                backgroundColor: done ? Colors.green : (cat['color'] as Color),
                child: done
                    ? const Icon(Icons.check, color: Colors.white)
                    : Text('${index + 1}',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              title: Text(lesson.title[lang] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  'Level: ${'⭐' * lesson.difficulty}${done ? '   ✓ $n $doneLabel' : ''}'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DrawOutlineGameScreen(lesson: lesson)),
              ),
            ),
          );
        },
      ),
    );
  }
}
