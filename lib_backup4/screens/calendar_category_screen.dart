import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/locale_service.dart';
import '../services/progress_service.dart';
import '../services/calendar_engine.dart';
import '../models/calendar_lesson.dart';
import 'calendar_game_screen.dart';

class CalendarCategoryScreen extends StatelessWidget {
  final Map<String, dynamic> category;
  const CalendarCategoryScreen({super.key, required this.category});

  // Bai mau tu sach. weekday: 0=月 1=火 2=水 3=木 4=金 5=土 6=日
  static const List<CalendarLesson> samples = [
    CalendarLesson(
      id: 'CL001',
      title: {'ja': '日ご・日まえ・日かん 1', 'en': 'Days After / Before 1', 'vi': 'Sau / trước / trong mấy ngày 1'},
      questions: [
        CalendarQuestion(type: 'after', month: 10, day: 5, weekday: 0, amount: 4),
        CalendarQuestion(type: 'after', month: 7, day: 12, weekday: 4, amount: 7),
        CalendarQuestion(type: 'before', month: 5, day: 20, weekday: 6, amount: 5),
        CalendarQuestion(type: 'before', month: 2, day: 9, weekday: 2, amount: 7),
        CalendarQuestion(type: 'span', month: 11, day: 12, weekday: 0, month2: 11, day2: 16),
        CalendarQuestion(type: 'span', month: 4, day: 10, weekday: 0, month2: 4, day2: 17),
      ],
      difficulty: 1,
    ),
    CalendarLesson(
      id: 'CL002',
      title: {'ja': '日ご・日まえ・日かん 2', 'en': 'Days After / Before 2', 'vi': 'Sau / trước / trong mấy ngày 2'},
      questions: [
        CalendarQuestion(type: 'after', month: 3, day: 2, weekday: 0, amount: 7),
        CalendarQuestion(type: 'after', month: 3, day: 2, weekday: 0, amount: 14),
        CalendarQuestion(type: 'after', month: 3, day: 2, weekday: 0, amount: 23),
        CalendarQuestion(type: 'after', month: 6, day: 19, weekday: 2, amount: 9),
        CalendarQuestion(type: 'before', month: 6, day: 19, weekday: 2, amount: 11),
        CalendarQuestion(type: 'span', month: 6, day: 5, weekday: 2, month2: 6, day2: 19),
      ],
      difficulty: 2,
    ),
    CalendarLesson(
      id: 'CL003',
      title: {'ja': '日ご・日まえ・日かん 3', 'en': 'Days After / Before 3', 'vi': 'Sau / trước / trong mấy ngày 3'},
      questions: [
        CalendarQuestion(type: 'afterMonth', month: 6, day: 28, weekday: 4, amount: 6),
        CalendarQuestion(type: 'beforeMonth', month: 9, day: 3, weekday: 0, amount: 5),
        CalendarQuestion(type: 'span', month: 4, day: 29, weekday: 0, month2: 5, day2: 6),
      ],
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
    final lessons = [...samples, ...progress.generatedCalendars];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9C4),
      appBar: AppBar(
        backgroundColor: color,
        title: Text(catName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => progress.addGeneratedCalendar(
            CalendarEngine.generate(level: 1 + (DateTime.now().millisecond % 3))),
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
                      '${lesson.questions.length}もん  Level: ${'⭐' * lesson.difficulty}${done ? '   ✓ $n $doneLabel' : ''}'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CalendarGameScreen(lesson: lesson)),
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
