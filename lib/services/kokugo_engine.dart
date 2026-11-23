import 'dart:math';
import '../models/kokugo_lesson.dart';
import 'stroke_data.dart';

// Bai 国語 (lop 1): viet chu Han (kaki) va viet cach doc (yomi).
// Kho tu vung va cau vi du do ta tu soan.
class KokugoEngine {
  static const List<String> kinds = ['kaki', 'yomi', 'hitsujun', 'hantai', 'kanyou'];

  static const Map<String, Map<String, String>> baseNames = {
    'kaki': {'ja': 'かん字を かこう', 'en': 'Write the Kanji', 'vi': 'Viết chữ Hán'},
    'yomi': {'ja': 'かん字の よみ', 'en': 'Kanji Readings', 'vi': 'Cách đọc chữ Hán'},
    'hitsujun': {'ja': 'かん字の ひつじゅん', 'en': 'Stroke Order', 'vi': 'Thứ tự nét chữ Hán'},
    'hantai': {'ja': 'はんたいの いみの かん字', 'en': 'Opposite Kanji', 'vi': 'Chữ Hán trái nghĩa'},
    'kanyou': {'ja': 'かんようく', 'en': 'Idioms', 'vi': 'Thành ngữ (bộ phận cơ thể)'},
  };

  static const List<String> numerals = ['一', '二', '三', '四', '五', '六', '七', '八', '九', '十'];

  static const List<String> _circ = ['①', '②', '③', '④', '⑤', '⑥', '⑦', '⑧', '⑨', '⑩'];
  static const List<String> _kana3 = ['ア', 'イ', 'ウ'];

  static Map<String, String> questionFor(String kind) {
    if (kind == 'hitsujun') {
      return {
        'ja': '→の ところは なんばん目に かきますか。○に かん字で すう字を かきましょう。',
        'en': 'Which stroke (in writing order) is the arrow pointing to? Write the number in kanji in the circle.',
        'vi': 'Mũi tên chỉ nét thứ mấy (theo thứ tự viết)? Viết số bằng chữ Hán vào hình tròn.',
      };
    }
    if (kind == 'kanyou') {
      return {
        'ja': '下の いみに あう かんようくに なるように、からだの ぶぶんを あらわす ことばを □に かきましょう。',
        'en': 'Write the word for a body part in the box so that the idiom matches the meaning below.',
        'vi': 'Viết từ chỉ bộ phận cơ thể vào ô để thành quán dụng ngữ đúng với nghĩa bên dưới.',
      };
    }
    if (kind == 'hantai') {
      return {
        'ja': 'はんたいの いみに なる かん字を くみあわせて、ことばを かんせいさせましょう。できた ことばを □に、よみがなを（　）に かきましょう。',
        'en': 'Combine kanji with opposite meanings to make words. Write each word in the boxes and its reading in ( ).',
        'vi': 'Ghép các chữ Hán có nghĩa trái ngược để thành từ. Viết từ vào ô, cách đọc vào ( ).',
      };
    }
    if (kind == 'kaki') {
      return {
        'ja': 'かたかなを かん字に なおして、□に かきましょう。',
        'en': 'Rewrite the katakana as kanji and write it in the boxes.',
        'vi': 'Đổi katakana thành chữ Hán rồi viết vào các ô.',
      };
    }
    return {
      'ja': '──せんの かん字の よみを、（　）に ひらがなで かきましょう。',
      'en': 'Write the reading of the underlined kanji in hiragana in the ( ).',
      'vi': 'Viết cách đọc bằng hiragana của chữ Hán gạch chân vào ( ).',
    };
  }

  static String wrongMessage(String kind, String lang) {
    if (kind == 'hitsujun') {
      return lang == 'ja'
          ? 'ちがう ところが あるよ。かく じゅんばんを おもいだして みよう'
          : lang == 'en'
              ? 'Some answers are wrong. Think about the writing order'
              : 'Có câu chưa đúng. Hãy nhớ lại thứ tự viết nét';
    }
    if (kind == 'kanyou') {
      return lang == 'ja'
          ? 'ちがう ところが あるよ。いみを よく よんで、からだの ことばを かんがえよう'
          : lang == 'en'
              ? 'Something is wrong. Read the meaning again and think of the body part'
              : 'Có chỗ chưa đúng. Hãy đọc kỹ nghĩa và nghĩ đến bộ phận cơ thể';
    }
    if (kind == 'hantai') {
      return lang == 'ja'
          ? 'ちがう ところが あるよ。はんたいの いみの かん字の くみあわせと よみを たしかめよう'
          : lang == 'en'
              ? 'Something is wrong. Check the opposite pairs and the readings'
              : 'Có chỗ chưa đúng. Hãy kiểm tra cặp chữ trái nghĩa và cách đọc';
    }
    if (kind == 'kaki') {
      return lang == 'ja'
          ? 'できなかった ところを もういちど かいてみよう'
          : lang == 'en'
              ? 'Try writing the missed ones again'
              : 'Hãy viết lại những chữ chưa đúng nhé';
    }
    return lang == 'ja'
        ? 'ちがう ところが あるよ。もういちど！'
        : lang == 'en'
            ? 'Some answers are wrong. Try again!'
            : 'Có chỗ chưa đúng. Thử lại nhé!';
  }

  // ---------- tao phan tu ----------
  static KokugoPart _t(String s) => KokugoPart(s);
  static KokugoPart _b(String kanji, String reads) =>
      KokugoPart(kanji, blank: true, reads: reads.split('|'));
  static KokugoPart _y(String kanji, List<String> answers) =>
      KokugoPart(kanji, blank: true, reads: answers);

  static KokugoItem _kakiItem(int no, String before, String kanji, String reads, String after) {
    return KokugoItem(label: _circ[no], parts: [
      if (before.isNotEmpty) _t(before),
      _b(kanji, reads),
      if (after.isNotEmpty) _t(after),
    ]);
  }

  // cau 'hitsujun': ch = chu Han, n = net duoc chi, p = dau net (0/1/-1), a = goc mui ten
  static KokugoItem _strokeItem(int no, String ch, int n, {int p = -1, double? a}) {
    return KokugoItem(
      label: '（${no + 1}）',
      parts: [_t(ch)],
      extra: {'k': ch, 'n': n, 'p': p, if (a != null) 'a': a},
    );
  }

  // cau 'kanyou': dap an (nhieu cach viet cach nhau bang |) + phan sau cho trong + nghia
  static KokugoItem _idiomItem(int no, String before, String answers, String after, String meaning) {
    return KokugoItem(
      label: '（${no + 1}）',
      parts: [
        if (before.isNotEmpty) _t(before),
        KokugoPart('', blank: true, reads: answers.split('|')),
        _t(after),
      ],
      extra: {'m': meaning},
    );
  }

  // [truoc cho trong, dap an, sau cho trong, nghia]
  static const List<List<String>> _idiomBank = [
    ['', 'あたま|頭', 'がかたい', 'ものわかりが わるい。ゆうずうが きかない。'],
    ['', 'あし|足', 'がぼうになる', 'ながい あいだ 立ったり あるいたり して、足が つかれる。'],
    ['', 'くち|口', 'がすべる', 'いっては いけないことを、うっかり いってしまう。'],
    ['', 'て|手', 'にあせをにぎる', 'どうなることかと はらはらする。'],
    ['', 'みみ|耳', 'をうたがう', 'しんじられない はなしを きいて、とまどう。'],
    ['', 'め|目', 'をまるくする', 'びっくりして 目を 見ひらく。'],
    ['', 'はな|鼻', 'がたかい', 'とくいになる。ほこらしくおもう。'],
    ['', 'くび|首', 'をながくする', 'まちどおしくおもい、いまかいまかと まちわびる。'],
    ['', 'め|目', 'がたかい', 'よい ものを みわける ちからが ある。'],
    ['', 'みみ|耳', 'がいたい', '人から いわれる ことが つらくて、きくのが いやだ。'],
    ['', 'くち|口', 'がかたい', 'ひみつを まもって、ほかの 人に いわない。'],
    ['', 'かお|顔', 'がひろい', 'しっている 人が たくさん いる。'],
    ['', 'て|手', 'がたりない', 'しごとを する 人が たりない。'],
    ['', 'め|目', 'がまわる', 'とても いそがしい。'],
    ['', 'はら|腹', 'がたつ', 'おこる。'],
    ['', 'あたま|頭', 'がいたい', 'こまって、なやむ。'],
    ['', 'くび|首', 'をひねる', 'ふしぎに おもう。'],
    ['', 'むね|胸', 'がおどる', 'うれしくて、わくわくする。'],
    ['', 'かた|肩', 'をおとす', 'がっかりして、げんきが なくなる。'],
    ['', 'うで|腕', 'をみがく', 'じょうずに なるように れんしゅうする。'],
  ];

  // Cac bo phan co the trong kho thanh ngu: [chu Han, hiragana], khong lap
  static List<List<String>> bodyParts() {
    final seen = <String>{};
    final out = <List<String>>[];
    for (final e in _idiomBank) {
      final a = e[1].split('|');
      if (a.length >= 2 && seen.add(a[1])) out.add([a[1], a[0]]);
    }
    return out;
  }

  // Cac cap tu trai nghia: [tu, cach doc]
  static const List<List<String>> _hantaiPairs = [
    ['大小', 'だいしょう'],
    ['左右', 'さゆう'],
    ['男女', 'だんじょ'],
    ['上下', 'じょうげ'],
  ];

  // Kho tu ghep tu hai chu Han trai nghia: [tu, cach doc, muc]
  // muc 1: chu hoc o lop 1-2, muc 2: chu quen thuoc hon, muc 3: tu kho hon
  static const List<List<String>> _hantaiPool = [
    ['大小', 'だいしょう', '1'], ['上下', 'じょうげ', '1'], ['左右', 'さゆう', '1'], ['男女', 'だんじょ', '1'],
    ['前後', 'ぜんご', '1'], ['内外', 'ないがい', '1'], ['天地', 'てんち', '1'], ['東西', 'とうざい', '1'],
    ['南北', 'なんぼく', '1'], ['昼夜', 'ちゅうや', '1'], ['多少', 'たしょう', '1'], ['強弱', 'きょうじゃく', '1'],
    ['古今', 'ここん', '1'], ['売買', 'ばいばい', '1'], ['朝夕', 'ちょうせき', '1'],
    ['長短', 'ちょうたん', '2'], ['高低', 'こうてい', '2'], ['明暗', 'めいあん', '2'], ['新旧', 'しんきゅう', '2'],
    ['遠近', 'えんきん', '2'], ['寒暖', 'かんだん', '2'], ['進退', 'しんたい', '2'], ['開閉', 'かいへい', '2'],
    ['増減', 'ぞうげん', '2'], ['貸借', 'たいしゃく', '2'], ['老若', 'ろうにゃく', '2'], ['苦楽', 'くらく', '2'],
    ['公私', 'こうし', '2'], ['生死', 'せいし', '2'], ['表裏', 'ひょうり', '2'], ['勝敗', 'しょうはい', '2'],
    ['損得', 'そんとく', '2'], ['善悪', 'ぜんあく', '2'], ['主従', 'しゅじゅう', '2'], ['縦横', 'じゅうおう', '2'],
    ['伸縮', 'しんしゅく', '2'], ['難易', 'なんい', '2'], ['往復', 'おうふく', '2'],
    ['賛否', 'さんぴ', '3'], ['貧富', 'ひんぷ', '3'], ['乾湿', 'かんしつ', '3'], ['軽重', 'けいじゅう', '3'],
    ['深浅', 'しんせん', '3'], ['広狭', 'こうきょう', '3'], ['真偽', 'しんぎ', '3'], ['正誤', 'せいご', '3'],
    ['是非', 'ぜひ', '3'], ['有無', 'うむ', '3'], ['昇降', 'しょうこう', '3'], ['師弟', 'してい', '3'],
    ['愛憎', 'あいぞう', '3'], ['吉凶', 'きっきょう', '3'], ['干満', 'かんまん', '3'], ['浮沈', 'ふちん', '3'],
    ['攻守', 'こうしゅ', '3'], ['発着', 'はっちゃく', '3'], ['出欠', 'しゅっけつ', '3'], ['授受', 'じゅじゅ', '3'],
    ['収支', 'しゅうし', '3'], ['緩急', 'かんきゅう', '3'], ['硬軟', 'こうなん', '3'], ['優劣', 'ゆうれつ', '3'],
    ['美醜', 'びしゅう', '3'], ['巧拙', 'こうせつ', '3'], ['興亡', 'こうぼう', '3'], ['成否', 'せいひ', '3'],
  ];

  // Chon cac cap cho bai tu sinh: moi chu Han chi xuat hien mot lan trong bai,
  // va hai chu khac cap khong ghep thanh mot tu khac trong kho (tranh nhieu dap an).
  static List<List<String>> _pickHantai(Random r, int count, int lv) {
    final known = <String>{for (final e in _hantaiPool) e[0]};
    for (var attempt = 0; attempt < 300; attempt++) {
      final cand = [for (final e in _hantaiPool) if (int.parse(e[2]) <= lv) e]..shuffle(r);
      final chosen = <List<String>>[];
      final used = <String>{};
      for (final e in cand) {
        final cs = e[0].split('');
        if (cs.any(used.contains)) continue;
        chosen.add(e);
        used.addAll(cs);
        if (chosen.length == count) break;
      }
      if (chosen.length < count) continue;
      if (lv == 2 && !chosen.any((e) => e[2] == '2')) continue;
      if (lv == 3 && chosen.where((e) => e[2] == '3').length < 2) continue;
      final own = <String>{for (final e in chosen) e[0]};
      final chars = used.toList();
      var clash = false;
      for (final a in chars) {
        for (final b in chars) {
          final w = a + b;
          if (a != b && known.contains(w) && !own.contains(w)) clash = true;
        }
      }
      if (clash) continue;
      return chosen;
    }
    return _hantaiPairs.take(count).toList();
  }

  static KokugoItem _hantaiItem(int no, List<String> pair) => KokugoItem(
        label: _circ[no],
        parts: [_b(pair[0], pair[1])],
      );

  static List<KokugoLesson>? _cache;

  static List<KokugoLesson> samples(String kind) {
    var all = _cache;
    if (all == null) {
      final kakiItems = <KokugoItem>[
        _kakiItem(0, 'れつの', '先', 'セン', 'とう。'),
        _kakiItem(1, '', '名字', 'ミョウ|ジ', 'を かく。'),
        _kakiItem(2, '', '年下', 'トシ|シタ', 'の ともだち。'),
        _kakiItem(3, '', '文', 'ブン', 'ぼうぐ'),
        _kakiItem(4, 'けっさくを', '生', 'ウ', 'む。'),
        _kakiItem(5, 'おく', '上', 'ジョウ', 'で あそぶ。'),
        KokugoItem(label: _circ[6], parts: [_b('男', 'オトコ'), _t('の'), _b('子', 'コ')]),
        _kakiItem(7, 'スケートの', '女王', 'ジョ|オウ', '。'),
        _kakiItem(8, '', '左', 'ヒダリ', 'きき'),
      ];
      final yomiItems = <KokugoItem>[
        KokugoItem(label: '①ア', parts: [_y('右', ['みぎ']), _t('となり')]),
        KokugoItem(label: '①イ', parts: [_y('右', ['う']), _t('せつ')]),
        KokugoItem(label: '①ウ', parts: [_t('左'), _y('右', ['ゆう'])]),
        KokugoItem(label: '②ア', parts: [_t('大'), _y('男', ['おとこ'])]),
        KokugoItem(label: '②イ', parts: [_y('男', ['だん']), _t('子')]),
        KokugoItem(label: '②ウ', parts: [_t('ちょう'), _y('男', ['なん'])]),
        KokugoItem(label: '③ア', parts: [_y('小', ['ちい']), _t('さい手')]),
        KokugoItem(label: '③イ', parts: [_y('小', ['こ']), _t('石')]),
        KokugoItem(label: '③ウ', parts: [_y('小', ['お']), _t('川')]),
      ];
      // dap an dung nhu sach: (1)右 ノ=1, (2)左 一=1, (3)女 一=3, (4)上 一ngan=2, (5)下 丶=3, (6)先 ノ=1
      final strokeItems = <KokugoItem>[
        _strokeItem(0, '右', 1, p: 1, a: 180),
        _strokeItem(1, '左', 1, p: 1, a: -45),
        _strokeItem(2, '女', 3, p: 1, a: -15),
        _strokeItem(3, '上', 2, p: 1, a: -50),
        _strokeItem(4, '下', 3, p: 1, a: -15),
        _strokeItem(5, '先', 1, p: 0, a: -60),
      ];
      // moi bai mau chi 3 cau
      all = <KokugoLesson>[
        for (var n = 0; n < 3; n++)
          KokugoLesson(
            id: 'KK00${n + 1}',
            title: {
              'ja': 'かん字を かこう ${n + 1}',
              'en': 'Write the Kanji ${n + 1}',
              'vi': 'Viết chữ Hán ${n + 1}',
            },
            question: questionFor('kaki'),
            kind: 'kaki',
            difficulty: n == 1 ? 1 : 2,
            items: kakiItems.sublist(n * 3, n * 3 + 3),
          ),
        for (var n = 0; n < 3; n++)
          KokugoLesson(
            id: 'KY00${n + 1}',
            title: {
              'ja': 'かん字の よみ ${n + 1}',
              'en': 'Kanji Readings ${n + 1}',
              'vi': 'Cách đọc chữ Hán ${n + 1}',
            },
            question: questionFor('yomi'),
            kind: 'yomi',
            difficulty: n == 0 ? 1 : 2,
            items: yomiItems.sublist(n * 3, n * 3 + 3),
          ),
        // ひつじゅん: 6 chu trong sach, chia 2 bai
        for (var n = 0; n < 2; n++)
          KokugoLesson(
            id: 'HJ00${n + 1}',
            title: {
              'ja': 'ひつじゅん ${n + 1}',
              'en': 'Stroke Order ${n + 1}',
              'vi': 'Thứ tự nét ${n + 1}',
            },
            question: questionFor('hitsujun'),
            kind: 'hitsujun',
            difficulty: n == 0 ? 2 : 1,
            items: strokeItems.sublist(n * 3, n * 3 + 3),
          ),
        // かんようく: 8 cau trong sach, chia 3 bai
        for (var n = 0; n < 3; n++)
          KokugoLesson(
            id: 'IK00${n + 1}',
            title: {
              'ja': 'かんようく ${n + 1}',
              'en': 'Idioms ${n + 1}',
              'vi': 'Thành ngữ ${n + 1}',
            },
            question: questionFor('kanyou'),
            kind: 'kanyou',
            difficulty: n == 2 ? 1 : 2,
            items: [
              for (var i = n * 3; i < (n == 2 ? 8 : n * 3 + 3); i++)
                _idiomItem(i, _idiomBank[i][0], _idiomBank[i][1], _idiomBank[i][2], _idiomBank[i][3]),
            ],
          ),
        // はんたい: dung nhu sach (4 cap, bang chu 8 chu)
        KokugoLesson(
          id: 'HT001',
          title: {
            'ja': 'はんたいの いみの かん字 1',
            'en': 'Opposite Kanji 1',
            'vi': 'Chữ Hán trái nghĩa 1',
          },
          question: questionFor('hantai'),
          kind: 'hantai',
          difficulty: 2,
          items: [for (var i = 0; i < _hantaiPairs.length; i++) _hantaiItem(i, _hantaiPairs[i])],
          bank: const ['小', '右', '女', '下', '左', '大', '男', '上'],
        ),
      ];
      _cache = all;
    }
    return [
      for (final s in all)
        if (s.kind == kind) s
    ];
  }

  // ---------- kho tu: kaki [kanji, katakana (cach nhau bang |), truoc, sau] ----------
  static const List<List<String>> _kakiBank = [
    ['花', 'ハナ', 'きれいな', 'が さく。'],
    ['犬', 'イヌ', '', 'と さんぽに いく。'],
    ['雨', 'アメ', '', 'が ふって きた。'],
    ['空', 'ソラ', 'あおい', 'を みる。'],
    ['月', 'ツキ', 'よるの', 'が きれい。'],
    ['火', 'ヒ', '', 'を つけない。'],
    ['水', 'ミズ', 'つめたい', 'を のむ。'],
    ['木', 'キ', 'おおきな', 'の かげ。'],
    ['川', 'カワ', '', 'で およぐ。'],
    ['石', 'イシ', '', 'を ひろう。'],
    ['車', 'クルマ', 'あかい', 'に のる。'],
    ['足', 'アシ', '', 'が はやい。'],
    ['耳', 'ミミ', '', 'を すます。'],
    ['目', 'メ', '', 'を とじる。'],
    ['口', 'クチ', 'おおきな', 'を あける。'],
    ['手', 'テ', '', 'を あらう。'],
    ['山', 'ヤマ', '', 'に のぼる。'],
    ['田', 'タ', '', 'うえを する。'],
    ['虫', 'ムシ', '', 'を つかまえる。'],
    ['森', 'モリ', 'ふかい', 'を あるく。'],
    ['学校', 'ガッ|コウ', '', 'へ いく。'],
    ['先生', 'セン|セイ', '', 'に あいさつ。'],
    ['休日', 'キュウ|ジツ', '', 'は あそぶ。'],
    ['入学', 'ニュウ|ガク', '', 'しきが ある。'],
    ['九月', 'ク|ガツ', '', 'に なった。'],
    ['一年', 'イチ|ネン', '', 'せいに なる。'],
    ['青空', 'アオ|ゾラ', '', 'の した。'],
    ['百円', 'ヒャク|エン', '', 'で かう。'],
    ['天気', 'テン|キ', 'いい', 'です。'],
    ['左手', 'ヒダリ|テ', '', 'に もつ。'],
    ['右足', 'ミギ|アシ', '', 'から だす。'],
    ['小雨', 'コ|サメ', '', 'が ふる。'],
    ['草花', 'クサ|バナ', '', 'を そだてる。'],
    ['女子', 'ジョ|シ', '', 'と あそぶ。'],
    ['男子', 'ダン|シ', '', 'の ちょうれつ。'],
    ['火山', 'カ|ザン', '', 'が ふんかする。'],
    ['出口', 'デ|グチ', '', 'は あちら。'],
    ['入口', 'イリ|グチ', '', 'に たつ。'],
    ['正月', 'ショウ|ガツ', '', 'を むかえる。'],
    ['大雨', 'オオ|アメ', '', 'に なった。'],
  ];

  // ---------- kho tu: yomi  chu Han -> [truoc, sau, dap an 1, dap an 2...] ----------
  static const Map<String, List<List<String>>> _yomiBank = {
    '大': [
      ['', 'きい', 'おお'],
      ['', '会', 'たい'],
      ['', '小', 'だい'],
    ],
    '小': [
      ['', 'さい', 'ちい'],
      ['', '学校', 'しょう'],
      ['', '石', 'こ'],
      ['', '川', 'お'],
    ],
    '男': [
      ['', '子', 'だん'],
      ['ちょう', '', 'なん'],
      ['', 'の子', 'おとこ'],
    ],
    '女': [
      ['', '子', 'じょ'],
      ['', 'の子', 'おんな'],
    ],
    '上': [
      ['', '手', 'じょう'],
      ['', 'る', 'のぼ'],
      ['', 'がる', 'あ'],
      ['', 'に のる', 'うえ'],
    ],
    '下': [
      ['', '校', 'げ'],
      ['', 'りる', 'お'],
      ['', 'がる', 'さ'],
      ['', 'に いる', 'した'],
    ],
    '日': [
      ['', '曜日', 'にち'],
      ['', 'の出', 'ひ'],
      ['三', '', 'か'],
    ],
    '月': [
      ['', 'が でる', 'つき'],
      ['', '曜日', 'げつ'],
      ['三', '', 'がつ'],
    ],
    '火': [
      ['', 'を つける', 'ひ'],
      ['', '曜日', 'か'],
      ['', '山', 'か'],
    ],
    '水': [
      ['', 'を のむ', 'みず'],
      ['', '曜日', 'すい'],
      ['', '道', 'すい'],
    ],
    '木': [
      ['', 'の えだ', 'き'],
      ['', '曜日', 'もく'],
    ],
    '金': [
      ['お', '', 'かね'],
      ['', '曜日', 'きん'],
    ],
    '土': [
      ['', 'を ほる', 'つち'],
      ['', '曜日', 'ど'],
      ['', '地', 'と'],
    ],
    '生': [
      ['', 'まれる', 'う'],
      ['', 'きる', 'い'],
      ['先', '', 'せい'],
      ['', 'たまご', 'なま'],
    ],
    '休': [
      ['', 'む', 'やす'],
      ['', '日', 'きゅう'],
      ['', 'み', 'やす'],
    ],
    '入': [
      ['', 'れる', 'い'],
      ['', '学', 'にゅう'],
      ['', 'る', 'はい'],
      ['', '口', 'いり'],
    ],
    '出': [
      ['', 'る', 'で'],
      ['', '口', 'で'],
      ['', 'す', 'だ'],
    ],
    '白': [
      ['', 'い', 'しろ'],
      ['', 'くま', 'しろ'],
    ],
    '正': [
      ['', 'しい', 'ただ'],
      ['', '月', 'しょう'],
    ],
  };

  static KokugoLesson generate(String kind, {int level = 1, Random? rng}) {
    final r = rng ?? Random();
    final int lv = level < 1 ? 1 : (level > 3 ? 3 : level);
    final id = 'kj_${DateTime.now().microsecondsSinceEpoch}';
    final title = {
      for (final e in baseNames[kind]!.entries) e.key: '${e.value} ✨',
    };
    if (kind == 'hitsujun') {
      // muc 1: chu it net, muc 2: den 5 net, muc 3: ca chu nhieu net; 2-4 cau tuy muc
      final maxStrokes = lv == 1 ? 3 : (lv == 2 ? 5 : 6);
      final pool = strokeKanjiUpTo(maxStrokes)..shuffle(r);
      final count = lv == 1 ? 2 : (lv == 2 ? 3 : 4);
      final pick = pool.take(count).toList();
      return KokugoLesson(
        id: id,
        title: title,
        question: questionFor('hitsujun'),
        kind: 'hitsujun',
        difficulty: lv,
        isAutoGenerated: true,
        items: [
          for (var i = 0; i < pick.length; i++)
            _strokeItem(i, pick[i], 1 + r.nextInt(kStrokeData[pick[i]]!.length)),
        ],
      );
    }
    if (kind == 'kanyou') {
      final count = lv == 1 ? 2 : (lv == 2 ? 3 : 4);
      final bank = List<List<String>>.from(_idiomBank)..shuffle(r);
      // moi bai khong lap cung mot bo phan co the
      final used = <String>{};
      final pick = <List<String>>[];
      for (final e in bank) {
        final key = e[1].split('|').first;
        if (used.add(key)) pick.add(e);
        if (pick.length == count) break;
      }
      return KokugoLesson(
        id: id,
        title: title,
        question: questionFor('kanyou'),
        kind: 'kanyou',
        difficulty: lv,
        isAutoGenerated: true,
        items: [for (var i = 0; i < pick.length; i++) _idiomItem(i, pick[i][0], pick[i][1], pick[i][2], pick[i][3])],
      );
    }
    if (kind == 'hantai') {
      final count = lv == 1 ? 2 : (lv == 2 ? 3 : 4);
      final use = _pickHantai(r, count, lv);
      final chars = <String>[for (final p in use) ...p[0].split('')]..shuffle(r);
      return KokugoLesson(
        id: id,
        title: title,
        question: questionFor('hantai'),
        kind: 'hantai',
        difficulty: lv,
        isAutoGenerated: true,
        items: [for (var i = 0; i < use.length; i++) _hantaiItem(i, use[i])],
        bank: chars,
      );
    }
    if (kind == 'kaki') {
      final count = lv == 1 ? 2 : 3;
      final bank = List<List<String>>.from(_kakiBank)..shuffle(r);
      // muc 3 uu tien tu 2 chu
      if (lv == 3) {
        bank.sort((a, b) => (b[0].length).compareTo(a[0].length));
      }
      final pick = bank.take(count).toList()..shuffle(r);
      return KokugoLesson(
        id: id,
        title: title,
        question: questionFor('kaki'),
        kind: 'kaki',
        difficulty: lv,
        isAutoGenerated: true,
        items: [
          for (var i = 0; i < pick.length; i++)
            _kakiItem(i, pick[i][2], pick[i][0], pick[i][1], pick[i][3]),
        ],
      );
    }
    final groups = 1; // moi bai chi 1 chu Han, 2-3 cau
    final kanjiList = _yomiBank.keys.toList()..shuffle(r);
    final items = <KokugoItem>[];
    for (var g = 0; g < groups; g++) {
      final k = kanjiList[g];
      final entries = List<List<String>>.from(_yomiBank[k]!)..shuffle(r);
      final use = entries.take(lv == 1 ? 2 : 3).toList();
      for (var j = 0; j < use.length; j++) {
        final e = use[j];
        final answers = e.sublist(2);
        items.add(KokugoItem(label: '${_circ[g]}${_kana3[j]}', parts: [
          if (e[0].isNotEmpty) _t(e[0]),
          _y(k, answers),
          if (e[1].isNotEmpty) _t(e[1]),
        ]));
      }
    }
    return KokugoLesson(
      id: id,
      title: title,
      question: questionFor('yomi'),
      kind: 'yomi',
      difficulty: lv,
      isAutoGenerated: true,
      items: items,
    );
  }
}
