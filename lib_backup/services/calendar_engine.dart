import 'dart:math';
import '../models/calendar_lesson.dart';

class CalendarEngine {
  static const List<int> baseMonthDays = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  static const List<String> weekNames = ['月', '火', '水', '木', '金', '土', '日'];

  // year == 0 nghia la dung quy uoc nam khong nhuan (bai mau tu sach)
  static bool isLeap(int year) =>
      year != 0 && ((year % 4 == 0 && year % 100 != 0) || year % 400 == 0);

  static int dim(int month, int year) =>
      (month == 2 && isLeap(year)) ? 29 : baseMonthDays[month - 1];

  static int yearLength(int year) => isLeap(year) ? 366 : 365;

  static int toIndex(int month, int day, [int year = 0]) {
    int s = 0;
    for (int m = 1; m < month; m++) {
      s += dim(m, year);
    }
    return s + day - 1;
  }

  static List<int> fromIndex(int idx, [int year = 0]) {
    final total = yearLength(year);
    int i = ((idx % total) + total) % total;
    int m = 1;
    while (i >= dim(m, year)) {
      i -= dim(m, year);
      m++;
    }
    return [m, i + 1];
  }

  static int weekdayAfter(int weekday, int n) => (((weekday + n) % 7) + 7) % 7;

  static List<String> slots(CalendarQuestion q) {
    switch (q.type) {
      case 'span':
        return ['n'];
      case 'afterMonth':
      case 'beforeMonth':
        return ['m', 'd', 'w'];
      default:
        return ['d', 'w'];
    }
  }

  static List<int> answer(CalendarQuestion q) {
    final y = q.year;
    final base = toIndex(q.month, q.day, y);
    switch (q.type) {
      case 'span':
        final diff = toIndex(q.month2, q.day2, y) - base;
        return [diff + 1];
      case 'before':
        final t = fromIndex(base - q.amount, y);
        return [t[1], weekdayAfter(q.weekday, -q.amount)];
      case 'beforeMonth':
        final t = fromIndex(base - q.amount, y);
        return [t[0], t[1], weekdayAfter(q.weekday, -q.amount)];
      case 'afterMonth':
        final t = fromIndex(base + q.amount, y);
        return [t[0], t[1], weekdayAfter(q.weekday, q.amount)];
      default:
        final t = fromIndex(base + q.amount, y);
        return [t[1], weekdayAfter(q.weekday, q.amount)];
    }
  }

  static String wk(int w) => weekNames[w];

  static String yearNote(int year, String lang) {
    if (year == 0) return '';
    final leap = isLeap(year);
    if (lang == 'ja') {
      return leap
          ? '（$year年は うるう年です。2月は 29日まで）'
          : '（$year年は うるう年では ありません。2月は 28日まで）';
    }
    if (lang == 'en') {
      return leap
          ? '(Year $year is a leap year. February has 29 days)'
          : '(Year $year is not a leap year. February has 28 days)';
    }
    return leap
        ? '(Năm $year là năm nhuận. Tháng 2 có 29 ngày)'
        : '(Năm $year không phải năm nhuận. Tháng 2 có 28 ngày)';
  }

  static String text(CalendarQuestion q, String lang) {
    String amt(int n) {
      if (n % 7 == 0 && n >= 7) {
        final w = n ~/ 7;
        return lang == 'ja' ? '$wしゅうかん' : lang == 'en' ? '$w week(s)' : '$w tuần';
      }
      return lang == 'ja' ? '$n日' : lang == 'en' ? '$n day(s)' : '$n ngày';
    }

    final y = q.year == 0 ? '' : '${q.year}年 ';
    final start = '$y${q.month}月${q.day}日 ${wk(q.weekday)}よう日';
    final yEn = q.year == 0 ? '' : '${q.year} ';
    switch (q.type) {
      case 'span':
        if (lang == 'ja') {
          return '$y${q.month}月${q.day}日から ${q.month2}月${q.day2}日まで 何日間？';
        }
        return lang == 'en'
            ? 'How many days from $yEn${q.month}/${q.day} to ${q.month2}/${q.day2}? (count both the first and last day)'
            : 'Từ ngày ${q.day}/${q.month} đến ngày ${q.day2}/${q.month2} là mấy ngày? (tính cả ngày đầu và ngày cuối)';
      case 'before':
      case 'beforeMonth':
        return lang == 'ja'
            ? '$start の ${amt(q.amount)}まえは'
            : lang == 'en'
                ? '${amt(q.amount)} before $yEn${q.month}/${q.day} (${wk(q.weekday)}) is'
                : '${amt(q.amount)} trước ngày ${q.day}/${q.month} (${wk(q.weekday)}) là';
      default:
        return lang == 'ja'
            ? '$start の ${amt(q.amount)}ごは'
            : lang == 'en'
                ? '${amt(q.amount)} after $yEn${q.month}/${q.day} (${wk(q.weekday)}) is'
                : '${amt(q.amount)} sau ngày ${q.day}/${q.month} (${wk(q.weekday)}) là';
    }
  }

  static CalendarQuestion? _tryQuestion(Random rng, int level, int year) {
    final types = level == 1
        ? ['after', 'before']
        : level == 2
            ? ['after', 'before', 'span']
            : ['after', 'before', 'afterMonth', 'beforeMonth', 'span'];
    final type = types[rng.nextInt(types.length)];
    final maxN = level == 1 ? 7 : (level == 2 ? 14 : 20);
    final month = 1 + rng.nextInt(12);
    final weekday = rng.nextInt(7);
    final d = dim(month, year);
    final total = yearLength(year);

    if (type == 'span') {
      final day = 1 + rng.nextInt(d);
      final idx = toIndex(month, day, year);
      final len = 3 + rng.nextInt(maxN);
      if (idx + len >= total) return null;
      final end = fromIndex(idx + len, year);
      return CalendarQuestion(
        type: 'span',
        year: year,
        month: month,
        day: day,
        weekday: weekday,
        month2: end[0],
        day2: end[1],
        inclusive: rng.nextBool(),
      );
    }

    if (type == 'afterMonth' || type == 'beforeMonth') {
      final amount = 3 + rng.nextInt(maxN);
      if (type == 'afterMonth') {
        final day = max(1, d - rng.nextInt(min(amount, d - 1)));
        if (toIndex(month, day, year) + amount >= total) return null;
        final t = fromIndex(toIndex(month, day, year) + amount, year);
        if (t[0] == month) return null;
        return CalendarQuestion(
            type: 'afterMonth', year: year, month: month, day: day, weekday: weekday, amount: amount);
      } else {
        final day = 1 + rng.nextInt(min(amount, d));
        if (toIndex(month, day, year) - amount < 0) return null;
        final t = fromIndex(toIndex(month, day, year) - amount, year);
        if (t[0] == month) return null;
        return CalendarQuestion(
            type: 'beforeMonth', year: year, month: month, day: day, weekday: weekday, amount: amount);
      }
    }

    final weekMode = level >= 2 && rng.nextInt(3) == 0;
    final amount = weekMode ? 7 * (1 + rng.nextInt(2)) : 1 + rng.nextInt(maxN);
    if (type == 'after') {
      final maxDay = d - amount;
      if (maxDay < 1) return null;
      final day = 1 + rng.nextInt(maxDay);
      return CalendarQuestion(
          type: 'after', year: year, month: month, day: day, weekday: weekday, amount: amount);
    } else {
      if (amount >= d) return null;
      final day = amount + 1 + rng.nextInt(d - amount);
      return CalendarQuestion(
          type: 'before', year: year, month: month, day: day, weekday: weekday, amount: amount);
    }
  }

  static CalendarQuestion randomQuestion(Random rng, int level, int year) {
    for (int i = 0; i < 200; i++) {
      final q = _tryQuestion(rng, level, year);
      if (q != null) return q;
    }
    return CalendarQuestion(type: 'after', year: year, month: 3, day: 5, weekday: 0, amount: 3);
  }

  // Nam ngau nhien tu 2000 den 2099, uu tien nhuan khoang 1/3 de tre gap
  static int randomYear(Random rng) {
    if (rng.nextInt(3) == 0) {
      int y;
      do {
        y = 2000 + rng.nextInt(100);
      } while (!isLeap(y));
      return y;
    }
    return 2000 + rng.nextInt(100);
  }

  static CalendarLesson generate({int? level}) {
    final rng = Random();
    final lv = level ?? (1 + rng.nextInt(3));
    final year = randomYear(rng);
    final count = 3 + rng.nextInt(2);
    final qs = List.generate(count, (_) => randomQuestion(rng, lv, year));
    return CalendarLesson(
      id: 'cal_${DateTime.now().millisecondsSinceEpoch}',
      title: {
        'ja': 'カレンダー じどう $year年',
        'en': 'Auto Calendar $year',
        'vi': 'Lịch tự động năm $year',
      },
      questions: qs,
      difficulty: lv,
      isAutoGenerated: true,
      year: year,
    );
  }
}

