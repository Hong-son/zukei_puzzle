import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/locale_service.dart';
import '../services/progress_service.dart';
import '../services/clock_engine.dart';
import '../models/clock_lesson.dart';
import 'clock_game_screen.dart';
import 'clock_span_screen.dart';

class ClockCategoryScreen extends StatelessWidget {
  final Map<String, dynamic> category;
  final String kind; // 'hands' = とけいの はり | 'span' = じこくと じかん (+ かがみの 中の とけい)
  const ClockCategoryScreen({super.key, required this.category, this.kind = 'hands'});

  // Bai mau tu sach (trang 3: とけいの はり)
  static const List<ClockLesson> samples = [
    ClockLesson(
      id: 'TK001',
      title: {'ja': 'とけいの はり 1', 'en': 'Clock Hands 1', 'vi': 'Kim đồng hồ 1'},
      questions: [
        ClockQuestion(type: 'set', hour: 2, minute: 0),
        ClockQuestion(type: 'set', hour: 2, minute: 30),
        ClockQuestion(type: 'set', hour: 10, minute: 30),
      ],
      difficulty: 1,
    ),
    ClockLesson(
      id: 'TK002',
      title: {'ja': 'とけいの はり 2', 'en': 'Clock Hands 2', 'vi': 'Kim đồng hồ 2'},
      questions: [
        ClockQuestion(type: 'draw', hour: 7, minute: 0),
        ClockQuestion(type: 'draw', hour: 5, minute: 30),
        ClockQuestion(type: 'draw', hour: 11, minute: 0),
        ClockQuestion(type: 'draw', hour: 1, minute: 30),
      ],
      difficulty: 1,
    ),
  ];

  // Bai mau tu sach (trang 4: じこくと じかん)
  static const List<ClockLesson> spanSamples = [
    ClockLesson(
      id: 'TJ001',
      title: {'ja': 'じこくと じかん 1', 'en': 'Time and Duration 1', 'vi': 'Giờ và khoảng thời gian 1'},
      kind: 'span',
      questions: [
        ClockQuestion(type: 'until', hour: 10, minute: 0, extra: [12]),
        ClockQuestion(type: 'until', hour: 9, minute: 30, extra: [12]),
        ClockQuestion(type: 'until', hour: 11, minute: 50, extra: [12]),
      ],
      difficulty: 1,
    ),
    ClockLesson(
      id: 'TJ002',
      title: {'ja': 'じこくと じかん 2', 'en': 'Time and Duration 2', 'vi': 'Giờ và khoảng thời gian 2'},
      kind: 'span',
      questions: [
        ClockQuestion(type: 'rate', hour: 2, extra: [3, 4, 5, 0, 0]),
      ],
      difficulty: 2,
    ),
    ClockLesson(
      id: 'TJ003',
      title: {'ja': 'かがみの 中の とけい 1', 'en': 'Clock in the Mirror 1', 'vi': 'Đồng hồ trong gương 1'},
      kind: 'mirror',
      questions: [
        ClockQuestion(type: 'mirror', hour: 4, minute: 30),
        ClockQuestion(type: 'mirror', hour: 3, minute: 5),
        ClockQuestion(type: 'mirror', hour: 7, minute: 50),
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
    final isSpan = kind == 'span';
    final kinds = isSpan ? const ['span', 'mirror'] : const ['hands'];
    final lessons = [
      ...(isSpan ? spanSamples : samples),
      ...progress.generatedClocks.where((e) => kinds.contains(e.kind)),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9C4),
      appBar: AppBar(
        backgroundColor: color,
        title: Text(catName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final lv = 1 + (DateTime.now().millisecond % 3);
          if (!isSpan) {
            progress.addGeneratedClock(ClockEngine.generate(level: lv));
          } else if (DateTime.now().microsecond % 2 == 0) {
            progress.addGeneratedClock(ClockEngine.generateSpan(level: lv));
          } else {
            progress.addGeneratedClock(ClockEngine.generateMirror(level: lv));
          }
        },
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
                    MaterialPageRoute(
                        builder: (_) => lesson.kind != 'hands'
                            ? ClockSpanScreen(lesson: lesson)
                            : ClockGameScreen(lesson: lesson)),
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
