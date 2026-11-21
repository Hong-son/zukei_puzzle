import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/locale_service.dart';
import '../services/progress_service.dart';
import '../services/view_engine.dart';
import 'view_category_screen.dart';

class ViewMenuScreen extends StatelessWidget {
  final Map<String, dynamic> category;
  const ViewMenuScreen({super.key, required this.category});

  static const List<Map<String, dynamic>> kinds = [
    {
      'kind': 'water',
      'icon': '💧',
      'name': {'ja': '水めんの かたち', 'en': 'Water Surface Shapes', 'vi': 'Hình dạng mặt nước'},
      'desc': {'ja': 'ま上から 見て じゅんばんを つけよう', 'en': 'Order the views from above', 'vi': 'Xếp thứ tự lượng nước nhìn từ trên'},
      'color': Color(0xFF29B6F6),
    },
    {
      'kind': 'shadow',
      'icon': '🌓',
      'name': {'ja': 'かげの 正たい', 'en': 'Whose Shadow?', 'vi': 'Bóng của vật nào?'},
      'desc': {'ja': 'かげから ものを あてよう', 'en': 'Guess the object', 'vi': 'Đoán vật từ cái bóng'},
      'color': Color(0xFF6D4C41),
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
                  final samples = ViewEngine.samples(kind);
                  final gen = progress.generatedViews.where((e) => e.kind == kind).toList();
                  final total = samples.length + gen.length;
                  final done = samples.where((s) => progress.isDone(s.id)).length +
                      gen.where((s) => progress.isDone(s.id)).length;
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ViewCategoryScreen(category: category, kind: kind),
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
