import 'package:flutter/material.dart';

// Van ban co furigana: viet 漢字《よみ》 thi phan 《》 hien nho tren dau chu Han.
// Vi du: '二人《ふたり》は けんえんの なかだ。'
class RubyText extends StatelessWidget {
  final String text;
  final TextStyle style;
  const RubyText(this.text, {super.key, required this.style});

  static final RegExp _re = RegExp(r'([一-鿿々]+)《([^》]+)》');

  @override
  Widget build(BuildContext context) {
    final matches = _re.allMatches(text).toList();
    if (matches.isEmpty) return Text(text, style: style);
    final base = style.fontSize ?? 20;
    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in matches) {
      if (m.start > last) spans.add(TextSpan(text: text.substring(last, m.start)));
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.bottom,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(m.group(2)!,
              style: TextStyle(fontSize: base * 0.45, height: 1.0, color: Colors.black54)),
          Text(m.group(1)!, style: style),
        ]),
      ));
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return Text.rich(TextSpan(style: style, children: spans));
  }
}
