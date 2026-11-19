import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/reward_service.dart';

class HintOption {
  final int cost;
  final String labelJa;
  const HintOption({required this.cost, required this.labelJa});
}

const hintOptions = [
  HintOption(cost: 1, labelJa: 'ブロックを 1つ みせる'),
];

class HintDialog extends StatelessWidget {
  final Function(HintOption) onSelect;
  const HintDialog({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final stars = context.watch<RewardService>().totalStars;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('ヒントを つかう？',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.star, color: Colors.amber, size: 20),
            const SizedBox(width: 4),
            Text('もっている: $stars', style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ]),
          const SizedBox(height: 10),
          const Text('⚠️ ヒントを つかうと ⭐ が へります',
              style: TextStyle(fontSize: 12, color: Colors.orange)),
          const SizedBox(height: 12),
          ...hintOptions.map((opt) {
            final ok = stars >= opt.cost;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: ok
                      ? () {
                          Navigator.pop(context);
                          onSelect(opt);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(opt.labelJa, style: const TextStyle(fontSize: 15)),
                    Row(children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      Text('-${opt.cost}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ]),
                  ]),
                ),
              ),
            );
          }),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('やめる', style: TextStyle(color: Colors.grey)),
          ),
        ]),
      ),
    );
  }
}

