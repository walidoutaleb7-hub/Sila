import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/api.dart';
import '../theme/app_theme.dart';

class StudentDetailScreen extends StatefulWidget {
  final Student student;
  const StudentDetailScreen({super.key, required this.student});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<StudentHistory> _historyFuture;
  late Future<StudentGrades> _gradesFuture;
  late Future<StudentNotes> _notesFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadAll() {
    setState(() {
      _historyFuture = ApiService.getStudentHistory(widget.student.id);
      _gradesFuture = ApiService.getStudentGrades(widget.student.id);
      _notesFuture = ApiService.getStudentNotes(widget.student.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: FutureBuilder<StudentHistory>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading();
          }
          if (snapshot.hasError) {
            return _buildError(snapshot.error.toString());
          }
          return _buildContent(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildLoading() {
    final colors = context.colors;
    return Column(children: [
      AppBar(
        title: Text(widget.student.fullName),
        centerTitle: true,
        backgroundColor: colors.headerGradientMid,
        foregroundColor: Colors.white,
      ),
      Expanded(
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            CircularProgressIndicator(color: Colors.green.shade600),
            const SizedBox(height: 16),
            Text('جاري التحميل...', style: TextStyle(color: colors.textSecondary)),
          ]),
        ),
      ),
    ]);
  }

  Widget _buildError(String error) {
    final colors = context.colors;
    return Column(children: [
      AppBar(
        title: Text(widget.student.fullName),
        centerTitle: true,
        backgroundColor: colors.headerGradientMid,
        foregroundColor: Colors.white,
      ),
      Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text('تعذّر التحميل',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary)),
              const SizedBox(height: 8),
              Text(error,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadAll,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ]),
          ),
        ),
      ),
    ]);
  }

  Widget _buildContent(StudentHistory history) {
    final colors = context.colors;
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverAppBar(
          expandedHeight: 240,
          pinned: true,
          backgroundColor: colors.headerGradientMid,
          foregroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 56, right: 16, bottom: 60),
            title: Text(history.student.fullName,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16)),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [colors.headerGradientMid, colors.headerGradientEnd],
                ),
              ),
              child: Stack(children: [
                Positioned(
                  top: -30, right: -30,
                  child: Icon(Icons.person, size: 200,
                      color: Colors.white.withOpacity(0.08)),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: _buildProgressRing(history.rate),
                  ),
                ),
              ]),
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            tabs: const [
              Tab(icon: Icon(Icons.event_available, size: 18), text: 'الحضور'),
              Tab(icon: Icon(Icons.grade_outlined, size: 18), text: 'الدرجات'),
              Tab(icon: Icon(Icons.sticky_note_2_outlined, size: 18), text: 'الملاحظات'),
            ],
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAttendanceTab(history),
          _buildGradesTab(),
          _buildNotesTab(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // تبويب الحضور
  // ═══════════════════════════════════════════
  Widget _buildAttendanceTab(StudentHistory history) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(children: [
          _buildStatCard('الحضور', '${history.present}', Icons.check_circle, Colors.green),
          const SizedBox(width: 10),
          _buildStatCard('الغياب', '${history.absent}', Icons.cancel, Colors.red),
          const SizedBox(width: 10),
          _buildStatCard('المجموع', '${history.total}', Icons.event, Colors.blue),
        ]),
        const SizedBox(height: 20),
        _buildSectionTitle('سجل الحضور', '${history.records.length} يوم'),
        const SizedBox(height: 12),
        if (history.records.isEmpty)
          _buildEmptyBox('لا يوجد سجل حضور بعد', Icons.event_busy)
        else
          ...history.records.asMap().entries.map(
                (e) => _buildAttendanceTile(e.value, e.key),
              ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // تبويب الدرجات
  // ═══════════════════════════════════════════
  Widget _buildGradesTab() {
    final colors = context.colors;
    return FutureBuilder<StudentGrades>(
      future: _gradesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Colors.green.shade600));
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                const SizedBox(height: 12),
                Text('${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => setState(() {
                    _gradesFuture = ApiService.getStudentGrades(widget.student.id);
                  }),
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                ),
              ]),
            ),
          );
        }

        final g = snapshot.data!;
        if (g.count == 0) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              SizedBox(height: 60),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildAverageCard(g.average),
            const SizedBox(height: 20),
            if (g.assessmentAverages.isNotEmpty) ...[
              _buildSectionTitle('حسب نوع التقييم', '${g.assessmentAverages.length} نوع'),
              const SizedBox(height: 12),
              ...g.assessmentAverages.map((a) => _buildAssessmentAvgTile(a)),
              const SizedBox(height: 20),
            ],
            _buildSectionTitle('كل النقاط', '${g.count} نقطة'),
            const SizedBox(height: 12),
            ...g.records.asMap().entries.map((e) => _buildGradeTile(e.value, e.key)),
            const SizedBox(height: 40),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════
  // تبويب الملاحظات
  // ═══════════════════════════════════════════
  Widget _buildNotesTab() {
    final colors = context.colors;
    return FutureBuilder<StudentNotes>(
      future: _notesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Colors.green.shade600));
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                const SizedBox(height: 12),
                Text('${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => setState(() {
                    _notesFuture = ApiService.getStudentNotes(widget.student.id);
                  }),
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                ),
              ]),
            ),
          );
        }

        final n = snapshot.data!;
        if (n.total == 0) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 60),
              _buildEmptyBox('لا توجد ملاحظات بعد', Icons.sticky_note_2_outlined),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ─── إحصائيات سريعة ───
            Row(children: [
              _buildStatCard('إيجابية', '${n.positive}', Icons.star_outline, Colors.green),
              const SizedBox(width: 10),
              _buildStatCard('سلبية', '${n.negative}', Icons.warning_amber_outlined, Colors.red),
              const SizedBox(width: 10),
              _buildStatCard('معلومات', '${n.info}', Icons.info_outline, Colors.blue),
            ]),
            const SizedBox(height: 20),
            _buildSectionTitle('كل الملاحظات', '${n.total} ملاحظة'),
            const SizedBox(height: 12),
            ...n.notes.asMap().entries.map((e) => _buildNoteTile(e.value, e.key)),
            const SizedBox(height: 40),
          ],
        );
      },
    );
  }

  Widget _buildNoteTile(NoteItem note, int index) {
    final colors = context.colors;
    final color = _noteTypeColor(note.type);
    final icon = _noteTypeIcon(note.type);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 250 + (index * 30)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(20 * (1 - value), 0),
        child: Opacity(opacity: value, child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: colors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            right: BorderSide(color: color.shade400, width: 4),
            top: BorderSide(color: colors.cardBorder),
            bottom: BorderSide(color: colors.cardBorder),
            left: BorderSide(color: colors.cardBorder),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: context.isDark
                      ? color.shade900.withOpacity(0.4)
                      : color.shade50,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: color.shade400, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(note.title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: colors.textPrimary)),
              ),
              Text(ApiService.formatDateArabic(note.date),
                  style: TextStyle(fontSize: 10, color: colors.textTertiary)),
            ]),
            const SizedBox(height: 10),
            Text(note.content,
                style: TextStyle(
                    fontSize: 13, height: 1.5, color: colors.textSecondary)),
          ]),
        ),
      ),
    );
  }

  MaterialColor _noteTypeColor(String type) {
    switch (type) {
      case 'POSITIVE':
        return Colors.green;
      case 'NEGATIVE':
        return Colors.red;
      case 'INFO':
        return Colors.blue;
      case 'JOURNAL':
      default:
        return Colors.orange;
    }
  }

  IconData _noteTypeIcon(String type) {
    switch (type) {
      case 'POSITIVE':
        return Icons.star_outline;
      case 'NEGATIVE':
        return Icons.warning_amber_outlined;
      case 'INFO':
        return Icons.info_outline;
      case 'JOURNAL':
      default:
        return Icons.menu_book_outlined;
    }
  }

  // ═══════════════════════════════════════════
  // عناصر مساعدة
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
      builder: (context, value, child) => SizedBox(
        width: 130, height: 130,
        child: Stack(alignment: Alignment.center, children: [
          CustomPaint(
            size: const Size(130, 130),
            painter: _RingPainter(
              progress: value,
              color: color,
              backgroundColor: Colors.white.withOpacity(0.2),
              strokeWidth: 10,
            ),
          ),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('${(value * 100).round()}%',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            const Text('نسبة الحضور',
                style: TextStyle(color: Colors.white70, fontSize: 11)),
          ]),
        ]),
      ),
    );
  }

  Widget _buildAverageCard(double average) {
    final color = average >= 15
        ? Colors.green
        : average >= 10
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [color.shade700, color.shade400],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('المعدل العام',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              Text(average.toStringAsFixed(2),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Text('/ 20',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.8), fontSize: 16)),
            ]),
          ]),
        ),
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
          ),
          child: Center(
            child: Icon(
              average >= 15
                  ? Icons.emoji_events
                  : average >= 10
                      ? Icons.thumb_up
                      : Icons.warning_amber_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildAssessmentAvgTile(AssessmentAverage a) {
    final colors = context.colors;
    final pct = a.avg / 20;
    final color = pct >= 0.75 ? Colors.green : pct >= 0.5 ? Colors.orange : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.isDark ? color.shade900.withOpacity(0.4) : color.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.assignment_outlined, color: color.shade400, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.assessment,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: colors.textPrimary)),
            const SizedBox(height: 2),
            Text('${a.count} نقطة',
                style: TextStyle(fontSize: 11, color: colors.textTertiary)),
          ]),
        ),
        Text(a.avg.toStringAsFixed(2),
            style: TextStyle(
                color: color.shade400,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        const SizedBox(width: 4),
        Text('/ 20', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
      ]),
    );
  }

  Widget _buildGradeTile(StudentGrade g, int index) {
    final colors = context.colors;
    final pct = g.score / g.maxScore;
    final color = pct >= 0.75 ? Colors.green : pct >= 0.5 ? Colors.orange : Colors.red;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 250 + (index * 30)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(20 * (1 - value), 0),
        child: Opacity(opacity: value, child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: colors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border(right: BorderSide(color: color.shade400, width: 4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: context.isDark ? color.shade900.withOpacity(0.4) : color.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(g.score.toStringAsFixed(g.score % 1 == 0 ? 0 : 1),
                    style: TextStyle(
                        color: color.shade400,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(g.assessment,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: colors.textPrimary)),
                const SizedBox(height: 2),
                Text('${ApiService.formatDateArabic(g.date)} • معامل ${g.coeff}',
                    style: TextStyle(fontSize: 11, color: colors.textTertiary)),
              ]),
            ),
            Text('/ ${g.maxScore.toInt()}',
                style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          ]),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, MaterialColor color) {
    final colors = context.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: colors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.cardBorder, width: 1),
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.isDark ? color.shade900.withOpacity(0.4) : color.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color.shade400, size: 20),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary)),
          Text(label, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
        ]),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String? trailing) {
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
      Text(title,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary)),
      const Spacer(),
      if (trailing != null)
        Text(trailing, style: TextStyle(color: colors.textTertiary, fontSize: 12)),
    ]);
  }

  Widget _buildEmptyBox(String text, IconData icon) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(children: [
        Icon(icon, size: 72, color: colors.textTertiary),
        const SizedBox(height: 16),
        Text(text,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: colors.textPrimary)),
      ]),
    );
  }

  Widget _buildAttendanceTile(AttendanceRecord record, int index) {
    final colors = context.colors;
    final isPresent = record.status == 'PRESENT';
    final color = isPresent ? Colors.green : Colors.red;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 250 + (index * 30)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(20 * (1 - value), 0),
        child: Opacity(opacity: value, child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: colors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border(right: BorderSide(color: color.shade400, width: 4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: context.isDark ? color.shade900.withOpacity(0.4) : color.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(isPresent ? Icons.check : Icons.close,
                  color: color.shade400, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(ApiService.formatDateArabic(record.date),
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: colors.textPrimary)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: context.isDark ? color.shade900.withOpacity(0.4) : color.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(isPresent ? 'حاضر' : 'غائب',
                  style: TextStyle(
                      color: color.shade400,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
          ]),
        ),
      ),
    );
  }
}

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

    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

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