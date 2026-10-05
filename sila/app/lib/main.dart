import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// ✅ إضافات جديدة
import 'services/cache_service.dart';
import 'services/connectivity_service.dart'; // ⚡ يهيي connectivityService تلقائياً

import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'theme/font_controller.dart';
import 'theme/preferences_controller.dart';
import 'theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ 1. Init Hive (داخل CacheService.init يوجد Hive.initFlutter + openBox)
  await CacheService.init();

  // ✅ 2. Init Connectivity
  // الـ connectivityService كايتهيأ تلقائياً في constructor (كي نستوردو الملف).
  // غير نستناو شوية باش أول نتيجة تكون واجدة قبل أول build.
  await Future.delayed(const Duration(milliseconds: 100));

  // ✅ 3. باقي الـ controllers
  await themeController.init();
  await fontController.init();
  await preferencesController.init();
  await authService.init();

  runApp(const SilaApp());
}

class SilaApp extends StatelessWidget {
  const SilaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        themeController,
        fontController,
        preferencesController,
        authService,
      ]),
      builder: (context, _) {
        return MaterialApp(
          // ✅ المفتاح السحري: يجبر Flutter على إعادة بناء كل الـ Navigator
          // عند تغيير حالة الدخول (لحل مشكلة تسجيل الخروج)
          key: ValueKey('sila_${authService.isLoggedIn}'),
          title: 'SILA',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(fontId: fontController.fontId),
          darkTheme: AppTheme.dark(fontId: fontController.fontId),
          themeMode: themeController.mode,
          locale: const Locale('ar', 'DZ'),
          supportedLocales: const [
            Locale('ar', 'DZ'),
            Locale('ar'),
            Locale('fr'),
            Locale('en'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            final scale = preferencesController.fontScale;
            return Directionality(
              textDirection: TextDirection.rtl,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                ),
                child: child!,
              ),
            );
          },
          home: authService.isLoggedIn
              ? const SplashScreen()
              : const LoginScreen(),
        );
      },
    );
  }
}