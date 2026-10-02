import 'package:flutter/material.dart';
import '../services/api.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import 'students.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<SchoolClass>> _classesFuture;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  void _loadClasses() {
    setState(() {
      _classesFuture = ApiService.getClasses();
    });
  }

  Future<void> _showAddClassDialog() async {
    final nameController = TextEditingController();
    final levelController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.isDark
                    ? const Color(0xFF1B3A1E)
                    : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.school_outlined,
                color: Color(0xFF4CAF50),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'قسم جديد',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInput(
              context,
              controller: nameController,
              label: 'اسم القسم',
              hint: 'مثال: 1AS-A',
              icon: Icons.meeting_room_outlined,
              action: TextInputAction.next,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            _buildInput(
              context,
              controller: levelController,
              label: 'المستوى الدراسي',
              hint: 'مثال: 1AS',
              icon: Icons.workspace_premium_outlined,
              action: TextInputAction.done,
              autofocus: false,
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: context.colors.textSecondary,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
            ),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text(
              'إضافة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true &&
        nameController.text.trim().isNotEmpty &&
        levelController.text.trim().isNotEmpty) {
      try {
        await ApiService.createClass(
          name: nameController.text.trim(),
          level: levelController.text.trim(),
        );
        _loadClasses();
        if (mounted) _showSnack('تم إضافة القسم بنجاح', isError: false);
      } catch (e) {
        if (mounted) _showSnack('خطأ: $e', isError: true);
      }
    }
  }

  Widget _buildInput(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required TextInputAction action,
    required bool autofocus,
  }) {
    final colors = context.colors;
    return TextField(
      controller: controller,
      autofocus: autofocus,
      textInputAction: action,
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
        prefixIcon: Icon(
          icon,
          color: context.isDark
              ? const Color(0xFF81C784)
              : Colors.green.shade400,
          size: 20,
        ),
        filled: true,
        fillColor: colors.inputFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.inputBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: context.isDark
                ? const Color(0xFF4CAF50)
                : Colors.green.shade300,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor:
            isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 210,
            pinned: true,
            backgroundColor: colors.headerGradientMid,
            foregroundColor: Colors.white,
            actions: [
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Material(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => themeController.toggle(),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) =>
                            RotationTransition(
                          turns: animation,
                          child: FadeTransition(
                              opacity: animation, child: child),
                        ),
                        child: Icon(
                          themeController.isDark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          key: ValueKey(themeController.isDark),
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.zero,
              background: _buildHomeHeader(),
            ),
          ),

          // ═══════ لوحة اليوم ═══════
          SliverToBoxAdapter(
            child: FutureBuilder<List<SchoolClass>>(
              future: _classesFuture,
              builder: (context, snapshot) {
                final classes = snapshot.data ?? [];
                if (classes.isEmpty) return const SizedBox.shrink();
                final totalStudents = classes.fold<int>(
                  0,
                  (sum, c) => sum + c.studentsCount,
                );
                return _buildTodayPanel(classes.length, totalStudents);
              },
            ),
          ),

          FutureBuilder<List<SchoolClass>>(
            future: _classesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Colors.green.shade600,
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 16),
                        Text('جاري التحميل...',
                            style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 14)),
                      ],
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: context.isDark
                                  ? const Color(0xFF3A1A1A)
                                  : Colors.red.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.wifi_off_rounded,
                                size: 56, color: Colors.red.shade400),
                          ),
                          const SizedBox(height: 20),
                          Text('تعذّر الاتصال',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary)),
                          const SizedBox(height: 8),
                          Text('${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 13)),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _loadClasses,
                            icon: const Icon(Icons.refresh),
                            label: const Text('إعادة المحاولة'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final classes = snapshot.data ?? [];

              if (classes.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                context.isDark
                                    ? const Color(0xFF1B3A1E)
                                    : Colors.green.shade50,
                                context.isDark
                                    ? const Color(0xFF1B3A1E)
                                    : Colors.green.shade100,
                              ]),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.school_outlined,
                                size: 64, color: Color(0xFF4CAF50)),
                          ),
                          const SizedBox(height: 20),
                          Text('لا توجد أقسام بعد',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              )),
                          const SizedBox(height: 8),
                          Text('اضغط زر + لإضافة أول قسم',
                              style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildClassCard(classes[index], index),
                    childCount: classes.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddClassDialog,
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('قسم جديد',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // لوحة اليوم
  // ═══════════════════════════════════════════
  Widget _buildTodayPanel(int classCount, int studentsCount) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              context.isDark
                  ? const Color(0xFF0D3B14)
                  : Colors.green.shade600,
              context.isDark
                  ? const Color(0xFF1B5E20)
                  : Colors.green.shade400,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
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
            // العنوان
            Row(
              children: [
                Icon(
                  Icons.dashboard_customize_outlined,
                  color: Colors.white.withOpacity(0.9),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'نظرة عامة',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // البطاقات
            Row(
              children: [
                Expanded(
                  child: _buildMiniStat(
                    icon: Icons.class_outlined,
                    label: 'الأقسام',
                    value: '$classCount',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMiniStat(
                    icon: Icons.people_outline,
                    label: 'التلاميذ',
                    value: '$studentsCount',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.22),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeHeader() {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.headerGradientStart,
            colors.headerGradientMid,
            colors.headerGradientEnd,
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: const Size(double.infinity, 130),
              painter: _SchoolSilhouettePainter(
                color: Colors.white.withOpacity(0.10),
              ),
            ),
          ),
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 24,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'صلة',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.handshake_outlined,
                              color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'المدرسة في جيبك',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'والتواصل في يدك',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(SchoolClass c, int index) {
    final colors = context.colors;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 60)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colors.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.cardBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(context.isDark ? 0.3 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudentsScreen(schoolClass: c),
                ),
              ).then((_) => _loadClasses());
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.green.shade500,
                          Colors.green.shade700,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.class_,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: colors.textPrimary,
                            )),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.signal_cellular_alt,
                                size: 14, color: colors.textTertiary),
                            const SizedBox(width: 4),
                            Text(c.level,
                                style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 13)),
                            const SizedBox(width: 12),
                            Icon(Icons.people_outline,
                                size: 14, color: colors.textTertiary),
                            const SizedBox(width: 4),
                            Text('${c.studentsCount} تلميذ',
                                style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      size: 16, color: colors.textTertiary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// 🏫 رسم المدرسة
// ═══════════════════════════════════════════════════════
class _SchoolSilhouettePainter extends CustomPainter {
  final Color color;

  _SchoolSilhouettePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    final mainBuilding = Path()
      ..moveTo(w * 0.15, h * 0.40)
      ..lineTo(w * 0.85, h * 0.40)
      ..lineTo(w * 0.85, h * 1.0)
      ..lineTo(w * 0.15, h * 1.0)
      ..close();
    canvas.drawPath(mainBuilding, paint);

    final roof = Path()
      ..moveTo(w * 0.15, h * 0.40)
      ..lineTo(w * 0.50, h * 0.10)
      ..lineTo(w * 0.85, h * 0.40)
      ..close();
    canvas.drawPath(roof, paint);

    final smallDome = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(w * 0.50, h * 0.10),
        radius: w * 0.025,
      ));
    canvas.drawPath(smallDome, paint);

    final flagPole = Rect.fromLTWH(w * 0.495, h * 0.02, w * 0.01, h * 0.08);
    canvas.drawRect(flagPole, paint);

    final windowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      final windowRect = Rect.fromLTWH(
        w * 0.22 + (i * w * 0.12),
        h * 0.52,
        w * 0.06,
        h * 0.12,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(windowRect, const Radius.circular(2)),
        windowPaint,
      );
    }

    for (int i = 0; i < 5; i++) {
      final windowRect = Rect.fromLTWH(
        w * 0.22 + (i * w * 0.12),
        h * 0.72,
        w * 0.06,
        h * 0.12,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(windowRect, const Radius.circular(2)),
        windowPaint,
      );
    }

    final door = Path()
      ..moveTo(w * 0.44, h * 1.0)
      ..lineTo(w * 0.44, h * 0.88)
      ..quadraticBezierTo(w * 0.50, h * 0.80, w * 0.56, h * 0.88)
      ..lineTo(w * 0.56, h * 1.0)
      ..close();
    canvas.drawPath(door, paint);

    final leftPillar =
        Rect.fromLTWH(w * 0.13, h * 0.42, w * 0.025, h * 0.58);
    canvas.drawRect(leftPillar, paint);

    final rightPillar =
        Rect.fromLTWH(w * 0.845, h * 0.42, w * 0.025, h * 0.58);
    canvas.drawRect(rightPillar, paint);

    final baseStep = Rect.fromLTWH(w * 0.10, h * 0.97, w * 0.80, h * 0.03);
    canvas.drawRect(baseStep, paint);
  }

  @override
  bool shouldRepaint(_SchoolSilhouettePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}