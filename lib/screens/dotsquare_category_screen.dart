import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/locale_service.dart';
import '../services/progress_service.dart';
import '../services/dotsquare_engine.dart';
import '../models/dotsquare_lesson.dart';
import 'dotsquare_game_screen.dart';

class DotSquareCategoryScreen extends StatelessWidget {
  final Map<String, dynamic> category;
  const DotSquareCategoryScreen({super.key, required this.category});

  static const List<DotSquareLesson> samples = [
    DotSquareLesson(
      id: 'DS001',
      title: {'ja': 'ましかくは いくつ？ 1', 'en': 'Count the Squares 1', 'vi': 'Đếm hình vuông 1'},
      question: DotSquareEngine.question,
      n: 4,
      rows: 5,
      areas: [1, 2, 4, 5, 9],
      difficulty: 2,
    ),
    DotSquareLesson(
      id: 'DS002',
      title: {'ja': 'ましかくは いくつ？ 2', 'en': 'Count the Squares 2', 'vi': 'Đếm hình vuông 2'},
      question: DotSquareEngine.question,
      n: 6,
      rows: 6,
      areas: [2, 4, 5, 8, 9],
      difficulty: 3,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleService>().lang;
    final progress = context.watch<ProgressService>();
    final catName = (category['name'] as Map<String, String>)[lang] ?? '';
    final color = category['color'] as Color;
    final doneLabel = lang == 'ja' ? 'かいクリア' : lang == 'en' ? 'times cleared' : 'lần hoàn thành';
    final lessons = [...samples, ...progress.generatedDotSquares];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9C4),
      appBar: AppBar(
        backgroundColor: color,
        title: Text(catName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => progress.addGeneratedDotSquare(
            DotSquareEngine.generate(level: 1 + (DateTime.now().millisecond % 3))),
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
                  subtitle: done ? Text('✓ $n $doneLabel') : null,
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DotSquareGameScreen(lesson: lesson)),
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
