// Giai thich tu bang tranh truyen tranh dong (emoji) + chu. Tu dong sinh boi tools/gen_wordhelp.py
// moi muc: [ja, en, vi, tranh]; tranh = cac khung cach nhau '/', moi khung = 'emoji|loi thoai'
// Muc co ja/en/vi rong thi lay nghia tu KokugoEngine.bunMeaning (bunsaku) hoac tu bai hoc (kan'you-ku).
import 'kokugo_engine.dart';

class ComicPanel {
  final String emoji;
  final String text;
  const ComicPanel(this.emoji, this.text);
}

// Mot muc can giai thich: key tra trong WordHelp, tieu de hien thi, nghia ja du phong, dong phu
class HelpEntry {
  final String key;
  final String title;
  final String ja;
  final String extra;
  const HelpEntry(this.key, {String? title, this.ja = '', this.extra = ''}) : title = title ?? key;
}

class WordHelp {
  static const Map<String, List<String>> _d = {
    'うれしい': ['', '', '', '🎁|プレゼントだ！/😊|うれしい！'],
    'はなす': ['', '', '', '👧|きのうね…/💬|おしゃべり！/👦|うんうん'],
    'こうふん': ['', '', '', '🎢|ジェットコースター！/😆|わくわく！/💓|どきどき'],
    'できる': ['', '', '', '🚲|じてんしゃに のれた！/🙌|できた！'],
    'まんぞく': ['', '', '', '🍰|ケーキを たべた/😌|おなかいっぱい！ まんぞく'],
    'よろこばせる': ['', '', '', '🎂|おたんじょうび おめでとう/🎉|みんなが にこにこ'],
    'たのしみ': ['', '', '', '📅|あしたは えんそく！/😆|まちきれない！'],
    'もうすぐ': ['', '', '', '⏰|あと すこし…/🎉|もうすぐ はじまる！'],
    'たのしい': ['', '', '', '🎮|みんなで あそぶ/😄|たのしい！'],
    'あそぶ': ['', '', '', '⚽|こうえんで/🏃|みんなで あそぶ'],
    'おどろく': ['おもわない ことで、はっと する。', 'To be startled by something unexpected.', 'Giật mình vì điều bất ngờ.', '🎁|ぱかっ！/😲|びっくり！'],
    'きく': ['', '', '', '📻|ラジオが ながれる/👂|おんがくを きく'],
    'かなしい': ['', '', '', '🧸|おもちゃが こわれた/😢|かなしい…'],
    'なく': ['', '', '', '😢|えーん/💧|なみだが でる'],
    'あんしん': ['', '', '', '😰|しんぱい…/🔍|みつかった！/😌|あんしん'],
    'かえる': ['', '', '', '🏫|がっこう おわり/🏠|いえに かえる'],
    'しんぱい': ['', '', '', '☔|あしたの えんそく はれるかな/😟|しんぱい…'],
    'ねる': ['', '', '', '🌙|よるに なった/😴|ぐうぐう ねる'],
    'はずかしい': ['', '', '', '🙋|みんなの まえで はっぴょう/😳|はずかしい…'],
    'わらう': ['', '', '', '🤣|あはは！/😄|にこにこ わらう'],
    'かんしゃ': ['', '', '', '🎒|おかあさん ありがとう/🙏|かんしゃ'],
    'つたえる': ['', '', '', '😊|すきだよ/💌|てがみで つたえる'],
    'がっかり': ['', '', '', '🎡|あそびに いけない…/😞|がっかり'],
    'なる': ['', '', '', '🌱|たね/🌻|はなに なる'],
    'まよう': ['どう しようか きめられない。', 'Not being able to decide.', 'Phân vân, không quyết định được.', '🍦|どっちに しよう？/🤔|まよう…'],
    'えらぶ': ['', '', '', '👕|どっち？/👆|これに きめた！'],
    'いそぐ': ['', '', '', '⏰|ちこくだ！/🏃|いそげ！'],
    'はしる': ['', '', '', '🏃|よーい どん！/💨|はしる'],
    'まつ': ['', '', '', '🚌|バスは まだかな/🙂|まつ'],
    'ほめる': ['いいね、すごいね と いう。', 'To praise someone.', 'Khen ngợi người khác.', '🎨|えを かいた/👏|じょうず！ たたえる'],
    'もうしわけない': ['', '', '', '🏺|コップを わった/🙇|ごめんなさい'],
    'かんちがい': ['', '', '', '👀|あれ？ ともだちだ/🙄|ちがう人だった'],
    'うしろめたい': ['', '', '', '🍪|ないしょで たべた/😓|わるいことを した…'],
    'こまる': ['', '', '', '🔑|かぎが ない！/😰|どうしよう… こまった'],
    'やくそく': ['', '', '', '🤝|ゆびきり げんまん/📅|あした あそぼうね'],
    'ともだち': ['', '', '', '👦|いっしょに あそぼう/👧|うん！/😄|ともだち'],
    'きまりが わるい': ['', '', '', '🙋|なまえを まちがえた/😅|あちゃ… きまりが わるい'],
    'パーティー': ['', '', '', '🎂|ケーキだ！/🎉|みんなで パーティー'],
    'はらが たつ': ['', '', '', '🧸|おもちゃを とられた/😠|はらが たつ！'],
    'たいせつな': ['とても だいじに おもう。', 'Something you value very much.', 'Rất quan trọng, rất trân trọng.', '💎|わたしの たからもの/🤗|だいじに する'],
    'たからもの': ['', '', '', '💎|ピカピカ/🎁|わたしの たからもの'],
    'ふまん': ['', '', '', '🍰|ぼくの ケーキだけ ちいさい/😠|ふまん！'],
    'うわさ': ['', '', '', '🗣|〜さんがね…/👂|うわさが ひろがる'],
    'おそろしい': ['おそろしくて、ぞっと する。', 'Scary; it makes you shiver.', 'Đáng sợ, làm người ta run lên.', '👻|ばあっ！/😱|こわい！'],
    'きもだめし': ['', '', '', '🌙|よるの もり/🔦|きもだめし ドキドキ'],
    'こころぼそい': ['', '', '', '🌃|ひとりで るすばん/😟|こころぼそい'],
    'はじめて': ['', '', '', '🚌|はじめての ひとりバス/✨|はじめて！'],
    'なつかしい': ['', '', '', '📷|むかしの しゃしん/😌|なつかしいなあ'],
    'しゃしん': ['', '', '', '📸|はい、チーズ！/🌄|しゃしんが できた'],
    'はげましたい': ['', '', '', '😢|しっぱい…/💪|がんばれ！'],
    'おとうと': ['', '', '', '👦|ぼく/👶|おとうと'],
    'こんらん': ['', '', '', '🌀|あたまが ぐるぐる/😵|こんらん'],
    'せつめい': ['', '', '', '📖|ここは こう だよ/💡|なるほど！'],
    'かう': ['', '', '', '🛒|おみせに いく/💰|おかねを はらって かう'],
    'うそ': ['', '', '', '🙊|ほんとうは…/😬|うそを ついた'],
    'ふしぎ': ['', '', '', '❓|なんで？/🌈|ふしぎ！'],
    'かいがい': ['', '', '', '🛫|ひこうきで/🌍|かいがいへ'],
    'はこ': ['', '', '', '📦|おおきな はこ/🎁|なかには なにが？'],
    'ざんねん': ['', '', '', '🎡|あそびに いけない…/😞|ざんねん！'],
    'あっというま': ['', '', '', '🎉|たのしい じかん/⚡|あっというまに おわった！'],
    'かわいそう': ['', '', '', '🌧|あめに ぬれた こねこ/😢|かわいそう…'],
    'かぜ': ['', '', '', '🤒|ねつが でた/🤧|かぜを ひいた'],
    'かんしんする': ['', '', '', '🧒|ひとりで できた！/👏|すごいなあ！ かんしん'],
    '手つだい': ['', '', '', '🧹|そうじを 手つだう/😊|ありがとう！'],
    'いとおしい': ['', '', '', '👶|ねむる あかちゃん/🥰|いとおしい…'],
    'あかちゃん': ['', '', '', '🍼|ミルクを のむ/👶|あかちゃん'],
    'じまんする': ['', '', '', '🏆|一とうを とった！/😎|みんなに じまんする'],
    'あてる': ['', '', '', '❓|クイズ！/🎯|ピタリと あてた！'],
    'しっぱい': ['', '', '', '🎤|はっぴょうで まちがえた/😖|しっぱい…'],
    'みつかる': ['', '', '', '🔍|さいふが ない…/👛|みつかった！'],
    'はながたかい': ['じぶんの ことが じまんで、とくいな きもち。', 'Feeling proud and pleased about yourself.', 'Cảm thấy tự hào, hãnh diện.', '💯|ひゃくてん！/😤|えっへん！ ほこらしい'],
    'ほこらしい': ['じぶんの ことが じまんで、とくいな きもち。', 'Feeling proud and pleased about yourself.', 'Cảm thấy tự hào, hãnh diện.', '💯|ひゃくてん！/😤|えっへん！ ほこらしい'],
    'あぜんとする': ['おもいがけない ことで、ことばも でなくなる。', 'So surprised or fed up that you cannot say a word.', 'Quá bất ngờ hoặc chán ngán đến nỗi không nói nên lời.', '🍦|ぽとっ…/😑|あきれた…'],
    'あきれる': ['おもいがけない ことで、ことばも でなくなる。', 'So surprised or fed up that you cannot say a word.', 'Quá bất ngờ hoặc chán ngán đến nỗi không nói nên lời.', '🍦|ぽとっ…/😑|あきれた…'],
    'うやまう': ['えらいなあと おもって、たいせつに する。', 'To respect someone and treat them with care.', 'Kính trọng, coi trọng người giỏi hơn mình.', '👴|すごい せんせい！/🙇|そんけい します'],
    'そんけいする': ['えらいなあと おもって、たいせつに する。', 'To respect someone and treat them with care.', 'Kính trọng, coi trọng người giỏi hơn mình.', '👴|すごい せんせい！/🙇|そんけい します'],
    'しゃがむ': ['ひざを まげて、こしを ひくく する。', 'To bend your knees and lower your body.', 'Gập đầu gối, hạ thấp người xuống.', '🐜|あ、ありが いる！/🧎|しゃがむ'],
    'かがむ': ['ひざを まげて、こしを ひくく する。', 'To bend your knees and lower your body.', 'Gập đầu gối, hạ thấp người xuống.', '🐜|あ、ありが いる！/🧎|しゃがむ'],
    'すぐれる': ['ほかより よい。ちからが うえ。', 'To be better than others.', 'Giỏi hơn, vượt trội hơn người khác.', '🏃|よーい どん！/🥇|いちばん！ すぐれている'],
    'まさる': ['ほかより よい。ちからが うえ。', 'To be better than others.', 'Giỏi hơn, vượt trội hơn người khác.', '🏃|よーい どん！/🥇|いちばん！ すぐれている'],
    'びっくりする': ['おもわない ことで、はっと する。', 'To be startled by something unexpected.', 'Giật mình vì điều bất ngờ.', '🎁|ぱかっ！/😲|びっくり！'],
    'だいじな': ['とても だいじに おもう。', 'Something you value very much.', 'Rất quan trọng, rất trân trọng.', '💎|わたしの たからもの/🤗|だいじに する'],
    'こわい': ['おそろしくて、ぞっと する。', 'Scary; it makes you shiver.', 'Đáng sợ, làm người ta run lên.', '👻|ばあっ！/😱|こわい！'],
    'すぐに': ['じかんを おかず、すぐ。', 'Right away, without waiting.', 'Ngay lập tức, không chần chừ.', '🔔|チャイムが なった/🏃|ただちに！'],
    'ただちに': ['じかんを おかず、すぐ。', 'Right away, without waiting.', 'Ngay lập tức, không chần chừ.', '🔔|チャイムが なった/🏃|ただちに！'],
    'たたえる': ['いいね、すごいね と いう。', 'To praise someone.', 'Khen ngợi người khác.', '🎨|えを かいた/👏|じょうず！ たたえる'],
    'じょうず': ['うまく できる こと。', 'Being good at something.', 'Làm giỏi, làm khéo.', '🎹|ピアノを ひく/👏|じょうず！ うまい！'],
    'うまい': ['うまく できる こと。', 'Being good at something.', 'Làm giỏi, làm khéo.', '🎹|ピアノを ひく/👏|じょうず！ うまい！'],
    'きれいな': ['見て いい きもちに なる。', 'Beautiful to look at.', 'Đẹp, nhìn thấy dễ chịu.', '🌸|さくらが さいた/✨|うつくしい'],
    'うつくしい': ['見て いい きもちに なる。', 'Beautiful to look at.', 'Đẹp, nhìn thấy dễ chịu.', '🌸|さくらが さいた/✨|うつくしい'],
    'つかれる': ['からだや こころが つかれる。', 'To get tired.', 'Mệt mỏi.', '🏃|いっぱい はしった/😩|くたくた…'],
    'くたびれる': ['からだや こころが つかれる。', 'To get tired.', 'Mệt mỏi.', '🏃|いっぱい はしった/😩|くたくた…'],
    'ゆっくり': ['いそがずに ゆったり。', 'Slowly, without hurrying.', 'Thong thả, không vội.', '🐢|いそがない/☕|のんびり'],
    'のんびり': ['いそがずに、ゆったり すごす ようす。', 'Relaxed, without hurrying.', 'Thong thả, thoải mái, không vội.', '🐢|いそがない/☕|のんびり'],
    'ねがう': ['こう なって ほしいと おもう。', 'To wish for something.', 'Mong muốn điều gì đó trở thành sự thật.', '🌠|ながれぼし！/🙏|ねがいごと'],
    'のぞむ': ['こう なって ほしいと おもう。', 'To wish for something.', 'Mong muốn điều gì đó trở thành sự thật.', '🌠|ながれぼし！/🙏|ねがいごと'],
    'ためらう': ['どう しようか きめられない。', 'Not being able to decide.', 'Phân vân, không quyết định được.', '🍦|どっちに しよう？/🤔|まよう…'],
    'つかまえる': ['にげないように おさえる。', 'To catch something.', 'Bắt lấy, bắt được.', '🦋|ちょうちょ！/🙌|つかまえた！'],
    'とらえる': ['にげないように おさえる。', 'To catch something.', 'Bắt lấy, bắt được.', '🦋|ちょうちょ！/🙌|つかまえた！'],
    'あわてる': ['きゅうな ことで おちつけなくなる。', 'To panic when something sudden happens.', 'Cuống lên, mất bình tĩnh khi có chuyện đột ngột.', '⏰|ねぼうした！/😵|あわあわ！'],
    'うろたえる': ['きゅうな ことで おちつけなくなる。', 'To panic when something sudden happens.', 'Cuống lên, mất bình tĩnh khi có chuyện đột ngột.', '⏰|ねぼうした！/😵|あわあわ！'],
    'なおす': ['こわれた ものを もとに もどす。', 'To fix something broken.', 'Sửa đồ hỏng cho như cũ.', '🔧|こわれた じてんしゃ/🚲|なおった！'],
    'しゅうりする': ['こわれた ものを もとに もどす。', 'To fix something broken.', 'Sửa đồ hỏng cho như cũ.', '🔧|こわれた じてんしゃ/🚲|なおった！'],
    'けしき': ['見える ふうけい。', 'The view you can see.', 'Phong cảnh, cảnh vật nhìn thấy.', '🌄|やまの うえ/👀|いい ながめ！'],
    'ながめ': ['見える ふうけい。', 'The view you can see.', 'Phong cảnh, cảnh vật nhìn thấy.', '🌄|やまの うえ/👀|いい ながめ！'],
    'むねをうつ': ['こころが ふかく うごく。', 'To be deeply moved.', 'Xúc động sâu sắc.', '🎻|すてきな えんそう/😭|じーん… かんどう'],
    'かんどうする': ['こころが ふかく うごく。', 'To be deeply moved.', 'Xúc động sâu sắc.', '🎻|すてきな えんそう/😭|じーん… かんどう'],
    'すずしい': ['ここちよく ひんやり している。', 'Pleasantly cool.', 'Mát mẻ dễ chịu.', '🌬️|かぜが ふく/😊|すずしい〜'],
    'つめたい': ['ふれると ひえていて さむい。', 'Cold to the touch.', 'Lạnh khi chạm vào.', '🧊|こおりを さわる/🥶|つめたい！'],
    'あつい': ['おゆや ひなど おんどが たかい（熱い）。きおんが たかい（暑い）。ものの あつみが ある（厚い）。', 'Hot (熱い/暑い), or thick (厚い), depending on the kanji.', 'Nóng (熱い/暑い) hoặc dày (厚い) tùy theo chữ Hán.', '☕|おゆを のむ/🥵|あつい！'],
    'とおい': ['はなれていて ちかくない。', 'Far away.', 'Xa.', '🏠|いえ/🏫|がっこうは とおい…'],
    'ふかい': ['うえから そこまで ながい。', 'Deep.', 'Sâu.', '🏊|プールで/🌊|あしが つかない！ ふかい'],
    'ひろい': ['ひろさが 大きい。', 'Wide; spacious.', 'Rộng.', '🏟️|ひろい グラウンド/🏃|たくさん はしれる'],
    'はげしい': ['いきおいが とても つよい。あめや かぜに つかう。', 'Intense; heavy (rain, wind).', 'Dữ dội, mạnh (mưa, gió).', '⛈️|あめが ザーザー/☔|はげしい あめ'],
    '大きい': ['かたちや 大きさが 大きい。「あめ」には あまり つかわない。', 'Big. Not usually used for rain.', 'To, lớn. Thường không dùng cho mưa.', '🐘|ぞうは/📏|大きい'],
    'ふとい': ['まわりが 大きい。ほそいの はんたい。', 'Thick (around); fat.', 'Dày/to bề ngang (ngược với ほそい).', '🪢|ふとい ロープ/💪|ふとい うで'],
    'きびしい': ['ゆるさず つよく しつける。ようすが つらい。', 'Strict; harsh.', 'Nghiêm khắc; khắc nghiệt.', '📚|せんせいは きびしい/😰|ちゃんと しよう…'],
    'きつい': ['ぴったりで ゆとりが ない。つらい。', 'Tight; tough.', 'Chật; vất vả.', '👖|ズボンが きつい/😣|はけない…'],
    'たくましい': ['からだが つよくて がっしり している。', 'Sturdy; strong and robust.', 'Vạm vỡ, khỏe mạnh.', '🏋️|スポーツせん手/💪|たくましい！'],
    'あらい': ['あなが 大きい。ざつな ようす。', 'Coarse; wide-meshed.', 'Thô; mắt lưới to.', '🧺|ざるの 目が 大きい/💧|あらい ざるは こまかい ものが おちる'],
    'ほそい': ['まわりが ちいさい。はばが せまい。', 'Thin; narrow.', 'Mảnh, hẹp.', '🍜|ほそい めん/📏|ほそい'],
    'みじかい': ['ながさが ちいさい。', 'Short.', 'Ngắn.', '✂️|かみを きる/😊|みじかい'],
    'にぶい': ['するどく ない。うごきや かんじ方が のろい。', 'Dull; slow.', 'Cùn; chậm chạp.', '🔪|きれない ナイフ/😮|にぶい…'],
    'するどい': ['さきが とがっている。あたまの はたらきが はやい。', 'Sharp; quick-witted.', 'Sắc bén; nhạy bén.', '💡|ヒントを きいて/🎯|すぐ わかる！ するどい'],
    'ゆるい': ['しまりが ない。きつくない。', 'Loose; lenient.', 'Lỏng lẻo.', '👟|くつひもが/😵|ゆるい…'],
    'くらい': ['ひかりが ない。', 'Dark.', 'Tối.', '🌑|よる/🔦|くらい へや'],
    'うすい': ['あつみや あじ・いろが こくない。', 'Thin; weak (taste or color).', 'Mỏng; nhạt.', '🍲|しおが たりない/😕|あじが うすい'],
    'さっぱり': ['ぜんぜん。まったく。「さっぱり わからない」は ちっとも わからない こと。', 'Not at all. 「さっぱり わからない」 means I have no idea.', 'Hoàn toàn (không). 「さっぱり わからない」 là hoàn toàn không hiểu gì.', '📚|この もんだい…/🤔|さっぱり わからない！'],
    'ぎっしり': ['すきまなく、いっぱい つまっている ようす。', 'Packed tightly with no gaps.', 'Chật cứng, không còn kẽ hở.', '🎒|ランドセルに/📚|ぎっしり！'],
    'くっきり': ['ほかと ちがって、はっきり よく 見える ようす。', 'Clearly and sharply visible.', 'Nhìn thấy rất rõ nét.', '🌫|きりが はれた/🗻|ふじさんが くっきり！'],
    'こっそり': ['ひとに 見つからないように、しずかに する ようす。', 'Quietly, so that nobody notices.', 'Lén lút, nhẹ nhàng để người khác không biết.', '🤫|しーっ/🍪|こっそり たべる'],
    'めっきり': ['ようすが はっきり かわる ようす。きゅうに かわる こと。', 'Noticeably, suddenly changing.', 'Thay đổi rõ rệt, đột ngột.', '🍂|あきに なって/🥶|めっきり さむく なった'],
    'ゆくゆく': ['これから さき。しょうらい。「ゆくゆくは」で つかう。', 'In the future; someday. Used as 「ゆくゆくは」.', 'Về sau, trong tương lai. Hay dùng dạng 「ゆくゆくは」.', '🌱|いまは ちいさな たね/🌳|ゆくゆくは おおきな き！'],
    'はるばる': ['とおいところから、わざわざ。', 'Coming all the way from far away, taking the trouble.', 'Từ nơi xa đến, mất công đến tận nơi.', '🛫|とおい くにから/🎁|はるばる やってきた！'],
    'ぐっすり': ['ふかく、よく ねむる ようす。', 'Sleeping deeply and soundly.', 'Ngủ say, ngủ sâu giấc.', '🌙|つかれた…/😴|ぐっすり'],
    'うっかり': ['ぼんやりして、つい まちがえる ようす。', 'Absent-mindedly making a mistake.', 'Lơ đãng nên lỡ làm sai.', '🎒|あっ！ わすれもの/😅|うっかり！'],
    'すっかり': ['ぜんぶ。すべて。かんぜんに。', 'Completely; all the way.', 'Hoàn toàn, tất cả.', '🤒|かぜを ひいた/😄|すっかり なおった！'],
    'しっかり': ['ちからを いれて、たしかに。', 'Firmly and surely.', 'Chắc chắn, vững vàng, dùng sức.', '🤝|ぎゅっ/💪|しっかり にぎる'],
    'なかなか': ['かんたんには ならない。「なかなか 〜ない」は、なかなか できない という いみ。', 'Not easily. 「なかなか 〜ない」 means it is hard to do.', 'Mãi mà (không). 「なかなか 〜ない」 là mãi mà không, không dễ gì.', '🔎|あれ？ 本が ない…/😟|なかなか 見つからない'],
    'さっそうと': ['すがたが かっこよく、いきおいが ある ようす。', 'Looking cool and full of energy.', 'Phong thái oai hùng, đầy khí thế.', '🌬|かぜを きって/😎|さっそうと あらわれる！'],
    'みるみる': ['見ている うちに、どんどん かわる ようす。', 'Changing quickly right before your eyes.', 'Thay đổi nhanh ngay trước mắt.', '🌱|め が でた！/🌳|みるみる のびる！'],
    '一目さんに': ['ほかの ことは かんがえず、ぜんりょくで はしって にげる ようす。', 'Running away as fast as possible.', 'Chạy hết tốc lực, chạy trốn thật nhanh.', '🐕|ワンワン！/💨|一目さんに にげる！'],
    'まじまじと': ['じっと よく 見る ようす。', 'Staring closely.', 'Nhìn chăm chú, nhìn kỹ.', '👀|じーっ/🔍|まじまじと 見る'],
    'もっとも': ['いちばん。いちばん ~ な こと。', 'The most; number one.', 'Nhất, số một.', '🍎|りんご/🥇|もっとも すき！'],
    'まだ': ['ときが きても、そう なっていない ようす。', 'Still; not yet.', 'Vẫn còn, chưa.', '🏃|はしって いる…/🏁|まだ ついて いない'],
    'もう': ['すでに おわっている ようす。', 'Already.', 'Đã rồi.', '✅|しゅくだい できた/😊|もう おわった！'],
    'なぜなら': ['りゆうを いう とき。「なぜなら 〜からだ」', 'Used to give a reason: 「なぜなら 〜からだ」 (because...).', 'Dùng để nêu lý do: 「なぜなら 〜からだ」 (bởi vì...).', '💯|ひゃくてん！/📝|なぜなら、がんばって べんきょうしたから'],
    'それとも': ['どちらか 一つを えらぶ とき。', 'Used to choose one of two things (or).', 'Dùng khi chọn một trong hai (hay là).', '🍎|りんご？/🍌|それとも バナナ？'],
    'または': ['どちらか 一つ。「AまたはB」', 'Either one: 「A または B」.', 'Hoặc: 「A または B」.', '🍵|おちゃ/🥤|または ジュース'],
    'だから': ['まえの ことが りゆうで、あとの ことが おこる。', 'So; the first thing causes the second.', 'Vì vậy; việc trước là lý do dẫn đến việc sau.', '☔|あめが ふってきた/🌂|だから かさを さした'],
    'それで': ['まえの ことが りゆうで、あとの ことが おこる。', 'So; because of that.', 'Vì thế; do chuyện đó nên...', '🤒|ねつが あった/🏠|それで やすんだ'],
    'けれども': ['まえと はんたいの ことを いう とき。', 'But; says something opposite to what came before.', 'Nhưng; nói điều trái ngược với trước đó.', '🏃|いっしょうけんめい はしった/😢|けれども まけた'],
    'しかし': ['まえと はんたいの ことを いう とき。', 'However; says something opposite to what came before.', 'Tuy nhiên; nói điều trái ngược với trước đó.', '😋|おいしそう！/🔥|しかし、とても からい！'],
    'でも': ['まえと はんたいの ことを いう とき。', 'But; says something opposite to what came before.', 'Nhưng; nói điều trái ngược với trước đó.', '🎮|あそびたい！/📚|でも、しゅくだいが さき'],
    'ところが': ['おもっていた こととは ちがう ことが おこる とき。', 'But then; something unexpected happens.', 'Thế mà; xảy ra điều khác với dự đoán.', '🌞|はれる と おもった/☔|ところが、あめ！'],
    'そして': ['つぎの ことを つけくわえる。', 'And then; adds the next thing.', 'Và rồi; thêm vào việc tiếp theo.', '🌅|あさ おきて/🍞|そして ごはんを たべる'],
    'そのうえ': ['まえの ことに、あとの ことを つけくわえる とき。', 'Besides; adds one more thing to what came before.', 'Hơn nữa; thêm một điều nữa vào điều trước.', '🍞|この パンは おいしい/💰|そのうえ やすい！'],
    'しかも': ['まえの ことに、さらに ことを くわえる とき。', 'Moreover; piles one more point on top.', 'Hơn nữa; chồng thêm một điều.', '🎤|うたが うまい/🎹|しかも ピアノも ひける'],
    'さらに': ['そのうえに もっと くわえる とき。', 'Furthermore; even more.', 'Hơn nữa; thêm nữa.', '🌧️|あめが ふる/🌬️|さらに かぜも つよい'],
    'それに': ['まえの ことに、あとの ことを つけくわえる とき。', 'Besides; also.', 'Thêm vào đó.', '🐶|かわいい/🐾|それに かしこい'],
    'すると': ['まえの ことの あとに、つぎの ことが おこる とき。', 'Then; and then something happened.', 'Thế là; sau đó thì...', '🚪|ドアを あけた/🐱|すると ねこが とびだした'],
    'そこで': ['まえの ことを うけて、つぎの こうどうを する とき。', 'So; then (acting on what came before).', 'Vì vậy; thế là (làm việc tiếp theo).', '🔑|かぎが 見つからない/🔍|そこで さがした'],
    'したがって': ['まえの ことが りゆうで、けつろんに なる とき。', 'Therefore.', 'Do đó.', '🌱|みずを あげた/🌻|したがって はなが さいた'],
    'だけど': ['まえと はんたいの ことを いう とき。（ふだんの ことば）', 'But (casual).', 'Nhưng (văn nói).', '🍰|たべたい！/😅|だけど ダイエットちゅう'],
    'だが': ['まえと はんたいの ことを いう とき。（かたい ことば）', 'But; however (formal).', 'Nhưng (văn viết).', '🏃|はしった/😢|だが まにあわなかった'],
    'それから': ['まえの ことの あとに つづく。', 'After that.', 'Sau đó.', '🍽|ごはんを たべた/🦷|それから はを みがく'],
    'i:あたまがかたい': ['', 'Not flexible; does not listen to other ideas.', 'Đầu óc cứng nhắc, không chịu nghe ý kiến khác.', '🧱|ひとの いけんを きかない/😤|あたまが かたい！'],
    'i:あしがぼうになる': ['', 'Your legs get very tired from walking or standing a long time.', 'Chân mỏi nhừ vì đi bộ hoặc đứng quá lâu.', '🚶|ずっと あるいた/🦵|あしが ぼうに！'],
    'i:くちがすべる': ['', 'To say something you should not say by accident.', 'Lỡ miệng nói ra điều không nên nói.', '🤐|ひみつ なのに…/😱|あっ いっちゃった！'],
    'i:てにあせをにぎる': ['', 'To feel nervous while watching something.', 'Hồi hộp, lo lắng khi theo dõi điều gì.', '🏃|リレーの さいご！/😰|てに あせ…'],
    'i:みみをうたがう': ['', 'To be unable to believe what you hear.', 'Không tin nổi vào tai mình.', '📢|ええっ！？/😳|みみを うたがう'],
    'i:めをまるくする': ['', 'To open your eyes wide in surprise.', 'Mở tròn mắt vì ngạc nhiên.', '🎁|ぱかっ！/😲|めを まるくする'],
    'i:はながたかい': ['', 'To feel proud.', 'Tự hào, đắc ý.', '💯|ひゃくてん！/😤|はなが たかい'],
    'i:くびをながくする': ['', 'To wait eagerly for something.', 'Ngóng trông, mong chờ.', '📦|まだ かな？/🦒|くびを ながく して まつ'],
    'i:めがたかい': ['', 'To have a good eye for quality things.', 'Có con mắt tinh đời, biết nhìn đồ tốt.', '🖼|ほんもの かな？/🧐|めが たかい'],
    'i:みみがいたい': ['', 'It hurts to hear something unpleasant said to you.', 'Nghe điều khó chịu nói về mình thì thấy nhói tai.', '😠|しゅくだいは？/🙉|みみが いたい…'],
    'i:くちがかたい': ['', 'To keep secrets and never tell anyone.', 'Giữ bí mật, không nói với ai.', '🤫|ひみつだよ/🔒|くちが かたい'],
    'i:かおがひろい': ['', 'To know many people.', 'Quen biết nhiều người.', '👋|やあ！/👥|かおが ひろい'],
    'i:てがたりない': ['', 'There are not enough people to do the work.', 'Thiếu người làm việc.', '📦|にもつが いっぱい/🙋|てが たりない！'],
    'i:めがまわる': ['', 'To be extremely busy.', 'Bận rộn đến hoa cả mắt.', '🛒|おきゃくさんが いっぱい/😵|めが まわる！'],
    'i:はらがたつ': ['', 'To get angry.', 'Tức giận.', '😡|おもちゃを とられた/💢|はらが たつ'],
    'i:あたまがいたい': ['', 'To be troubled and worried.', 'Đau đầu, phiền não vì lo nghĩ.', '📝|むずかしい もんだい/🤕|あたまが いたい'],
    'i:くびをひねる': ['', 'To wonder; to feel puzzled.', 'Thắc mắc, băn khoăn.', '❓|どうして？/🤨|くびを ひねる'],
    'i:むねがおどる': ['', 'To feel excited and happy.', 'Phấn khích, vui sướng.', '🎪|あしたは えんそく！/💓|むねが おどる'],
    'i:かたをおとす': ['', 'To lose heart and feel down.', 'Thất vọng, chán nản.', '🏆|まけちゃった…/😞|かたを おとす'],
    'i:うでをみがく': ['', 'To practice to get better.', 'Rèn luyện để giỏi hơn.', '🎹|まいにち れんしゅう/🌟|うでを みがく'],
  };

  static bool has(String key) => _d.containsKey(key);

  static List<ComicPanel> panels(String key) {
    final d = _d[key];
    if (d == null || d[3].isEmpty) return const [];
    return [
      for (final p in d[3].split('/'))
        ComicPanel(p.split('|')[0], p.split('|')[1]),
    ];
  }

  // Nghia theo ngon ngu; fallback: bunMeaning, roi nghia ja do bai hoc cung cap
  static String meaning(String key, String lang, {String ja = ''}) {
    final d = _d[key];
    final i = lang == 'en' ? 1 : (lang == 'vi' ? 2 : 0);
    if (d != null && d[i].isNotEmpty) return d[i];
    final b = KokugoEngine.bunMeaning(key, lang);
    if (b.isNotEmpty) return b;
    if (d != null && d[0].isNotEmpty) return d[0];
    return ja;
  }

  static List<String> get allKeys => _d.keys.toList();
}
