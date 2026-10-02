import 'package:flutter/material.dart';
import '../services/api.dart';
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
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.school_outlined,
                color: Color(0xFF2E7D32),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'قسم جديد',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF263238),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'اسم القسم',
                hintText: 'مثال: 1AS-A',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 13,
                ),
                labelStyle: const TextStyle(
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.w600,
                ),
                prefixIcon: Icon(
                  Icons.meeting_room_outlined,
                  color: Colors.green.shade400,
                  size: 20,
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAF9),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: Colors.green.shade100,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: Colors.green.shade300,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: levelController,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'المستوى الدراسي',
                hintText: 'مثال: 1AS',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 13,
                ),
                labelStyle: const TextStyle(
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.w600,
                ),
                prefixIcon: Icon(
                  Icons.workspace_premium_outlined,
                  color: Colors.green.shade400,
                  size: 20,
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAF9),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: Colors.green.shade100,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: Colors.green.shade300,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'إلغاء',
              style: TextStyle(fontSize: 14),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text(
              'إضافة',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
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

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle,
                color: Colors.white),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 210,
            pinned: true,
            backgroundColor: const Color(0xFF1B5E20),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              title: const SizedBox.shrink(),
              background: _buildHomeHeader(),
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
                          color: Colors.green.shade700,
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 16),
                        Text('جاري التحميل...',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 14)),
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
                              color: Colors.red.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.wifi_off_rounded,
                                size: 56, color: Colors.red.shade400),
                          ),
                          const SizedBox(height: 20),
                          const Text('تعذّر الاتصال',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 13)),
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
                                Colors.green.shade50,
                                Colors.green.shade100,
                              ]),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.school_outlined,
                                size: 64, color: Colors.green.shade400),
                          ),
                          const SizedBox(height: 20),
                          const Text('لا توجد أقسام بعد',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF37474F),
                              )),
                          const SizedBox(height: 8),
                          Text('اضغط زر + لإضافة أول قسم',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
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

  Widget _buildHomeHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D3B14),
            Color(0xFF1B5E20),
            Color(0xFF2E7D32),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: Color(0xFF263238),
                            )),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.signal_cellular_alt,
                                size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(c.level,
                                style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13)),
                            const SizedBox(width: 12),
                            Icon(Icons.people_outline,
                                size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text('${c.studentsCount} تلميذ',
                                style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey.shade400),
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
// 🏫 رسم المدرسة - مبنى أكاديمي معماري راقٍ
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