import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/locale_service.dart';
import '../services/progress_service.dart';
import '../services/pyramid_engine.dart';
import '../models/pyramid_lesson.dart';
import 'pyramid_game_screen.dart';

class PyramidCategoryScreen extends StatefulWidget {
  final Map<String, dynamic> category;
  const PyramidCategoryScreen({super.key, required this.category});

  static const Map<String, String> _qFill = {
    'ja': 'となりどうしの 2つの つみ木の かずを あわせると、上のだんの つみ木に かいてある かずに なります。なにも かいていない つみ木に かずを かきましょう。',
    'en': 'Two neighbouring blocks add up to the block above. Fill in the empty blocks.',
    'vi': 'Hai ô cạnh nhau cộng lại bằng ô nằm trên. Hãy điền các ô còn trống.',
  };
  static const Map<String, String> _qAll = {
    'ja': 'なにも かいていない つみ木に かずを 入れます。「0」は 入れては いけません。入れかたを ぜんぶ かきましょう。',
    'en': 'Fill in the empty blocks without using 0. Find ALL the ways.',
    'vi': 'Điền số vào các ô trống, không dùng số 0. Hãy tìm TẤT CẢ các cách điền.',
  };

  static const List<PyramidLesson> samples = [
    PyramidLesson(
      id: 'PY001',
      title: {'ja': 'かずの つみ木 1', 'en': 'Number Tower 1', 'vi': 'Tháp số 1'},
      question: _qFill,
      levels: 4,
      given: [
        [3, 0, 4], [3, 1, 1], [3, 2, 3], [3, 3, 7]
      ],
      difficulty: 1,
    ),
    PyramidLesson(
      id: 'PY002',
      title: {'ja': 'かずの つみ木 2', 'en': 'Number Tower 2', 'vi': 'Tháp số 2'},
      question: _qFill,
      levels: 4,
      given: [
        [0, 0, 41], [1, 0, 17], [2, 1, 8], [3, 2, 3]
      ],
      difficulty: 2,
    ),
    PyramidLesson(
      id: 'PY003',
      title: {'ja': 'かずの つみ木 ぜんぶ', 'en': 'Number Tower (all ways)', 'vi': 'Tháp số (tìm đủ cách)'},
      question: _qAll,
      levels: 3,
      given: [
        [0, 0, 14], [2, 1, 5]
      ],
      multi: true,
      difficulty: 3,
    ),
  ];

  @override
  State<PyramidCategoryScreen> createState() => _PyramidCategoryScreenState();
}

class _PyramidCategoryScreenState extends State<PyramidCategoryScreen> {
  bool _busy = false;

  Future<void> _add() async {
    if (_busy) return;
    setState(() => _busy = true);
    await Future.delayed(const Duration(milliseconds: 50));
    final l = PyramidEngine.generate(level: 1 + (DateTime.now().millisecond % 3));
    if (!mounted) return;
    if (l != null) {
      await context.read<ProgressService>().addGeneratedPyramid(l);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not generate. Try again.')));
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleService>().lang;
    final progress = context.watch<ProgressService>();
    final cat = widget.category;
    final catName = (cat['name'] as Map<String, String>)[lang] ?? '';
    final doneLabel = lang == 'ja' ? 'かいクリア' : lang == 'en' ? 'times cleared' : 'lần hoàn thành';
    final color = cat['color'] as Color;
    final lessons = [...PyramidCategoryScreen.samples, ...progress.generatedPyramids];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9C4),
      appBar: AppBar(
        backgroundColor: color,
        title: Text(catName,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _add,
        backgroundColor: color,
        icon: _busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.auto_awesome, color: Colors.white),
        label: Text(lang == 'ja' ? 'あたらしい もんだい' : lang == 'en' ? 'New puzzle' : 'Bài mới',
            style: const TextStyle(color: Colors.white)),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: lessons.length,
            itemBuilder: (context, index) {
              final lesson = lessons[index];
              final n = progress.completions(lesson.id);
              final done = n > 0;
              final kind = lesson.multi
                  ? (lang == 'ja' ? 'ぜんぶ さがす' : lang == 'en' ? 'Find all' : 'Tìm đủ cách')
                  : (lang == 'ja' ? 'かずを うめる' : lang == 'en' ? 'Fill in' : 'Điền số');
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: done ? const Color(0xFFE8F5E9) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: CircleAvatar(
                    backgroundColor: done ? Colors.green : color,
                    child: done
                        ? const Icon(Icons.check, color: Colors.white)
                        : Text('${index + 1}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(lesson.title[lang] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      '$kind  ${lesson.levels}だん  Level: ${'⭐' * lesson.difficulty}${done ? '   ✓ $n $doneLabel' : ''}'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PyramidGameScreen(lesson: lesson)),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
