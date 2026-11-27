import 'dart:math';
import '../models/kokugo_lesson.dart';
import 'stroke_data.dart';

// Bai 国語 (lop 1): viet chu Han (kaki) va viet cach doc (yomi).
// Kho tu vung va cau vi du do ta tu soan.
class KokugoEngine {
  static const List<String> kinds = ['kaki', 'yomi', 'hitsujun', 'kakijun', 'shugo', 'kotowaza', 'hantai', 'kanyou', 'setsuzoku', 'doon', 'ruigi', 'narabe', 'bunsaku', 'shiji', 'erabu', 'tsunagi', 'doyomi', 'hantaigo'];

  static const Map<String, Map<String, String>> baseNames = {
    'kaki': {'ja': 'かん字を かこう', 'en': 'Write the Kanji', 'vi': 'Viết chữ Hán'},
    'yomi': {'ja': 'かん字の よみ', 'en': 'Kanji Readings', 'vi': 'Cách đọc chữ Hán'},
    'hitsujun': {'ja': 'かん字の ひつじゅん', 'en': 'Stroke Order', 'vi': 'Thứ tự nét chữ Hán'},
    'kakijun': {'ja': '正しい かきじゅん', 'en': 'Correct Stroke Order', 'vi': 'Thứ tự viết nét đúng'},
    'hantai': {'ja': 'はんたいの いみの かん字', 'en': 'Opposite Kanji', 'vi': 'Chữ Hán trái nghĩa'},
    'kanyou': {'ja': 'かんようく', 'en': 'Idioms', 'vi': 'Thành ngữ (bộ phận cơ thể)'},
    'setsuzoku': {'ja': 'あてはまる ことば', 'en': 'Fill in the Word', 'vi': 'Điền từ thích hợp'},
    'doon': {'ja': 'おなじ おとの かん字', 'en': 'Same-Sound Kanji', 'vi': 'Chữ Hán đồng âm'},
    'shugo': {'ja': 'しゅご と じゅつご', 'en': 'Subject & Predicate', 'vi': 'Chủ ngữ và vị ngữ'},
    'kotowaza': {'ja': 'ことわざ', 'en': 'Proverbs', 'vi': 'Tục ngữ (ことわざ)'},
    'shiji': {'ja': 'こそあど ことば', 'en': 'What Does It Point To?', 'vi': 'Từ chỉ thị (これ・それ…)'},
    'ruigi': {'ja': 'にた いみの ことば', 'en': 'Similar Words', 'vi': 'Từ đồng nghĩa'},
    'narabe': {'ja': 'ぶんを つくろう', 'en': 'Build the Sentence', 'vi': 'Sắp xếp thành câu'},
    'bunsaku': {'ja': 'ことばを つかって ぶんを つくろう', 'en': 'Write a Sentence with the Words', 'vi': 'Đặt câu với từ cho sẵn'},
    'erabu': {'ja': 'あう ことばを えらぼう', 'en': 'Choose the Best Word', 'vi': 'Chọn từ phù hợp nhất'},
    'tsunagi': {'ja': 'つなぎことば', 'en': 'Connecting Words', 'vi': 'Từ nối (つなぎことば)'},
    'doyomi': {'ja': 'おなじ よみの かん字', 'en': 'Kanji with the Same Reading', 'vi': 'Chữ Hán cùng cách đọc'},
    'hantaigo': {'ja': 'はんたいの いみの ことば', 'en': 'Opposite Words', 'vi': 'Từ trái nghĩa'},
  };

  static const List<String> numerals = ['一', '二', '三', '四', '五', '六', '七', '八', '九', '十'];

  static const List<String> _circ = ['①', '②', '③', '④', '⑤', '⑥', '⑦', '⑧', '⑨', '⑩'];
  static const List<String> _kana3 = ['ア', 'イ', 'ウ', 'エ'];

  static Map<String, String> questionFor(String kind) {
    if (kind == 'hitsujun') {
      return {
        'ja': '→の ところは なんばん目に かきますか。○に かん字で すう字を かきましょう。',
        'en': 'Which stroke (in writing order) is the arrow pointing to? Write the number in kanji in the circle.',
        'vi': 'Mũi tên chỉ nét thứ mấy (theo thứ tự viết)? Viết số bằng chữ Hán vào hình tròn.',
      };
    }
    if (kind == 'shugo') {
      return {
        'ja': 'つぎの 文の しゅごを ○で、じゅつごを □で かこみましょう。',
        'en': 'In each sentence, circle the subject (しゅご) with ○ and box the predicate (じゅつご) with □.',
        'vi': 'Trong mỗi câu, khoanh tròn ○ chủ ngữ (しゅご) và khoanh khung □ vị ngữ (じゅつご).',
      };
    }
    if (kind == 'kotowaza') {
      return {
        'ja': 'つぎの 絵と せつめいに あう ことわざを、□の 中から えらんで、かきましょう。',
        'en': 'Choose the proverb (ことわざ) that matches each picture and explanation.',
        'vi': 'Chọn ことわざ (tục ngữ) hợp với hình và lời giải nghĩa.',
      };
    }
    if (kind == 'kakijun') {
      return {
        'ja': '正しい ほうの かきじゅんに ○を つけましょう。',
        'en': 'Which writing order is correct? Choose ア or イ.',
        'vi': 'Chọn cách viết nét đúng thứ tự (ア hoặc イ).',
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
    if (kind == 'shiji') {
      return {
        'ja': 'つぎの ──せんの こそあどことばは、なにを さしていますか。正しい ものの（　）に ○を かきましょう。',
        'en': 'What does the underlined word (これ / それ / そこ …) point to? Put ○ in the parentheses of the correct choice.',
        'vi': 'Từ gạch chân (これ・それ・そこ…) chỉ cái gì? Hãy đánh ○ vào dấu ngoặc ( ) của đáp án đúng.',
      };
    }
    if (kind == 'doyomi') {
      return {
        'ja': 'ワクの 中から おなじ よみの かん字を 見つけて、□に かきましょう。かん字は 一かいずつしか つかえません。',
        'en': 'Find two kanji in the box with the given reading and put them in the boxes. Use each kanji only once.',
        'vi': 'Tìm trong khung các chữ Hán có cùng cách đọc đã cho rồi điền vào ô. Mỗi chữ chỉ dùng một lần.',
      };
    }
    if (kind == 'hantaigo') {
      return {
        'ja': 'つぎの ──せんの ことばと はんたいの いみの ことばを、ひらがなで（　）に かきましょう。',
        'en': 'Write in hiragana the word that means the opposite of the underlined word.',
        'vi': 'Viết bằng hiragana từ trái nghĩa với từ gạch chân vào ( ).',
      };
    }
    if (kind == 'erabu') {
      return {
        'ja': 'つぎの 文に いちばん あう ことばの きごうを、○で かこみましょう。',
        'en': 'Choose the word that fits the sentence best and circle its letter (ア・イ・ウ).',
        'vi': 'Chọn từ hợp nhất với câu và khoanh tròn ký hiệu (ア・イ・ウ).',
      };
    }
    if (kind == 'tsunagi') {
      return {
        'ja': 'つぎの（　）に あてはまる つなぎことばを、ワクの 中から えらんで かきましょう。ことばは なんどでも つかえます。',
        'en': 'Choose the connecting word from the box that fits each blank. You may use a word more than once.',
        'vi': 'Chọn từ nối trong khung điền vào mỗi chỗ trống. Mỗi từ được dùng nhiều lần.',
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
    if (kind == 'shugo') {
      return lang == 'ja'
          ? 'ちがう ところが あるよ。じゅつごを さいしょに さがして、「だれが」「なにが」を かんがえよう'
          : lang == 'en'
              ? 'Something is wrong. Find the predicate first, then ask who or what does it'
              : 'Có chỗ chưa đúng. Hãy tìm vị ngữ trước, rồi hỏi "ai / cái gì" làm việc đó';
    }
    if (kind == 'kotowaza') {
      return lang == 'ja'
          ? 'ちがう ところが あるよ。せつめいと ことわざを もういちど くらべて みよう'
          : lang == 'en'
              ? 'Something is wrong. Compare each explanation with the proverbs again'
              : 'Có chỗ chưa đúng. Hãy so sánh lại lời giải nghĩa với từng câu tục ngữ';
    }
    if (kind == 'kakijun') {
      return lang == 'ja'
          ? 'ちがう ところが あるよ。1ばん目の かきかたから じゅんばんに たしかめよう'
          : lang == 'en'
              ? 'Something is wrong. Check each step from the first stroke'
              : 'Có chỗ chưa đúng. Hãy kiểm tra từng bước, bắt đầu từ nét đầu tiên';
    }
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
    if (kind == 'shiji') {
      return lang == 'ja'
          ? 'ちがう ところが あるよ。こそあどことばの ところに えらんだ ことばを いれて よんでみよう'
          : lang == 'en'
              ? 'Something is wrong. Put your choice in place of the underlined word and read it again'
              : 'Có chỗ chưa đúng. Hãy thay từ gạch chân bằng đáp án đã chọn rồi đọc lại';
    }
    if (kind == 'erabu') {
      return lang == 'ja'
          ? 'ちがう ところが あるよ。（　）に ことばを いれて よんで、いみが とおるか たしかめよう'
          : lang == 'en'
              ? 'Something is wrong. Put each word into the blank and check that the sentence makes sense'
              : 'Có chỗ chưa đúng. Hãy đặt từng từ vào chỗ trống rồi đọc xem câu có nghĩa không';
    }
    if (kind == 'tsunagi') {
      return lang == 'ja'
          ? 'ちがう ところが あるよ。まえの 文と あとの 文が どう つながるか よく かんがえよう'
          : lang == 'en'
              ? 'Something is wrong. Think about how the first sentence connects to the second'
              : 'Có chỗ chưa đúng. Hãy nghĩ xem câu trước và câu sau nối với nhau như thế nào';
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

  // cau 'yomi' dang cau van: [[chu Han|cach doc]] la cho can viet cach doc.
  // Moi cho tro thanh 1 cau hoi (ア イ ウ); cac chu Han con lai trong cau chi hien thi.
  static List<KokugoItem> _yomiSentence(int no, String src) {
    final re = RegExp(r'〔([^|〕]+)\|([^〕]+)〕');
    final targets = re.allMatches(src).toList();
    final items = <KokugoItem>[];
    for (var t = 0; t < targets.length; t++) {
      final parts = <KokugoPart>[];
      var buf = '';
      var last = 0;
      for (var k = 0; k < targets.length; k++) {
        final m = targets[k];
        buf += src.substring(last, m.start);
        if (k == t) {
          if (buf.isNotEmpty) parts.add(_t(buf));
          buf = '';
          parts.add(_y(m.group(1)!, [m.group(2)!]));
        } else {
          buf += m.group(1)!;
        }
        last = m.end;
      }
      buf += src.substring(last);
      if (buf.isNotEmpty) parts.add(_t(buf));
      items.add(KokugoItem(label: '${_circ[no]}${_kana3[t]}', parts: parts));
    }
    return items;
  }

  // ページ3 (かん字の よみ: ──せんの かん字): 8 cau, moi cau la 1 bai
  static const List<String> _yomiSent = [
    '〔上|のぼ〕りの てん車は あと〔五|ご〕ふんで くる。',
    '〔早生|はやう〕まれの〔人|ひと〕は、まだ〔六|ろく〕さいだ。',
    '〔小学生|しょうがくせい〕が〔小|ちい〕さな こえで じぶんの〔名|な〕まえを いう。',
    'わたしは、〔生|い〕け〔花|ばな〕を ならっている。',
    '〔金|きん〕よう日に〔金|かな〕あみを かいに いった。',
    'きれいな〔字|じ〕で〔上下|じょうげ〕 〔左右|さゆう〕と かく。',
    '〔年中|ねんじゅう〕 はんそでを きている あの〔男|おとこ〕の子は、〔本|ほん〕とうに じょうぶだ。',
    '〔花|か〕だんの まん〔中|なか〕に、きゅうこんを うえた。',
  ];

  // ページ1 (2): おなじ かん字の ちがう よみ: [ア/イ/ウ, 前, 漢字, [こたえ], 後]
  static const List<List<List<dynamic>>> _yomiSame = [
    [
      ['ア', 'やさしい', '人', ['ひと'], '。'],
      ['イ', '百', '人', ['にん', 'ひゃくにん'], '一首（しゅ）'],
      ['ウ', '町（まち）の', '人', ['じん', 'じんこう'], '口。'],
    ],
    [
      ['ア', 'はたを', '立', ['た'], 'てる。'],
      ['イ', 'き', '立', ['りつ', 'きりつ'], '、れい、ちゃくせき。'],
      ['ウ', '', '立', ['りっ', 'りっしゅん'], '春（しゅん）'],
    ],
    [
      ['ア', '右（みぎ）', '足', ['あし'], ''],
      ['イ', '一', '足', ['そく', 'いっそく'], 'のくつ。'],
      ['ウ', '五と八を', '足', ['た'], 'す。'],
    ],
  ];

  // ページ3 (2): ──せんの かん字の よみ。（ ）の ひらがなは 本に ふりがなとして 出ている よみ
  static const List<String> _yomiSent2 = [
    '「〔竹|ちく〕馬（ば）のとも」とは、〔竹|たけ〕馬（うま）に のって あそんだ 小（ちい）さい ころからの ともだちと いう いみだ。',
    '〔人|にん〕気（き）の しばいなので、〔立|た〕ち〔見|み〕の きゃくが〔出|で〕た。',
    'めずらしい〔虫|ちゅう〕が えがかれた 切（きっ）〔手|て〕を〔入手|にゅうしゅ〕した。',
    '「〔犬|けん〕えんのなか」とは、とても なかの わるい かんけいの ことだ。',
    'きれいな〔花|はな〕を さかせるため、〔花|か〕だんに〔入|はい〕っては いけない。',
    '〔休日|きゅうじつ〕に、この 音（おん）がくを きくと、こころが〔休|やす〕まる。',
    'もう その はなしを しっているなんて、きみは〔早耳|はやみみ〕だね。',
    'いろいろな〔貝|かい〕を、たべたいだけ たべたので まん〔足|ぞく〕した。',
  ];

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

  // cau 'kakijun': k = chu Han, c = cac cach viet (ア, イ) -- moi cach la danh sach buoc,
  // moi buoc la chi so (0-based) cac net da viet; i = dap an dung (0 = ア, 1 = イ)
  static List<List<int>> _stagesOf(List<int> order) => [
        for (var k = 0; k < order.length; k++) ([...order.sublist(0, k + 1)]..sort()),
      ];

  static KokugoItem _kakijunItem(String label, String ch, List<List<List<int>>> choices, int correct) {
    return KokugoItem(
      label: label,
      parts: [KokugoPart('', blank: true, reads: [_kana3[correct]])],
      extra: {'k': ch, 'c': choices, 'i': correct},
    );
  }

  // --- 'shugo': 文節 cach nhau '|', chi so chu ngu (○), chi so vi ngu (□) ---
  static const List<List<dynamic>> _shugoBook = [
    ['ぼくの|おかあさんは|かんごしだ。', 1, 2],
    ['夜空の|ほしが|とても|きれいだ。', 1, 3],
    ['おとうとは|めだかと|金ぎょを|そだてている。', 0, 3],
    ['ともだちが|先生に|プレゼントを|わたした。', 0, 3],
    ['森には|たくさんの|虫たちも|すんでいる。', 2, 3],
    ['赤いろの|車は|とつぜん|はしり出した。', 1, 3],
  ];
  static const List<List<dynamic>> _shugoPool = [
    ['小さな|ねこが|木の上で|ねている。', 1, 3],
    ['あたらしい|先生は|とても|やさしい。', 1, 3],
    ['ぼくは|毎日|学校へ|行く。', 0, 3],
    ['はるの|花が|きれいに|さいた。', 1, 3],
    ['おとうさんは|おいしい|カレーを|つくった。', 0, 3],
    ['空の|雲が|ゆっくり|うごいている。', 1, 3],
    ['妹は|赤い|ぼうしを|かぶっている。', 0, 3],
    ['すずしい|風が|ふいてくる。', 1, 2],
    ['ぼくの|犬は|とても|かしこい。', 1, 3],
    ['校ていの|さくらが|まんかいだ。', 1, 2],
    ['おばあさんは|毎朝|さんぽを|する。', 0, 3],
    ['先生が|黒ばんに|字を|書いた。', 0, 3],
    ['青い|鳥が|空を|とんでいる。', 1, 3],
    ['大きな|犬が|ワンワン|ほえた。', 1, 3],
    ['ひろい|校ていで|みんなが|あそんでいる。', 2, 3],
    ['わたしの|ゆめは|パイロットだ。', 1, 2],
    ['きょうの|けしきは|すばらしい。', 1, 2],
    ['弟は|ゆうえんちで|はしゃいだ。', 0, 2],
    ['夜の|海は|しずかだ。', 1, 2],
    ['となりの|子が|なわとびを|している。', 1, 3],
  ];

  static KokugoItem _shugoItem(String label, String sent, int s, int j) {
    final c = sent.split('|');
    return KokugoItem(label: label, parts: [
      for (var k = 0; k < c.length; k++) k == s ? _y(c[k], ['s']) : (k == j ? _y(c[k], ['j']) : _t(c[k])),
    ]);
  }

  // --- 'kotowaza': [ことわざ, せつめい(ja), 絵(emoji), en, vi] ---
  static const List<List<String>> _kotoPool = [
    ['どんぐりのせいくらべ', 'どれもみなおなじくらいで、とくにすぐれたものがないということ。', '👦📝👧',
      'Everyone is about the same; nobody stands out.', 'Ai cũng na ná như nhau, không ai nổi bật hơn.'],
    ['ほとけのかおも三どまで', 'どんなにおだやかな人でも、ひどいことをなんどもされればおこり出すということ。', '😇😠',
      'Even the gentlest person gets angry if treated badly again and again.', 'Dù hiền đến mấy, bị đối xử tệ nhiều lần cũng sẽ nổi giận.'],
    ['とらのいをかるきつね', 'じぶんに力はないのに、力のある人をたのみにしていばる人のこと。', '🦊🐯',
      'A person with no power who boasts by relying on someone powerful.', 'Người không có sức mạnh nhưng dựa hơi người mạnh để làm oai.'],
    ['いそがばまわれ', 'いそぐときほど、あわてずていねいにとりくむほうが、うまくいくということ。', '🐢🗻',
      'The more hurried you are, the more carefully you should work; it goes better that way.', 'Càng vội càng nên làm cẩn thận, từ tốn thì mới thành công.'],
    ['しらぬがほとけ', 'しらないほうが、はらも立たず、おだやかでいられるということ。', '🙈',
      'Not knowing keeps you calm.', 'Không biết thì lòng thanh thản.'],
    ['さるも木からおちる', 'どんな名人でも、しっぱいすることがあるというたとえ。', '🐒',
      'Even an expert can make a mistake.', 'Dù là cao thủ cũng có lúc thất bại.'],
    ['ねこにこばん', 'とてもたいせつなものでも、わからない人にはねうちがないということ。', '🐱💰',
      'Something precious is worthless to someone who does not understand it.', 'Đồ quý giá với người không biết giá trị thì cũng vô ích.'],
    ['かえるの子はかえる', 'こどもは、おやににるものだということ。', '🐸',
      'Children take after their parents.', 'Con cái thường giống bố mẹ.'],
    ['七ころび八おき', 'なんどしっぱいしても、あきらめずにがんばることがたいせつだということ。', '💪',
      'Even if you fail many times, do not give up and keep trying.', 'Thất bại nhiều lần cũng đừng bỏ cuộc, cứ cố gắng tiếp.'],
    ['花よりだんご', 'きれいなものより、じっさいにやくに立つもののほうがよいということ。', '🌸🍡',
      'Something useful is better than something pretty.', 'Thực dụng còn hơn đẹp mã.'],
    ['石の上にも三年', 'つらくても、がまんしてつづければ、いつかうまくいくということ。', '⏳',
      'If you keep going patiently, you will succeed in the end.', 'Dù vất vả, kiên nhẫn theo đuổi thì rồi sẽ thành công.'],
    ['ちりもつもれば山となる', 'ちいさなことでも、つみかさねれば大きなものになるということ。', '🧹',
      'Small things add up to something big.', 'Việc nhỏ tích lại sẽ thành việc lớn.'],
    ['ころばぬさきのつえ', 'しっぱいしないように、まえもってよういしておくことがたいせつだということ。', '🧓',
      'Prepare in advance so that you do not fail.', 'Chuẩn bị trước để không bị thất bại.'],
    ['くさってもたい', 'ほんものは、すこしようすがわるくなっても、ねうちがあるということ。', '🐟',
      'The real thing keeps its value even when it looks worse.', 'Hàng thật dù hơi xuống cấp vẫn có giá trị.'],
    ['犬もあるけばぼうにあたる', 'なにかをすれば、おもいがけないことにであうということ。', '🐕',
      'If you go out and do something, you may run into something unexpected.', 'Cứ hành động thì sẽ gặp chuyện bất ngờ (may hoặc rủi).'],
    ['あとのまつり', 'もうまにあわない、おそすぎるということ。', '🎆',
      'It is too late.', 'Đã quá muộn rồi.'],
  ];

  static KokugoItem _kotowazaItem(String label, String name) {
    final e = _kotoPool.firstWhere((x) => x[0] == name);
    return KokugoItem(
      label: label,
      parts: [_t(e[1]), _y(e[0], [e[0]])],
      extra: {'e': e[2], 'm': {'en': e[3], 'vi': e[4]}},
    );
  }

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
    // --- ページ3: ぎたいご・ふくし (本の 3 (1)〜(6) の じゅんばん) ---
    ['このところ、木のはも いろづき、', 'めっきり', 'あきらしく なってきた。', 'zめっきり'],
    ['ともだちが、', 'こっそり', 'ないしょばなしを おしえてくれた。', 'zこっそり'],
    ['としょかんの 本だなには、本が', 'ぎっしり', 'つまっている。', 'zぎっしり'],
    ['日本ばれの 空に、ふじ山が', 'くっきり', '見えた。', 'zくっきり'],
    ['おばあちゃんが、九州から', 'はるばる', 'あそびに きてくれた。', 'zはるばる'],
    ['どうして こんな かんたんな けいさんを まちがえたのか', 'さっぱり', 'わからない。', 'zさっぱり'],
    // --- じぶんで ふやした ぶん (じどう生成用) ---
    ['いまは ちいさい ゆめだけれど、', 'ゆくゆく', 'せかいで かつやくしたい。', 'zゆくゆく'],
    ['はしりつかれて、よるは', 'ぐっすり', 'ねむった。', 'zぐっすり'],
    ['いそがずに、こうえんを', 'のんびり', 'さんぽした。', 'zのんびり'],
    ['ともだちの ぼうしを', 'うっかり', 'まちがえて かぶって きてしまった。', 'zうっかり'],
    ['あめが やんで、そらが', 'すっかり', 'はれた。', 'zすっかり'],
    ['あぶないから、てを', 'しっかり', 'にぎって あるこう。', 'zしっかり'],
    // --- ページ4 (本の 3 (1)〜(6) の じゅんばん) ---
    ['かりた 本が', 'なかなか', '見つからない。', 'zなかなか'],
    ['正ぎの みかたが', 'さっそうと', 'あらわれる。', 'zさっそうと'],
    ['一ばんぼしが 出ると、', 'みるみる', '空が くらくなった。', 'zみるみる'],
    ['犬に ほえられ', '一目さんに', 'にげた。', 'z一目さんに'],
    ['おかあさんの かおを', 'まじまじと', '見る。', 'zまじまじと'],
    ['きみが', 'もっとも', 'すきな たべものは なに？', 'zもっとも'],
  ];

  // ぎたいご・ふくし (adverb) -- 'z' loai cau
  static const List<String> _advWords = [
    'さっぱり', 'ぎっしり', 'くっきり', 'こっそり', 'めっきり', 'ゆくゆく', 'はるばる',
    'ぐっすり', 'のんびり', 'うっかり', 'すっかり', 'しっかり',
    'なかなか', 'さっそうと', 'みるみる', '一目さんに', 'まじまじと', 'もっとも',
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
    // ぎたいご: cung hop nghia voi cau thi them vao (ke ca chinh no)
    'zめっきり': ['めっきり', 'すっかり', 'みるみる'],
    'zこっそり': ['こっそり'],
    'zぎっしり': ['ぎっしり'],
    'zくっきり': ['くっきり', 'はっきり'],
    'zはるばる': ['はるばる'],
    'zさっぱり': ['さっぱり'],
    'zゆくゆく': ['ゆくゆく'],
    'zぐっすり': ['ぐっすり'],
    'zのんびり': ['のんびり'],
    'zうっかり': ['うっかり'],
    'zすっかり': ['すっかり', 'めっきり', 'みるみる'],
    'zなかなか': ['なかなか'],
    'zさっそうと': ['さっそうと'],
    'zみるみる': ['みるみる', 'めっきり', 'すっかり'],
    'z一目さんに': ['一目さんに'],
    'zまじまじと': ['まじまじと'],
    'zもっとも': ['もっとも', 'なかなか'],
    'zしっかり': ['しっかり'],
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

  // shiji (こそあど ことば): [truoc, tu chi thi (gach chan), sau, [3 lua chon], chi so dap an]
  static const List<List<dynamic>> _shijiPool = [
    ['ゆうたさんは あたらしい じてんしゃを かった。', 'それ', 'で まいにち がっこうに かよっている。', ['ゆうたさん', 'じてんしゃ', 'がっこう'], 1],
    ['わたしは ほんやで おもしろい まんがを みつけた。', 'それ', 'を かって いえに かえった。', ['ほんや', 'まんが', 'いえ'], 1],
    ['えきの まえに おおきな ケーキやが ある。', 'そこ', 'で いもうとの たんじょうびの ケーキを かった。', ['えき', 'ケーキや', 'たんじょうび'], 1],
    ['せんせいが きょうしつに ちいさな はちうえを もって きた。', 'これ', 'は ひまわりの なえだと いう。', ['せんせい', 'きょうしつ', 'はちうえ'], 2],
    ['おじいさんが かわで おおきな さかなを つった。', 'それ', 'を ばんごはんに たべた。', ['おじいさん', 'かわ', 'さかな'], 2],
    ['ひろしくんは としょかんで れきしの ほんを かりた。', 'そこ', 'は しずかで よく べんきょうが できる。', ['ひろしくん', 'としょかん', 'ほん'], 1],
    ['ねえさんが わたしに あかい マフラーを あんで くれた。', 'これ', 'を つけると とても あたたかい。', ['ねえさん', 'わたし', 'マフラー'], 2],
    ['ともだちが ぼくに あたらしい ゲームを みせてくれた。', 'それ', 'は ぼくも ずっと ほしかった ものだ。', ['ともだち', 'ぼく', 'ゲーム'], 2],
    ['あかちゃんが ベッドの うえで ぬいぐるみを だいていた。', 'それ', 'は おかあさんが かった ものだ。', ['あかちゃん', 'ベッド', 'ぬいぐるみ'], 2],
  ];

  static KokugoItem _shijiItem(String label, String pre, String pron, String post, List<String> opts, int ans) =>
      KokugoItem(
        label: label,
        parts: [
          if (pre.isNotEmpty) _t(pre),
          KokugoPart(pron, underline: true),
          if (post.isNotEmpty) _t(post),
          KokugoPart('', blank: true, reads: [opts[ans]]),
        ],
        extra: {'opts': opts},
      );

  // erabu (あう ことばを えらぼう): [truoc, sau, [3 lua chon], chi so dap an]. Cho trong la （　　）
  static const List<List<dynamic>> _erabuBook = [
    ['おゆは 水より', '。', ['すずしい', 'つめたい', 'あつい'], 2],
    ['足が つかないほど この プールは', '。', ['とおい', 'ふかい', 'ひろい'], 1],
    ['そとは、雨が', '。', ['はげしい', '大きい', 'ふとい'], 0],
    ['スポーツせん手の からだは', '。', ['きびしい', 'きつい', 'たくましい'], 2],
    ['この ざるの 目は', '。', ['あらい', 'ほそい', 'みじかい'], 0],
    ['この ヒントで すぐに こたえが わかる 人は', '。', ['にぶい', 'するどい', 'ゆるい'], 1],
    ['しおが 足りないのか、あじが', '。', ['くらい', 'あつい', 'うすい'], 2],
  ];
  // cau do ta soan them (dung cho bai tu sinh)
  static const List<List<dynamic>> _erabuExtra = [
    ['ふゆの よるは こおるほど', '。', ['さむい', 'すずしい', 'あつい'], 0],
    ['この カレーは とうがらしが たくさん はいっていて', '。', ['からい', 'すっぱい', 'あまい'], 0],
    ['この ナイフは よく きれて、さきが', '。', ['するどい', 'にぶい', 'あつい'], 0],
    ['この ふくろは ものが たくさん はいって', '。', ['おもい', 'ひくい', 'せまい'], 0],
    ['まっくらで なにも 見えない ほど へやの なかは', '。', ['くらい', 'あかるい', 'まぶしい'], 0],
    ['はやく ねないと、あしたの あさ とても', '。', ['ねむい', 'からい', 'たかい'], 0],
    ['この うみは そこが 見えないほど', '。', ['ふかい', 'あさい', 'かるい'], 0],
    ['この ひもは ゆびほど', 'ので、つよそうだ。', ['ふとい', 'ほそい', 'みじかい'], 0],
    ['この スープは みずを いれすぎて あじが', '。', ['うすい', 'こい', 'おもい'], 0],
    ['この みちは はばが せまくて', '。', ['ほそい', 'ひろい', 'ふかい'], 0],
  ];
  static KokugoItem _erabuItem(String label, List<dynamic> e, {List<String>? opts}) {
    final o = (e[2] as List).cast<String>();
    final ans = o[e[3] as int];
    final sh = opts ?? o;
    return _shijiItem(label, e[0] as String, '（　　）', e[1] as String, sh, sh.indexOf(ans));
  }

  // tsunagi (つなぎことば): [文1, 文2, dap an]. Tu trong khung dung lai duoc nhieu lan (extra.reuse)
  static const List<String> _tsunagiWords = ['でも', 'だから', 'そのうえ'];
  static const List<List<String>> _tsunagiBook = [
    ['いえで たくさん ふくしゅうした。', 'さんすうの もんだいが とけなかった。', 'でも'],
    ['にわに パンくずを まいた。', 'とりが あつまってきた。', 'だから'],
    ['みちに まよってしまった。', 'ちずまで なくしてしまった。', 'そのうえ'],
    ['あには、さく文が とても 上手だ。', '字が きたないと しかられる。', 'でも'],
    ['きょう、ともだちに プレゼントを もらった。', 'おかあさんから おこづかいも もらった。', 'そのうえ'],
  ];
  static const List<List<String>> _tsunagiExtra = [
    ['あめが ふってきた。', 'かさを さした。', 'だから'],
    ['けさは ねぼうした。', 'がっこうに ちこくした。', 'だから'],
    ['まいにち れんしゅうした。', 'しあいで かつことが できた。', 'だから'],
    ['ぼくは はやく おきた。', 'でんしゃに のりおくれた。', 'でも'],
    ['この カレーは とても からい。', 'おいしくて おかわりを した。', 'でも'],
    ['きょうは かぜを ひいている。', 'がっこうに いきたい。', 'でも'],
    ['この みせの パンは おいしい。', 'ねだんも やすい。', 'そのうえ'],
    ['いもうとは うたが じょうずだ。', 'ピアノも ひける。', 'そのうえ'],
    ['きょうは かぜが つよい。', 'あめも ふってきた。', 'そのうえ'],
  ];
  // doyomi (おなじ よみの かん字): [よみ, [かん字...]]。 1つの よみに 2つの □。 どちらの じゅんでも OK (extra.any)
  static const List<List<dynamic>> _doyomiBook = [
    ['けん', ['犬', '見']],
    ['か', ['火', '花']],
    ['もく', ['木', '目']],
    ['きゅう', ['九', '休']],
  ];
  static const List<String> _doyomiBookBank = ['九', '木', '犬', '火', '四', '八', '目', '見', '休', '花', '水'];
  static const List<List<dynamic>> _doyomiPool = [
    ['けん', ['犬', '見']],
    ['か', ['火', '花']],
    ['もく', ['木', '目']],
    ['きゅう', ['九', '休']],
    ['さん', ['三', '山']],
    ['し', ['四', '子', '糸']],
    ['じ', ['字', '耳']],
    ['せい', ['生', '青', '正']],
    ['ちゅう', ['中', '虫']],
    ['そう', ['早', '草']],
  ];
  static List<KokugoItem> _doyomiItems(int no, String reading, List<String> kanji) => [
        for (var j = 0; j < kanji.length; j++)
          KokugoItem(
            label: '${_circ[no]}${_kana3[j]}',
            parts: [_t(reading), KokugoPart('', blank: true, reads: [kanji[j]])],
            extra: {'any': kanji},
          ),
      ];

  // hantaigo (はんたいの いみの ことば): [まえの ことば, ──せんの ことば, こたえ, (べつの こたえ)...]
  static const List<List<String>> _hantaigoBook = [
    ['やくそくを', 'まもる', 'やぶる'],
    ['ひもを', 'むすぶ', 'ほどく', 'とく'],
    ['いきを', 'すう', 'はく'],
    ['日が', 'のぼる', 'しずむ', 'おちる'],
    ['シールを', 'はる', 'はがす'],
    ['本を', 'ひらく', 'とじる'],
    ['はしごを', 'のぼる', 'おりる'],
    ['本を', 'かりる', 'かす'],
  ];
  static const List<List<String>> _hantaigoExtra = [
    ['まどを', 'あける', 'しめる', 'とじる'],
    ['でんきを', 'つける', 'けす'],
    ['ふくを', 'きる', 'ぬぐ'],
    ['ドアが', 'しまる', 'あく', 'ひらく'],
    ['ものを', 'うる', 'かう'],
    ['手を', 'あげる', 'おろす', 'さげる'],
    ['ふねに', 'のる', 'おりる'],
    ['みずが', 'ふえる', 'へる'],
    ['ベッドから', 'おきる', 'ねる'],
  ];
  static KokugoItem _hantaigoItem(int no, List<String> e) => KokugoItem(
        label: _circ[no],
        parts: [_t(e[0]), _y(e[1], e.sublist(2))],
      );

  // かん字と おくりがな (ワクの ことばを かん字に): [ぶんの まえ, かん字+おくりがな, ぶんの あと]
  static const List<String> _okuriBank = ['いれる', 'たつ', 'みる', 'たりる', 'はいる', 'やすむ'];
  static const List<List<String>> _okuriBook = [
    ['きれいな 夕《ゆう》やけ空《ぞら》を', '見る', '。'],
    ['びょう気《き》で 学校《がっこう》を', '休む', '。'],
    ['こうえんの まえに かんばんが', '立つ', '。'],
    ['こうちゃに さとうを', '入れる', '。'],
    ['たからものが 手《て》に', '入る', '。'],
    ['こん月の おこづかいは なんとか', '足りる', '。'],
  ];
  static KokugoItem _okuriItem(int no, List<String> e) => KokugoItem(
        label: _circ[no],
        parts: [_t(e[0]), _b(e[1], ''), if (e[2].isNotEmpty) _t(e[2])],
      );

  static KokugoItem _tsunagiItem(int no, List<String> e) => KokugoItem(
        label: '（${no + 1}）',
        parts: [
          _t(e[0]),
          KokugoPart('', blank: true, reads: [e[2]]),
          _t('、${e[1]}'),
        ],
        extra: const {'reuse': true},
      );

  // bunsaku: cac cau trong sach (5 va 6, moi trang 4 cau)
  static const List<List<dynamic>> _bunBook = [
    ['うれしい', 'はなす', ['うれしい できごとを おかあさんに はなしました。', 'ぼくは うれしくて、ともだちに はなしました。']],
    ['こうふん', 'できる', ['しあいの まえは こうふんして、うまく できませんでした。', 'こうふんしても、おちついて できるように なりたい。']],
    ['まんぞく', 'よろこばせる', ['おとうとを よろこばせる ことが できて、まんぞくしました。', 'みんなを よろこばせて、まんぞくした。']],
    ['たのしみ', 'もうすぐ', ['もうすぐ えんそくで、とても たのしみです。', 'たのしみに していた たんじょうびが もうすぐ きます。']],
    // 本の 6
    ['はずかしい', 'ほめる', ['みんなの まえで ほめられて、はずかしかった。', 'ほめられて はずかしかったけれど、うれしかった。']],
    ['もうしわけない', 'かんちがい', ['かんちがいして さきに かえって しまい、もうしわけない ことを しました。', 'かんちがいで めいわくを かけて、もうしわけなく おもいました。']],
    ['うしろめたい', 'たからもの', ['ともだちの たからものを こわして、うしろめたい きもちだった。', 'たからものを かくして しまい、うしろめたく なった。']],
    ['ふまん', 'うわさ', ['うわさを きいて、ふまんに おもった。', 'ふまんが あっても、うわさを しんじては いけません。']],
    // 本の 7
    ['おそろしい', 'きもだめし', ['きもだめしは おそろしくて、なきそうに なった。', 'おそろしい はなしを きいた あとの きもだめしは ドキドキした。']],
    ['こころぼそい', 'はじめて', ['はじめて ひとりで ねたので、こころぼそかった。', 'はじめての ばしょは、こころぼそい きもちに なる。']],
    ['なつかしい', 'しゃしん', ['むかしの しゃしんを みて、なつかしく なった。', 'なつかしい ともだちの しゃしんが でてきた。']],
    ['はげましたい', 'おとうと', ['しあいに まけた おとうとを はげましたい。', 'おとうとが しょげて いたので、はげましたい と おもった。']],
    // 本の 8
    ['こんらん', 'せつめい', ['せつめいが むずかしくて、あたまが こんらんした。', 'こんらんして いる ともだちに、ゆっくり せつめいした。']],
    ['まよう', 'かう', ['どの くつを かうか まよった。', 'ふたつの ほんで まよったけれど、あおい ほうを かいました。']],
    ['うしろめたい', 'うそ', ['うそを ついて しまい、うしろめたい きもちに なった。', 'うそを ついた あとは、ずっと うしろめたかった。']],
    ['ふしぎ', 'かいがい', ['かいがいの おみやげは、ふしぎな かたちを して いた。', 'かいがいで ふしぎな できごとに であった。']],
    // 本の 9
    ['おどろく', 'はこ', ['はこを あけたら、なかから おもちゃが とび出して おどろきました。', 'おどろいて、はこを おとして しまった。']],
    ['ざんねん', 'あっというま', ['たのしい えんそくは あっというまに おわって、ざんねんでした。', 'ざんねんな ことに、なつやすみは あっというまだった。']],
    ['かわいそう', 'かぜ', ['かぜを ひいた ともだちが かわいそうで、おみまいに いった。', 'かぜで ねて いる いもうとが かわいそうに なった。']],
    ['かんしんする', '手つだい', ['おとうとが ていねいに 手つだいを して くれて、かんしんしました。', 'まいにち 手つだいを する ともだちに かんしんする。']],
    // 本の 5 (ページ5)
    ['いとおしい', 'あかちゃん', ['あかちゃんの ねがおが いとおしくて、ずっと 見ていた。', 'いとおしい あかちゃんを そっと だっこした。']],
    ['じまんする', 'あてる', ['クイズの こたえを あてて、みんなに じまんした。', 'ぼくが あてたと じまんする ともだちが いる。']],
    ['はずかしい', 'しっぱい', ['はっぴょうで しっぱいして、はずかしかった。', 'しっぱいした ことが はずかしくて、かおが あかく なった。']],
    ['あんしん', 'みつかる', ['なくした さいふが みつかって、あんしんした。', 'いなく なった いぬが みつかったと きいて、あんしんした。']],
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
    'はこ': ['はこ'],
    'ざんねん': ['ざんねん'],
    'あっというま': ['あっというま'],
    'かわいそう': ['かわいそう'],
    'かぜ': ['かぜ', '風'],
    'かんしんする': ['かんしんする', 'かんしんし', 'かんしんした', 'かんしんして', 'かんしんさ'],
    '手つだい': ['手つだい', '手つだ', 'てつだ'],
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
    'ほめる': ['ほめる', 'ほめ', 'ほめて', 'ほめた', 'ほめら'],
    'もうしわけない': ['もうしわけない', 'もうしわけなく', 'もうしわけなかった', 'もうしわけ'],
    'かんちがい': ['かんちがい'],
    'うしろめたい': ['うしろめたい', 'うしろめたく', 'うしろめたかった'],
    'たからもの': ['たからもの'],
    'ふまん': ['ふまん'],
    'うわさ': ['うわさ'],
    'おそろしい': ['おそろしい', 'おそろしく', 'おそろしかった', 'おそろしさ'],
    'きもだめし': ['きもだめし'],
    'こころぼそい': ['こころぼそい', 'こころぼそく', 'こころぼそかった'],
    'はじめて': ['はじめて', 'はじめ'],
    'なつかしい': ['なつかしい', 'なつかしく', 'なつかしかった', 'なつかしさ'],
    'しゃしん': ['しゃしん'],
    'はげましたい': ['はげましたい', 'はげます', 'はげまし', 'はげまして', 'はげました', 'はげまそ'],
    'おとうと': ['おとうと'],
    'こんらん': ['こんらん'],
    'せつめい': ['せつめい'],
    'かう': ['かう', 'かい', 'かっ', 'かわ', 'かお'],
    'うそ': ['うそ'],
    'ふしぎ': ['ふしぎ'],
    'かいがい': ['かいがい'],
    'いとおしい': ['いとおしい', 'いとおしく', 'いとおしかった', 'いとおしさ'],
    'あかちゃん': ['あかちゃん', '赤ちゃん'],
    'じまんする': ['じまんする', 'じまんし', 'じまんして', 'じまんした', 'じまんさ', 'じまん'],
    'あてる': ['あてる', 'あて', 'あてた', 'あてて', 'あてら'],
    'しっぱい': ['しっぱい'],
    'みつかる': ['みつかる', 'みつかり', 'みつかって', 'みつかった', 'みつから'],
  };

  // bunsaku: nghia cua tu, giai thich de hieu cho tre (ja / en / vi)
  static const Map<String, Map<String, String>> _bunMeaning = {
    'はこ': {'ja': 'ものを いれる しかくい いれもの。', 'en': 'A box; a container for putting things in.', 'vi': 'Cái hộp, vật dùng để đựng đồ.'},
    'ざんねん': {'ja': 'おもった とおりに ならなくて、がっかり する きもち。', 'en': 'The disappointed feeling when things do not go as you hoped.', 'vi': 'Cảm giác tiếc nuối, thất vọng vì việc không như mong muốn.'},
    'あっというま': {'ja': 'とても みじかい じかんの こと。きが つく まえに おわって しまう ようす。', 'en': 'A very short time; over before you notice.', 'vi': 'Khoảng thời gian rất ngắn, chớp mắt đã hết.'},
    'かわいそう': {'ja': 'こまって いる 人や どうぶつを 見て、むねが いたく なる きもち。', 'en': 'The sad feeling you get when you see someone in trouble.', 'vi': 'Thương xót khi thấy ai đó hoặc con vật gặp khó khăn.'},
    'かぜ': {'ja': 'ねつや せきが でる びょうき。ほかに、そらを ふく「風」の ことも かぜと いうよ。', 'en': 'A cold (an illness with fever or cough). かぜ can also mean the wind.', 'vi': 'Bệnh cảm (sốt, ho). かぜ cũng có thể là "gió".'},
    'かんしんする': {'ja': 'すごいなあと おもって、ほめたく なる こと。', 'en': 'To be impressed; to think "wow, that is great".', 'vi': 'Cảm phục, thấy giỏi quá nên muốn khen.'},
    '手つだい': {'ja': '人の しごとを いっしょに して あげる こと。', 'en': 'Helping someone with their work.', 'vi': 'Giúp đỡ người khác làm việc.'},
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
    'ほめる': {'ja': 'いい ことを した ひとに「すごいね」と いう こと。', 'en': 'To tell someone "great job!" for something good.', 'vi': 'Khen, nói "giỏi quá!" với người đã làm việc tốt.'},
    'もうしわけない': {'ja': 'わるい ことを して、「ごめんなさい」と ふかく おもう きもち。', 'en': 'Feeling very sorry, wanting to say "I am so sorry".', 'vi': 'Cảm thấy rất có lỗi, muốn nói "xin lỗi" thật lòng.'},
    'かんちがい': {'ja': 'ほんとうは ちがうのに、そうだと おもいこむ こと。', 'en': 'Thinking something is true when it is actually not.', 'vi': 'Hiểu lầm, tưởng là thế này nhưng thật ra không phải.'},
    'うしろめたい': {'ja': 'わるい ことを した ようで、むねが ちくちく して ひとの かおが みられない きもち。', 'en': 'Feeling guilty inside, so you cannot look people in the eye.', 'vi': 'Thấy áy náy trong lòng, không dám nhìn thẳng vào người khác vì thấy mình có lỗi.'},
    'たからもの': {'ja': 'とても だいじに している もの。', 'en': 'Something you treasure very much.', 'vi': 'Món đồ mà mình rất quý, rất trân trọng.'},
    'ふまん': {'ja': 'おもった ように ならなくて、「いやだな」と おもう きもち。', 'en': 'Feeling unhappy because things did not go the way you wanted.', 'vi': 'Bất mãn, không vừa ý vì mọi việc không như mình mong.'},
    'うわさ': {'ja': 'ほんとうか どうか わからないのに、ひとから ひとへ つたわる はなし。', 'en': 'A story passed from person to person, even if no one knows if it is true.', 'vi': 'Tin đồn, chuyện truyền từ người này sang người khác dù chưa biết thật hay không.'},
    'おそろしい': {'ja': 'とても こわい。ぞっと する くらい こわい こと。', 'en': 'Very scary; so scary it makes you shiver.', 'vi': 'Rất đáng sợ, sợ đến mức rùng mình.'},
    'きもだめし': {'ja': 'くらい ところを あるいて、こわさに まけないか ためす あそび。', 'en': 'A game of walking through dark places to test your courage.', 'vi': 'Trò thử gan: đi qua nơi tối để xem mình có dám không.'},
    'こころぼそい': {'ja': 'ひとりぼっちで、たよる ひとが いなくて、ふあんな きもち。', 'en': 'Feeling uneasy and alone, with no one to rely on.', 'vi': 'Cảm thấy bất an, cô đơn vì không có ai để nương tựa.'},
    'はじめて': {'ja': 'いちばん さいしょ。いままで いちども したことが ない こと。', 'en': 'The very first time; never done it before.', 'vi': 'Lần đầu tiên, trước giờ chưa từng làm.'},
    'なつかしい': {'ja': 'むかしの ことを おもいだして、また あいたい、もどりたいと おもう きもち。', 'en': 'The warm feeling of remembering the past and wanting to go back.', 'vi': 'Cảm giác hoài niệm, nhớ chuyện ngày xưa và muốn quay lại.'},
    'しゃしん': {'ja': 'カメラで うつした けしきや ひとの すがた。', 'en': 'A picture of a person or place taken with a camera.', 'vi': 'Ảnh chụp bằng máy ảnh.'},
    'はげましたい': {'ja': 'げんきの ない ひとに「がんばれ」と こえを かけて、げんきづけたい きもち。（もとの ことば: はげます）', 'en': 'Wanting to cheer someone up by saying "You can do it!" (base word: はげます)', 'vi': 'Muốn động viên, nói "cố lên" để người khác có thêm tinh thần. (Từ gốc: はげます)'},
    'おとうと': {'ja': 'じぶんより としが した の おとこの きょうだい。', 'en': 'Your younger brother.', 'vi': 'Em trai.'},
    'こんらん': {'ja': 'いろいろな ことが ごちゃごちゃに なって、なにが なんだか わからなく なる こと。', 'en': 'Being so mixed up that you cannot tell what is what.', 'vi': 'Rối loạn, mọi thứ lẫn lộn đến mức không hiểu gì nữa.'},
    'せつめい': {'ja': 'ほかの ひとが わかるように、わけや ようすを はなして おしえる こと。', 'en': 'Explaining something so that others can understand.', 'vi': 'Giải thích để người khác hiểu.'},
    'かう': {'ja': 'おかねを はらって、ものを じぶんの ものに する こと。', 'en': 'To pay money and get something.', 'vi': 'Mua, trả tiền để có món đồ.'},
    'うそ': {'ja': 'ほんとうでは ない ことを、ほんとうのように いう こと。', 'en': 'Saying something that is not true as if it were true.', 'vi': 'Nói dối, nói điều không thật như thể thật.'},
    'ふしぎ': {'ja': 'どうして そう なるのか わからなくて、ふしぎに おもう こと。', 'en': 'Strange and puzzling; you cannot tell why it happens.', 'vi': 'Kỳ lạ, khó hiểu, không biết vì sao lại như vậy.'},
    'かいがい': {'ja': 'にほんの そとの くに。', 'en': 'Foreign countries, outside Japan.', 'vi': 'Nước ngoài, những nước ở ngoài Nhật Bản.'},
    'いとおしい': {'ja': 'かわいくて たいせつで、だきしめたく なる ような きもち。', 'en': 'Feeling so dear and lovable that you want to cherish and hold it.', 'vi': 'Thương yêu, quý mến đến mức muốn ôm ấp, che chở.'},
    'あかちゃん': {'ja': 'うまれて まもない ちいさな こども。', 'en': 'A baby; a very young child.', 'vi': 'Em bé mới sinh.'},
    'じまんする': {'ja': 'じぶんの いい ところや とくいな ことを、ほかの ひとに えらそうに 見せたり いったり する こと。', 'en': 'To show off or boast about something you are proud of.', 'vi': 'Khoe khoang điều mình giỏi hoặc điều mình tự hào với người khác.'},
    'あてる': {'ja': 'もんだいの こたえを ぴたりと いう こと。ほかに、ねらった ところに ぶつける ことも あてると いうよ。', 'en': 'To guess the right answer. (It can also mean to hit a target.)', 'vi': 'Đoán trúng đáp án. (Cũng có nghĩa là ném/đánh trúng mục tiêu.)'},
    'しっぱい': {'ja': 'うまく いかなかった こと。まちがえて しまう こと。', 'en': 'A failure; when things did not go well or you made a mistake.', 'vi': 'Thất bại, làm không thành hoặc mắc lỗi.'},
    'みつかる': {'ja': 'さがして いた ものが 見つけられる こと。かくれていた ものが 見られて しまう ことも いうよ。', 'en': 'To be found; something you were looking for turns up.', 'vi': 'Được tìm thấy; thứ đang tìm đã xuất hiện.'},
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
        // --- ページ3: かたかなを かん字に なおして (おくりがなも かく) ---
        // おくりがなの ひらがなも 1もじずつ 1ますに かく (よみは カタカナ)
        KokugoItem(label: _circ[0], parts: [
          _b('音', 'オン'), _t('がくの'), _b('先生', 'セン|セイ'), _t('は'),
          _b('大きい', 'オオ|キ|イ'), _t('こえを'), _b('出せる', 'ダ|セ|ル'), _t('。'),
        ]),
        KokugoItem(label: _circ[1], parts: [
          _b('男子', 'ダン|シ'), _t('と'), _b('女子', 'ジョ|シ'), _t('、あわせて'), _b('百人', 'ヒャク|ニン'), _t('いる。'),
        ]),
        KokugoItem(label: _circ[2], parts: [
          _t('わたしの ほうが'), _b('早く', 'ハヤ|ク'), _b('本', 'ホン'), _t('を よみおえた。'),
        ]),
        KokugoItem(label: _circ[3], parts: [
          _t('この さかを'), _b('下って', 'クダ|ッ|テ'), _b('右', 'ミギ'), _t('に まがると、'),
          _b('中学校', 'チュウ|ガッ|コウ'), _t('が'), _b('見える', 'ミ|エ|ル'), _t('。'),
        ]),
        KokugoItem(label: _circ[4], parts: [
          _t('しょうらい、この'), _b('子', 'コ'), _t('は'), _b('大', 'オオ'), _t('ものに なると、'),
          _b('小さい', 'チイ|サ|イ'), _t('ころから いわれていた。'),
        ]),
        KokugoItem(label: _circ[5], parts: [
          _b('下校', 'ゲ|コウ'), _t('すると、'), _b('中', 'チュウ'), _t('で、'), _b('年上', 'トシ|ウエ'), _t('の ともだちに あった。'),
        ]),
        KokugoItem(label: _circ[6], parts: [
          _b('右', 'ミギ'), _t('ききなので、'), _b('左手', 'ヒダリ|テ'), _t('で'), _b('名', 'ナ'), _t('まえを かくのは むずかしい。'),
        ]),
        KokugoItem(label: _circ[7], parts: [
          _t('しょうぎの'), _b('名人', 'メイ|ジン'), _t('が、'), _b('本音', 'ホン|ネ'), _t('を かいた'), _b('文', 'ブン'), _t('しょう。'),
        ]),
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
      // --- ページ4・5: かん字の もんだい (1)かたかなを かん字に (2)おくりがな ---
      KokugoItem ki(int no, List<KokugoPart> parts) => KokugoItem(label: _circ[no], parts: parts);
      final kakiP1 = <KokugoItem>[
        ki(0, [_t('えいごを'), _b('学ぶ', 'マナ|ブ'), _t('。')]),
        ki(1, [_b('本', 'ホン'), _t('気を'), _b('出', 'ダ'), _t('す。')]),
        ki(2, [_t('てん'), _b('校生', 'コウ|セイ')]),
        ki(3, [_b('文', 'ブン'), _t('化の日')]),
        ki(4, [_t('しょうぎの'), _b('名人', 'メイ|ジン'), _t('。')]),
        ki(5, [_t('空を'), _b('見上げる', 'ミ|ア|ゲ|ル'), _t('。')]),
        ki(6, [_t('円の'), _b('中', 'チュウ'), _t('しん。')]),
        ki(7, [_b('上下', 'ジョウ|ゲ'), _t('に うごかす。')]),
        ki(8, [_b('年', 'トシ'), _t('こしそば')]),
      ];
      final kakiP2 = <KokugoItem>[
        ki(0, [_b('名', 'メイ'), _t('さくを よむ。')]),
        ki(1, [_b('生', 'ナマ'), _t('たまご')]),
        ki(2, [_b('小学生', 'ショウ|ガク|セイ')]),
        ki(3, [_b('校', 'コウ'), _t('ていで あそぶ。')]),
        ki(4, [_b('音', 'オン'), _t('どくを する。')]),
        ki(5, [_b('上', 'ウワ'), _t('ぎを きる。')]),
        ki(6, [_b('年下', 'トシ|シタ'), _t('の ゆう人。')]),
        ki(7, [_b('右手', 'ミギ|テ'), _t('を あげる。')]),
        ki(8, [_b('文字', 'モ|ジ'), _t('を かく。')]),
      ];
      // おくりがな: かん字は もんだいに 印刷されている。ひらがなの おくりがなだけを かく
      KokugoItem oku(String label, String before, String okuri, String reads) =>
          KokugoItem(label: label, parts: [_t(before), _b(okuri, reads), _t('。')]);
      final kakiExtra = <List<KokugoItem>>[
        for (var g = 0; g < 3; g++) kakiP1.sublist(g * 3, g * 3 + 3),
        for (var g = 0; g < 3; g++) kakiP2.sublist(g * 3, g * 3 + 3),
        [
          oku('①ア', '子犬が 生', 'まれる', 'ウマレル||'),
          oku('①イ', '花を 生', 'ける', 'イケル|'),
        ],
        [
          oku('①ウ', '百さいまで 生', 'きる', 'イキル|'),
          oku('①エ', '草が 生', 'える', 'ハエル|'),
        ],
        [
          oku('②ア', 'さかを 上', 'る', 'ノボル'),
          oku('②イ', 'かいだんを 上', 'がる', 'アガル|'),
          oku('②ウ', 'スピードを 上', 'げる', 'アゲル|'),
        ],
      ];
      // かん字の よみ ページ4: おなじ かん字の ちがう よみ (音・生・先)
      final yomiExtra = <KokugoItem>[
        KokugoItem(label: '①ア', parts: [_t('足'), _y('音', ['おと'])]),
        KokugoItem(label: '①イ', parts: [_y('音', ['おん']), _t('がく')]),
        KokugoItem(label: '①ウ', parts: [_y('音', ['ね']), _t('いろ')]),
        KokugoItem(label: '②ア', parts: [_t('一年'), _y('生', ['せい'])]),
        KokugoItem(label: '②イ', parts: [_t('一'), _y('生', ['しょう'])]),
        KokugoItem(label: '②ウ', parts: [_y('生', ['う']), _t('まれる')]),
        KokugoItem(label: '③ア', parts: [_y('先', ['せん']), _t('生')]),
        KokugoItem(label: '③イ', parts: [_t('ゆび'), _y('先', ['さき'])]),
        KokugoItem(label: '③ウ', parts: [_y('先', ['せん']), _t('日')]),
      ];
      // --- かん字の もんだい (トップ/ボトム 2ページ) ---
      // ページ1 (1): かたかなを かん字に
      final kakiMore = <List<KokugoItem>>[
        [
          ki(0, [_b('入学', 'ニュウ|ガク'), _t('しき')]),
          ki(1, [_b('足音', 'アシ|オト'), _t('が する。')]),
          ki(2, [_t('ふじ山の'), _b('火口', 'カ|コウ'), _t('。')]),
        ],
        [
          ki(3, [_t('水が ふ'), _b('足', 'ソク'), _t('する。')]),
          ki(4, [_t('本の'), _b('目', 'モク'), _t('じ。')]),
          ki(5, [_t('かすみ'), _b('草', 'ソウ'), _t('が さく。')]),
        ],
        [
          ki(6, [_b('立', 'リッ'), _t('体こうさてん')]),
          ki(7, [_b('休日', 'キュウ|ジツ')]),
          ki(8, [_b('学校', 'ガッ|コウ'), _t('を'), _b('早', 'ソウ'), _t('たいする。')]),
        ],
        // ページ2 (1): かたかなを かん字に
        [
          ki(0, [_t('やきゅうせん'), _b('手', 'シュ')]),
          ki(1, [_b('文', 'ブン'), _t('しょうだい')]),
          ki(2, [_b('日本', 'ニ|ホン'), _t('の'), _b('人口', 'ジン|コウ'), _t('。')]),
        ],
        [
          ki(3, [_b('一本', 'イッ|ポン'), _t('の'), _b('虫', 'ムシ'), _t('ば。')]),
          ki(4, [_b('名', 'ナ'), _t('まえを かく。')]),
          ki(5, [_b('見本', 'ミ|ホン'), _t('を'), _b('見', 'ミ'), _t('る。')]),
        ],
        [
          ki(6, [_b('音', 'オン'), _t('がくを きく。')]),
          ki(7, [_b('文', 'モン'), _t('くを いう。')]),
          ki(8, [_b('竹', 'チク'), _t('林に'), _b('入', 'ハイ'), _t('る。')]),
        ],
        // ページ3 (1): かたかなを かん字に (慣用句・熟語)
        [
          ki(0, [_t('もんだいが むずかしすぎて、'), _b('手', 'テ'), _t('も'), _b('足', 'アシ'), _t('も'), _b('出', 'デ'), _t('ない。')]),
          ki(1, [_t('かい'), _b('犬', 'イヌ'), _t('に'), _b('手', 'テ'), _t('を かまれるとは、まさに このことだ。')]),
          ki(2, [_b('花火', 'ハナ|ビ'), _t('の'), _b('見', 'ケン'), _t('ぶつ'), _b('人', 'ニン'), _t('が ぞくぞくと あつまる。')]),
        ],
        [
          ki(3, [_t('かぜで 学校を'), _b('早', 'ソウ'), _t('たいしたが、あすは'), _b('休', 'ヤス'), _t('みたくない。')]),
          ki(4, [_t('こん'), _b('月', 'ゲツ'), _t('の'), _b('入金', 'ニュウ|キン'), _t('は'), _b('百', 'ヒャク'), _t('まん円だ。')]),
          ki(5, [_t('この天じょうは、うつくしい'), _b('木目', 'モク|メ'), _t('が とくちょうだ。')]),
        ],
        [
          ki(6, [_b('草', 'クサ'), _t('むらで、こん'), _b('虫', 'チュウ'), _t('を'), _b('四', 'ヨン'), _t('ひき つかまえた。')]),
          ki(7, [_b('王', 'オウ'), _t('さまは、バルコニーに'), _b('立', 'タ'), _t('ち、とおくを'), _b('見', 'ミ'), _t('た。')]),
        ],
        // ページ1 (1): かたかなを かん字に (③は かん字と おくりがな)
        [
          ki(0, [_t('こん'), _b('虫', 'チュウ'), _t('さいしゅう')]),
          ki(1, [_b('耳', 'ミミ'), _t('を かたむける。')]),
          ki(2, [_t('中に'), _b('入る', 'ハイル|'), _t('。')]),
        ],
        [
          ki(3, [_b('王子', 'オウ|ジ'), _t('と'), _b('王', 'オウ'), _t('女。')]),
          ki(4, [_b('花見', 'ハナ|ミ'), _t('に いく。')]),
          ki(5, [_t('せん'), _b('手入', 'シュ|ニュウ'), _t('じょう')]),
        ],
        [
          ki(6, [_b('出口', 'デ|グチ'), _t('を さがす。')]),
          ki(7, [_b('犬', 'イヌ'), _t('を かう。')]),
          ki(8, [_t('からだを'), _b('休', 'ヤス'), _t('める。')]),
        ],
      ];
      // ページ1 (2): ──せんの かん字の よみ (本・名・文)
      final yomiMore = <KokugoItem>[
        KokugoItem(label: '①ア', parts: [_t('見'), _y('本', ['ほん'])]),
        KokugoItem(label: '①イ', parts: [_y('本', ['ほん']), _t('を よむ。')]),
        KokugoItem(label: '①ウ', parts: [_t('三'), _y('本', ['ぼん']), _t('の えんぴつ。')]),
        KokugoItem(label: '②ア', parts: [_y('名', ['な']), _t('ふだ')]),
        KokugoItem(label: '②イ', parts: [_t('ゆう'), _y('名', ['めい']), _t('な きょく。')]),
        KokugoItem(label: '②ウ', parts: [_t('本'), _y('名', ['みょう']), _t('を きく。')]),
        KokugoItem(label: '③ア', parts: [_t('さく'), _y('文', ['ぶん'])]),
        KokugoItem(label: '③イ', parts: [_t('天'), _y('文', ['もん']), _t('学')]),
        KokugoItem(label: '③ウ', parts: [_y('文', ['も', 'もん']), _t('字を かく。')]),
      ];
      // ページ2 (2): 正しい かきじゅんを えらぶ (出・入・耳・子)。ア/イの じゅんは 本の とおり
      final kakijunItems = <KokugoItem>[
        _kakijunItem('①', '出', [_stagesOf(const [1, 2, 0, 3, 4]), _stagesOf(const [0, 1, 2, 3, 4])], 1),
        _kakijunItem('②', '入', [_stagesOf(const [0, 1]), _stagesOf(const [1, 0])], 0),
        _kakijunItem('③', '耳', [_stagesOf(const [0, 1, 2, 3, 4, 5]), _stagesOf(const [0, 1, 5, 2, 3, 4])], 0),
        _kakijunItem('④', '子', [_stagesOf(const [0, 1, 2]), const [[0, 1], [0, 1, 2]]], 0),
      ];
      // moi bai mau chi 3 cau
      all = <KokugoLesson>[
        for (var n = 0; n < (kakiItems.length + 2) ~/ 3; n++)
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
            items: kakiItems.sublist(n * 3, min(n * 3 + 3, kakiItems.length)),
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
        // かん字を かこう ページ4・5 (おくりがなを ふくむ): 上の kakiExtra
        for (var n = 0; n < kakiExtra.length; n++)
          KokugoLesson(
            id: 'KK${(n + 10).toString().padLeft(3, '0')}',
            title: {
              'ja': 'かん字を かこう ${n + 10}',
              'en': 'Write the Kanji ${n + 10}',
              'vi': 'Viết chữ Hán ${n + 10}',
            },
            question: n < 6
                ? questionFor('kaki')
                : {
                    'ja': 'つぎの かん字を つかい、正しい おくりがなを ひらがなで かきましょう。',
                    'en': 'Using the kanji shown, write the correct okurigana (hiragana ending).',
                    'vi': 'Dùng chữ Hán cho sẵn, viết okurigana (phần hiragana đi kèm) cho đúng.',
                  },
            kind: 'kaki',
            difficulty: 2,
            items: kakiExtra[n],
          ),
        // かん字を かこう (かたかなを かん字に): 上の kakiMore
        for (var n = 0; n < kakiMore.length; n++)
          KokugoLesson(
            id: 'KK${(n + kakiExtra.length + 10).toString().padLeft(3, '0')}',
            title: {
              'ja': 'かん字を かこう ${n + kakiExtra.length + 10}',
              'en': 'Write the Kanji ${n + kakiExtra.length + 10}',
              'vi': 'Viết chữ Hán ${n + kakiExtra.length + 10}',
            },
            question: n == kakiMore.length - 3
                ? {
                    'ja': 'かたかなを かん字に なおして、□に かきましょう。□には、かん字と おくりがなを かきます。（③は 2つの □）',
                    'en': 'Rewrite the katakana as kanji in the boxes. Some answers need kanji + okurigana (③ has two boxes).',
                    'vi': 'Đổi katakana thành chữ Hán và viết vào ô. Có chỗ cần viết chữ Hán + okurigana (câu ③ có 2 ô).',
                  }
                : questionFor('kaki'),
            kind: 'kaki',
            difficulty: 2,
            items: kakiMore[n],
          ),
        // かん字と おくりがな (ワクの ことばを かん字に): 本の 2 ③ (1)〜(6) を 3もんずつ
        for (var n = 0; n < 2; n++)
          KokugoLesson(
            id: 'KK${(n + kakiExtra.length + kakiMore.length + 10).toString().padLeft(3, '0')}',
            title: {
              'ja': 'かん字を かこう ${n + kakiExtra.length + kakiMore.length + 10}',
              'en': 'Write the Kanji ${n + kakiExtra.length + kakiMore.length + 10}',
              'vi': 'Viết chữ Hán ${n + kakiExtra.length + kakiMore.length + 10}',
            },
            question: {
              'ja': 'ワクの ことばを、かん字と おくりがなで かきましょう。ことばは 一かいずつしか つかえません。',
              'en': 'Write each word from the box in kanji with okurigana. Use each word only once.',
              'vi': 'Viết các từ trong khung bằng chữ Hán + okurigana. Mỗi từ chỉ dùng một lần.',
            },
            kind: 'kaki',
            difficulty: 2,
            items: [for (var i = n * 3; i < n * 3 + 3; i++) _okuriItem(i, _okuriBook[i])],
            bank: _okuriBank,
          ),
        // かん字の よみ (本・名・文): 3 bai
        for (var n = 0; n < 3; n++)
          KokugoLesson(
            id: 'KY${(n + 18).toString().padLeft(3, '0')}',
            title: {
              'ja': 'かん字の よみ ${n + 18}',
              'en': 'Kanji Readings ${n + 18}',
              'vi': 'Cách đọc chữ Hán ${n + 18}',
            },
            question: questionFor('yomi'),
            kind: 'yomi',
            difficulty: 2,
            items: yomiMore.sublist(n * 3, n * 3 + 3),
          ),
        // かん字の よみ ページ3 (2): 8 cau van, gop thanh 6 bai (cau chi co 1 cho thi gop voi cau ke)
        for (var n = 0; n < 6; n++)
          KokugoLesson(
            id: 'KY${(n + 21).toString().padLeft(3, '0')}',
            title: {
              'ja': 'かん字の よみ ${n + 21}',
              'en': 'Kanji Readings ${n + 21}',
              'vi': 'Cách đọc chữ Hán ${n + 21}',
            },
            question: questionFor('yomi'),
            kind: 'yomi',
            difficulty: 2,
            items: [
              for (final g in const [
                [0], [1], [2], [3, 4], [5], [6, 7]
              ][n])
                ..._yomiSentence(g, _yomiSent2[g]),
            ],
          ),
        // かん字の よみ ページ1 (2): おなじ かん字の ちがう よみ (人・立・足) ① ② ③ を 1つずつ
        for (var n = 0; n < 3; n++)
          KokugoLesson(
            id: 'KY${(n + 27).toString().padLeft(3, '0')}',
            title: {
              'ja': 'かん字の よみ ${n + 27}',
              'en': 'Kanji Readings ${n + 27}',
              'vi': 'Cách đọc chữ Hán ${n + 27}',
            },
            question: questionFor('yomi'),
            kind: 'yomi',
            difficulty: 2,
            items: [
              for (final e in _yomiSame[n])
                KokugoItem(label: '${_circ[n]}${e[0]}', parts: [
                  if ((e[1] as String).isNotEmpty) _t(e[1] as String),
                  _y(e[2] as String, (e[3] as List).cast<String>()),
                  if ((e[4] as String).isNotEmpty) _t(e[4] as String),
                ]),
            ],
          ),
        // しゅご・じゅつご: 6 cau, chia 3 bai
        for (var n = 0; n < _shugoBook.length ~/ 2; n++)
          KokugoLesson(
            id: 'SG00${n + 1}',
            title: {
              'ja': 'しゅごと じゅつご ${n + 1}',
              'en': 'Subject & Predicate ${n + 1}',
              'vi': 'Chủ ngữ và vị ngữ ${n + 1}',
            },
            question: questionFor('shugo'),
            kind: 'shugo',
            difficulty: 1,
            items: [
              for (var k = 0; k < 2; k++)
                _shugoItem('(${n * 2 + k + 1})', _shugoBook[n * 2 + k][0] as String,
                    _shugoBook[n * 2 + k][1] as int, _shugoBook[n * 2 + k][2] as int),
            ],
          ),
        // ことわざ: 4 cau (nhu sach), chia 2 bai; khung chon co them ca ngu sai trong sach
        KokugoLesson(
          id: 'KW001',
          title: {'ja': 'ことわざ 1', 'en': 'Proverbs 1', 'vi': 'Tục ngữ 1'},
          question: questionFor('kotowaza'),
          kind: 'kotowaza',
          difficulty: 2,
          bank: const ['いそがばまわれ', 'しらぬがほとけ', 'どんぐりのせいくらべ', 'ほとけのかおも三どまで'],
          items: [
            _kotowazaItem('(1)', 'どんぐりのせいくらべ'),
            _kotowazaItem('(2)', 'ほとけのかおも三どまで'),
          ],
        ),
        KokugoLesson(
          id: 'KW002',
          title: {'ja': 'ことわざ 2', 'en': 'Proverbs 2', 'vi': 'Tục ngữ 2'},
          question: questionFor('kotowaza'),
          kind: 'kotowaza',
          difficulty: 2,
          bank: const ['いそがばまわれ', 'しらぬがほとけ', 'とらのいをかるきつね', 'ほとけのかおも三どまで'],
          items: [
            _kotowazaItem('(3)', 'とらのいをかるきつね'),
            _kotowazaItem('(4)', 'いそがばまわれ'),
          ],
        ),
        // 正しい かきじゅん: 4 cau, chia 2 bai
        for (var n = 0; n < 2; n++)
          KokugoLesson(
            id: 'KJ00${n + 1}',
            title: {
              'ja': '正しい かきじゅん ${n + 1}',
              'en': 'Correct Stroke Order ${n + 1}',
              'vi': 'Thứ tự viết đúng ${n + 1}',
            },
            question: questionFor('kakijun'),
            kind: 'kakijun',
            difficulty: 2,
            items: kakijunItems.sublist(n * 2, n * 2 + 2),
          ),
        // かん字の よみ ページ4 (おなじ かん字の ちがう よみ): 3 bai
        for (var n = 0; n < 3; n++)
          KokugoLesson(
            id: 'KY${(n + 15).toString().padLeft(3, '0')}',
            title: {
              'ja': 'かん字の よみ ${n + 15}',
              'en': 'Kanji Readings ${n + 15}',
              'vi': 'Cách đọc chữ Hán ${n + 15}',
            },
            question: questionFor('yomi'),
            kind: 'yomi',
            difficulty: 2,
            items: yomiExtra.sublist(n * 3, n * 3 + 3),
          ),
        // かん字の よみ ページ3: 8 cau van (moi cau 2-3 cho), moi cau la 1 bai
        for (var n = 0; n < _yomiSent.length; n++)
          KokugoLesson(
            id: 'KY${(n + 7).toString().padLeft(3, '0')}',
            title: {
              'ja': 'かん字の よみ ${n + 7}',
              'en': 'Kanji Readings ${n + 7}',
              'vi': 'Cách đọc chữ Hán ${n + 7}',
            },
            question: questionFor('yomi'),
            kind: 'yomi',
            difficulty: 2,
            items: _yomiSentence(n, _yomiSent[n]),
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
        // あてはまる ことば ページ3 (ぎたいご): (1)〜(6) を 3もんずつ 2つの 問題に わける
        // 本の わくの ことば 7つ: さっぱり ぎっしり くっきり こっそり めっきり ゆくゆく はるばる (ゆくゆくは つかわない)
        for (var n = 0; n < 2; n++)
          KokugoLesson(
            id: 'ST00${n + 3}',
            title: {
              'ja': 'あてはまる ことば ${n + 3}',
              'en': 'Fill in the Word ${n + 3}',
              'vi': 'Điền từ thích hợp ${n + 3}',
            },
            question: questionFor('setsuzoku'),
            kind: 'setsuzoku',
            difficulty: 2,
            items: [
              for (var i = 0; i < 3; i++)
                _setsuItem(n * 3 + i, _setsuBank[_setsuBank.indexWhere((e) => e[3] == 'zめっきり') + n * 3 + i]),
            ],
            bank: n == 0
                ? const ['めっきり', 'こっそり', 'ぎっしり', 'ゆくゆく']
                : const ['くっきり', 'はるばる', 'さっぱり', 'ゆくゆく'],
          ),
        // あてはまる ことば ページ4 (ぎたいご・ふくし): 本の 3 (1)〜(6) を 3もんずつ 2つの 問題に わける
        // 本の わくの ことば: まじまじと さっそうと なかなか もっとも 一目さんに みるみる
        for (var n = 0; n < 2; n++)
          KokugoLesson(
            id: 'ST00${n + 5}',
            title: {
              'ja': 'あてはまる ことば ${n + 5}',
              'en': 'Fill in the Word ${n + 5}',
              'vi': 'Điền từ thích hợp ${n + 5}',
            },
            question: questionFor('setsuzoku'),
            kind: 'setsuzoku',
            difficulty: 2,
            items: [
              for (var i = 0; i < 3; i++)
                _setsuItem(n * 3 + i, _setsuBank[_setsuBank.indexWhere((e) => e[3] == 'zなかなか') + n * 3 + i]),
            ],
            bank: n == 0
                ? const ['なかなか', 'さっそうと', 'みるみる', 'まじまじと']
                : const ['一目さんに', 'まじまじと', 'もっとも', 'さっそうと'],
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
        // こそあど ことば: 本の 4 (1)〜(3)
        KokugoLesson(
          id: 'SJ001',
          title: {'ja': 'こそあど ことば 1', 'en': 'What Does It Point To? 1', 'vi': 'Từ chỉ thị 1'},
          question: questionFor('shiji'),
          kind: 'shiji',
          difficulty: 2,
          items: [
            _shijiItem('(1)', 'あたらしい レストランが えきの そばに できた。ぼくは ', 'そこ', 'で ごはんを たべた。',
                ['レストラン', 'えき', 'ごはん'], 0),
            _shijiItem('(2)', 'おばあちゃんが みんなに おこづかいを くれた。わたしは ', 'それ',
                'を ちょ金して、いつか じてん車を かおうと きめた。', ['おばあちゃん', 'おこづかい', 'じてん車'], 1),
            _shijiItem('(3)', 'ともだちが でん車の もけいを 見せてくれた。「', 'これ',
                'が ぼくの たからものだよ」と いいながら、ともだちは にこにこしていた。', ['でん車', 'もけい', 'たからもの'], 1),
          ],
        ),
        // あう ことばを えらぼう: 本の 3 (1)〜(7) を 3・2・2 もんに わける
        for (var n = 0; n < 3; n++)
          KokugoLesson(
            id: 'ER00${n + 1}',
            title: {
              'ja': 'あう ことばを えらぼう ${n + 1}',
              'en': 'Choose the Best Word ${n + 1}',
              'vi': 'Chọn từ phù hợp nhất ${n + 1}',
            },
            question: questionFor('erabu'),
            kind: 'erabu',
            difficulty: 2,
            items: [
              for (var i = const [0, 3, 5][n]; i < const [3, 5, 7][n]; i++)
                _erabuItem('(${i + 1})', _erabuBook[i]),
            ],
          ),
        // つなぎことば: 本の 4 (1)〜(5) を 3・2 もんに わける
        for (var n = 0; n < 2; n++)
          KokugoLesson(
            id: 'TN00${n + 1}',
            title: {
              'ja': 'つなぎことば ${n + 1}',
              'en': 'Connecting Words ${n + 1}',
              'vi': 'Từ nối ${n + 1}',
            },
            question: questionFor('tsunagi'),
            kind: 'tsunagi',
            difficulty: 2,
            items: [
              for (var i = n * 3; i < (n == 0 ? 3 : 5); i++) _tsunagiItem(i, _tsunagiBook[i]),
            ],
            bank: _tsunagiWords,
          ),
        // おなじ よみの かん字: 本の 2 ② の 4つの よみを 2つずつの 問題に わける
        for (var n = 0; n < 2; n++)
          KokugoLesson(
            id: 'DY00${n + 1}',
            title: {
              'ja': 'おなじ よみの かん字 ${n + 1}',
              'en': 'Kanji with the Same Reading ${n + 1}',
              'vi': 'Chữ Hán cùng cách đọc ${n + 1}',
            },
            question: questionFor('doyomi'),
            kind: 'doyomi',
            difficulty: 2,
            items: [
              for (final g in const [
                [0, 1],
                [2, 3]
              ][n])
                ..._doyomiItems(g, _doyomiBook[g][0] as String, (_doyomiBook[g][1] as List).cast<String>()),
            ],
            bank: _doyomiBookBank,
          ),
        // はんたいの いみの ことば: 本の 4 (1)〜(8) を 3・3・2 もんに わける
        for (var n = 0; n < 3; n++)
          KokugoLesson(
            id: 'HG00${n + 1}',
            title: {
              'ja': 'はんたいの いみの ことば ${n + 1}',
              'en': 'Opposite Words ${n + 1}',
              'vi': 'Từ trái nghĩa ${n + 1}',
            },
            question: questionFor('hantaigo'),
            kind: 'hantaigo',
            difficulty: 2,
            items: [
              for (var i = const [0, 3, 6][n]; i < const [3, 6, 8][n]; i++) _hantaigoItem(i, _hantaigoBook[i]),
            ],
          ),
        // ことばを つかって ぶんを つくろう: 本の 5・6・7・8 (各 (1)〜(4)) を 2もんずつ 4つの 問題に わける
        // (cau mau la do ta soan de tu cham)
        for (var n = 0; n < _bunBook.length ~/ 2; n++)
          KokugoLesson(
            id: 'BS00${n + 1}',
            title: {
              'ja': 'ことばを つかって ぶんを つくろう ${n + 1}',
              'en': 'Write a Sentence with the Words ${n + 1}',
              'vi': 'Đặt câu với từ cho sẵn ${n + 1}',
            },
            question: questionFor('bunsaku'),
            kind: 'bunsaku',
            difficulty: 2,
            items: [
              for (var i = 0; i < 2; i++)
                _bunItem('(${(n % 2) * 2 + i + 1})', _bunBook[n * 2 + i][0] as String, _bunBook[n * 2 + i][1] as String,
                    (_bunBook[n * 2 + i][2] as List).cast<String>()),
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
    ['大きい', 'オオ|キ|イ', '', 'いぬが いる。'],
    ['小さい', 'チイ|サ|イ', '', 'ねこが ねている。'],
    ['早く', 'ハヤ|ク', '', 'おきて さんぽに いく。'],
    ['見える', 'ミ|エ|ル', 'とおくの やまが', '。'],
    ['出せる', 'ダ|セ|ル', 'おおきな こえが', '。'],
    ['下って', 'クダ|ッ|テ', 'さかを', 'いく。'],
    ['百人', 'ヒャク|ニン', '', 'が あつまる。'],
    ['年上', 'トシ|ウエ', '', 'の ともだち。'],
    ['下校', 'ゲ|コウ', '', 'の じかん。'],
    ['中学校', 'チュウ|ガッ|コウ', '', 'に かよう。'],
    ['名人', 'メイ|ジン', 'しょうぎの', '。'],
    ['本音', 'ホン|ネ', '', 'を はなす。'],
    ['年下', 'トシ|シタ', '', 'の ゆう人。'],
    ['右手', 'ミギ|テ', '', 'を あげる。'],
    ['文字', 'モ|ジ', '', 'を かく。'],
    ['音読', 'オン|ドク', '', 'を する。'],
    ['名作', 'メイ|サク', '', 'を よむ。'],
    ['上着', 'ウワ|ギ', '', 'を きる。'],
    ['学ぶ', 'マナ|ブ', 'えいごを', '。'],
    ['見上げる', 'ミ|ア|ゲ|ル', 'そらを', '。'],
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
    if (kind == 'shugo') {
      final count = lv == 1 ? 2 : 3;
      final pool = List<List<dynamic>>.from(_shugoPool)..shuffle(r);
      return KokugoLesson(
        id: id,
        title: title,
        question: questionFor('shugo'),
        kind: 'shugo',
        difficulty: lv,
        isAutoGenerated: true,
        items: [
          for (var i = 0; i < count; i++)
            _shugoItem('(${i + 1})', pool[i][0] as String, pool[i][1] as int, pool[i][2] as int),
        ],
      );
    }
    if (kind == 'kotowaza') {
      final count = lv == 1 ? 2 : 3;
      final pool = List<List<String>>.from(_kotoPool)..shuffle(r);
      final bank = [for (final e in pool.sublist(0, count + 1)) e[0]]..shuffle(r);
      return KokugoLesson(
        id: id,
        title: title,
        question: questionFor('kotowaza'),
        kind: 'kotowaza',
        difficulty: lv,
        isAutoGenerated: true,
        bank: bank,
        items: [for (var i = 0; i < count; i++) _kotowazaItem('(${i + 1})', pool[i][0])],
      );
    }
    if (kind == 'kakijun') {
      final count = lv == 1 ? 2 : 3;
      final pool = kStrokeData.keys.toList()..shuffle(r);
      final items = <KokugoItem>[];
      for (var i = 0; i < count; i++) {
        final ch = pool[i];
        final n = kStrokeData[ch]!.length;
        final good = _stagesOf([for (var k = 0; k < n; k++) k]);
        // ca sai: net cuoi viet truoc (chu 子: gop 2 net dau thanh 1 buoc, nhu sach)
        final bad = ch == '子'
            ? <List<int>>[[0, 1], [0, 1, 2]]
            : _stagesOf([n - 1, for (var k = 0; k < n - 1; k++) k]);
        final goodFirst = r.nextBool();
        items.add(_kakijunItem(circled(i), ch, goodFirst ? [good, bad] : [bad, good], goodFirst ? 0 : 1));
      }
      return KokugoLesson(
        id: id,
        title: title,
        question: questionFor('kakijun'),
        kind: 'kakijun',
        difficulty: lv,
        isAutoGenerated: true,
        items: items,
      );
    }
    if (kind == 'erabu') {
      final count = lv == 1 ? 2 : 3;
      final pool = <List<dynamic>>[..._erabuBook, ..._erabuExtra]..shuffle(r);
      return KokugoLesson(
        id: id,
        title: title,
        question: questionFor('erabu'),
        kind: 'erabu',
        difficulty: lv,
        isAutoGenerated: true,
        items: [
          for (var i = 0; i < count; i++)
            _erabuItem('(${i + 1})', pool[i], opts: List<String>.from((pool[i][2] as List).cast<String>())..shuffle(r)),
        ],
      );
    }
    if (kind == 'tsunagi') {
      final count = lv == 1 ? 3 : 4;
      List<List<String>> picks;
      do {
        picks = (List<List<String>>.from(_tsunagiExtra)..shuffle(r)).take(count).toList();
      } while (picks.map((e) => e[2]).toSet().length < 3);
      return KokugoLesson(
        id: id,
        title: title,
        question: questionFor('tsunagi'),
        kind: 'tsunagi',
        difficulty: lv,
        isAutoGenerated: true,
        items: [for (var i = 0; i < picks.length; i++) _tsunagiItem(i, picks[i])],
        bank: (List<String>.from(_tsunagiWords)..shuffle(r)),
      );
    }
    if (kind == 'shiji') {
      final count = lv == 1 ? 2 : 3;
      final pool = List<List<dynamic>>.from(_shijiPool)..shuffle(r);
      final items = <KokugoItem>[];
      for (var i = 0; i < count; i++) {
        final e = pool[i];
        final opts = (e[3] as List).cast<String>();
        final ans = opts[e[4] as int];
        final sh = List<String>.from(opts)..shuffle(r);
        items.add(_shijiItem('(${i + 1})', e[0] as String, e[1] as String, e[2] as String, sh, sh.indexOf(ans)));
      }
      return KokugoLesson(
        id: id,
        title: title,
        question: questionFor('shiji'),
        kind: 'shiji',
        difficulty: lv,
        isAutoGenerated: true,
        items: items,
      );
    }
    if (kind == 'bunsaku') {
      const count = 2; // moi bai chi 2 cau cho de lam
      final pool = <List<dynamic>>[..._bunPool, ..._bunBook]..shuffle(r);
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
      var adv = r.nextBool(); // true: ぎたいご(ふくし) / false: せつぞくご
      List<List<String>> picks = [];
      List<String> words = [];
      for (var t = 0; t < 300; t++) {
        final pool = [for (final e in _setsuBank) if (e[3].startsWith('z') == adv) e]..shuffle(r);
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
        adv = false;
        picks = [_setsuBank[0], _setsuBank[4]];
        words = ['まだ', 'もう'];
      }
      final extra = lv == 1 ? 0 : (lv == 2 ? 1 : 2);
      final spare = [
        for (final w in (adv ? _advWords : _setsuWords))
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
    if (kind == 'doyomi') {
      final gc = lv == 1 ? 2 : 3;
      final pool = List<List<dynamic>>.from(_doyomiPool)..shuffle(r);
      final chosen = pool.take(gc).toList();
      final rest = pool.skip(gc).toList();
      final bank = <String>[];
      final items = <KokugoItem>[];
      for (var g = 0; g < chosen.length; g++) {
        final ks = List<String>.from((chosen[g][1] as List).cast<String>())..shuffle(r);
        final two = ks.take(2).toList();
        bank.addAll(two);
        items.addAll(_doyomiItems(g, chosen[g][0] as String, two));
      }
      // ひっかけ: ほかの よみの かん字を 1〜3こ まぜる
      for (var k = 0; k < lv && k < rest.length; k++) {
        bank.add((rest[k][1] as List).cast<String>().first);
      }
      bank.shuffle(r);
      return KokugoLesson(
        id: id,
        title: title,
        question: questionFor('doyomi'),
        kind: 'doyomi',
        difficulty: lv,
        isAutoGenerated: true,
        items: items,
        bank: bank,
      );
    }
    if (kind == 'hantaigo') {
      final count = lv == 1 ? 2 : 3;
      final pool = [..._hantaigoBook, ..._hantaigoExtra]..shuffle(r);
      return KokugoLesson(
        id: id,
        title: title,
        question: questionFor('hantaigo'),
        kind: 'hantaigo',
        difficulty: lv,
        isAutoGenerated: true,
        items: [for (var i = 0; i < count; i++) _hantaigoItem(i, pool[i])],
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
