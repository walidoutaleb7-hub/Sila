import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/api.dart';

class StudentDetailScreen extends StatefulWidget {
  final Student student;

  const StudentDetailScreen({super.key, required this.student});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  late Future<StudentHistory> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _historyFuture = ApiService.getStudentHistory(widget.student.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: FutureBuilder<StudentHistory>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading();
          }

          if (snapshot.hasError) {
            return _buildError(snapshot.error.toString());
          }

          final history = snapshot.data!;
          return _buildContent(history);
        },
      ),
    );
  }

  // ═══════════════════════════════════════════
  // حالة التحميل
  // ═══════════════════════════════════════════
  Widget _buildLoading() {
    return Column(
      children: [
        _buildSimpleAppBar(),
        const Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.green),
                SizedBox(height: 16),
                Text('جاري التحميل...'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // حالة الخطأ
  // ═══════════════════════════════════════════
  Widget _buildError(String error) {
    return Column(
      children: [
        _buildSimpleAppBar(),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 60, color: Colors.red.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'تعذّر التحميل',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _loadHistory,
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
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // AppBar بسيط (أثناء التحميل/الخطأ)
  // ═══════════════════════════════════════════
  Widget _buildSimpleAppBar() {
    return AppBar(
      title: Text(widget.student.fullName),
      centerTitle: true,
      backgroundColor: Colors.green.shade800,
      foregroundColor: Colors.white,
    );
  }

  // ═══════════════════════════════════════════
  // المحتوى الرئيسي
  // ═══════════════════════════════════════════
  Widget _buildContent(StudentHistory history) {
    return CustomScrollView(
      slivers: [
        // ─── الرأس ───
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: Colors.green.shade800,
          foregroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding:
                const EdgeInsets.only(left: 56, right: 16, bottom: 16),
            title: Text(
              history.student.fullName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Colors.green.shade800,
                    Colors.green.shade500,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -30,
                    right: -30,
                    child: Icon(
                      Icons.person,
                      size: 200,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  // ─── دائرة النسبة ───
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: _buildProgressRing(history.rate),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ─── بطاقات الإحصائيات ───
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildStatCard(
                  label: 'الحضور',
                  value: '${history.present}',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
                const SizedBox(width: 10),
                _buildStatCard(
                  label: 'الغياب',
                  value: '${history.absent}',
                  icon: Icons.cancel,
                  color: Colors.red,
                ),
                const SizedBox(width: 10),
                _buildStatCard(
                  label: 'المجموع',
                  value: '${history.total}',
                  icon: Icons.event,
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ),

        // ─── عنوان السجل ───
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.green.shade700,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'سجل الحضور',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF263238),
                  ),
                ),
                const Spacer(),
                Text(
                  '${history.records.length} يوم',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ─── قائمة السجل ───
        if (history.records.isEmpty)
          SliverToBoxAdapter(child: _buildEmptyHistory())
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _buildRecordTile(history.records[index], index),
                childCount: history.records.length,
              ),
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // دائرة النسبة (Progress Ring)
  // ═══════════════════════════════════════════
  Widget _buildProgressRing(int rate) {
    final color = rate >= 75
        ? Colors.green
        : rate >= 50
            ? Colors.orange
            : Colors.red;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: rate / 100),
      builder: (context, value, child) {
        return SizedBox(
          width: 130,
          height: 130,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // الحلقة الخلفية
              CustomPaint(
                size: const Size(130, 130),
                painter: _RingPainter(
                  progress: value,
                  color: color,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  strokeWidth: 10,
                ),
              ),
              // النص
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${(value * 100).round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'نسبة الحضور',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════
  // بطاقة إحصائية
  // ═══════════════════════════════════════════
  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required MaterialColor color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color.shade700, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color.shade900,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // سجل فارغ
  // ═══════════════════════════════════════════
  Widget _buildEmptyHistory() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.event_busy,
            size: 72,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'لا يوجد سجل حضور بعد',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF37474F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بتسجيل الحضور من شاشة القسم',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // سطر في السجل
  // ═══════════════════════════════════════════
  Widget _buildRecordTile(AttendanceRecord record, int index) {
    final isPresent = record.status == 'PRESENT';
    final color = isPresent ? Colors.green : Colors.red;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 250 + (index * 30)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(20 * (1 - value), 0),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            right: BorderSide(
              color: color.shade400,
              width: 4,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // الأيقونة
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isPresent ? Icons.check : Icons.close,
                  color: color.shade700,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // التاريخ
              Expanded(
                child: Text(
                  ApiService.formatDateArabic(record.date),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF263238),
                  ),
                ),
              ),

              // الحالة
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isPresent ? 'حاضر' : 'غائب',
                  style: TextStyle(
                    color: color.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// رسّام الحلقة
// ═══════════════════════════════════════════
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // الحلقة الخلفية
    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // حلقة التقدم
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}