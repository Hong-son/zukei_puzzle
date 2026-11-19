import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/locale_service.dart';
import '../services/progress_service.dart';
import 'dice_category_screen.dart';

class DiceMenuScreen extends StatelessWidget {
  final Map<String, dynamic> category;
  const DiceMenuScreen({super.key, required this.category});

  static const List<Map<String, dynamic>> kinds = [
    {
      'kind': 'dice',
      'icon': '📝',
      'name': {'ja': '目の かず', 'en': 'Fill Numbers', 'vi': 'Điền số'},
      'desc': {'ja': 'きごうの 目を こたえよう', 'en': 'Find the missing numbers', 'vi': 'Tìm số ở ký hiệu'},
      'color': Color(0xFFFF7043),
    },
    {
      'kind': 'net',
      'icon': '🔍',
      'name': {'ja': 'ならない かたち', 'en': 'Not a Dice', 'vi': 'Hình không gấp được'},
      'desc': {'ja': 'さいころに ならない かたち', 'en': 'Shapes that do not fold', 'vi': 'Tìm hình không gấp được'},
      'color': Color(0xFF7E57C2),
    },
    {
      'kind': 'mark',
      'icon': '🔄',
      'name': {'ja': 'むかいあう めん', 'en': 'Opposite Face', 'vi': 'Mặt đối diện'},
      'desc': {'ja': '◎の 反対がわは どこ？', 'en': 'Find the face opposite ◎', 'vi': 'Tìm mặt đối diện ◎'},
      'color': Color(0xFF26A69A),
    },
    {
      'kind': 'hide',
      'icon': '🙈',
      'name': {'ja': 'かくれんぼ', 'en': 'Hide and Seek', 'vi': 'Trốn tìm'},
      'desc': {'ja': 'かくれた かたちを さがそう', 'en': 'Find the hidden net', 'vi': 'Tìm hình khai triển ẩn'},
      'color': Color(0xFFEC407A),
    },
    {
      'kind': 'back',
      'icon': '👀',
      'name': {'ja': 'うしろから みると', 'en': 'View from Behind', 'vi': 'Nhìn từ phía sau'},
      'desc': {'ja': 'うしろの 目の ごうけい', 'en': 'Total on the back faces', 'vi': 'Tổng các mặt phía sau'},
      'color': Color(0xFF5C6BC0),
    },
    {
      'kind': 'pick',
      'icon': '🎯',
      'name': {'ja': 'どの さいころ？', 'en': 'Which Dice?', 'vi': 'Xúc xắc nào?'},
      'desc': {'ja': 'きりひらいた かたちから えらぶ', 'en': 'Pick from the net', 'vi': 'Chọn từ hình khai triển'},
      'color': Color(0xFF8D6E63),
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
            ? 'Choose a puzzle type'
            : 'Chọn dạng bài';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9C4),
      appBar: AppBar(
        backgroundColor: category['color'] as Color,
        title: Text(catName,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  final total = DiceCategoryScreen.sampleIds(kind).length +
                      progress.countGenerated(kind);
                  final done = DiceCategoryScreen.sampleIds(kind)
                          .where((id) => progress.isDone(id))
                          .length +
                      progress.doneGenerated(kind);
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DiceCategoryScreen(category: category, kind: kind),
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
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
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
                                style: const TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.bold)),
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

