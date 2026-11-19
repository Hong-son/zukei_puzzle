import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/reward_service.dart';
import '../services/locale_service.dart';
import 'category_screen.dart';
import 'dice_menu_screen.dart';
import 'pyramid_category_screen.dart';
import 'calendar_category_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const List<Map<String, dynamic>> categories = [
    {
      'id': 'zukei_puzzle',
      'icon': '🧩',
      'name': {'ja': 'ずけいパズル', 'en': 'Shape Puzzle', 'vi': 'Xếp Hình'},
      'desc': {'ja': 'ブロックを ならべよう', 'en': 'Arrange blocks', 'vi': 'Xếp khối'},
      'color': Color(0xFF4CAF50),
      'mode': 'draw_outline',
    },
    {
      'id': 'dice',
      'icon': '🎲',
      'name': {'ja': 'さいころ', 'en': 'Dice', 'vi': 'Xúc xắc'},
      'desc': {'ja': 'おりたたんで みよう', 'en': 'Fold the net', 'vi': 'Gấp hình khai triển'},
      'color': Color(0xFFFF7043),
      'mode': 'dice',
    },
    {
      'id': 'pyramid',
      'icon': '🧱',
      'name': {'ja': 'かずの つみ木', 'en': 'Number Tower', 'vi': 'Tháp số'},
      'desc': {'ja': 'たして うめよう', 'en': 'Add and fill in', 'vi': 'Cộng để điền số'},
      'color': Color(0xFF8D6E63),
      'mode': 'pyramid',
    },
    {
      'id': 'calendar',
      'icon': '📅',
      'name': {'ja': 'カレンダー', 'en': 'Calendar', 'vi': 'Lịch'},
      'desc': {'ja': '日ご・日まえ・日かん', 'en': 'Days after, before, between', 'vi': 'Tính ngày tháng'},
      'color': Color(0xFF26A69A),
      'mode': 'calendar',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final stars = context.watch<RewardService>().totalStars;
    final locale = context.watch<LocaleService>();
    final lang = locale.lang;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9C4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        title: const Text(
          'かんがえるん 🧠',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 2),
                Text(
                  '$stars',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFFE8F5E9),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('言語 / Language / Ngôn ngữ: ',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                _LangButton(label: '日本語', code: 'ja', current: lang, onTap: locale.setLang),
                const SizedBox(width: 6),
                _LangButton(label: 'English', code: 'en', current: lang, onTap: locale.setLang),
                const SizedBox(width: 6),
                _LangButton(label: 'Tiếng Việt', code: 'vi', current: lang, onTap: locale.setLang),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              lang == 'ja'
                  ? 'どの もんだいを やりますか？'
                  : lang == 'en'
                      ? 'Which problem do you want to try?'
                      : 'Bạn muốn làm dạng bài nào?',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, i) {
                    final cat = categories[i];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => cat['mode'] == 'dice'
                                ? DiceMenuScreen(category: cat)
                                : cat['mode'] == 'pyramid'
                                    ? PyramidCategoryScreen(category: cat)
                                    : cat['mode'] == 'calendar'
                                        ? CalendarCategoryScreen(category: cat)
                                        : CategoryScreen(category: cat)),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cat['color'] as Color,
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
                            Text(cat['icon'] as String,
                                style: const TextStyle(fontSize: 44)),
                            const SizedBox(height: 8),
                            Text(
                              (cat['name'] as Map<String, String>)[lang] ?? '',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              (cat['desc'] as Map<String, String>)[lang] ?? '',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LangButton extends StatelessWidget {
  final String label;
  final String code;
  final String current;
  final Future<void> Function(String) onTap;

  const _LangButton({
    required this.label,
    required this.code,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = code == current;
    return GestureDetector(
      onTap: () => onTap(code),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4CAF50) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? const Color(0xFF4CAF50) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? Colors.white : Colors.grey.shade700,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
