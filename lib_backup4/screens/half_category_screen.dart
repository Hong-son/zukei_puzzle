import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/locale_service.dart';
import '../services/progress_service.dart';
import '../services/half_engine.dart';
import '../models/half_lesson.dart';
import 'half_game_screen.dart';

class HalfCategoryScreen extends StatelessWidget {
  final Map<String, dynamic> category;
  const HalfCategoryScreen({super.key, required this.category});

  static final List<HalfLesson> samples = [
    HalfEngine.fromNames(
      id: 'HF001',
      title: {'ja': 'はんぶんだけぬる 1', 'en': 'Paint Half 1', 'vi': 'Tô một nửa 1'},
      names: ['top', 'quarter', 'diamond', 'lshape', 'arrows', 'triSmall', 'slant', 'oneArrow'],
      difficulty: 1,
    ),
    HalfEngine.fromNames(
      id: 'HF002',
      title: {'ja': 'はんぶんだけぬる 2', 'en': 'Paint Half 2', 'vi': 'Tô một nửa 2'},
      names: [
        'bowtie', 'threeQuarter', 'checker4', 'diamondS', 'stripes', 'triBig',
        'triDown', 'stripesPlus', 'checker2', 'quarter', 'diag', 'lshape'
      ],
      difficulty: 2,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleService>().lang;
    final progress = context.watch<ProgressService>();
    final catName = (category['name'] as Map<String, String>)[lang] ?? '';
    final color = category['color'] as Color;
    final doneLabel = lang == 'ja' ? 'かいクリア' : lang == 'en' ? 'times cleared' : 'lần hoàn thành';
    final lessons = [...samples, ...progress.generatedHalves];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9C4),
      appBar: AppBar(
        backgroundColor: color,
        title: Text(catName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => progress.addGeneratedHalf(
            HalfEngine.generate(level: 1 + (DateTime.now().millisecond % 3))),
        backgroundColor: color,
        icon: const Icon(Icons.auto_awesome, color: Colors.white),
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
                  title: Text(lesson.title[lang] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      'Level: ${'⭐' * lesson.difficulty}${done ? '   ✓ $n $doneLabel' : ''}'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => HalfGameScreen(lesson: lesson)),
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
