import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════
// ألوان التطبيق المخصصة (تعمل مع الوضعين)
// ═══════════════════════════════════════════════════════
class AppColors extends ThemeExtension<AppColors> {
  final Color background;
  final Color cardBg;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color divider;
  final Color inputFill;
  final Color inputBorder;
  final Color headerGradientStart;
  final Color headerGradientMid;
  final Color headerGradientEnd;

  const AppColors({
    required this.background,
    required this.cardBg,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.divider,
    required this.inputFill,
    required this.inputBorder,
    required this.headerGradientStart,
    required this.headerGradientMid,
    required this.headerGradientEnd,
  });

  @override
  AppColors copyWith({
    Color? background,
    Color? cardBg,
    Color? cardBorder,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? divider,
    Color? inputFill,
    Color? inputBorder,
    Color? headerGradientStart,
    Color? headerGradientMid,
    Color? headerGradientEnd,
  }) {
    return AppColors(
      background: background ?? this.background,
      cardBg: cardBg ?? this.cardBg,
      cardBorder: cardBorder ?? this.cardBorder,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      divider: divider ?? this.divider,
      inputFill: inputFill ?? this.inputFill,
      inputBorder: inputBorder ?? this.inputBorder,
      headerGradientStart:
          headerGradientStart ?? this.headerGradientStart,
      headerGradientMid: headerGradientMid ?? this.headerGradientMid,
      headerGradientEnd: headerGradientEnd ?? this.headerGradientEnd,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      cardBg: Color.lerp(cardBg, other.cardBg, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      inputBorder: Color.lerp(inputBorder, other.inputBorder, t)!,
      headerGradientStart:
          Color.lerp(headerGradientStart, other.headerGradientStart, t)!,
      headerGradientMid:
          Color.lerp(headerGradientMid, other.headerGradientMid, t)!,
      headerGradientEnd:
          Color.lerp(headerGradientEnd, other.headerGradientEnd, t)!,
    );
  }
}

// ═══════════════════════════════════════════════════════
// نظام الثيمات
// ═══════════════════════════════════════════════════════
class AppTheme {
  // ─── الوضع النهاري ───
  static const _lightColors = AppColors(
    background: Color(0xFFF5F7FA),
    cardBg: Colors.white,
    cardBorder: Color(0xFFE8ECEF),
    textPrimary: Color(0xFF263238),
    textSecondary: Color(0xFF607D8B),
    textTertiary: Color(0xFF90A4AE),
    divider: Color(0xFFECEFF1),
    inputFill: Color(0xFFF8FAF9),
    inputBorder: Color(0xFFC8E6C9),
    headerGradientStart: Color(0xFF0D3B14),
    headerGradientMid: Color(0xFF1B5E20),
    headerGradientEnd: Color(0xFF2E7D32),
  );

  // ─── الوضع الليلي ───
  static const _darkColors = AppColors(
    background: Color(0xFF0F1419),
    cardBg: Color(0xFF1A2027),
    cardBorder: Color(0xFF2A323B),
    textPrimary: Color(0xFFECEFF1),
    textSecondary: Color(0xFFB0BEC5),
    textTertiary: Color(0xFF78909C),
    divider: Color(0xFF2A323B),
    inputFill: Color(0xFF1F262D),
    inputBorder: Color(0xFF2E7D32),
    headerGradientStart: Color(0xFF051A08),
    headerGradientMid: Color(0xFF0D3B14),
    headerGradientEnd: Color(0xFF1B5E20),
  );

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _lightColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2E7D32),
        brightness: Brightness.light,
      ),
      extensions: const [_lightColors],
      fontFamily: 'Cairo',
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: _lightColors.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _darkColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF66BB6A),
        brightness: Brightness.dark,
      ),
      extensions: const [_darkColors],
      fontFamily: 'Cairo',
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Color(0xFF0D3B14),
        foregroundColor: Colors.white,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: _darkColors.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// اختصارات للوصول السريع
// ═══════════════════════════════════════════════════════
extension ThemeX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}