import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/locale_service.dart';
import '../services/progress_service.dart';
import '../services/kokugo_engine.dart';
import 'kokugo_game_screen.dart';
import 'kokugo_stroke_screen.dart';
import 'kokugo_hantai_screen.dart';
import 'kokugo_ruigi_screen.dart';
import 'kokugo_idiom_screen.dart';
import 'kokugo_word_screen.dart';
import 'kokugo_narabe_screen.dart';
import 'kokugo_bun_screen.dart';

class KokugoCategoryScreen extends StatelessWidget {
  final Map<String, dynamic> category;
  final Map<String, dynamic> tile; // nhom dang bai (xem KokugoMenuScreen.kinds)
  const KokugoCategoryScreen({super.key, required this.category, required this.tile});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleService>().lang;
    final progress = context.watch<ProgressService>();
    final kinds = (tile['kinds'] as List).cast<String>();
    final color = tile['color'] as Color;
    final name = (tile['name'] as Map<String, String>)[lang] ?? '';
    final doneLabel = lang == 'ja' ? 'かいクリア' : lang == 'en' ? 'times cleared' : 'lần hoàn thành';
    // Bai mau + bai tu sinh cua tung dang trong nhom, theo thu tu dang
    final lessons = [
      for (final kd in kinds) ...KokugoEngine.samples(kd),
      for (final kd in kinds) ...progress.generatedKokugo.where((e) => e.kind == kd),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9C4),
      appBar: AppBar(
        backgroundColor: color,
        title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // chon ngau nhien 1 dang trong nhom (moi dang chi giu 1 bai tu sinh)
          final rnd = Random();
          final kd = kinds[rnd.nextInt(kinds.length)];
          progress.addGeneratedKokugo(KokugoEngine.generate(kd, level: 1 + rnd.nextInt(3)));
        },
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
                      if (lesson.kind == 'hitsujun') return KokugoStrokeScreen(lesson: lesson);
                      if (lesson.kind == 'hantai') return KokugoHantaiScreen(lesson: lesson);
                      if (lesson.kind == 'ruigi') return KokugoRuigiScreen(lesson: lesson);
                      if (lesson.kind == 'kanyou') return KokugoIdiomScreen(lesson: lesson);
                      if (lesson.kind == 'setsuzoku') return KokugoWordScreen(lesson: lesson);
                      if (lesson.kind == 'narabe') return KokugoNarabeScreen(lesson: lesson);
                      if (lesson.kind == 'bunsaku') return KokugoBunScreen(lesson: lesson);
                      return KokugoGameScreen(lesson: lesson);
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
