import 'dart:math';
import '../models/view_lesson.dart';
import 'view_shapes.dart';

// 水めんのかたち (water): nhin tu tren xuong, xep 4 hinh theo luong nuoc nhieu -> it (1 = nhieu nhat).
// かげの正たい (shadow): tu 3 cai bong (nhin tu 3 huong) doan ra vat.
class ViewEngine {
  static const List<String> kinds = ['water', 'shadow'];

  static const Map<String, Map<String, String>> baseNames = {
    'water': {'ja': '水めんの かたち', 'en': 'Water Surface Shapes', 'vi': 'Hình dạng mặt nước'},
    'shadow': {'ja': 'かげの 正たい', 'en': 'Whose Shadow?', 'vi': 'Bóng của vật nào?'},
  };

  // Cac vat de chon, theo thu tu ① ... ⑥ trong sach
  static const List<String> objects = ['cheese', 'ball', 'can', 'kit', 'cake', 'tissue'];
  static const List<String> circled = ['①', '②', '③', '④', '⑤', '⑥'];

  static const Map<String, Map<String, String>> objectNames = {
    'cheese': {'ja': 'チーズ', 'en': 'Cheese', 'vi': 'Phô mai'},
    'ball': {'ja': 'やきゅうボール', 'en': 'Baseball', 'vi': 'Bóng chày'},
    'can': {'ja': 'おちゃの つつ', 'en': 'Tea canister', 'vi': 'Hộp trà'},
    'kit': {'ja': 'きゅうきゅうばこ', 'en': 'First-aid box', 'vi': 'Hộp cứu thương'},
    'cake': {'ja': 'ケーキ', 'en': 'Cake', 'vi': 'Bánh kem'},
    'tissue': {'ja': 'ティッシュの はこ', 'en': 'Tissue box', 'vi': 'Hộp khăn giấy'},
  };

  static Map<String, String> questionFor(String kind) {
    if (kind == 'water') {
      return {
        'ja': '右のような 入れものに 水を 入れながら、ま上から 見ました。下の 4つの えは、この 入れものを ま上から 見た ようすです。水が たくさん 入っている じゅんに、（　）に ばんごうを かきましょう。',
        'en': 'Water is poured into the container shown, looking straight down from above. The four pictures show the container seen from directly above. Write numbers in the ( ) in order from the most water (1) to the least.',
        'vi': 'Đổ nước vào bình như hình và nhìn thẳng từ trên xuống. 4 hình dưới là cảnh nhìn từ trên. Điền số vào ( ) theo thứ tự nước từ nhiều nhất (1) đến ít nhất.',
      };
    }
    return {
      'ja': 'かげの 正たいを 見やぶり、ばんごうを かきましょう。',
      'en': 'Work out what made the shadows and write its number.',
      'vi': 'Đoán xem các cái bóng này là của vật nào và viết số của vật đó.',
    };
  }

  static String wrongMessage(String kind, String lang) {
    if (kind == 'water') {
      return lang == 'ja'
          ? 'ちがう ところが あるよ。水が ふえると、水めんは どう かわるかな？'
          : lang == 'en'
              ? 'Something is wrong. How does the water surface change as the water rises?'
              : 'Có chỗ chưa đúng. Khi nước dâng lên, mặt nước thay đổi thế nào?';
    }
    return lang == 'ja'
        ? 'ちがう ところが あるよ。いろいろな むきから 見た かたちを かんがえよう'
        : lang == 'en'
            ? 'Something is wrong. Think about the shapes seen from different directions'
            : 'Có chỗ chưa đúng. Hãy nghĩ về hình dạng khi nhìn từ các hướng khác nhau';
  }

  // ---- 水めん ----

  // hang 1 = nhieu nhat
  static List<int> _ranks(List<double> amounts) =>
      [for (final a in amounts) 1 + amounts.where((b) => b > a).length];

  // binh hinh non (hoac bat): vanh ngoai 1.0, mieng non 0.78, mat nuoc rw
  static Map<String, dynamic> _coneTop(double rw) => {
        'c': [1.0, 0.78, rw],
        's0': 0.0,
        's1': rw,
      };

  // binh bac thang: state = muc nuoc nam trong tang state (0 = tang duoi cung); state = n -> ngap het
  static Map<String, dynamic> _stairTop(List<double> r, int state) {
    final n = r.length;
    if (state >= n) {
      return {'c': [1.0], 's0': 0.0, 's1': 1.0};
    }
    return {
      'c': [1.0, for (var j = state; j < n; j++) r[j]],
      's0': r[state],
      's1': 1.0,
    };
  }

  static ViewItem _waterItem(String label, String pic, List<Map<String, dynamic>> tops, List<double> amounts) {
    return ViewItem(label: label, data: {'pic': pic, 'tops': tops, 'ans': _ranks(amounts)});
  }

  static ViewItem _stairItem(String key, List<int> states) {
    final r = kStairRadii[key]!;
    return _waterItem('', key, [for (final s in states) _stairTop(r, s)], [for (final s in states) s.toDouble()]);
  }

  static ViewItem _coneItem(String pic, List<double> rws) {
    return _waterItem('', pic, [for (final w in rws) _coneTop(w)], rws);
  }

  // ---- かげ ----
  static ViewItem _shadowItem(int no, String obj) =>
      ViewItem(label: '（${no + 1}）', data: {'obj': obj});

  static List<ViewLesson>? _cache;

  static List<ViewLesson> samples(String kind) {
    _cache ??= _build();
    return _cache!.where((l) => l.kind == kind).toList();
  }

  static List<ViewLesson> _build() {
    return [
      // 水めん: dung nhu sach. Thu tu hinh nhu trong sach.
      ViewLesson(
        id: 'WT001',
        title: {'ja': '水めんの かたち 1', 'en': 'Water Surface 1', 'vi': 'Mặt nước 1'},
        question: questionFor('water'),
        kind: 'water',
        difficulty: 1,
        items: [
          _coneItem('cone', [0.42, 0.69, 0.22, 0.55]), // dap an 3,1,4,2
        ],
      ),
      ViewLesson(
        id: 'WT002',
        title: {'ja': '水めんの かたち 2', 'en': 'Water Surface 2', 'vi': 'Mặt nước 2'},
        question: questionFor('water'),
        kind: 'water',
        difficulty: 2,
        items: [
          _stairItem('st3a', [3, 2, 0, 1]), // dap an 1,2,4,3
        ],
      ),
      // かげ: 4 cau trong sach chia 2 bai; dap an (1)④ (2)③ (3)⑤ (4)②
      ViewLesson(
        id: 'SH001',
        title: {'ja': 'かげの 正たい 1', 'en': 'Whose Shadow? 1', 'vi': 'Bóng của vật nào? 1'},
        question: questionFor('shadow'),
        kind: 'shadow',
        difficulty: 2,
        items: [_shadowItem(0, 'kit'), _shadowItem(1, 'can')],
        bank: objects,
      ),
      ViewLesson(
        id: 'SH002',
        title: {'ja': 'かげの 正たい 2', 'en': 'Whose Shadow? 2', 'vi': 'Bóng của vật nào? 2'},
        question: questionFor('shadow'),
        kind: 'shadow',
        difficulty: 2,
        items: [_shadowItem(2, 'cake'), _shadowItem(3, 'ball')],
        bank: objects,
      ),
    ];
  }

  static ViewItem _randomCone(Random r) {
    final pool = <double>[0.14, 0.26, 0.38, 0.50, 0.62, 0.74]..shuffle(r);
    final rws = [
      for (final x in pool.take(4)) double.parse((x + (r.nextDouble() - 0.5) * 0.04).toStringAsFixed(2)),
    ];
    return _coneItem(r.nextBool() ? 'cone' : 'bowl', rws);
  }

  static ViewItem _randomStairs(Random r, int n) {
    final keys = [for (final k in kStairRadii.keys) if (kStairRadii[k]!.length == n) k];
    final key = keys[r.nextInt(keys.length)];
    final states = List<int>.generate(n + 1, (i) => i)..shuffle(r);
    return _stairItem(key, states.take(4).toList());
  }

  static ViewLesson generate(String kind, {int level = 1, Random? rng}) {
    final r = rng ?? Random();
    final int lv = level < 1 ? 1 : (level > 3 ? 3 : level);
    final id = 'vw_${DateTime.now().microsecondsSinceEpoch}';
    final title = {
      for (final e in baseNames[kind]!.entries) e.key: '${e.value} ✨',
    };
    if (kind == 'water') {
      // muc 1: non/bat; muc 2: 3 tang; muc 3: 2 cau (4 tang + non/bat hoac 3 tang)
      final items = <ViewItem>[
        if (lv == 1) _randomCone(r),
        if (lv == 2) _randomStairs(r, 3),
        if (lv == 3) ...[
          _randomStairs(r, 4),
          r.nextBool() ? _randomCone(r) : _randomStairs(r, 3),
        ],
      ];
      return ViewLesson(
        id: id,
        title: title,
        question: questionFor('water'),
        kind: 'water',
        difficulty: lv,
        isAutoGenerated: true,
        items: items,
      );
    }
    final count = lv == 1 ? 2 : (lv == 2 ? 3 : 4);
    final pick = List<String>.from(objects)..shuffle(r);
    return ViewLesson(
      id: id,
      title: title,
      question: questionFor('shadow'),
      kind: 'shadow',
      difficulty: lv,
      isAutoGenerated: true,
      items: [for (var i = 0; i < count; i++) _shadowItem(i, pick[i])],
      bank: objects,
    );
  }
}
