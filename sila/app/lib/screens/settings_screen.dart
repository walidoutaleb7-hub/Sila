import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../theme/font_controller.dart';
import '../theme/preferences_controller.dart';
import '../theme/theme_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('الإعدادات'),
        centerTitle: true,
        backgroundColor: colors.headerGradientMid,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          themeController,
          fontController,
          preferencesController,
          authService,
        ]),
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ═══════ حسابي ═══════
              _sectionTitle('حسابي', Icons.account_circle_outlined),
              const SizedBox(height: 10),
              _buildUserCard(context),
              const SizedBox(height: 20),

              // ═══════ المظهر ═══════
              _sectionTitle('المظهر', Icons.palette_outlined),
              const SizedBox(height: 10),
              _settingsCard(
                context,
                children: [
                  _switchTile(
                    context,
                    icon: themeController.isDark
                        ? Icons.dark_mode
                        : Icons.light_mode,
                    title: 'الوضع الليلي',
                    subtitle: themeController.isDark ? 'مُفعّل' : 'مُعطّل',
                    value: themeController.isDark,
                    onChanged: (_) => themeController.toggle(),
                  ),
                  _divider(context),
                  _sliderTile(context),
                ],
              ),
              const SizedBox(height: 20),

              // ═══════ الخطوط ═══════
              _sectionTitle('الخط', Icons.text_fields),
              const SizedBox(height: 10),
              Text(
                'اختر الخط المفضّل للتطبيق',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              ...kAvailableFonts.map((font) => _fontTile(context, font)),
              const SizedBox(height: 20),

              // ═══════ التطبيق ═══════
              _sectionTitle('التطبيق', Icons.apps),
              const SizedBox(height: 10),
              _settingsCard(
                context,
                children: [
                  _actionTile(
                    context,
                    icon: Icons.share_outlined,
                    title: 'مشاركة التطبيق',
                    subtitle: 'أرسل التطبيق لأصدقائك',
                    onTap: () => _shareApp(context),
                  ),
                  _divider(context),
                  _actionTile(
                    context,
                    icon: Icons.star_outline,
                    title: 'تقييم التطبيق',
                    subtitle: 'ساعدنا بتقييمك على Google Play',
                    onTap: () => _showRatingDialog(context),
                  ),
                  _divider(context),
                  _actionTile(
                    context,
                    icon: Icons.help_outline,
                    title: 'المساعدة والدعم',
                    subtitle: 'أسئلة شائعة وطرق التواصل',
                    onTap: () => _showHelp(context),
                  ),
                  _divider(context),
                  _actionTile(
                    context,
                    icon: Icons.privacy_tip_outlined,
                    title: 'سياسة الخصوصية',
                    subtitle: 'كيف نحمي بياناتك',
                    onTap: () => _showPrivacy(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ═══════ البيانات ═══════
              _sectionTitle('البيانات', Icons.storage_outlined),
              const SizedBox(height: 10),
              _settingsCard(
                context,
                children: [
                  _actionTile(
                    context,
                    icon: Icons.cleaning_services_outlined,
                    title: 'مسح البيانات المحلية',
                    subtitle: 'الإعدادات + الخطوط + التفضيلات',
                    color: Colors.orange,
                    onTap: () => _confirmClearData(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ═══════ تسجيل الخروج ═══════
              _settingsCard(
                context,
                children: [
                  _actionTile(
                    context,
                    icon: Icons.logout,
                    title: 'تسجيل الخروج',
                    subtitle: 'سيتم إنهاء جلستك على هذا الجهاز',
                    color: Colors.red,
                    onTap: () => _confirmLogout(context),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // ═══════ Footer (بالصورة الحقيقية) ═══════
              Center(
                child: Column(
                  children: [
                    // ✅ شعار التطبيق الحقيقي
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: context.isDark
                            ? const Color(0xFF1B3A1E)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: context.isDark
                              ? const Color(0xFF2E7D32)
                              : Colors.green.shade200,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          'assets/IMG_20261002_165513.jpg',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'SILA',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: colors.textPrimary,
                        letterSpacing: 6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFFFFB300), Color(0xFFFFD54F)]),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'صُنع بحب في الجزائر 🇩🇿',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'من طرف أوطالب وليد',
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: context.isDark
                            ? const Color(0xFF1B3A1E)
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: context.isDark
                              ? const Color(0xFF2E7D32)
                              : Colors.green.shade100,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_outlined,
                              size: 14,
                              color: context.isDark
                                  ? const Color(0xFF81C784)
                                  : Colors.green.shade700),
                          const SizedBox(width: 6),
                          Text(
                            'الإصدار 1.0.0',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: context.isDark
                                  ? const Color(0xFF81C784)
                                  : Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════
  // بطاقة المستخدم
  // ═══════════════════════════════════════════
  Widget _buildUserCard(BuildContext context) {
    final user = authService.user;

    if (user == null) {
      return _settingsCard(
        context,
        children: [
          _actionTile(
            context,
            icon: Icons.login,
            title: 'تسجيل الدخول',
            subtitle: 'للمتابعة',
            onTap: () {},
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            context.isDark ? const Color(0xFF0D3B14) : Colors.green.shade700,
            context.isDark ? const Color(0xFF1B5E20) : Colors.green.shade500,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  _initials(user.fullName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Material(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showEditProfile(context),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.edit_outlined,
                      color: Colors.white, size: 18),
                ),
              ),
            ),
          ]),
          if (user.schoolName != null &&
              user.schoolName!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(color: Colors.white.withOpacity(0.15)),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.school_outlined,
                  color: Colors.white.withOpacity(0.9), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  user.schoolName!,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return parts[0][0];
  }

  // ═══════════════════════════════════════════
  // تعديل الملف الشخصي
  // ═══════════════════════════════════════════
  void _showEditProfile(BuildContext context) {
    final user = authService.user;
    if (user == null) return;

    final nameController = TextEditingController(text: user.fullName);
    final schoolController =
        TextEditingController(text: user.schoolName ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.isDark
                  ? const Color(0xFF1B3A1E)
                  : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.edit_outlined,
                color: Color(0xFF4CAF50), size: 22),
          ),
          const SizedBox(width: 12),
          const Text('تعديل الحساب',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 17)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInput(
              context,
              controller: nameController,
              label: 'الاسم الكامل',
              hint: 'مثال: أوطالب وليد',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 14),
            _buildInput(
              context,
              controller: schoolController,
              label: 'المدرسة',
              hint: 'مثال: ثانوية الأمير عبد القادر',
              icon: Icons.school_outlined,
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
                foregroundColor: context.colors.textSecondary),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              await authService.updateProfile(
                fullName: nameController.text,
                schoolName: schoolController.text,
              );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Row(children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('تم حفظ التعديلات'),
                  ]),
                  backgroundColor: Colors.green.shade700,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ));
              }
            },
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('حفظ',
                style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    final colors = context.colors;
    return TextField(
      controller: controller,
      style: TextStyle(color: colors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: colors.textTertiary, fontSize: 13),
        labelStyle: TextStyle(
          color: context.isDark
              ? const Color(0xFF81C784)
              : const Color(0xFF2E7D32),
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon,
            color: context.isDark
                ? const Color(0xFF81C784)
                : Colors.green.shade400,
            size: 20),
        filled: true,
        fillColor: colors.inputFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors.cardBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: context.isDark
                    ? const Color(0xFF4CAF50)
                    : Colors.green.shade300,
                width: 1.5)),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // تسجيل الخروج
  // ═══════════════════════════════════════════
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.isDark
                  ? const Color(0xFF3A1A1A)
                  : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.logout,
                color: Color(0xFFEF5350), size: 22),
          ),
          const SizedBox(width: 12),
          const Text('تسجيل الخروج',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 17)),
        ]),
        content: const Text(
          'هل أنت متأكد من تسجيل الخروج؟\n'
          'ستحتاج إدخال بياناتك مرة أخرى للدخول.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
                foregroundColor: context.colors.textSecondary),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              // ✅ تسجيل الخروج — main.dart سيتولى التنقل تلقائياً
              await authService.logout();
            },
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('خروج',
                style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // مشاركة
  // ═══════════════════════════════════════════
  void _shareApp(BuildContext context) {
    Share.share(
      '📚 تطبيق SILA - صلة\n\n'
      'منصة تواصل مدرسية ذكية\n'
      'المدرسة في جيبك، والتواصل في يدك\n\n'
      'حمّل التطبيق الآن!',
      subject: 'تطبيق صلة - SILA',
    );
  }

  // ═══════════════════════════════════════════
  // تقييم
  // ═══════════════════════════════════════════
  void _showRatingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.isDark
                  ? const Color(0xFF3A2A0A)
                  : const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.star_outline,
                color: Color(0xFFFFB300), size: 22),
          ),
          const SizedBox(width: 12),
          const Text('تقييم التطبيق',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 17)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('هل أعجبك التطبيق؟',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'تقييمك يساعدنا على التحسين ويساعد غيرك على اكتشاف التطبيق.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: context.colors.textSecondary),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (i) => const Icon(Icons.star,
                    size: 32, color: Color(0xFFFFB300)),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colors.inputFill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Icon(Icons.info_outline,
                    size: 16, color: context.colors.textTertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'سيتوفر التقييم عند نشر التطبيق على Google Play',
                    style: TextStyle(
                        fontSize: 11,
                        color: context.colors.textTertiary),
                  ),
                ),
              ]),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('حسناً',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // المساعدة
  // ═══════════════════════════════════════════
  void _showHelp(BuildContext context) {
    final faqs = [
      {'q': 'كيف أضيف قسماً جديداً؟', 'a': 'من الشاشة الرئيسية، اضغط الزر الأخضر "+ قسم جديد".'},
      {'q': 'كيف أسجّل حضور التلاميذ؟', 'a': 'افتح القسم، اضغط زر "الحضور"، حدّد حالة كل تلميذ ثم "حفظ".'},
      {'q': 'كيف أضيف صورة لتلميذ؟', 'a': 'من قائمة التلاميذ → ⋮ → "تعديل" → أيقونة الكاميرا.'},
      {'q': 'كيف أُدخل الدرجات؟', 'a': 'افتح القسم → "الدرجات" → "+ تقييم جديد".'},
      {'q': 'كيف أنشر مذكرة حصة؟', 'a': 'افتح القسم → "الملاحظات" → "+ ملاحظة" → نوع "مذكرة حصة".'},
      {'q': 'كيف أُصدّر تقريراً؟', 'a': 'افتح القسم → أيقونة المشاركة → CSV أو تقرير نصي.'},
      {'q': 'كيف أرسل رسالة لولي؟', 'a': 'افتح تفاصيل التلميذ → زر "مراسلة" → اختر رسالة جاهزة.'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.isDark
                  ? const Color(0xFF1B2A3A)
                  : const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.help_outline,
                color: Color(0xFF42A5F5), size: 22),
          ),
          const SizedBox(width: 12),
          const Text('المساعدة',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 17)),
        ]),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: faqs.length,
            separatorBuilder: (_, __) => Divider(
                color: context.colors.divider, height: 20),
            itemBuilder: (context, i) {
              final faq = faqs[i];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('؟',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(faq['q']!,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(right: 28),
                    child: Text(faq['a']!,
                        style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: context.colors.textSecondary)),
                  ),
                ],
              );
            },
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('فهمت',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // الخصوصية
  // ═══════════════════════════════════════════
  void _showPrivacy(BuildContext context) {
    final items = [
      {'title': 'حماية البيانات', 'content': 'بيانات التلاميذ محفوظة على خادم آمن ولا تُشارك مع أي طرف ثالث.'},
      {'title': 'حساب واحد لكل مستخدم', 'content': 'كل حساب معزول تماماً — لا يمكنك رؤية بيانات حساب آخر.'},
      {'title': 'لا إعلانات', 'content': 'التطبيق لا يحتوي على إعلانات ولا يتتبع استخدامك.'},
      {'title': 'صور التلاميذ', 'content': 'الصور تُحفظ بشكل مشفر. يمكن حذفها في أي وقت.'},
      {'title': 'حقوقك', 'content': 'لك الحق في حذف جميع بياناتك في أي وقت.'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.isDark
                  ? const Color(0xFF1B3A1E)
                  : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.privacy_tip_outlined,
                color: Color(0xFF4CAF50), size: 22),
          ),
          const SizedBox(width: 12),
          const Text('سياسة الخصوصية',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 17)),
        ]),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: items.length,
            separatorBuilder: (_, __) => Divider(
                color: context.colors.divider, height: 20),
            itemBuilder: (context, i) {
              final item = items[i];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.check_circle,
                        size: 16, color: Colors.green.shade600),
                    const SizedBox(width: 8),
                    Text(item['title']!,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ]),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: Text(item['content']!,
                        style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: context.colors.textSecondary)),
                  ),
                ],
              );
            },
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('موافق',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // مسح البيانات
  // ═══════════════════════════════════════════
  void _confirmClearData(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.isDark
                  ? const Color(0xFF3A2A0A)
                  : const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: Color(0xFFFFB300), size: 22),
          ),
          const SizedBox(width: 12),
          const Text('مسح البيانات',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 17)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('سيتم مسح:',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 10),
            _bullet(context, 'اختيار الخط وحجمه'),
            _bullet(context, 'تفضيلات الوضع الليلي'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.isDark
                    ? const Color(0xFF3A2A0A)
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                Icon(Icons.info_outline,
                    size: 14, color: Colors.orange.shade700),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'بيانات التلاميذ وحسابك لن تُمسح.',
                    style: TextStyle(
                        fontSize: 11, color: Colors.orange.shade800),
                  ),
                ),
              ]),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
                foregroundColor: context.colors.textSecondary),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              await preferencesController.clearAll();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Row(children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('تم مسح البيانات'),
                  ]),
                  backgroundColor: Colors.green.shade700,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ));
              }
            },
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('مسح',
                style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bullet(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Container(
          width: 5, height: 5,
          decoration: BoxDecoration(
            color: context.colors.textSecondary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(text,
            style: TextStyle(
                fontSize: 12, color: context.colors.textSecondary)),
      ]),
    );
  }

  // ═══════════════════════════════════════════
  // عناصر الواجهة
  // ═══════════════════════════════════════════
  Widget _sectionTitle(String title, IconData icon) {
    return Builder(
      builder: (context) {
        final colors = context.colors;
        return Row(children: [
          Container(
            width: 4, height: 20,
            decoration: BoxDecoration(
              color: Colors.green.shade700,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Icon(icon, size: 18, color: Colors.green.shade700),
          const SizedBox(width: 6),
          Text(title,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary)),
        ]);
      },
    );
  }

  Widget _settingsCard(BuildContext context,
      {required List<Widget> children}) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder, width: 1),
      ),
      child: Column(children: children),
    );
  }

  Widget _divider(BuildContext context) {
    final colors = context.colors;
    return Divider(
        height: 1,
        color: colors.divider,
        indent: 60,
        endIndent: 16);
  }

  Widget _switchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: context.isDark
                ? const Color(0xFF1B3A1E)
                : Colors.green.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: Colors.green.shade600),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: colors.textPrimary)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 11, color: colors.textTertiary)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.green.shade600,
        ),
      ]),
    );
  }

  Widget _sliderTile(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: context.isDark
                    ? const Color(0xFF1B3A1E)
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.format_size,
                  size: 18, color: Colors.green.shade600),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('حجم الخط',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: colors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(preferencesController.fontScaleName,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            const Text('أ', style: TextStyle(fontSize: 12)),
            Expanded(
              child: Slider(
                value: preferencesController.fontScale,
                min: 0.85,
                max: 1.3,
                divisions: 3,
                activeColor: Colors.green.shade600,
                inactiveColor: colors.cardBorder,
                label: preferencesController.fontScaleName,
                onChanged: (v) => preferencesController.setFontScale(v),
              ),
            ),
            const Text('أ',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
          ]),
        ],
      ),
    );
  }

  Widget _fontTile(BuildContext context, AppFont font) {
    final colors = context.colors;
    final selected = fontController.fontId == font.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected
            ? (context.isDark
                ? const Color(0xFF1B3A1E)
                : Colors.green.shade50)
            : colors.cardBg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => fontController.setFont(font.id),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? Colors.green.shade400
                    : colors.cardBorder,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(font.name,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: colors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(font.sample,
                        style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary)),
                  ],
                ),
              ),
              if (selected)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check,
                      color: Colors.white, size: 14),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _actionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    MaterialColor? color,
  }) {
    final colors = context.colors;
    final MaterialColor c = color ?? Colors.green;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: context.isDark
                    ? c.withOpacity(0.15)
                    : c.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: c.shade600),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: colors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 11, color: colors.textTertiary)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 14, color: colors.textTertiary),
          ]),
        ),
      ),
    );
  }
}