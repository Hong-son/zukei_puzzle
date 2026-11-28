import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/elapsed_timer.dart';
import '../models/kokugo_lesson.dart';
import '../services/reward_service.dart';
import '../services/locale_service.dart';
import '../services/progress_service.dart';
import '../services/kokugo_engine.dart';
import '../widgets/hint_dialog.dart';
import '../widgets/word_comic.dart';
import '../widgets/ruby_text.dart';
import '../services/word_help.dart';
import 'reward_screen.dart';

// あてはまる ことば: cho trong trong cau, chon tu trong khung (bank) de dien.
// Moi tu chi duoc dung mot lan. Khi sai chi bao sai, khong chi ra cau nao sai.
class KokugoWordScreen extends StatefulWidget {
  final KokugoLesson lesson;
  const KokugoWordScreen({super.key, required this.lesson});

  @override
  State<KokugoWordScreen> createState() => _KokugoWordScreenState();
}

class _KokugoWordScreenState extends State<KokugoWordScreen> {
  late List<String> _ans;
  final Set<int> _locked = {}; // cau da duoc goi y (khong doi duoc)
  int _sel = 0;
  int _tries = 0;

  List<KokugoItem> get _items => widget.lesson.items;
  // 'tsunagi': tu trong khung duoc dung nhieu lan
  bool get _reuse => _items.isNotEmpty && _items.first.extra['reuse'] == true;
  String _correct(int i) => _items[i].firstBlank.reads.first;
  // 'doyomi': 1つの よみに 2つの かん字 (どちらの じゅんでも OK) -> extra['any']
  List<String> _anyOf(int i) {
    final a = _items[i].extra['any'];
    return a is List ? a.cast<String>() : const [];
  }

  bool _ok(int i) {
    final any = _anyOf(i);
    return any.isNotEmpty ? any.contains(_ans[i]) : _ans[i] == _correct(i);
  }

  @override
  void initState() {
    super.initState();
    _ans = List<String>.filled(_items.length, '');
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 5),
    ));
  }

  int _nextEmpty(int from) {
    for (var k = 1; k <= _items.length; k++) {
      final j = (from + k) % _items.length;
      if (_ans[j].isEmpty && !_locked.contains(j)) return j;
    }
    return from;
  }

  void _pick(String w) {
    // tu da dung trong cau da khoa thi khong dung lai duoc (tru khi cho phep dung nhieu lan)
    if (!_reuse) {
      for (final j in _locked) {
        if (_ans[j] == w) return;
      }
    }
    var target = _sel;
    if (_locked.contains(target)) target = _nextEmpty(target);
    if (_locked.contains(target)) return;
    setState(() {
      if (!_reuse) {
        for (var j = 0; j < _ans.length; j++) {
          if (_ans[j] == w && !_locked.contains(j)) _ans[j] = '';
        }
      }
      _ans[target] = w;
      _sel = _nextEmpty(target);
    });
  }

  void _tapBlank(int i) {
    setState(() {
      if (_sel == i && _ans[i].isNotEmpty && !_locked.contains(i)) {
        _ans[i] = ''; // cham lan nua de xoa
      } else {
        _sel = i;
      }
    });
  }

  Future<void> _onCheck() async {
    final lang = context.read<LocaleService>().lang;
    if (_ans.any((a) => a.isEmpty)) {
      _snack(lang == 'ja'
          ? 'まだ かいていない ところが あるよ'
          : lang == 'en'
              ? 'Some boxes are still empty'
              : 'Còn ô chưa điền');
      return;
    }
    _tries++;
    final bad = <String>[];
    for (var i = 0; i < _ans.length; i++) {
      if (!_ok(i)) bad.add(_items[i].label);
    }
    final ok = bad.isEmpty;
    if (ok) {
      final stars = RewardService.calcStars(_tries);
      final rs = context.read<RewardService>();
      final ps = context.read<ProgressService>();
      await rs.addReward(stars);
      await ps.markCompleted(widget.lesson.id);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => RewardScreen(tries: _tries, starsEarned: stars)),
      );
      return;
    }
    _snack(KokugoEngine.withWrong(KokugoEngine.wrongMessage(
        const ['kotowaza', 'tsunagi', 'doyomi', 'kosoado'].contains(widget.lesson.kind) ? widget.lesson.kind : 'setsuzoku', lang), bad, lang));
  }

  // Goi y: dien dung san mot cau chua dung va khoa lai
  void _onHint() {
    final rs = context.read<RewardService>();
    final lang = context.read<LocaleService>().lang;
    showDialog(
      context: context,
      builder: (_) => HintDialog(onSelect: (opt) async {
        var target = -1;
        for (var i = 0; i < _ans.length; i++) {
          if (!_ok(i) && !_locked.contains(i)) {
            target = i;
            break;
          }
        }
        if (target < 0) {
          _snack(lang == 'ja' ? 'ぜんぶ あっているよ！' : (lang == 'en' ? 'All correct!' : 'Đúng hết rồi!'));
          return;
        }
        final ok = await rs.spendStars(opt.cost);
        if (!ok || !mounted) return;
        var w = _correct(target);
        final any = _anyOf(target);
        if (any.isNotEmpty) {
          // ほかの 問題で つかっていない かん字を えらぶ
          w = any.firstWhere((k) => !List.generate(_ans.length, (j) => j).any((j) => j != target && _ans[j] == k), orElse: () => w);
        }
        setState(() {
          if (!_reuse) {
            for (var j = 0; j < _ans.length; j++) {
              if (_ans[j] == w && j != target) _ans[j] = '';
            }
          }
          _ans[target] = w;
          _locked.add(target);
          _sel = _nextEmpty(target);
        });
      }),
    );
  }

  void _onReset() {
    setState(() {
      _ans = List<String>.filled(_items.length, '');
      _locked.clear();
      _sel = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final stars = context.watch<RewardService>().totalStars;
    final lang = context.watch<LocaleService>().lang;
    final l = widget.lesson;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9C4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00897B),
        title: Text(l.title[lang] ?? '',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          ElapsedTimer(lessonId: widget.lesson.id),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.amber.shade700, borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.star, color: Colors.white, size: 18),
                const SizedBox(width: 4),
                Text('$stars', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ]),
            ),
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Text(l.question[lang] ?? '',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        ),
        if (l.kind == 'kotowaza') _kotoGuide(lang),
        if (l.kind == 'tsunagi') _tsunagiGuide(lang),
        if (l.kind == 'kosoado') _kosoadoGuide(lang),
        // khung chua cac tu de chon
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black54, width: 1.5),
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [for (final w in l.bank) _chip(w)],
            ),
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                itemCount: _items.length,
                itemBuilder: (context, i) => _item(i, _items[i]),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          color: Colors.white,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _ToolBtn(icon: Icons.refresh, label: 'リセット', color: Colors.red, onTap: _onReset),
            _ToolBtn(icon: Icons.lightbulb, label: 'ヒント', color: Colors.amber, onTap: _onHint),
            if (widget.lesson.kind != 'kotowaza' && widget.lesson.kind != 'doyomi' && widget.lesson.kind != 'kosoado')
            _ToolBtn(
                icon: Icons.menu_book,
                label: 'いみ',
                color: Colors.teal,
                onTap: () => showWordHelpDialog(
                    context, [for (final w in widget.lesson.bank) HelpEntry(w)], context.read<LocaleService>().lang)),
            ElevatedButton.icon(
              onPressed: _onCheck,
              icon: const Icon(Icons.check_circle, size: 18),
              label: const Text('こたえる', style: TextStyle(fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3F51B5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _chip(String w) {
    final used = !_reuse && _ans.contains(w);
    final lockedUse = !_reuse && _locked.any((j) => _ans[j] == w);
    return GestureDetector(
      onTap: () => _pick(w),
      child: Opacity(
        opacity: used ? 0.4 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: lockedUse ? Colors.grey.shade300 : const Color(0xFFE0F2F1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF00897B), width: 2),
          ),
          child: Text(w, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  // つなぎことばって なあに？ -- sach: trang 4 (khung giai thich)
  Widget _tsunagiGuide(String lang) {
    final rows = <List<String>>[
      [
        'だから・すると・それで・そこで・したがって',
        lang == 'ja'
            ? 'まえの ことが りゆうや げんいんに なって、つぎの ことが おこった ときに つかう。'
            : lang == 'en'
                ? 'The first thing is the reason or cause, and the next thing happens because of it.'
                : 'Việc trước là lý do/nguyên nhân, và việc sau xảy ra do đó.',
      ],
      [
        'だけど・しかし・けれども・でも・だが・ところが',
        lang == 'ja'
            ? 'まえと ちがう ことや、はんたいの ことを いう ときに つかう。'
            : lang == 'en'
                ? 'Used to say something different from, or opposite to, what came before.'
                : 'Dùng để nói điều khác hoặc trái ngược với điều trước.',
      ],
      [
        'さらに・そのうえ・しかも・そして・それに',
        lang == 'ja'
            ? 'まえの ことに、あとの ことを つけくわえる ときに つかう。'
            : lang == 'en'
                ? 'Used to add another thing to what came before.'
                : 'Dùng để thêm một điều nữa vào điều trước.',
      ],
    ];
    const colors = [Color(0xFFFFE0B2), Color(0xFFBBDEFB), Color(0xFFC8E6C9)];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE0F7FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.teal.shade300, width: 1.5),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 10),
          dense: true,
          title: Text(
              lang == 'ja' ? '📘 つなぎことばって なあに？' : (lang == 'en' ? '📘 What are connecting words?' : '📘 Từ nối là gì?'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
          children: [
            Text(
              lang == 'ja'
                  ? '文と 文、ことばと ことば などを つなぐ はたらきを もつ ことばの こと。'
                  : lang == 'en'
                      ? 'Words that join sentences to sentences, or words to words.'
                      : 'Là những từ có tác dụng nối câu với câu, từ với từ.',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 6),
            for (var i = 0; i < rows.length; i++)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: colors[i], borderRadius: BorderRadius.circular(8)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(rows[i][0], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  Text('➡ ${rows[i][1]}', style: const TextStyle(fontSize: 12)),
                ]),
              ),
          ],
        ),
      ),
    );
  }

  // こそあどことばって なあに？ -- sach: trang 4 (khung giai thich)
  Widget _kosoadoGuide(String lang) {
    final rows = <List<String>>[
      [
        'これ・ここ・この・こんな',
        lang == 'ja'
            ? 'じぶんに ちかい ところの ものを さす。'
            : lang == 'en'
                ? 'Points to something near the speaker.'
                : 'Chỉ vật ở gần người nói.',
      ],
      [
        'それ・そこ・その・そんな',
        lang == 'ja'
            ? 'あい手に ちかい ところの ものを さす。'
            : lang == 'en'
                ? 'Points to something near the listener.'
                : 'Chỉ vật ở gần người nghe.',
      ],
      [
        'あれ・あそこ・あの・あんな',
        lang == 'ja'
            ? 'とおい ところの ものを さす。'
            : lang == 'en'
                ? 'Points to something far away.'
                : 'Chỉ vật ở xa.',
      ],
      [
        'どれ・どこ・どの・どんな',
        lang == 'ja'
            ? 'どれか はっきり わからない ものを さす。'
            : lang == 'en'
                ? 'Points to something that is not clear (which one?).'
                : 'Chỉ vật chưa rõ là cái nào.',
      ],
    ];
    const colors = [Color(0xFFFFE0B2), Color(0xFFBBDEFB), Color(0xFFC8E6C9), Color(0xFFE1BEE7)];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE0F7FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.teal.shade300, width: 1.5),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 10),
          dense: true,
          title: Text(
              lang == 'ja' ? '📘 こそあどことばって なあに？' : (lang == 'en' ? '📘 What are こそあど words?' : '📘 Từ こそあど là gì?'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
          children: [
            Text(
              lang == 'ja'
                  ? '「これ」「それ」「あれ」「どれ」など「さししめす ことば」を「こそあどことば」と いいます。'
                  : lang == 'en'
                      ? 'Words like これ, それ, あれ, どれ that point to things are called こそあど words.'
                      : 'Những từ chỉ vào sự vật như これ・それ・あれ・どれ gọi là từ こそあど.',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 6),
            for (var i = 0; i < rows.length; i++)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: colors[i], borderRadius: BorderRadius.circular(8)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(rows[i][0], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  Text('➡ ${rows[i][1]}', style: const TextStyle(fontSize: 12)),
                ]),
              ),
          ],
        ),
      ),
    );
  }

  // ことわざって なあに？ (れい) -- sach: trang 3
  Widget _kotoGuide(String lang) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F7FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.teal.shade300, width: 1.5),
        ),
        child: Text(
          lang == 'ja'
              ? 'ことわざ ＝ むかしから いいつたえられている おしえや いましめを、みじかい ことばに したもの。\n〈れい〉さるも 木から おちる ＝ どんな 名人でも しっぱいする ことが あると いう たとえ。'
              : lang == 'en'
                  ? 'A proverb is a short saying passed down since long ago that teaches a lesson.\nExample: さるも木からおちる = even an expert can make a mistake.'
                  : 'ことわざ là câu nói ngắn truyền từ xưa, chứa lời dạy hoặc lời nhắc nhở.\nVí dụ: さるも木からおちる = dù là cao thủ cũng có lúc thất bại.',
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  Widget _kotoItem(int i, KokugoItem it, String lang) {
    final selected = _sel == i;
    final locked = _locked.contains(i);
    final text = it.parts.firstWhere((p) => !p.blank).text;
    final emoji = (it.extra['e'] as String?) ?? '';
    final m = (it.extra['m'] as Map?)?[lang] as String?;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 40, child: Text(it.label, style: const TextStyle(fontSize: 16))),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4))),
          if (emoji.isNotEmpty)
            Padding(padding: const EdgeInsets.only(left: 8), child: Text(emoji, style: const TextStyle(fontSize: 32))),
        ]),
        if (m != null && lang != 'ja')
          Padding(
            padding: const EdgeInsets.only(left: 40, top: 2),
            child: Text(m, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _tapBlank(i),
          child: Container(
            width: double.infinity,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: locked ? const Color(0xFFE3F2FD) : (selected ? const Color(0xFFFFF3E0) : Colors.grey.shade100),
              border: Border.all(color: selected ? const Color(0xFFEF6C00) : Colors.black87, width: selected ? 3 : 2),
            ),
            child: Text(_ans[i],
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
          ),
        ),
      ]),
    );
  }

  Widget _item(int i, KokugoItem it) {
    if (widget.lesson.kind == 'kotowaza') return _kotoItem(i, it, context.read<LocaleService>().lang);
    final selected = _sel == i;
    final locked = _locked.contains(i);
    final children = <Widget>[];
    for (final part in it.parts) {
      if (part.blank) {
        children.add(GestureDetector(
          onTap: () => _tapBlank(i),
          child: Container(
            width: 130,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: locked ? const Color(0xFFE3F2FD) : (selected ? const Color(0xFFFFF3E0) : Colors.grey.shade100),
              border: Border.all(
                color: selected ? const Color(0xFFEF6C00) : Colors.black87,
                width: selected ? 3 : 2,
              ),
            ),
            child: Text(_ans[i],
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
          ),
        ));
      } else if (part.text.isNotEmpty) {
        children.add(RubyText(part.text, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.black87)));
      }
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        SizedBox(width: 44, child: Text(it.label, style: const TextStyle(fontSize: 16))),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            runSpacing: 6,
            children: children,
          ),
        ),
      ]),
    );
  }
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ToolBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 20),
          Text(label, style: TextStyle(fontSize: 10, color: color)),
        ]),
      ),
    );
  }
}
