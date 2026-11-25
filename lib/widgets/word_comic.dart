import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/word_help.dart';

// Truyen tranh dong nho (2-3 khung) bang emoji: tung khung hien ra lan luot, emoji nhun nhay.
// Cham vao de xem lai.
class WordComic extends StatefulWidget {
  final String wordKey;
  const WordComic({super.key, required this.wordKey});

  @override
  State<WordComic> createState() => _WordComicState();
}

class _WordComicState extends State<WordComic> {
  int _gen = 0; // tang len de chay lai hoat anh

  @override
  Widget build(BuildContext context) {
    final panels = WordHelp.panels(widget.wordKey);
    if (panels.isEmpty) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => setState(() => _gen++),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDE7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.shade300, width: 2),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (var i = 0; i < panels.length; i++) ...[
                if (i > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Center(
                      child: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.orange)
                          .animate(key: ValueKey('a$_gen-$i'), delay: (700 * i - 250).ms)
                          .fadeIn(duration: 250.ms),
                    ),
                  ),
                Expanded(child: _panel(panels[i], i)),
              ],
            ]),
          ),
          const SizedBox(height: 2),
          const Text('▶ タップで もういちど', style: TextStyle(fontSize: 10, color: Colors.black38)),
        ]),
      ),
    );
  }

  Widget _panel(ComicPanel p, int i) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black87, width: 1.5),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(p.emoji, style: const TextStyle(fontSize: 34))
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(begin: 0, end: -4, duration: 700.ms, curve: Curves.easeInOut),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(p.text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, height: 1.2)),
        ),
      ]),
    )
        .animate(key: ValueKey('p$_gen-$i'), delay: (700 * i).ms)
        .fadeIn(duration: 300.ms)
        .scale(begin: const Offset(0.7, 0.7), duration: 350.ms, curve: Curves.easeOutBack);
  }
}

// Mot muc giai thich: tu + tranh dong + nghia (chu) + dong phu
class WordHelpCard extends StatelessWidget {
  final HelpEntry entry;
  final String lang;
  const WordHelpCard({super.key, required this.entry, required this.lang});

  @override
  Widget build(BuildContext context) {
    final meaning = WordHelp.meaning(entry.key, lang, ja: entry.ja);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('「${entry.title}」', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        WordComic(wordKey: entry.key),
        if (meaning.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(meaning, style: const TextStyle(fontSize: 15)),
        ],
        if (entry.extra.isNotEmpty)
          Text(entry.extra, style: const TextStyle(fontSize: 13, color: Colors.black54)),
      ]),
    );
  }
}

// Hop thoai giai thich nghia cac tu (mien phi) -- dung cho nut 📖
Future<void> showWordHelpDialog(BuildContext context, List<HelpEntry> entries, String lang, {String? footer}) {
  final seen = <String>{};
  final list = [for (final e in entries) if (seen.add(e.key)) e];
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(lang == 'ja' ? '📖 ことばの いみ' : (lang == 'en' ? '📖 Word meanings' : '📖 Nghĩa của từ')),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final e in list) WordHelpCard(entry: e, lang: lang),
            if (footer != null) ...[const Divider(), Text(footer, style: const TextStyle(fontSize: 15))],
          ]),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
    ),
  );
}
