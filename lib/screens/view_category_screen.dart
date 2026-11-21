import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/locale_service.dart';
import '../services/progress_service.dart';
import '../services/view_engine.dart';
import 'water_game_screen.dart';
import 'shadow_game_screen.dart';
import 'view_menu_screen.dart';

class ViewCategoryScreen extends StatelessWidget {
  final Map<String, dynamic> category;
  final String kind;
  const ViewCategoryScreen({super.key, required this.category, required this.kind});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleService>().lang;
    final progress = context.watch<ProgressService>();
    final kindInfo = ViewMenuScreen.kinds.firstWhere((k) => k['kind'] == kind);
    final color = kindInfo['color'] as Color;
    final name = (kindInfo['name'] as Map<String, String>)[lang] ?? '';
    final doneLabel = lang == 'ja' ? 'かいクリア' : lang == 'en' ? 'times cleared' : 'lần hoàn thành';
    final lessons = [
      ...ViewEngine.samples(kind),
      ...progress.generatedViews.where((e) => e.kind == kind),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9C4),
      appBar: AppBar(
        backgroundColor: color,
        title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => progress.addGeneratedView(
            ViewEngine.generate(kind, level: 1 + Random().nextInt(3))),
        backgroundColor: color,
        icon: const Icon(Icons.auto_awesome, color: Colors.white),
        label: Text(lang == 'ja' ? 'あたらしい もんだい' : lang == 'en' ? 'New problem' : 'Bài mới',
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
                      'Level: ${'⭐' * lesson.difficulty}   ${lesson.items.length}もん${done ? '   ✓ $n $doneLabel' : ''}'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) {
                      if (lesson.kind == 'water') return WaterGameScreen(lesson: lesson);
                      return ShadowGameScreen(lesson: lesson);
                    }),
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
