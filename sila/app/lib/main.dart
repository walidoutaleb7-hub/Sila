import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'theme/font_controller.dart';
import 'theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await themeController.init();
  await fontController.init();
  runApp(const SilaApp());
}

class SilaApp extends StatelessWidget {
  const SilaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([themeController, fontController]),
      builder: (context, _) {
        return MaterialApp(
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
            return Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            );
          },
          home: const SplashScreen(),
        );
      },
    );
  }
}