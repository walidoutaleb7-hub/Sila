import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesController extends ChangeNotifier {
  static const _keyTeacherName = 'teacher_name';
  static const _keySchoolName = 'school_name';
  static const _keyFontScale = 'font_scale';

  String _teacherName = '';
  String _schoolName = '';
  double _fontScale = 1.0;

  String get teacherName => _teacherName;
  String get schoolName => _schoolName;
  double get fontScale => _fontScale;

  bool get hasTeacherInfo =>
      _teacherName.trim().isNotEmpty || _schoolName.trim().isNotEmpty;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _teacherName = prefs.getString(_keyTeacherName) ?? '';
    _schoolName = prefs.getString(_keySchoolName) ?? '';
    _fontScale = prefs.getDouble(_keyFontScale) ?? 1.0;
    notifyListeners();
  }

  Future<void> setTeacherInfo({
    required String name,
    required String school,
  }) async {
    _teacherName = name.trim();
    _schoolName = school.trim();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTeacherName, _teacherName);
    await prefs.setString(_keySchoolName, _schoolName);
  }

  Future<void> setFontScale(double scale) async {
    if (scale < 0.85 || scale > 1.3) return;
    _fontScale = scale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyFontScale, scale);
  }

  String get fontScaleName {
    if (_fontScale <= 0.9) return 'صغير';
    if (_fontScale <= 1.0) return 'متوسط';
    if (_fontScale <= 1.15) return 'كبير';
    return 'كبير جداً';
  }

  Future<void> clearAll() async {
    _teacherName = '';
    _schoolName = '';
    _fontScale = 1.0;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyTeacherName);
    await prefs.remove(_keySchoolName);
    await prefs.remove(_keyFontScale);
  }
}

final preferencesController = PreferencesController();