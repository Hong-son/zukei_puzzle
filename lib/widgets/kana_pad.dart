import 'package:flutter/material.dart';

// Bang chon hiragana (khong can ban phim)
class KanaPad extends StatefulWidget {
  final String initial;
  const KanaPad({super.key, required this.initial});

  @override
  State<KanaPad> createState() => _KanaPadState();
}

class _KanaPadState extends State<KanaPad> {
  late String _cur = widget.initial;

  static const List<List<String>> _rows = [
    ['あ', 'い', 'う', 'え', 'お'],
    ['か', 'き', 'く', 'け', 'こ'],
    ['さ', 'し', 'す', 'せ', 'そ'],
    ['た', 'ち', 'つ', 'て', 'と'],
    ['な', 'に', 'ぬ', 'ね', 'の'],
    ['は', 'ひ', 'ふ', 'へ', 'ほ'],
    ['ま', 'み', 'む', 'め', 'も'],
    ['や', '', 'ゆ', '', 'よ'],
    ['ら', 'り', 'る', 'れ', 'ろ'],
    ['わ', '', 'を', '', 'ん'],
    ['が', 'ぎ', 'ぐ', 'げ', 'ご'],
    ['ざ', 'じ', 'ず', 'ぜ', 'ぞ'],
    ['だ', 'ぢ', 'づ', 'で', 'ど'],
    ['ば', 'び', 'ぶ', 'べ', 'ぼ'],
    ['ぱ', 'ぴ', 'ぷ', 'ぺ', 'ぽ'],
    ['ゃ', 'ゅ', 'ょ', 'っ', 'ー'],
  ];

  Widget _key(String k) {
    if (k.isEmpty) return const SizedBox(width: 52, height: 46);
    return Padding(
      padding: const EdgeInsets.all(2),
      child: SizedBox(
        width: 48,
        height: 42,
        child: ElevatedButton(
          onPressed: () => setState(() => _cur += k),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(k, style: const TextStyle(fontSize: 22)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.85;
    return Dialog(
      backgroundColor: const Color(0xFFFFF8E1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 320, maxHeight: maxH),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: double.infinity,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade500, width: 2),
              ),
              child: Text(_cur, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: Column(children: [
                  for (final row in _rows)
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      for (final k in row) _key(k),
                    ]),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              OutlinedButton.icon(
                onPressed: _cur.isEmpty
                    ? null
                    : () => setState(() => _cur = _cur.characters.skipLast(1).toString()),
                icon: const Icon(Icons.backspace_outlined, size: 18),
                label: const Text('けす'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, _cur),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3F51B5), foregroundColor: Colors.white),
                child: const Text('OK', style: TextStyle(fontSize: 16)),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
