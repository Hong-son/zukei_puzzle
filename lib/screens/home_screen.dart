import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/reward_service.dart';
import '../services/locale_service.dart';
import 'subject_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const List<Map<String, dynamic>> subjects = [
    {
      'id': 'sansu',
      'icon': '🔢',
      'name': {'ja': '算数', 'en': 'Math', 'vi': 'Toán (算数)'},
      'desc': {'ja': 'パズル・さいころ・ずけい', 'en': 'Puzzles, dice, shapes', 'vi': 'Xếp hình, xúc xắc, hình học'},
      'color': Color(0xFF4CAF50),
    },
    {
      'id': 'kokugo',
      'icon': '📖',
      'name': {'ja': '国語', 'en': 'Japanese', 'vi': 'Tiếng Nhật (国語)'},
      'desc': {'ja': 'かん字を かいて よもう', 'en': 'Write and read kanji', 'vi': 'Viết và đọc chữ Hán'},
      'color': Color(0xFF5C6BC0),
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
                  ? 'どの きょうかを やりますか？'
                  : lang == 'en'
                      ? 'Which subject do you want to study?'
                      : 'Bạn muốn học môn nào?',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 320,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: subjects.length,
                  itemBuilder: (context, i) {
                    final sub = subjects[i];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SubjectScreen(subject: sub['id'] as String, info: sub),
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: sub['color'] as Color,
                          borderRadius: BorderRadius.circular(24),
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
                            Text(sub['icon'] as String, style: const TextStyle(fontSize: 64)),
                            const SizedBox(height: 10),
                            Text(
                              (sub['name'] as Map<String, String>)[lang] ?? '',
                              style: const TextStyle(
                                  fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                (sub['desc'] as Map<String, String>)[lang] ?? '',
                                style: const TextStyle(fontSize: 12, color: Colors.white70),
                                textAlign: TextAlign.center,
                              ),
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
