import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lesson.dart';
import '../models/dice_lesson.dart';
import '../models/net_lesson.dart';
import '../models/mark_lesson.dart';
import '../models/hide_lesson.dart';
import '../models/pyramid_lesson.dart';
import '../models/calendar_lesson.dart';
import '../models/clock_lesson.dart';
import '../models/back_lesson.dart';
import '../models/pick_lesson.dart';
import '../models/half_lesson.dart';
import '../models/dotsquare_lesson.dart';
import '../models/stack_lesson.dart';
import '../models/kokugo_lesson.dart';
import '../models/view_lesson.dart';

class ProgressService extends ChangeNotifier {
  final Map<String, int> _completed = {};
  final List<Lesson> _generated = [];
  final List<DiceLesson> _generatedDice = [];
  final List<NetLesson> _generatedNets = [];
  final List<MarkLesson> _generatedMarks = [];
  final List<HideLesson> _generatedHides = [];
  final List<PyramidLesson> _generatedPyramids = [];
  final List<CalendarLesson> _generatedCalendars = [];
  final List<ClockLesson> _generatedClocks = [];
  final List<BackLesson> _generatedBacks = [];
  final List<PickLesson> _generatedPicks = [];
  final List<HalfLesson> _generatedHalves = [];
  final List<DotSquareLesson> _generatedDotSquares = [];
  final List<StackLesson> _generatedStacks = [];
  final List<KokugoLesson> _generatedKokugo = [];
  final List<ViewLesson> _generatedViews = [];

  List<Lesson> get generated => List.unmodifiable(_generated);
  List<DiceLesson> get generatedDice => List.unmodifiable(_generatedDice);
  List<NetLesson> get generatedNets => List.unmodifiable(_generatedNets);
  List<MarkLesson> get generatedMarks => List.unmodifiable(_generatedMarks);
  List<HideLesson> get generatedHides => List.unmodifiable(_generatedHides);
  List<PyramidLesson> get generatedPyramids => List.unmodifiable(_generatedPyramids);
  List<CalendarLesson> get generatedCalendars => List.unmodifiable(_generatedCalendars);
  List<ClockLesson> get generatedClocks => List.unmodifiable(_generatedClocks);
  List<BackLesson> get generatedBacks => List.unmodifiable(_generatedBacks);
  List<PickLesson> get generatedPicks => List.unmodifiable(_generatedPicks);
  List<HalfLesson> get generatedHalves => List.unmodifiable(_generatedHalves);
  List<DotSquareLesson> get generatedDotSquares => List.unmodifiable(_generatedDotSquares);
  List<StackLesson> get generatedStacks => List.unmodifiable(_generatedStacks);
  List<KokugoLesson> get generatedKokugo => List.unmodifiable(_generatedKokugo);
  List<ViewLesson> get generatedViews => List.unmodifiable(_generatedViews);
  int completions(String lessonId) => _completed[lessonId] ?? 0;
  bool isDone(String lessonId) => completions(lessonId) > 0;

  ProgressService() {
    _load();
  }

  void _loadList<T>(SharedPreferences prefs, String key, List<T> target,
      T Function(Map<String, dynamic>) from) {
    final s = prefs.getString(key);
    if (s == null) return;
    try {
      for (final e in jsonDecode(s) as List) {
        target.add(from(Map<String, dynamic>.from(e as Map)));
      }
    } catch (_) {}
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final c = prefs.getString('completed_map');
    if (c != null) {
      final m = jsonDecode(c) as Map<String, dynamic>;
      m.forEach((k, v) => _completed[k] = v as int);
    }
    _loadList(prefs, 'generated_lessons', _generated, Lesson.fromJson);
    _loadList(prefs, 'generated_dice', _generatedDice, DiceLesson.fromJson);
    _loadList(prefs, 'generated_nets', _generatedNets, NetLesson.fromJson);
    _loadList(prefs, 'generated_marks', _generatedMarks, MarkLesson.fromJson);
    _loadList(prefs, 'generated_hides', _generatedHides, HideLesson.fromJson);
    _loadList(prefs, 'generated_backs', _generatedBacks, BackLesson.fromJson);
    _loadList(prefs, 'generated_picks', _generatedPicks, PickLesson.fromJson);
    _loadList(prefs, 'generated_halves', _generatedHalves, HalfLesson.fromJson);
    _loadList(prefs, 'generated_dotsquares', _generatedDotSquares, DotSquareLesson.fromJson);
    _loadList(prefs, 'generated_stacks', _generatedStacks, StackLesson.fromJson);
    _loadList(prefs, 'generated_kokugo', _generatedKokugo, KokugoLesson.fromJson);
    _loadList(prefs, 'generated_views', _generatedViews, ViewLesson.fromJson);
    _loadList(prefs, 'generated_pyramids', _generatedPyramids, PyramidLesson.fromJson);
    _loadList(prefs, 'generated_calendars', _generatedCalendars, CalendarLesson.fromJson);
    _loadList(prefs, 'generated_clocks', _generatedClocks, ClockLesson.fromJson);
    // du lieu cu co the co nhieu bai tu sinh: chi giu bai moi nhat
    void keepLast(List<dynamic> l) {
      if (l.length > 1) l.removeRange(0, l.length - 1);
    }
    for (final l in <List<dynamic>>[
      _generated, _generatedDice, _generatedNets, _generatedMarks, _generatedHides,
      _generatedBacks, _generatedPicks, _generatedHalves, _generatedDotSquares,
      _generatedPyramids, _generatedCalendars, _generatedClocks,
    ]) {
      keepLast(l);
    }
    final lastKokugo = <String, KokugoLesson>{};
    for (final e in _generatedKokugo) {
      lastKokugo[e.kind] = e;
    }
    _generatedKokugo
      ..clear()
      ..addAll(lastKokugo.values);
    final lastView = <String, ViewLesson>{};
    for (final e in _generatedViews) {
      lastView[e.kind] = e;
    }
    _generatedViews
      ..clear()
      ..addAll(lastView.values);
    final lastByKind = <String, StackLesson>{};
    for (final e in _generatedStacks) {
      lastByKind[e.kind] = e;
    }
    _generatedStacks
      ..clear()
      ..addAll(lastByKind.values);
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('completed_map', jsonEncode(_completed));
    await prefs.setString('generated_lessons', jsonEncode(_generated.map((l) => l.toJson()).toList()));
    await prefs.setString('generated_dice', jsonEncode(_generatedDice.map((l) => l.toJson()).toList()));
    await prefs.setString('generated_nets', jsonEncode(_generatedNets.map((l) => l.toJson()).toList()));
    await prefs.setString('generated_marks', jsonEncode(_generatedMarks.map((l) => l.toJson()).toList()));
    await prefs.setString('generated_hides', jsonEncode(_generatedHides.map((l) => l.toJson()).toList()));
    await prefs.setString('generated_backs', jsonEncode(_generatedBacks.map((l) => l.toJson()).toList()));
    await prefs.setString('generated_picks', jsonEncode(_generatedPicks.map((l) => l.toJson()).toList()));
    await prefs.setString('generated_halves', jsonEncode(_generatedHalves.map((l) => l.toJson()).toList()));
    await prefs.setString('generated_dotsquares', jsonEncode(_generatedDotSquares.map((l) => l.toJson()).toList()));
    await prefs.setString('generated_stacks', jsonEncode(_generatedStacks.map((l) => l.toJson()).toList()));
    await prefs.setString('generated_kokugo', jsonEncode(_generatedKokugo.map((l) => l.toJson()).toList()));
    await prefs.setString('generated_views', jsonEncode(_generatedViews.map((l) => l.toJson()).toList()));
    await prefs.setString('generated_pyramids', jsonEncode(_generatedPyramids.map((l) => l.toJson()).toList()));
    await prefs.setString('generated_calendars', jsonEncode(_generatedCalendars.map((l) => l.toJson()).toList()));
    await prefs.setString('generated_clocks', jsonEncode(_generatedClocks.map((l) => l.toJson()).toList()));
  }

  Future<void> markCompleted(String lessonId) async {
    _completed[lessonId] = completions(lessonId) + 1;
    await _save();
    notifyListeners();
  }

  Future<void> addGenerated(Lesson l) async {
    _generated
      ..clear()
      ..add(l); // chi giu 1 bai tu sinh, bai moi thay bai cu
    await _save();
    notifyListeners();
  }

  Future<void> addGeneratedDice(DiceLesson l) async {
    _generatedDice
      ..clear()
      ..add(l); // chi giu 1 bai tu sinh, bai moi thay bai cu
    await _save();
    notifyListeners();
  }

  Future<void> addGeneratedNet(NetLesson l) async {
    _generatedNets
      ..clear()
      ..add(l); // chi giu 1 bai tu sinh, bai moi thay bai cu
    await _save();
    notifyListeners();
  }

  Future<void> addGeneratedMark(MarkLesson l) async {
    _generatedMarks
      ..clear()
      ..add(l); // chi giu 1 bai tu sinh, bai moi thay bai cu
    await _save();
    notifyListeners();
  }

  Future<void> addGeneratedHide(HideLesson l) async {
    _generatedHides
      ..clear()
      ..add(l); // chi giu 1 bai tu sinh, bai moi thay bai cu
    await _save();
    notifyListeners();
  }

  Future<void> addGeneratedPyramid(PyramidLesson l) async {
    _generatedPyramids
      ..clear()
      ..add(l); // chi giu 1 bai tu sinh, bai moi thay bai cu
    await _save();
    notifyListeners();
  }

  Future<void> addGeneratedBack(BackLesson l) async {
    _generatedBacks
      ..clear()
      ..add(l); // chi giu 1 bai tu sinh, bai moi thay bai cu
    await _save();
    notifyListeners();
  }

  Future<void> addGeneratedPick(PickLesson l) async {
    _generatedPicks
      ..clear()
      ..add(l); // chi giu 1 bai tu sinh, bai moi thay bai cu
    await _save();
    notifyListeners();
  }

  Future<void> addGeneratedHalf(HalfLesson l) async {
    _generatedHalves
      ..clear()
      ..add(l); // chi giu 1 bai tu sinh, bai moi thay bai cu
    await _save();
    notifyListeners();
  }

  Future<void> addGeneratedDotSquare(DotSquareLesson l) async {
    _generatedDotSquares
      ..clear()
      ..add(l); // chi giu 1 bai tu sinh, bai moi thay bai cu
    await _save();
    notifyListeners();
  }

  Future<void> addGeneratedStack(StackLesson l) async {
    _generatedStacks.removeWhere((e) => e.kind == l.kind); // moi dang chi giu 1 bai tu sinh
    _generatedStacks.add(l);
    await _save();
    notifyListeners();
  }

  Future<void> addGeneratedKokugo(KokugoLesson l) async {
    _generatedKokugo.removeWhere((e) => e.kind == l.kind); // moi dang chi giu 1 bai tu sinh
    _generatedKokugo.add(l);
    await _save();
    notifyListeners();
  }

  Future<void> addGeneratedView(ViewLesson l) async {
    _generatedViews.removeWhere((e) => e.kind == l.kind); // moi dang chi giu 1 bai tu sinh
    _generatedViews.add(l);
    await _save();
    notifyListeners();
  }

  Future<void> addGeneratedCalendar(CalendarLesson l) async {
    _generatedCalendars
      ..clear()
      ..add(l); // chi giu 1 bai tu sinh, bai moi thay bai cu
    await _save();
    notifyListeners();
  }

  Future<void> addGeneratedClock(ClockLesson l) async {
    _generatedClocks.removeWhere((e) => e.kind == l.kind); // moi dang chi giu 1 bai tu sinh
    _generatedClocks.add(l);
    await _save();
    notifyListeners();
  }

  int countGenerated(String kind) {
    switch (kind) {
      case 'net':
        return _generatedNets.length;
      case 'mark':
        return _generatedMarks.length;
      case 'hide':
        return _generatedHides.length;
      case 'back':
        return _generatedBacks.length;
      case 'pick':
        return _generatedPicks.length;
      case 'stack':
      case 'same':
      case 'line':
      case 'around':
        return _generatedStacks.where((e) => e.kind == kind).length;
      default:
        return _generatedDice.length;
    }
  }

  int doneGenerated(String kind) {
    Iterable<String> ids;
    switch (kind) {
      case 'net':
        ids = _generatedNets.map((e) => e.id);
        break;
      case 'mark':
        ids = _generatedMarks.map((e) => e.id);
        break;
      case 'hide':
        ids = _generatedHides.map((e) => e.id);
        break;
      case 'back':
        ids = _generatedBacks.map((e) => e.id);
        break;
      case 'pick':
        ids = _generatedPicks.map((e) => e.id);
        break;
      case 'stack':
      case 'same':
      case 'line':
      case 'around':
        ids = _generatedStacks.where((e) => e.kind == kind).map((e) => e.id);
        break;
      default:
        ids = _generatedDice.map((e) => e.id);
    }
    return ids.where((id) => isDone(id)).length;
  }
}
