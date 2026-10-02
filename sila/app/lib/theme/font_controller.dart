import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════
// الخطوط العربية المتوفرة
// ═══════════════════════════════════════════
class AppFont {
  final String id;       // للاستخدام الداخلي
  final String name;     // الاسم بالعربي
  final String sample;   // عينة نصية

  const AppFont({
    required this.id,
    required this.name,
    required this.sample,
  });
}

const kAvailableFonts = <AppFont>[
  AppFont(id: 'Cairo', name: 'القاهرة', sample: 'المدرسة في جيبك'),
  AppFont(id: 'Tajawal', name: 'تجوّل', sample: 'المدرسة في جيبك'),
  AppFont(id: 'Almarai', name: 'المراعي', sample: 'المدرسة في جيبك'),
  AppFont(id: 'IBM Plex Sans Arabic', name: 'IBM بلكس', sample: 'المدرسة في جيبك'),
  AppFont(id: 'El Messiri', name: 'المصيري', sample: 'المدرسة في جيبك'),
  AppFont(id: 'Readex Pro', name: 'ريدكس برو', sample: 'المدرسة في جيبك'),
  AppFont(id: 'Noto Kufi Arabic', name: 'نوتو كوفي', sample: 'المدرسة في جيبك'),
  AppFont(id: 'Changa', name: 'شنغا', sample: 'المدرسة في جيبك'),
];

// ═══════════════════════════════════════════
// متحكّم الخط
// ═══════════════════════════════════════════
class FontController extends ChangeNotifier {
  static const _key = 'font_family';
  String _fontId = 'Cairo';

  String get fontId => _fontId;
  String get fontName {
    final f = kAvailableFonts.firstWhere(
      (f) => f.id == _fontId,
      orElse: () => kAvailableFonts.first,
    );
    return f.name;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null &&
        kAvailableFonts.any((f) => f.id == saved)) {
      _fontId = saved;
    }
    notifyListeners();
  }

  Future<void> setFont(String fontId) async {
    if (!kAvailableFonts.any((f) => f.id == fontId)) return;
    _fontId = fontId;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, fontId);
  }
}

// نسخة عالمية واحدة
final fontController = FontController();