import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RewardScreen extends StatelessWidget {
  final int tries;
  final int starsEarned;
  final VoidCallback? onNext;
  const RewardScreen({
    super.key,
    required this.tries,
    required this.starsEarned,
    this.onNext,
  });

  Map<String, dynamic> get rewardData {
    if (tries == 1) {
      return {'stamp': '🌟', 'title': 'かんぺき！', 'sub': 'いっかいで できたよ！',
          'color': const Color(0xFFFFD700)};
    } else if (tries <= 3) {
      return {'stamp': '⭐', 'title': 'すごい！', 'sub': 'よく できました！',
          'color': const Color(0xFF4CAF50)};
    } else if (tries <= 5) {
      return {'stamp': '👍', 'title': 'がんばったね！', 'sub': 'つぎも がんばろう！',
          'color': const Color(0xFF2196F3)};
    } else {
      return {'stamp': '😊', 'title': 'よく できました！', 'sub': 'れんしゅうを つづけよう！',
          'color': Colors.orange};
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = rewardData;
    final color = r['color'] as Color;
    return Scaffold(
      backgroundColor: color,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(r['stamp'] as String, style: const TextStyle(fontSize: 110))
                  .animate()
                  .scale(
                      begin: const Offset(0, 0),
                      end: const Offset(1, 1),
                      duration: 600.ms,
                      curve: Curves.elasticOut),
              const SizedBox(height: 16),
              Text(r['title'] as String,
                      style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.white))
                  .animate()
                  .fadeIn(delay: 400.ms),
              const SizedBox(height: 6),
              Text(r['sub'] as String,
                      style: const TextStyle(fontSize: 17, color: Colors.white70))
                  .animate()
                  .fadeIn(delay: 600.ms),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  starsEarned,
                  (i) => const Icon(Icons.star, color: Colors.amber, size: 36)
                      .animate(delay: Duration(milliseconds: 700 + i * 200))
                      .scale(curve: Curves.elasticOut),
                ),
              ),
              const SizedBox(height: 6),
              Text('+$starsEarned ⭐ もらったよ！',
                      style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold))
                  .animate()
                  .fadeIn(delay: 800.ms),
              const SizedBox(height: 32),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.list),
                    label: const Text('もんだいの いちらんへ',
                        style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: color,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        Navigator.popUntil(context, (route) => route.isFirst),
                    icon: const Icon(Icons.home),
                    label: const Text('ホームへもどる',
                        style: TextStyle(fontSize: 16)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 1000.ms),
            ],
          ),
        ),
      ),
    );
  }
}
