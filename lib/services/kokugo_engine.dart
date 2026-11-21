import 'dart:math';
import '../models/kokugo_lesson.dart';

// Bai 国語 (lop 1): viet chu Han (kaki) va viet cach doc (yomi).
// Kho tu vung va cau vi du do ta tu soan.
class KokugoEngine {
  static const List<String> kinds = ['kaki', 'yomi'];

  static const Map<String, Map<String, String>> baseNames = {
    'kaki': {'ja': 'かん字を かこう', 'en': 'Write the Kanji', 'vi': 'Viết chữ Hán'},
    'yomi': {'ja': 'かん字の よみ', 'en': 'Kanji Readings', 'vi': 'Cách đọc chữ Hán'},
  };

  static const List<String> _circ = ['①', '②', '③', '④', '⑤', '⑥', '⑦', '⑧', '⑨', '⑩'];
  static const List<String> _kana3 = ['ア', 'イ', 'ウ'];

  static Map<String, String> questionFor(String kind) {
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
