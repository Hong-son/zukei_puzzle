import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RewardService extends ChangeNotifier {
  int _totalStars = 0;
  int get totalStars => _totalStars;

  RewardService() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _totalStars = prefs.getInt('total_stars') ?? 10;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('total_stars', _totalStars);
  }

  Future<void> addReward(int stars) async {
    _totalStars += stars;
    await _save();
    notifyListeners();
  }

  Future<bool> spendStars(int amount) async {
    if (_totalStars < amount) return false;
    _totalStars -= amount;
    await _save();
    notifyListeners();
    return true;
  }

  static int calcStars(int tries) {
    if (tries == 1) return 3;
    if (tries <= 3) return 2;
    return 1;
  }
}
