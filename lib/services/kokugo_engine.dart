import 'dart:math';
import '../models/kokugo_lesson.dart';
import 'stroke_data.dart';

// Bai 国語 (lop 1): viet chu Han (kaki) va viet cach doc (yomi).
// Kho tu vung va cau vi du do ta tu soan.
class KokugoEngine {
  static const List<String> kinds = ['kaki', 'yomi', 'hitsujun', 'hantai', 'kanyou', 'setsuzoku', 'doon', 'ruigi', 'narabe', 'bunsaku'];

  static const Map<String, Map<String, String>> baseNames = {
    'kaki': {'ja': 'かん字を かこう', 'en': 'Write the Kanji', 'vi': 'Viết chữ Hán'},
    'yomi': {'ja': 'かん字の よみ', 'en': 'Kanji Readings', 'vi': 'Cách đọc chữ Hán'},
    'hitsujun': {'ja': 'かん字の ひつじゅん', 'en': 'Stroke Order', 'vi': 'Thứ tự nét chữ Hán'},
    'hantai': {'ja': 'はんたいの いみの かん字', 'en': 'Opposite Kanji', 'vi': 'Chữ Hán trái nghĩa'},
    'kanyou': {'ja': 'かんようく', 'en': 'Idioms', 'vi': 'Thành ngữ (bộ phận cơ thể)'},
    'setsuzoku': {'ja': 'あてはまる ことば', 'en': 'Fill in the Word', 'vi': 'Điền từ thích hợp'},
    'doon': {'ja': 'おなじ おとの かん字', 'en': 'Same-Sound Kanji', 'vi': 'Chữ Hán đồng âm'},
    'ruigi': {'ja': 'にた いみの ことば', 'en': 'Similar Words', 'vi': 'Từ đồng nghĩa'},
    'narabe': {'ja': 'ぶんを つくろう', 'en': 'Build the Sentence', 'vi': 'Sắp xếp thành câu'},
    'bunsaku': {'ja': 'ことばを つかって ぶんを つくろう', 'en': 'Write a Sentence with the Words', 'vi': 'Đặt câu với từ cho sẵn'},
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
    if (kind == 'bunsaku') {
      return {
        'ja': '【 】の 中の ことばを つかって、文を つくりましょう。ことばは かたちを かえても かまいません。',
        'en': 'Write a sentence using the two words in 【 】. You may change the form of the words.',
        'vi': 'Dùng hai từ trong 【 】 để tự đặt câu. Được phép đổi dạng của từ.',
      };
    }
    if (kind == 'narabe') {
      return {
        'ja': 'つぎの ことばを 入れかえて、いみの とおる 文を つくりましょう。\n〈れい〉あそびました／たろうは／たのしく／犬と → たろうは、犬と たのしく あそびました。\n文の さいごには「。」を つけよう。',
        'en': 'Rearrange the words to make a sentence that makes sense.\nExample: あそびました / たろうは / たのしく / 犬と → たろうは、犬と たのしく あそびました。\nPut 「。」 at the end of the sentence.',
        'vi': 'Sắp xếp lại các từ để thành câu có nghĩa.\nVí dụ: あそびました / たろうは / たのしく / 犬と → たろうは、犬と たのしく あそびました。\nCuối câu nhớ thêm 「。」.',
      };
    }
    if (kind == 'ruigi') {
      return {
        'ja': '□の 中から、にた いみの ことばを 二つずつ さがして □に かきましょう。',
        'en': 'From the box, find two words with similar meanings and put them together in the boxes.',
        'vi': 'Từ trong khung, tìm từng cặp hai từ có nghĩa gần nhau rồi xếp vào ô.',
      };
    }
    if (kind == 'doon') {
      return {
        'ja': '──せんに あう かん字を □に かきましょう。',
        'en': 'Write the kanji that fits the underlined hiragana in each box.',
        'vi': 'Viết chữ Hán hợp với phần hiragana gạch chân vào ô.',
      };
    }
    if (kind == 'setsuzoku') {
      return {
        'ja': '□に あてはまる ことばを、あとの ことばから えらび、□に かきましょう。おなじ ことばは、二ど つかえません。',
        'en': 'Choose the word from the box that fits each blank. Each word can be used only once.',
        'vi': 'Chọn từ thích hợp trong khung để điền vào mỗi ô trống. Mỗi từ chỉ được dùng một lần.',
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

  // Them danh sach cac cau sai vao thong bao (国語 cho phep chi ra cau sai)
  static String withWrong(String msg, List<String> labels, String lang) {
    if (labels.isEmpty) return msg;
    final head = lang == 'ja' ? 'ちがう ところ' : (lang == 'en' ? 'Check' : 'Chưa đúng ở');
    return '$msg\n$head: ${labels.join('  ')}';
  }

  static String circled(int i) => _circ[i < _circ.length ? i : _circ.length - 1];

  static String wrongMessage(String kind, String lang) {
    if (kind == 'bunsaku') {
      return lang == 'ja'
          ? 'もういちど かいてみよう'
          : lang == 'en'
              ? 'Try writing it again'
              : 'Hãy viết lại nhé';
    }
    if (kind == 'narabe') {
      return lang == 'ja'
          ? 'ちがう ところが あるよ。ことばの ならびを かえて、いみが とおるか よんで みよう'
          : lang == 'en'
              ? 'Something is wrong. Change the word order and read it to check it makes sense'
              : 'Có chỗ chưa đúng. Hãy thử đổi thứ tự từ rồi đọc lại xem câu có nghĩa không';
    }
    if (kind == 'setsuzoku') {
      return lang == 'ja'
          ? 'ちがう ところが あるよ。ぶんの つながりを よく かんがえよう'
          : lang == 'en'
              ? 'Something is wrong. Think about how the sentences connect'
              : 'Có chỗ chưa đúng. Hãy nghĩ kỹ xem các câu nối với nhau thế nào';
    }
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
    if (kind == 'ruigi') {
      return lang == 'ja'
          ? 'ちがう ところが あるよ。ことばの いみを よく かんがえて、にて いる ものを ペアに しよう'
          : lang == 'en'
              ? 'Something is wrong. Think about the meanings and pair the similar ones'
              : 'Có chỗ chưa đúng. Hãy nghĩ kỹ về nghĩa và ghép các từ gần nghĩa thành cặp';
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
  // cau 'doon': [truoc, hiragana gach chan, sau, chu Han dap an]
  static KokugoItem _doonItem(int no, List<String> e) {
    return KokugoItem(label: _circ[no], parts: [
      if (e[0].isNotEmpty) _t(e[0]),
      KokugoPart(e[1], underline: true),
      if (e[2].isNotEmpty) _t(e[2]),
      _b(e[3], ''),
    ]);
  }

  // Cac nhom chu Han cung am: moi nhom la danh sach [truoc, hiragana gach chan, sau, chu Han]
  static const List<List<List<String>>> _doonBank = [
    [
      ['', 'こ', 'ごえで はなす。', '小'],
      ['', 'こ', 'の はが まう。', '木'],
      ['', 'こ', 'もりうた', '子'],
    ],
    [
      ['ち', 'か', 'しつ', '下'],
      ['', 'か', 'びんを かう。', '花'],
      ['山《やま》', 'か', 'じが おきた。', '火'],
    ],
    [
      ['', 'せん', 'ばづる', '千'],
      ['', 'せん', 'とうを はしる。', '先'],
    ],
    [
      ['ざっ', 'そう', 'を ぬく。', '草'],
      ['', 'そう', 'ちょうれんしゅう', '早'],
    ],
    [
      ['', 'こう', 'そくを まもる。', '校'],
      ['人', 'こう', 'が おおい。', '口'],
    ],
    [
      ['二人《ふたり》は ', 'けん', 'えんの なかだ。', '犬'],
      ['こうじょう', 'けん', '学', '見'],
    ],
    [
      ['先', 'せい', 'に あいさつを する。', '生'],
      ['', 'せい', 'かいを えらぶ。', '正'],
      ['', 'せい', 'ねんが あるく。', '青'],
    ],
    [
      ['', 'き', 'の えだに とまる。', '木'],
      ['てん', 'き', 'が いい。', '気'],
    ],
    [
      ['', 'しょう', 'がっこうに はいる。', '小'],
      ['', 'しょう', 'がつに おもちを たべる。', '正'],
    ],
    [
      ['', 'ちゅう', 'しんに たつ。', '中'],
      ['こん', 'ちゅう', 'を つかまえる。', '虫'],
    ],
    [
      ['', 'ゆう', 'やけが きれいだ。', '夕'],
      ['さ', 'ゆう', 'を よく 見る。', '右'],
    ],
  ];

  // cau 'ruigi': mot cap hai tu dong nghia (hai doan blank)
  static KokugoItem _ruigiItem(int no, List<String> pair) =>
      KokugoItem(label: _circ[no], parts: [_b(pair[0], ''), _b(pair[1], '')]);

  // Cac tu trong khung: sample giu thu tu trong sach (r == null), tu sinh thi xao tron
  static List<String> _ruigiBank(List<List<String>> pairs, Random? r) {
    final words = <String>[for (final p in pairs) ...p];
    if (r != null) {
      words.shuffle(r);
    } else {
      // thu tu trong khung cua sach
      const order = ['はながたかい', 'あぜんとする', 'うやまう', 'しゃがむ', 'あきれる', 'かがむ', 'すぐれる', 'そんけいする', 'まさる', 'ほこらしい'];
      words.sort((a, b) => order.indexOf(a).compareTo(order.indexOf(b)));
    }
    return words;
  }

  // 5 cap trong sach (trang 3 bai 3), theo thu tu xuat hien trong khung
  static const List<List<String>> _ruigiBook = [
    ['はながたかい', 'ほこらしい'],
    ['あぜんとする', 'あきれる'],
    ['うやまう', 'そんけいする'],
    ['しゃがむ', 'かがむ'],
    ['すぐれる', 'まさる'],
  ];

  // Kho cap dong nghia them cho bai tu sinh (cap nao cung co mot nghia rieng, khong lan sang cap khac)
  static const List<List<String>> _ruigiPool = [
    ['おどろく', 'びっくりする'],
    ['たいせつな', 'だいじな'],
    ['こわい', 'おそろしい'],
    ['すぐに', 'ただちに'],
    ['ほめる', 'たたえる'],
    ['じょうず', 'うまい'],
    ['きれいな', 'うつくしい'],
    ['つかれる', 'くたびれる'],
    ['ゆっくり', 'のんびり'],
    ['ねがう', 'のぞむ'],
    ['まよう', 'ためらう'],
    ['つかまえる', 'とらえる'],
    ['あわてる', 'うろたえる'],
    ['なおす', 'しゅうりする'],
    ['けしき', 'ながめ'],
    ['むねをうつ', 'かんどうする'],
  ];

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

  // ---------- あてはまる ことば (tu noi / pho tu) ----------
  // [truoc cho trong, dap an, sau cho trong, loai]
  // loai: m=まだ u=もう n=なぜなら c=それとも/または k=だから/それで x=けれども/しかし/でも/ところが s=そして/それから
  static const List<List<String>> _setsuBank = [
    ['あしたまでの しゅくだいが、', 'まだ', 'おわっていない。', 'm'],
    ['ごはんは ', 'まだ', 'できていません。', 'm'],
    ['あさがおの はなは ', 'まだ', 'さいていない。', 'm'],
    ['おとうとは ', 'まだ', 'ねています。', 'm'],
    ['ともだちから かりた 本は、', 'もう', 'よみおえた。', 'u'],
    ['おやつは ', 'もう', 'たべてしまった。', 'u'],
    ['しゅくだいは ', 'もう', 'おわったよ。', 'u'],
    ['バスは ', 'もう', 'いってしまいました。', 'u'],
    ['テストで 百てんを とった。', 'なぜなら', '、がんばって べんきょうしたからだ。', 'n'],
    ['きょうは えんそくに いけない。', 'なぜなら', '、あめが ふっているからだ。', 'n'],
    ['わたしは 本が すきだ。', 'なぜなら', '、おもしろい おはなしが たくさん あるからだ。', 'n'],
    ['りんごが すきですか。', 'それとも', '、いちごが すきですか。', 'c'],
    ['おやつは ケーキに しますか。', 'それとも', '、ゼリーに しますか。', 'c'],
    ['バスで いきますか。', 'それとも', '、あるいて いきますか。', 'c'],
    ['おちゃ', 'または', 'ジュースを どうぞ。', 'c'],
    ['えんぴつ', 'または', 'ペンで かいて ください。', 'c'],
    ['雨が ふってきた。', 'だから', '、まどを しめた。', 'k'],
    ['ねぼうを した。', 'だから', '、がっこうに ちこくした。', 'k'],
    ['きょうは とても さむい。', 'だから', '、あつい コートを きた。', 'k'],
    ['ねつが あった。', 'それで', '、がっこうを やすんだ。', 'k'],
    ['おなかが すいた。', 'それで', '、おにぎりを たべた。', 'k'],
    ['目ざましどけいが なった。', 'けれども', '、また ねてしまった。', 'x'],
    ['いっしょうけんめい はしった。', 'けれども', '、まにあわなかった。', 'x'],
    ['ひとりで やってみた。', 'しかし', '、うまく できなかった。', 'x'],
    ['ともだちを さそった。', 'でも', '、こられないと いわれた。', 'x'],
    ['あしたは はれると おもった。', 'ところが', '、あめが ふった。', 'x'],
    ['おふろに はいった。', 'そして', '、ごはんを たべた。', 's'],
    ['はるに なった。', 'そして', '、さくらが さいた。', 's'],
    ['あさ おきて かおを あらった。', 'それから', '、はを みがいた。', 's'],
    ['まず てを あらう。', 'それから', '、おやつを たべる。', 's'],
  ];

  // Cac tu (ngoai dap an) cung hop voi cau thuoc loai nay -> khong duoc dung chung trong 1 bai
  static const Map<String, List<String>> _setsuCompat = {
    'm': ['まだ'],
    'u': ['もう'],
    'n': ['なぜなら'],
    'c': ['それとも', 'または'],
    'k': ['だから', 'それで', 'そして', 'それから'],
    'x': ['けれども', 'しかし', 'でも', 'ところが', 'そして', 'それから'],
    's': ['そして', 'それから'],
  };

  static const List<String> _setsuWords = [
    'まだ', 'もう', 'なぜなら', 'それとも', 'または', 'だから', 'それで',
    'けれども', 'しかし', 'でも', 'ところが', 'そして', 'それから',
  ];

  static KokugoItem _setsuItem(int no, List<String> e) {
    return KokugoItem(
      label: '（${no + 1}）',
      parts: [
        if (e[0].isNotEmpty) _t(e[0]),
        KokugoPart('', blank: true, reads: [e[1]]),
        _t(e[2]),
      ],
    );
  }

  // Moi cau chi co dung 1 tu trong bank hop (khong co tu nao khac cung hop nghia)
  static bool _setsuUnique(List<List<String>> picks, List<String> bank) {
    for (final e in picks) {
      final fit = _setsuCompat[e[3]]!.where(bank.contains).toList();
      if (fit.length != 1 || fit.first != e[1]) return false;
    }
    return true;
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

  // ---------- narabe: sap xep tu thanh cau ----------
  // Moi cau: [thoi gian ('' neu khong co), chu ngu (~は), cac tu tu do (~と, ~で ...), cac tu cuoi cau (giu nguyen thu tu)]
  static const List<List<dynamic>> _narabePool = [
    ['きのう', 'はなこは', ['おかあさんと', 'スーパーで'], ['かいものを', 'しました']],
    ['あした', 'ぼくは', ['おじいさんと', 'うみで'], ['つりを', 'します']],
    ['', 'たろうは', ['いもうとと', 'たのしく'], ['うたを', 'うたいました']],
    ['けさ', 'わたしは', ['はやく'], ['あさごはんを', 'たべました']],
    ['きょう', 'ぼくは', ['がっこうで', 'ともだちと'], ['サッカーを', 'しました']],
    ['', 'ひろしさんは', ['じてんしゃで', 'こうえんへ'], ['いきました']],
    ['きのう', 'あきこさんは', ['おばあさんに'], ['てがみを', 'かきました']],
    ['ゆうがた', 'ぼくは', ['おとうとと', 'にわで'], ['みずを', 'まきました']],
    ['', 'ももこさんは', ['いえで', 'ゆっくり'], ['ほんを', 'よみました']],
    ['よる', 'わたしは', ['おかあさんと', 'いっしょに'], ['カレーを', 'つくりました']],
    ['あさ', 'ぼくは', ['いぬと', 'こうえんを'], ['さんぽしました']],
    ['きょう', 'わたしは', ['いえで'], ['おかあさんの', 'てつだいを', 'しました']],
    ['きのう', 'ゆうたさんは', ['ともだちと', 'プールで'], ['およぎました']],
    ['', 'ようこさんは', ['まいにち', 'ていねいに'], ['はなに', 'みずを', 'あげます']],
  ];

  // bunsaku: [tu 1, tu 2, [cac cau mau]] (cau mau de tu cham ○✕)
  static const List<List<dynamic>> _bunPool = [
    ['たのしい', 'あそぶ', ['たのしい ゆうえんちで ともだちと あそびました。', 'あそぶと たのしいので、まいにち こうえんへ いきます。']],
    ['おどろく', 'きく', ['ニュースを きいて、とても おどろきました。', 'おどろいて、もういちど きいて みました。']],
    ['かなしい', 'なく', ['ともだちが ひっこして、かなしくて なきました。', 'かなしい えいがを みて、なきそうに なりました。']],
    ['あんしん', 'かえる', ['いえに かえって、あんしんしました。', 'おかあさんが かえって きて、あんしんした。']],
    ['しんぱい', 'ねる', ['あしたの テストが しんぱいで、ねられません。', 'しんぱいしないで、はやく ねましょう。']],
    ['はずかしい', 'わらう', ['みんなに わらわれて、はずかしかった。', 'はずかしくて、わらって ごまかしました。']],
    ['かんしゃ', 'つたえる', ['おかあさんに かんしゃの きもちを つたえました。', 'かんしゃを つたえる ために てがみを かきます。']],
    ['がっかり', 'なる', ['あめで えんそくが ちゅうしに なって、がっかりしました。', 'しあいに まけて、がっかりした きもちに なった。']],
    ['まよう', 'えらぶ', ['どの ほんを えらぶか まよって います。', 'まよったけれど、あかい かばんを えらびました。']],
    ['いそぐ', 'はしる', ['おくれそうで、いそいで はしりました。', 'いそいで いても、ろうかを はしっては いけません。']],
    ['たのしみ', 'まつ', ['えんそくの ひを たのしみに まって います。', 'たんじょうびを たのしみに して まちました。']],
    ['うれしい', 'わらう', ['ほめられて うれしくて、にっこり わらいました。', 'うれしい ことが あって、みんなで わらいました。']],
  ];

  // bunsaku: cac dang bien doi cua tu (de goi y va de tu kiem tra khi go phim)
  static const Map<String, List<String>> _bunForms = {
    'うれしい': ['うれしい', 'うれしく', 'うれしかった', 'うれしさ'],
    'はなす': ['はなす', 'はなし', 'はなして', 'はなした', 'はなさ'],
    'こうふん': ['こうふん'],
    'できる': ['できる', 'できた', 'できて', 'できな', 'でき'],
    'まんぞく': ['まんぞく'],
    'よろこばせる': ['よろこばせる', 'よろこばせ'],
    'たのしみ': ['たのしみ'],
    'もうすぐ': ['もうすぐ'],
    'たのしい': ['たのしい', 'たのしく', 'たのしかった', 'たのしさ'],
    'あそぶ': ['あそぶ', 'あそび', 'あそんで', 'あそんだ', 'あそば'],
    'おどろく': ['おどろく', 'おどろき', 'おどろい', 'おどろか'],
    'きく': ['きく', 'きき', 'きいて', 'きいた', 'きか'],
    'かなしい': ['かなしい', 'かなしく', 'かなしかった', 'かなしさ'],
    'なく': ['なく', 'なき', 'ないて', 'ないた', 'なか'],
    'あんしん': ['あんしん'],
    'かえる': ['かえる', 'かえり', 'かえって', 'かえった', 'かえら'],
    'しんぱい': ['しんぱい'],
    'ねる': ['ねる', 'ねて', 'ねた', 'ねな', 'ねら', 'ねま', 'ねよ'],
    'はずかしい': ['はずかしい', 'はずかしく', 'はずかしかった'],
    'わらう': ['わらう', 'わらい', 'わらって', 'わらった', 'わらわ'],
    'かんしゃ': ['かんしゃ'],
    'つたえる': ['つたえる', 'つたえ'],
    'がっかり': ['がっかり'],
    'なる': ['なる', 'なり', 'なって', 'なった', 'なら', 'なれ'],
    'まよう': ['まよう', 'まよい', 'まよって', 'まよった', 'まよわ'],
    'えらぶ': ['えらぶ', 'えらび', 'えらんで', 'えらんだ', 'えらば'],
    'いそぐ': ['いそぐ', 'いそぎ', 'いそいで', 'いそいだ', 'いそが'],
    'はしる': ['はしる', 'はしり', 'はしって', 'はしった', 'はしら'],
    'まつ': ['まつ', 'まち', 'まって', 'まった'],
  };

  // bunsaku: nghia cua tu, giai thich de hieu cho tre (ja / en / vi)
  static const Map<String, Map<String, String>> _bunMeaning = {
    'うれしい': {'ja': 'いいことが あって、にこにこ したくなる きもち。', 'en': 'The happy feeling you get when something good happens.', 'vi': 'Cảm giác vui, muốn mỉm cười khi có chuyện tốt xảy ra.'},
    'はなす': {'ja': 'ことばで ひとに つたえる こと。おしゃべりを する こと。', 'en': 'To tell someone something with words; to talk.', 'vi': 'Nói chuyện, dùng lời để kể cho người khác nghe.'},
    'こうふん': {'ja': 'わくわく、どきどきして、きもちが たかぶる こと。', 'en': 'Feeling so excited that your heart goes pounding.', 'vi': 'Hồi hộp, phấn khích đến mức tim đập thình thịch.'},
    'できる': {'ja': 'じぶんの ちからで やれる こと。うまく しあがる こと。', 'en': 'To be able to do something; to get it done.', 'vi': 'Làm được, có thể làm được việc gì đó.'},
    'まんぞく': {'ja': 'おもった とおりで、「これで いいな」と おもう きもち。', 'en': 'Feeling "this is just right" because it turned out as you wished.', 'vi': 'Cảm thấy hài lòng, thấy "thế này là được rồi".'},
    'よろこばせる': {'ja': 'ほかの ひとを うれしい きもちに させる こと。', 'en': 'To make another person feel happy.', 'vi': 'Làm cho người khác vui.'},
    'たのしみ': {'ja': 'これから あることを、まちどおしく おもう こと。', 'en': 'Looking forward to something that will happen.', 'vi': 'Mong chờ, háo hức đến lúc sắp tới.'},
    'もうすぐ': {'ja': 'あと すこしで。ちかいうちに。', 'en': 'Very soon; in just a little while.', 'vi': 'Sắp rồi, chỉ còn một lát nữa thôi.'},
    'たのしい': {'ja': 'おもしろくて、わらいたくなる きもち。', 'en': 'The feeling of fun, when you want to laugh.', 'vi': 'Vui, thú vị, muốn cười.'},
    'あそぶ': {'ja': 'すきな ことを して たのしく すごす こと。', 'en': 'To spend time having fun doing what you like.', 'vi': 'Chơi, làm điều mình thích để vui.'},
    'おどろく': {'ja': 'おもっても みなかった ことで、びっくり する こと。', 'en': 'To be surprised by something you did not expect.', 'vi': 'Bất ngờ, giật mình vì chuyện không ngờ tới.'},
    'きく': {'ja': 'みみで おとや はなしを うけとる こと。', 'en': 'To take in sounds or words with your ears.', 'vi': 'Nghe bằng tai (hoặc hỏi).'},
    'かなしい': {'ja': 'なきたくなる ような、つらくて さびしい きもち。', 'en': 'The sad, lonely feeling that makes you want to cry.', 'vi': 'Buồn, cảm giác muốn khóc.'},
    'なく': {'ja': 'かなしい ときや いたい ときに、なみだを ながす こと。', 'en': 'To cry tears when you are sad or hurt.', 'vi': 'Khóc, rơi nước mắt khi buồn hoặc đau.'},
    'あんしん': {'ja': 'しんぱいが なくなって、ほっと する こと。', 'en': 'Feeling relieved because the worry is gone.', 'vi': 'Yên tâm, nhẹ nhõm vì hết lo lắng.'},
    'かえる': {'ja': 'いた ところから、もとの いえや ばしょへ もどる こと。', 'en': 'To go back home or to where you started.', 'vi': 'Trở về nhà hoặc nơi ban đầu.'},
    'しんぱい': {'ja': 'わるい ことが おきないか と、きに なって おちつかない こと。', 'en': 'Worrying that something bad might happen.', 'vi': 'Lo lắng, sợ có chuyện không tốt xảy ra.'},
    'ねる': {'ja': 'めを とじて、からだを やすめる こと。ねむる こと。', 'en': 'To close your eyes and rest; to sleep.', 'vi': 'Ngủ, nhắm mắt nghỉ ngơi.'},
    'はずかしい': {'ja': 'ひとに みられて、かおが あかく なる ような きもち。', 'en': 'Feeling shy, as if your face turns red when people look.', 'vi': 'Xấu hổ, ngại, cảm giác đỏ mặt khi bị người khác nhìn.'},
    'わらう': {'ja': 'おもしろい ときや うれしい ときに、かおが にこっと する こと。', 'en': 'To smile or laugh when something is funny or happy.', 'vi': 'Cười khi thấy vui hoặc buồn cười.'},
    'かんしゃ': {'ja': '「ありがとう」と おもう きもち。', 'en': 'The feeling of "thank you".', 'vi': 'Lòng biết ơn, cảm giác muốn nói "cảm ơn".'},
    'つたえる': {'ja': 'じぶんの おもいや ことを、あいてに わかるように おしえる こと。', 'en': 'To let someone know your thoughts or news.', 'vi': 'Truyền đạt, cho người khác biết điều mình nghĩ hoặc muốn nói.'},
    'がっかり': {'ja': 'たのしみに していた ことが だめに なって、げんきが なくなる こと。', 'en': 'Feeling let down when something you hoped for does not happen.', 'vi': 'Thất vọng, mất hết tinh thần khi chuyện mong chờ không thành.'},
    'なる': {'ja': 'ほかの ようすに かわる こと。', 'en': 'To become something different.', 'vi': 'Trở thành, biến đổi sang trạng thái khác.'},
    'まよう': {'ja': 'どちらに しようか きめられなくて、こまる こと。', 'en': 'Not being able to decide which one to choose.', 'vi': 'Phân vân, không biết chọn cái nào.'},
    'えらぶ': {'ja': 'いくつかの なかから、すきな ものを ひとつ きめる こと。', 'en': 'To pick one thing from several.', 'vi': 'Chọn một thứ trong nhiều thứ.'},
    'いそぐ': {'ja': 'おくれないように、はやく しようと する こと。', 'en': 'To hurry so that you will not be late.', 'vi': 'Vội, làm nhanh để không bị trễ.'},
    'はしる': {'ja': 'あしを はやく うごかして すすむ こと。', 'en': 'To move fast on your feet.', 'vi': 'Chạy, di chuyển nhanh bằng chân.'},
    'まつ': {'ja': 'だれかが くる ことや、なにかが おこる ことを、そのまま いて まって いる こと。', 'en': 'To stay where you are until someone comes or something happens.', 'vi': 'Chờ đợi, ở yên đến khi ai đó đến hoặc việc gì xảy ra.'},
  };

  static String bunMeaning(String w, String lang) => _bunMeaning[w]?[lang] ?? '';

  // Cac dang cua tu (ke ca chinh no): de tu kiem tra va goi y
  static List<String> bunForms(String w) => _bunForms[w] ?? [w];

  static KokugoItem _bunItem(String label, String a, String b, List<String> examples) => KokugoItem(
        label: label,
        parts: [KokugoPart('', blank: true, reads: examples), KokugoPart(a), KokugoPart(b)],
      );

  static List<List<String>> _perms(List<String> xs) {
    if (xs.length <= 1) return [List<String>.from(xs)];
    final out = <List<String>>[];
    for (var i = 0; i < xs.length; i++) {
      final rest = [...xs.sublist(0, i), ...xs.sublist(i + 1)];
      for (final p in _perms(rest)) {
        out.add([xs[i], ...p]);
      }
    }
    return out;
  }

  // time/subj dung dau (time truoc hoac sau subj deu duoc), free dao thu tu tu do, tail cuoi cau
  static KokugoItem _narabeItem(String label, String time, String subj, List<String> free, List<String> tail,
      {Random? r, List<String>? shown}) {
    final heads = time.isEmpty
        ? [[subj]]
        : [[time, subj], [subj, time]];
    final accepted = <String>[];
    for (final h in heads) {
      for (final p in _perms(free)) {
        accepted.add('${[...h, ...p, ...tail].join()}。');
      }
    }
    final order = [...heads.first, ...free, ...tail]; // thu tu chuan
    var display = shown ?? List<String>.from(order);
    if (shown == null) {
      final rnd = r ?? Random();
      var guard = 0;
      do {
        display = List<String>.from(order)..shuffle(rnd);
        guard++;
      } while (accepted.contains('${display.join()}。') && guard < 50);
    }
    return KokugoItem(
      label: label,
      parts: [
        KokugoPart('', blank: true, reads: accepted),
        for (final c in display) KokugoPart(c),
      ],
      extra: {'order': order},
    );
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
        // --- ページ2: かたかなを かん字に なおして かきましょう ---
        _kakiItem(0, '', '本', 'ホン', 'を よむ。'),
        _kakiItem(1, '', '学校', 'ガッ|コウ', 'に いく。'),
        _kakiItem(2, 'はらが', '立', 'タ', 'つ。'),
        _kakiItem(3, 'ふえの', '音', 'ネ', 'いろ。'),
        _kakiItem(4, '', '手先', 'テ|サキ', 'が きようだ。'),
        _kakiItem(5, '', '名', 'ナ', 'ふだ'),
        _kakiItem(6, '', '大学生', 'ダイ|ガク|セイ', ''),
        KokugoItem(label: _circ[7], parts: [_b('左右', 'サ|ユウ'), _t('を よく'), _b('見', 'ミ'), _t('る。')]),
        _kakiItem(8, '', '小', 'コ', 'ゆび'),
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
        // --- ページ2: ──せんの かん字の よみ (女・大・中) ---
        KokugoItem(label: '①ア', parts: [_y('女', ['め']), _t('がみさま')]),
        KokugoItem(label: '①イ', parts: [_y('女', ['じょ']), _t('子')]),
        KokugoItem(label: '①ウ', parts: [_y('女', ['おんな']), _t('の子')]),
        KokugoItem(label: '②ア', parts: [_y('大', ['おお']), _t('きいおさら。')]),
        KokugoItem(label: '②イ', parts: [_y('大', ['たい']), _t('木')]),
        KokugoItem(label: '②ウ', parts: [_t('さい'), _y('大', ['だい']), _t('の力を出す。')]),
        KokugoItem(label: '③ア', parts: [_y('中', ['ちゅう']), _t('心')]),
        KokugoItem(label: '③イ', parts: [_t('ひとばん'), _y('中', ['じゅう'])]),
        KokugoItem(label: '③ウ', parts: [_y('中', ['なか']), _t('ゆび')]),
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
        for (var n = 0; n < 6; n++)
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
        for (var n = 0; n < 6; n++)
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
        // あてはまる ことば: 6 cau trong sach (bang tu: まだ もう けれども なぜなら それとも だから), chia 2 bai
        for (var n = 0; n < 2; n++)
          KokugoLesson(
            id: 'ST00${n + 1}',
            title: {
              'ja': 'あてはまる ことば ${n + 1}',
              'en': 'Fill in the Word ${n + 1}',
              'vi': 'Điền từ thích hợp ${n + 1}',
            },
            question: questionFor('setsuzoku'),
            kind: 'setsuzoku',
            difficulty: 2,
            items: [
              for (var i = 0; i < 3; i++) _setsuItem(n * 3 + i, _setsuBank[const [0, 4, 8, 11, 16, 21][n * 3 + i]]),
            ],
            bank: const ['まだ', 'もう', 'けれども', 'なぜなら', 'それとも', 'だから'],
          ),
        // おなじ おとの かん字: 6 nhom trong sach (1)-(6), moi nhom la 1 bai (2-3 cau)
        for (var n = 0; n < 6; n++)
          KokugoLesson(
            id: 'DO00${n + 1}',
            title: {
              'ja': 'おなじ おとの かん字 (${n + 1})',
              'en': 'Same-Sound Kanji (${n + 1})',
              'vi': 'Chữ Hán đồng âm (${n + 1})',
            },
            question: questionFor('doon'),
            kind: 'doon',
            difficulty: _doonBank[n].length == 3 ? 2 : 1,
            items: [
              for (var i = 0; i < _doonBank[n].length; i++) _doonItem(i, _doonBank[n][i]),
            ],
          ),
        // にた いみの ことば: 5 cap trong sach, chia thanh 2 bai (3 cap + 2 cap); khung chi chua tu cua bai do
        for (var n = 0; n < 2; n++)
          KokugoLesson(
            id: 'RG00${n + 1}',
            title: {
              'ja': 'にた いみの ことば ${n + 1}',
              'en': 'Similar Words ${n + 1}',
              'vi': 'Từ đồng nghĩa ${n + 1}',
            },
            question: questionFor('ruigi'),
            kind: 'ruigi',
            difficulty: n == 0 ? 2 : 1,
            items: [
              for (var i = 0; i < (n == 0 ? 3 : 2); i++) _ruigiItem(i, _ruigiBook[n * 3 + i]),
            ],
            bank: _ruigiBank(n == 0 ? _ruigiBook.sublist(0, 3) : _ruigiBook.sublist(3), null),
          ),
        // ぶんを つくろう: 本の 4 (1)(2) (れいは もんだい文に ある)
        KokugoLesson(
          id: 'NB001',
          title: {
            'ja': 'ぶんを つくろう 1',
            'en': 'Build the Sentence 1',
            'vi': 'Sắp xếp thành câu 1',
          },
          question: questionFor('narabe'),
          kind: 'narabe',
          difficulty: 2,
          items: [
            _narabeItem('(1)', 'きのう', 'わたしは', const [], ['おとうさんの', 'かたを', 'たたいてあげました'],
                shown: ['かたを', 'たたいてあげました', 'きのう', 'わたしは', 'おとうさんの']),
            _narabeItem('(2)', 'あした', 'ぼくは', ['ともだちと', 'こうえんで'], ['あそぶ', 'やくそくを', 'しました'],
                shown: ['やくそくを', 'あそぶ', 'あした', 'しました', 'こうえんで', 'ともだちと', 'ぼくは']),
          ],
        ),
        // ことばを つかって ぶんを つくろう: 本の 5 (1)〜(4) (cau mau la do ta soan de tu cham)
        KokugoLesson(
          id: 'BS001',
          title: {
            'ja': 'ことばを つかって ぶんを つくろう 1',
            'en': 'Write a Sentence with the Words 1',
            'vi': 'Đặt câu với từ cho sẵn 1',
          },
          question: questionFor('bunsaku'),
          kind: 'bunsaku',
          difficulty: 2,
          items: [
            _bunItem('(1)', 'うれしい', 'はなす', ['うれしい できごとを おかあさんに はなしました。', 'ぼくは うれしくて、ともだちに はなしました。']),
            _bunItem('(2)', 'こうふん', 'できる', ['しあいの まえは こうふんして、うまく できませんでした。', 'こうふんしても、おちついて できるように なりたい。']),
            _bunItem('(3)', 'まんぞく', 'よろこばせる', ['おとうとを よろこばせる ことが できて、まんぞくしました。', 'みんなを よろこばせて、まんぞくした。']),
            _bunItem('(4)', 'たのしみ', 'もうすぐ', ['もうすぐ えんそくで、とても たのしみです。', 'たのしみに していた たんじょうびが もうすぐ きます。']),
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
    ['本', 'ホン', '', 'を よむ。'],
    ['立', 'タ', 'ぼうが', 'つ。'],
    ['音', 'オト', 'きれいな', 'が きこえる。'],
    ['手先', 'テ|サキ', '', 'が きようだ。'],
    ['名', 'ナ', '', 'ふだを つける。'],
    ['大学生', 'ダイ|ガク|セイ', '', 'に なる。'],
    ['小', 'コ', '', 'ゆび'],
  ];

  // ---------- kho tu: yomi  chu Han -> [truoc, sau, dap an 1, dap an 2...] ----------
  static const Map<String, List<List<String>>> _yomiBank = {
    '大': [
      ['', 'きい', 'おお'],
      ['', '会', 'たい'],
      ['', '小', 'だい'],
      ['', '木', 'たい'],
      ['さい', 'の力を出す。', 'だい'],
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
      ['', 'がみさま', 'め'],
      ['', '王', 'じょ'],
    ],
    '中': [
      ['', '心', 'ちゅう'],
      ['ひとばん', '', 'じゅう'],
      ['', 'ゆび', 'なか'],
      ['', '学生', 'ちゅう'],
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
    if (kind == 'bunsaku') {
      final count = lv == 1 ? 2 : 3;
      final pool = List<List<dynamic>>.from(_bunPool)..shuffle(r);
      return KokugoLesson(
        id: id,
        title: title,
        question: questionFor('bunsaku'),
        kind: 'bunsaku',
        difficulty: lv,
        isAutoGenerated: true,
        items: [
          for (var i = 0; i < count; i++)
            _bunItem('(${i + 1})', pool[i][0] as String, pool[i][1] as String, (pool[i][2] as List).cast<String>()),
        ],
      );
    }
    if (kind == 'narabe') {
      // muc 1: 2 cau (it tu), muc 2-3: 3 cau (day du tu)
      final count = lv == 1 ? 2 : 3;
      final pool = List<List<dynamic>>.from(_narabePool)..shuffle(r);
      return KokugoLesson(
        id: id,
        title: title,
        question: questionFor('narabe'),
        kind: 'narabe',
        difficulty: lv,
        isAutoGenerated: true,
        items: [
          for (var i = 0; i < count; i++)
            _narabeItem(
              '(${i + 1})',
              lv == 1 ? '' : pool[i][0] as String,
              pool[i][1] as String,
              lv == 1 ? (pool[i][2] as List).cast<String>().take(1).toList() : (pool[i][2] as List).cast<String>(),
              (pool[i][3] as List).cast<String>(),
              r: r,
            ),
        ],
      );
    }
    if (kind == 'ruigi') {
      final count = lv == 1 ? 2 : 3;
      final pool = [..._ruigiBook, ..._ruigiPool]..shuffle(r);
      final use = pool.take(count).toList();
      return KokugoLesson(
        id: id,
        title: title,
        question: questionFor('ruigi'),
        kind: 'ruigi',
        difficulty: lv,
        isAutoGenerated: true,
        items: [for (var i = 0; i < use.length; i++) _ruigiItem(i, use[i])],
        bank: _ruigiBank(use, r),
      );
    }
    if (kind == 'doon') {
      // chon 1 nhom chu Han cung am: muc 1 lay 2 cau, muc 2-3 uu tien nhom co 3 cau
      final all = List<List<List<String>>>.from(_doonBank);
      var cand = lv == 1 ? all : all.where((g) => g.length >= 3).toList();
      if (cand.isEmpty) cand = all;
      cand.shuffle(r);
      final g = List<List<String>>.from(cand.first)..shuffle(r);
      final pick = g.take(lv == 1 ? 2 : 3).toList();
      return KokugoLesson(
        id: id,
        title: title,
        question: questionFor('doon'),
        kind: 'doon',
        difficulty: lv,
        isAutoGenerated: true,
        items: [for (var i = 0; i < pick.length; i++) _doonItem(i, pick[i])],
      );
    }
    if (kind == 'setsuzoku') {
      // muc 1: 2 cau, muc 2-3: 3 cau; muc 2 them 1 tu thua, muc 3 them 2 tu thua
      final count = lv == 1 ? 2 : 3;
      List<List<String>> picks = [];
      List<String> words = [];
      for (var t = 0; t < 300; t++) {
        final pool = List<List<String>>.from(_setsuBank)..shuffle(r);
        final cand = <List<String>>[];
        final used = <String>{};
        for (final e in pool) {
          if (used.add(e[1])) cand.add(e);
          if (cand.length == count) break;
        }
        final w = [for (final e in cand) e[1]];
        if (_setsuUnique(cand, w)) {
          picks = cand;
          words = w;
          break;
        }
      }
      if (picks.isEmpty) {
        // du phong (hiem): lay 2 cau mau trong sach
        picks = [_setsuBank[0], _setsuBank[4]];
        words = ['まだ', 'もう'];
      }
      final extra = lv == 1 ? 0 : (lv == 2 ? 1 : 2);
      final spare = [
        for (final w in _setsuWords)
          if (!words.contains(w) && picks.every((e) => !_setsuCompat[e[3]]!.contains(w))) w,
      ]..shuffle(r);
      final bank = [...words, ...spare.take(extra)]..shuffle(r);
      return KokugoLesson(
        id: id,
        title: title,
        question: questionFor('setsuzoku'),
        kind: 'setsuzoku',
        difficulty: lv,
        isAutoGenerated: true,
        items: [for (var i = 0; i < picks.length; i++) _setsuItem(i, picks[i])],
        bank: bank,
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
