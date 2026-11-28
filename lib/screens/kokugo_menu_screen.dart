import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/locale_service.dart';
import '../services/progress_service.dart';
import '../services/kokugo_engine.dart';
import 'kokugo_category_screen.dart';

class KokugoMenuScreen extends StatelessWidget {
  final Map<String, dynamic> category;
  const KokugoMenuScreen({super.key, required this.category});

  // Moi the tren menu la mot NHOM, co the chua nhieu dang bai giong nhau ('kinds').
  // Moi bai hoc van giu 'kind' rieng cua no nen man hinh choi khong doi.
  static const List<Map<String, dynamic>> kinds = [
    {
      'id': 'kaki',
      'kinds': ['kaki', 'doon', 'doyomi'],
      'icon': '✍️',
      'name': {'ja': 'かん字を かこう', 'en': 'Write the Kanji', 'vi': 'Viết chữ Hán'},
      'desc': {
        'ja': 'かたかな・おくりがな・おなじ おと・おなじ よみ',
        'en': 'Katakana, okurigana, same-sound & same-reading kanji',
        'vi': 'Katakana, okurigana, đồng âm & cùng cách đọc'
      },
      'color': Color(0xFF5C6BC0),
    },
    {
      'id': 'yomi',
      'kinds': ['yomi'],
      'icon': '🔤',
      'name': {'ja': 'かん字の よみ', 'en': 'Kanji Readings', 'vi': 'Cách đọc chữ Hán'},
      'desc': {'ja': 'よみを ひらがなで かこう', 'en': 'Write the reading', 'vi': 'Viết cách đọc bằng hiragana'},
      'color': Color(0xFF26A69A),
    },
    {
      'id': 'hitsujun',
      'kinds': ['hitsujun', 'kakijun'],
      'icon': '🖌️',
      'name': {'ja': 'かん字の ひつじゅん', 'en': 'Stroke Order', 'vi': 'Thứ tự nét chữ Hán'},
      'desc': {
        'ja': 'なんばん目？・正しい かきじゅんは？',
        'en': 'Which stroke? / Which order is right?',
        'vi': 'Nét thứ mấy? / Thứ tự viết nào đúng?'
      },
      'color': Color(0xFFEF6C00),
    },
    {
      'id': 'imi',
      'kinds': ['hantai', 'ruigi', 'erabu', 'hantaigo'],
      'icon': '↔️',
      'name': {'ja': 'ことばの いみ', 'en': 'Word Meanings', 'vi': 'Nghĩa của từ'},
      'desc': {
        'ja': 'はんたいの いみ・にた いみ・あう ことば',
        'en': 'Opposite & similar meanings / best word',
        'vi': 'Trái nghĩa, đồng nghĩa & chọn từ hợp nhất'
      },
      'color': Color(0xFFAB47BC),
    },
    {
      'id': 'ireru',
      'kinds': ['kanyou', 'setsuzoku', 'tsunagi', 'kotowaza'],
      'icon': '🧩',
      'name': {'ja': 'ことばを いれよう', 'en': 'Fill in the Word', 'vi': 'Điền từ vào chỗ trống'},
      'desc': {
        'ja': 'かんようく・ことわざ・せつぞくの ことば・つなぎことば',
        'en': 'Idioms, proverbs, fill-in words & connecting words',
        'vi': 'Quán dụng ngữ, tục ngữ, điền từ & từ nối'
      },
      'color': Color(0xFF43A047),
    },
    {
      'id': 'narabe',
      'kinds': ['narabe', 'bunsaku', 'shugo'],
      'icon': '📝',
      'name': {'ja': 'ぶんを つくろう', 'en': 'Build the Sentence', 'vi': 'Sắp xếp thành câu'},
      'desc': {
        'ja': 'ならべかえる・ことばを つかって かく・しゅご じゅつご',
        'en': 'Reorder words / write with given words / subject & predicate',
        'vi': 'Xếp từ / đặt câu / chủ ngữ & vị ngữ'
      },
      'color': Color(0xFF1E88E5),
    },
    {
      'id': 'shiji',
      'kinds': ['shiji', 'kosoado'],
      'icon': '👉',
      'name': {'ja': 'こそあど ことば', 'en': 'This / That Words', 'vi': 'Từ chỉ thị (これ・それ…)'},
      'desc': {
        'ja': 'これ・それ・そこは なにを さしているかな？・この その あの どの',
        'en': 'What does これ / それ point to? / この・その・あの・どの',
        'vi': 'これ・それ・そこ chỉ cái gì? / điền この・その・あの・どの'
      },
      'color': Color(0xFFEF6C00),
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
                  final ks = (k['kinds'] as List).cast<String>();
                  var total = 0;
                  var done = 0;
                  for (final kd in ks) {
                    final all = [
                      ...KokugoEngine.samples(kd),
                      ...progress.generatedKokugo.where((e) => e.kind == kd),
                    ];
                    total += all.length;
                    done += all.where((s) => progress.isDone(s.id)).length;
                  }
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => KokugoCategoryScreen(category: category, tile: k),
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
