import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

String formatSeconds(int sec) {
  final m = (sec ~/ 60).toString().padLeft(2, '0');
  final s = (sec % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

class TimeResult {
  final int seconds;
  final int? previousBest; // null neu day la lan dau
  final bool isNewBest;
  const TimeResult(this.seconds, this.previousBest, this.isNewBest);
}

// Ghi lai thoi gian tu luc mo bai den luc tra loi dung; luu thoi gian tot nhat cua tung bai.
class TimeRecord {
  static DateTime? _start;
  static String? _lessonId;

  static void begin(String? lessonId) {
    _start = DateTime.now();
    _lessonId = lessonId;
  }

  // Goi mot lan khi bai xong. Tra ve null neu khong co dong ho.
  static Future<TimeResult?> finish() async {
    final st = _start;
    final id = _lessonId;
    _start = null;
    _lessonId = null;
    if (st == null) return null;
    final sec = DateTime.now().difference(st).inSeconds;
    if (id == null) return TimeResult(sec, null, false);
    int? prev;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('best_times');
      final map = raw == null ? <String, dynamic>{} : Map<String, dynamic>.from(jsonDecode(raw) as Map);
      prev = map[id] as int?;
      final isBest = prev == null || sec < prev;
      if (isBest) {
        map[id] = sec;
        await prefs.setString('best_times', jsonEncode(map));
      }
      return TimeResult(sec, prev, isBest);
    } catch (_) {
      return TimeResult(sec, prev, false);
    }
  }
}

// Dong ho dem thoi gian tu luc mo bai. Dung lai khi roi man hinh (vd. sang man hinh thuong).
class ElapsedTimer extends StatefulWidget {
  final String? lessonId;
  const ElapsedTimer({super.key, this.lessonId});

  @override
  State<ElapsedTimer> createState() => _ElapsedTimerState();
}

class _ElapsedTimerState extends State<ElapsedTimer> {
  final DateTime _start = DateTime.now();
  Timer? _timer;
  int _sec = 0;

  @override
  void initState() {
    super.initState();
    TimeRecord.begin(widget.lessonId);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _sec = DateTime.now().difference(_start).inSeconds);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.timer, color: Colors.white, size: 16),
          const SizedBox(width: 3),
          Text(formatSeconds(_sec),
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ]),
      ),
    );
  }
}
