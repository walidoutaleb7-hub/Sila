import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// ✅ إضافات جديدة
import 'services/cache_service.dart';
import 'services/connectivity_service.dart'; // ⚡ كاينيتياليزي تلقائياً

import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'theme/font_controller.dart';
import 'theme/preferences_controller.dart';
import 'theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ 1. Init Hive (داخل CacheService.init هناك Hive.initFlutter + openBox)
  await CacheService.init();

  // ✅ 2. Init Connectivity
  // الـ connectivityService كاينيتياليزي في constructor (كي نستوردو الملف)،
  // بصح نستناو أول نتيجة باش ما يكونش state غالط في أول إطار.
  // (اختياري - إذا حبيت نأجلو الأول frame)
  await Future.delayed(const Duration(milliseconds: 50));

  // ✅ 3. باقي الـ controllers
  await themeController.init();
  await fontController.init();
  await preferencesController.init();
  await authService.init();

  runApp(const SilaApp());
}

// ⚠️ باقي الكود تاع SilaApp كيما راه (ما بدلناش فيه والو)
// ... (خليه كيما هو)