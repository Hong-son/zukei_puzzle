import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/locale_service.dart';
import '../services/progress_service.dart';
import '../services/dice_engine.dart';
import '../services/net_engine.dart';
import '../services/mark_engine.dart';
import '../services/hide_engine.dart';
import '../models/dice_lesson.dart';
import '../models/net_lesson.dart';
import '../models/mark_lesson.dart';
import '../models/hide_lesson.dart';
import 'dice_game_screen.dart';
import 'net_game_screen.dart';
import 'mark_game_screen.dart';
import 'hide_game_screen.dart';
import '../services/dice3d_engine.dart';
import '../models/back_lesson.dart';
import '../models/pick_lesson.dart';
import 'back_game_screen.dart';
import 'pick_game_screen.dart';



class DiceCategoryScreen extends StatefulWidget {
  final Map<String, dynamic> category;
  final String kind;
  const DiceCategoryScreen({super.key, required this.category, required this.kind});

  static List<String> sampleIds(String kind) {
    switch (kind) {
      case 'net':
        return ['NT001'];
      case 'mark':
        return ['MK001'];
      case 'hide':
        return ['HD001', 'HD002'];
      case 'back':
        return ['BK001'];
      case 'pick':
        return ['PK001'];  
      default:
        return ['DC001', 'DC002'];
    }
  }

  static const Map<String, String> _qDice = {
    'ja': 'かたちを せんで おりまげて くみ立てて さいころを つくります。きごうが かいてある ところの 目の かずは いくつですか。',
    'en': 'Fold the net into a dice. What number is on each marked face?',
    'vi': 'Gấp hình khai triển thành xúc xắc. Mặt có ký hiệu mang số mấy?',
  };

  static const Map<String, String> _qHide = {
    'ja': 'えの 中に、くみ立てると さいころに なる かたちが 1つ かくれています。さがして かこみましょう。',
    'en': 'One net that folds into a dice is hidden here. Find it and select its 6 squares.',
    'vi': 'Có 1 hình khai triển gấp được thành xúc xắc đang ẩn ở đây. Hãy tìm và chọn 6 ô của nó.',
  };

  static List<dynamic> samples(String kind) {
    switch (kind) {
      case 'net':
        return [_net1];
      case 'mark':
        return [_mark1];
      case 'hide':
        return [_hide1, _hide2];
      default:
        return [_lesson1, _lesson2];
    }
  }

  static const DiceLesson _lesson1 = DiceLesson(
    id: 'DC001',
    title: {'ja': 'さいころ 1', 'en': 'Dice 1', 'vi': 'Xúc xắc 1'},
    question: _qDice,
    cells: [
      [0, 1], [1, 1], [1, 2], [2, 1], [3, 1], [3, 0]
    ],
    values: {0: 1, 1: 3, 2: 5, 3: 6, 4: 4, 5: 2},
    hiddenIdx: [3, 4],
    labels: ['ア', 'イ'],
    difficulty: 1,
  );

  static const DiceLesson _lesson2 = DiceLesson(
    id: 'DC002',
    title: {'ja': 'さいころ 2', 'en': 'Dice 2', 'vi': 'Xúc xắc 2'},
    question: _qDice,
    cells: [
      [0, 0], [1, 0], [1, 1], [1, 2], [1, 3], [2, 0]
    ],
    values: {0: 1, 1: 4, 2: 5, 3: 3, 4: 2, 5: 6},
    hiddenIdx: [3, 4, 5],
    labels: ['ウ', 'エ', 'オ'],
    difficulty: 2,
  );

  static const NetLesson _net1 = NetLesson(
    id: 'NT001',
    title: {'ja': 'さいころに ならない かたち 1', 'en': 'Not a Dice 1', 'vi': 'Hình không gấp được 1'},
    question: {
      'ja': '下の かたちのうち、せんで おりまげて くみ立てても さいころの かたちに ならないものは どれですか。ぜんぶ えらびましょう。',
      'en': 'Choose ALL shapes that cannot be folded into a dice.',
      'vi': 'Chọn TẤT CẢ hình không thể gấp thành xúc xắc.',
    },
    shapes: [
      [[0, 1], [1, 0], [1, 1], [2, 1], [3, 1], [3, 2]],
      [[0, 0], [1, 0], [1, 1], [2, 1], [2, 2], [3, 2]],
      [[0, 1], [1, 0], [1, 1], [2, 0], [2, 1], [3, 0]],
      [[0, 0], [1, 0], [1, 1], [1, 2], [1, 3], [2, 1]],
      [[0, 2], [1, 2], [2, 0], [2, 1], [2, 2], [3, 2]],
      [[0, 1], [1, 1], [2, 0], [2, 1], [2, 2], [3, 2]],
      [[0, 0], [1, 0], [1, 1], [2, 1], [2, 2], [2, 3]],
      [[0, 0], [0, 1], [0, 2], [1, 2], [1, 3], [1, 4]],
    ],
    difficulty: 2,
  );

  static const MarkLesson _mark1 = MarkLesson(
    id: 'MK001',
    title: {'ja': 'むかいあう めん 1', 'en': 'Opposite Face 1', 'vi': 'Mặt đối diện 1'},
    question: {
      'ja': '下の かたちを せんで おりまげて くみ立てて、さいころの かたちを つくります。◎のある めんと むかいあう めんは どれですか。そのめんにも ◎を かきましょう。',
      'en': 'Fold each net into a dice. Which face is opposite the ◎ face? Draw a ◎ on it too.',
      'vi': 'Gấp từng hình thành xúc xắc. Mặt nào đối diện với mặt có ◎? Hãy vẽ ◎ vào mặt đó.',
    },
    nets: [
      [[0, 0], [0, 1], [0, 2], [1, 1], [2, 1], [3, 1]],
      [[0, 1], [1, 0], [1, 1], [1, 2], [2, 2], [2, 3]],
      [[0, 2], [1, 0], [1, 1], [1, 2], [1, 3], [2, 1]],
      [[0, 3], [1, 0], [1, 1], [1, 2], [1, 3], [2, 2]],
      [[0, 1], [0, 2], [1, 1], [2, 0], [2, 1], [3, 0]],
    ],
    marks: [1, 1, 2, 5, 5],
    difficulty: 2,
  );

  // Bai mau かくれんぼ: so cham doc tu anh sach. App tu tim dap an;
  // neu doc sai so cham thi app bao khong co dap an hop le.
  static const HideLesson _hide1 = HideLesson(
    id: 'HD001',
    title: {'ja': 'さいころの かくれんぼ 1', 'en': 'Hide and Seek 1', 'vi': 'Trốn tìm 1'},
    question: _qHide,
    grid: [
      [6, 2, 4, 13],
      [3, 1, 4, 16],
      [4, 5, 3, 2],
    ],
    difficulty: 1,
  );

  static const HideLesson _hide2 = HideLesson(
    id: 'HD002',
    title: {'ja': 'さいころの かくれんぼ 2', 'en': 'Hide and Seek 2', 'vi': 'Trốn tìm 2'},
    question: _qHide,
    grid: [
      [4, 1, 13, 5],
      [12, 3, 4, 16],
      [4, 5, 3, 2],
      [5, 6, 1, 5],
    ],
    difficulty: 2,
  );
  static const BackLesson _back1 = BackLesson(
    id: 'BK001',
    title: {'ja': 'うしろから みると 1', 'en': 'View from Behind 1', 'vi': 'Nhìn từ phía sau 1'},
    question: {
      'ja': 'さいころには 1〜6の 目が あって、むかいあう 目の かずを あわせると 7に なります。下のように 2この さいころを ならべました。まえから 見ると 3の 目が 2つ 見えるので、あわせて 6の 目が 見えます。うしろから 見える 目の かずは あわせて いくつですか。',
      'en': 'Opposite faces add up to 7. Two dice are placed side by side. From the front you see 3 and 3 (total 6). What is the total of the faces seen from behind?',
      'vi': 'Hai mặt đối nhau cộng bằng 7. Hai xúc xắc đặt cạnh nhau. Nhìn từ trước thấy 3 và 3 (tổng 6). Tổng các mặt nhìn từ phía sau là bao nhiêu?',
    },
    fronts: [3, 3],
    difficulty: 1,
  );
  // Hinh khai trien chu thap ngang. Xuc xac cho truoc: ban phai doc lai tu anh sach.
  static const PickLesson _pick1 = PickLesson(
    id: 'PK001',
    title: {'ja': 'どの さいころ？ 1', 'en': 'Which Dice? 1', 'vi': 'Xúc xắc nào? 1'},
    question: {
      'ja': '右は さいころを きりひらいた ものです。これを くみたてたときに できる さいころを、ア〜ウから 1つ えらびましょう。',
      'en': 'This is a dice cut open. Choose the dice that can be made by folding it.',
      'vi': 'Đây là xúc xắc được cắt ra. Hãy chọn xúc xắc có thể tạo được khi gấp hình này.',
    },
    cells: [
      [0, 1], [1, 0], [1, 1], [1, 2], [1, 3], [2, 1]
    ],
    values: [2, 3, 1, 4, 6, 5],
    options: [
      [3, 6, 1],
      [1, 3, 2],
      [4, 6, 3],
    ],
    correct: 0,
    difficulty: 2,
  );

  @override
  State<DiceCategoryScreen> createState() => _DiceCategoryScreenState();
}

class _DiceCategoryScreenState extends State<DiceCategoryScreen> {
  bool _busy = false;

  Future<void> _add() async {
    if (_busy) return;
    setState(() => _busy = true);
    await Future.delayed(const Duration(milliseconds: 50));
    final lv = 1 + (DateTime.now().millisecond % 3);
    final ps = context.read<ProgressService>();
    bool ok = true;
    switch (widget.kind) {
      case 'net':
        await ps.addGeneratedNet(NetEngine.generate(level: lv));
        break;
      case 'mark':
        await ps.addGeneratedMark(MarkEngine.generate(level: lv));
        break;
      case 'hide':
        final h = HideEngine.generate(level: lv);
        if (h == null) {
          ok = false;
        } else {
          await ps.addGeneratedHide(h);
        }
        break;
      case 'back':
        await ps.addGeneratedBack(Dice3DEngine.generateBack(level: 1 + (DateTime.now().millisecond % 5)));
        break;
      case 'pick':
        final p = Dice3DEngine.generatePick(level: lv);
        if (p == null) {
          ok = false;
        } else {
          await ps.addGeneratedPick(p);
        }
        break;
      default:
        await ps.addGeneratedDice(DiceEngine.generate(level: lv));
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not generate. Try again.')));
    }
  }

  Widget _screenFor(dynamic lesson) {
    switch (widget.kind) {
      case 'net':
        return NetGameScreen(lesson: lesson as NetLesson);
      case 'mark':
        return MarkGameScreen(lesson: lesson as MarkLesson);
      case 'hide':
        return HideGameScreen(lesson: lesson as HideLesson);
      case 'back':
        return BackGameScreen(lesson: lesson as BackLesson);
      case 'pick':
        return PickGameScreen(lesson: lesson as PickLesson);
      default:
        return DiceGameScreen(lesson: lesson as DiceLesson);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleService>().lang;
    final progress = context.watch<ProgressService>();
    final cat = widget.category;
    final doneLabel = lang == 'ja' ? 'かいクリア' : lang == 'en' ? 'times cleared' : 'lần hoàn thành';
    final names = {
      'dice': {'ja': '目の かず', 'en': 'Fill Numbers', 'vi': 'Điền số'},
      'net': {'ja': 'ならない かたち', 'en': 'Not a Dice', 'vi': 'Hình không gấp được'},
      'mark': {'ja': 'むかいあう めん', 'en': 'Opposite Face', 'vi': 'Mặt đối diện'},
      'hide': {'ja': 'かくれんぼ', 'en': 'Hide and Seek', 'vi': 'Trốn tìm'},
      'back': {'ja': 'うしろから みると', 'en': 'View from Behind', 'vi': 'Nhìn từ phía sau'},
      'pick': {'ja': 'どの さいころ？', 'en': 'Which Dice?', 'vi': 'Xúc xắc nào?'},
    };
    final kindColors = {
      'dice': const Color(0xFFFF7043),
      'net': const Color(0xFF7E57C2),
      'mark': const Color(0xFF26A69A),
      'hide': const Color(0xFFEC407A),
      'back': const Color(0xFF5C6BC0),
      'pick': const Color(0xFF8D6E63),
    };
    final color = kindColors[widget.kind]!;
    final title = names[widget.kind]![lang] ?? '';

    final List<dynamic> generated;
    switch (widget.kind) {
      case 'net':
        generated = progress.generatedNets;
        break;
      case 'mark':
        generated = progress.generatedMarks;
        break;
      case 'hide':
        generated = progress.generatedHides;
        break;
      case 'back':
          generated = progress.generatedBacks;
          break;
        case 'pick':
          generated = progress.generatedPicks;
          break;
      default:
        generated = progress.generatedDice;
    }
    final lessons = [...DiceCategoryScreen.samples(widget.kind), ...generated];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9C4),
      appBar: AppBar(
        backgroundColor: color,
        title: Text('${(cat['name'] as Map<String, String>)[lang] ?? ''}  ›  $title',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _add,
        backgroundColor: color,
        icon: _busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.auto_awesome, color: Colors.white),
        label: Text(lang == 'ja' ? 'あたらしい もんだい' : lang == 'en' ? 'New puzzle' : 'Bài mới',
            style: const TextStyle(color: Colors.white)),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: lessons.length,
            itemBuilder: (context, index) {
              final lesson = lessons[index];
              final String id = lesson.id as String;
              final Map<String, String> t = lesson.title as Map<String, String>;
              final int diff = lesson.difficulty as int;
              final n = progress.completions(id);
              final done = n > 0;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: done ? const Color(0xFFE8F5E9) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: CircleAvatar(
                    backgroundColor: done ? Colors.green : color,
                    child: done
                        ? const Icon(Icons.check, color: Colors.white)
                        : Text('${index + 1}',
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(t[lang] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Level: ${'⭐' * diff}${done ? '   ✓ $n $doneLabel' : ''}'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => _screenFor(lesson)),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

