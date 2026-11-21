import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/reward_service.dart';
import '../services/locale_service.dart';
import 'category_screen.dart';
import 'dice_menu_screen.dart';
import 'pyramid_category_screen.dart';
import 'calendar_category_screen.dart';
import 'half_category_screen.dart';
import 'dotsquare_category_screen.dart';
import 'kokugo_menu_screen.dart';

// Man hinh cap 2: danh sach cac dang bai cua mot mon (sansu hoac kokugo).
class SubjectScreen extends StatelessWidget {
  final String subject; // 'sansu' | 'kokugo'
  final Map<String, dynamic> info;
  const SubjectScreen({super.key, required this.subject, required this.info});

  static const List<Map<String, dynamic>> categories = [
    {
      'id': 'zukei_puzzle',
      'icon': '🧩',
      'name': {'ja': 'ずけいパズル', 'en': 'Shape Puzzle', 'vi': 'Xếp Hình'},
      'desc': {'ja': 'ブロックを ならべよう', 'en': 'Arrange blocks', 'vi': 'Xếp khối'},
      'color': Color(0xFF4CAF50),
      'mode': 'draw_outline',
      'subject': 'sansu',
    },
    {
      'id': 'dice',
      'icon': '🎲',
      'name': {'ja': 'さいころ', 'en': 'Dice', 'vi': 'Xúc xắc'},
      'desc': {'ja': 'おりたたんで みよう', 'en': 'Fold the net', 'vi': 'Gấp hình khai triển'},
      'color': Color(0xFFFF7043),
      'mode': 'dice',
      'subject': 'sansu',
    },
    {
      'id': 'pyramid',
      'icon': '🧱',
      'name': {'ja': 'かずの つみ木', 'en': 'Number Tower', 'vi': 'Tháp số'},
      'desc': {'ja': 'たして うめよう', 'en': 'Add and fill in', 'vi': 'Cộng để điền số'},
      'color': Color(0xFF8D6E63),
      'mode': 'pyramid',
      'subject': 'sansu',
    },
    {
      'id': 'calendar',
      'icon': '📅',
      'name': {'ja': 'カレンダー', 'en': 'Calendar', 'vi': 'Lịch'},
      'desc': {'ja': '日ご・日まえ・日かん', 'en': 'Days after, before, between', 'vi': 'Tính ngày tháng'},
      'color': Color(0xFF26A69A),
      'mode': 'calendar',
      'subject': 'sansu',
    },
    {
      'id': 'half',
      'icon': '🎨',
      'name': {'ja': 'はんぶんだけぬる', 'en': 'Paint Half', 'vi': 'Tô một nửa'},
      'desc': {'ja': 'はんぶんの ひろさを みつけよう', 'en': 'Find the half-coloured squares', 'vi': 'Tìm hình tô đúng một nửa'},
      'color': Color(0xFFAB47BC),
      'mode': 'half',
      'subject': 'sansu',
    },
    {
      'id': 'dotsquare',
      'icon': '🔲',
      'name': {'ja': 'ましかくは いくつ？', 'en': 'Count the Squares', 'vi': 'Đếm hình vuông'},
      'desc': {'ja': 'てんを つないで かぞえよう', 'en': 'Join dots and count', 'vi': 'Nối điểm và đếm'},
      'color': Color(0xFF42A5F5),
      'mode': 'dotsquare',
      'subject': 'sansu',
    },
    {
      'id': 'kanji',
      'icon': '✍️',
      'name': {'ja': 'かん字', 'en': 'Kanji', 'vi': 'Chữ Hán'},
      'desc': {'ja': 'かいて・よんで みよう', 'en': 'Write and read kanji', 'vi': 'Viết và đọc chữ Hán'},
      'color': Color(0xFF5C6BC0),
      'mode': 'kokugo',
      'subject': 'kokugo',
    },
  ];

  Widget _screenFor(Map<String, dynamic> cat) {
    switch (cat['mode']) {
      case 'dice':
        return DiceMenuScreen(category: cat);
      case 'pyramid':
        return PyramidCategoryScreen(category: cat);
      case 'calendar':
        return CalendarCategoryScreen(category: cat);
      case 'half':
        return HalfCategoryScreen(category: cat);
      case 'dotsquare':
        return DotSquareCategoryScreen(category: cat);
      case 'kokugo':
        return KokugoMenuScreen(category: cat);
      default:
        return CategoryScreen(category: cat);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stars = context.watch<RewardService>().totalStars;
    final lang = context.watch<LocaleService>().lang;
    final list = categories.where((c) => c['subject'] == subject).toList();
    final name = (info['name'] as Map<String, String>)[lang] ?? '';
    final color = info['color'] as Color;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9C4),
      appBar: AppBar(
        backgroundColor: color,
        title: Text(name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 2),
              Text('$stars',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
          ),
        ],
      ),
      body: Column(
        children: [
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
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final cat = list[i];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => _screenFor(cat)),
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
                            Text(cat['icon'] as String, style: const TextStyle(fontSize: 44)),
                            const SizedBox(height: 8),
                            Text(
                              (cat['name'] as Map<String, String>)[lang] ?? '',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              (cat['desc'] as Map<String, String>)[lang] ?? '',
                              style: const TextStyle(fontSize: 11, color: Colors.white70),
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
