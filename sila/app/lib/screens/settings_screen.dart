import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/font_controller.dart';
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
        animation: Listenable.merge([themeController, fontController]),
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
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

              // ═══════ عن التطبيق ═══════
              _sectionTitle('عن التطبيق', Icons.info_outline),
              const SizedBox(height: 10),
              _settingsCard(
                context,
                children: [
                  _infoTile(
                    context,
                    icon: Icons.apps,
                    title: 'اسم التطبيق',
                    value: 'SILA - صلة',
                  ),
                  _divider(context),
                  _infoTile(
                    context,
                    icon: Icons.tag,
                    title: 'الإصدار',
                    value: '1.0.0',
                  ),
                  _divider(context),
                  _infoTile(
                    context,
                    icon: Icons.description_outlined,
                    title: 'الوصف',
                    value: 'المدرسة في جيبك، والتواصل في يدك',
                  ),
                  _divider(context),
                  _infoTile(
                    context,
                    icon: Icons.person_outline,
                    title: 'المطوّر',
                    value: 'أوطالب وليد',
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // ═══════ Footer ═══════
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'ص',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'SILA',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: colors.textPrimary,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'صُنع بحب في الجزائر',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'من طرف أوطالب وليد 🇩🇿',
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: context.isDark
                            ? const Color(0xFF1B3A1E)
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 14,
                            color: Colors.red.shade400,
                          ),
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

  Widget _sectionTitle(String title, IconData icon) {
    return Builder(
      builder: (context) {
        final colors = context.colors;
        return Row(children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.green.shade700,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Icon(icon, size: 18, color: Colors.green.shade700),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
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
      endIndent: 16,
    );
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
                  style:
                      TextStyle(fontSize: 11, color: colors.textTertiary)),
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
          onTap: () {
            fontController.setFont(font.id);
          },
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
                    Text(
                      font.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      font.sample,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
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

  Widget _infoTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  style:
                      TextStyle(fontSize: 12, color: colors.textTertiary)),
              const SizedBox(height: 3),
              Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: colors.textPrimary)),
            ],
          ),
        ),
      ]),
    );
  }
}