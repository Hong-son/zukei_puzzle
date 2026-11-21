import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/locale_service.dart';
import '../services/progress_service.dart';
import '../services/kokugo_engine.dart';
import 'kokugo_category_screen.dart';

class KokugoMenuScreen extends StatelessWidget {
  final Map<String, dynamic> category;
  const KokugoMenuScreen({super.key, required this.category});

  static const List<Map<String, dynamic>> kinds = [
    {
      'kind': 'kaki',
      'icon': '✍️',
      'name': {'ja': 'かん字を かこう', 'en': 'Write the Kanji', 'vi': 'Viết chữ Hán'},
      'desc': {'ja': 'かたかなを かん字に なおそう', 'en': 'Katakana to kanji', 'vi': 'Đổi katakana thành chữ Hán'},
      'color': Color(0xFF5C6BC0),
    },
    {
      'kind': 'yomi',
      'icon': '🔤',
      'name': {'ja': 'かん字の よみ', 'en': 'Kanji Readings', 'vi': 'Cách đọc chữ Hán'},
      'desc': {'ja': 'よみを ひらがなで かこう', 'en': 'Write the reading', 'vi': 'Viết cách đọc bằng hiragana'},
      'color': Color(0xFF26A69A),
    },
    {
      'kind': 'hitsujun',
      'icon': '🖌️',
      'name': {'ja': 'かん字の ひつじゅん', 'en': 'Stroke Order', 'vi': 'Thứ tự nét chữ Hán'},
      'desc': {'ja': 'なんばん目に かくかな？', 'en': 'Which stroke is it?', 'vi': 'Mũi tên chỉ nét thứ mấy?'},
      'color': Color(0xFFEF6C00),
    },
    {
      'kind': 'hantai',
      'icon': '↔️',
      'name': {'ja': 'はんたいの いみ', 'en': 'Opposite Kanji', 'vi': 'Chữ Hán trái nghĩa'},
      'desc': {'ja': 'かん字を くみあわせよう', 'en': 'Combine opposite kanji', 'vi': 'Ghép chữ trái nghĩa thành từ'},
      'color': Color(0xFFAB47BC),
    },
    {
      'kind': 'kanyou',
      'icon': '👂',
      'name': {'ja': 'かんようく', 'en': 'Idioms', 'vi': 'Thành ngữ'},
      'desc': {'ja': 'からだの ことばを いれよう', 'en': 'Fill in the body part', 'vi': 'Điền từ chỉ bộ phận cơ thể'},
      'color': Color(0xFF43A047),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleService>().lang;
    final progress = context.watch<ProgressService>();
    final catName = (category['name'] as Map<String, String>)[lang] ?? '';
    final title = lang == 'ja'
        ? 'どの もんだいを やりますか？'
        : lang == 'en'
            ? 'Choose a type'
            : 'Chọn dạng bài';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9C4),
      appBar: AppBar(
        backgroundColor: category['color'] as Color,
        title: Text(catName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 240,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.0,
                ),
                itemCount: kinds.length,
                itemBuilder: (context, i) {
                  final k = kinds[i];
                  final kind = k['kind'] as String;
                  final samples = KokugoEngine.samples(kind);
                  final gen = progress.generatedKokugo.where((e) => e.kind == kind).toList();
                  final total = samples.length + gen.length;
                  final done = samples.where((s) => progress.isDone(s.id)).length +
                      gen.where((s) => progress.isDone(s.id)).length;
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => KokugoCategoryScreen(category: category, kind: kind),
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: k['color'] as Color,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(k['icon'] as String, style: const TextStyle(fontSize: 44)),
                          const SizedBox(height: 8),
                          Text((k['name'] as Map<String, String>)[lang] ?? '',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 2),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text((k['desc'] as Map<String, String>)[lang] ?? '',
                                style: const TextStyle(fontSize: 11, color: Colors.white70),
                                textAlign: TextAlign.center),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('✓ $done / $total',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
