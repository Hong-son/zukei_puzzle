import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/locale_service.dart';
import '../services/progress_service.dart';
import '../services/fold_engine.dart';
import '../models/fold_lesson.dart';
import 'fold_game_screen.dart';

// たいしょうな かたち: かみを おって きって ひらく
class FoldCategoryScreen extends StatelessWidget {
  final Map<String, dynamic> category;
  const FoldCategoryScreen({super.key, required this.category});

  static final List<FoldLesson> samples = [
    // 本の たいしょうな かたち 1・2 (4つに おって きる)
    FoldLesson(
      id: 'FD001',
      title: {'ja': 'たいしょうな かたち 1', 'en': 'Symmetric Shapes 1', 'vi': 'Hình đối xứng 1'},
      questions: [
        FoldQuestion(shape: 'sq', cut: [FoldEngine.code(0, 0, 0), FoldEngine.code(0, 0, 3)]),
        FoldQuestion(shape: 'tri', cut: [FoldEngine.code(1, 0, 0)]),
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
    final lessons = [...samples, ...progress.generatedFolds];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9C4),
      appBar: AppBar(
        backgroundColor: color,
        title: Text(catName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => progress.addGeneratedFold(FoldEngine.generate(level: 1 + (DateTime.now().millisecond % 3))),
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
                  subtitle: Text('${lesson.questions.length}もん${done ? '   ✓ $n $doneLabel' : ''}'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => FoldGameScreen(lesson: lesson)),
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
