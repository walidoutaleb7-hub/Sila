import 'package:flutter/material.dart';
import '../services/api.dart';
import '../theme/app_theme.dart';
import 'grades_entry.dart';

class GradesListScreen extends StatefulWidget {
  final SchoolClass schoolClass;
  const GradesListScreen({super.key, required this.schoolClass});

  @override
  State<GradesListScreen> createState() => _GradesListScreenState();
}

class _GradesListScreenState extends State<GradesListScreen> {
  late Future<List<GradeSession>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _sessionsFuture = ApiService.getClassGrades(widget.schoolClass.id);
    });
  }

  void _goToEntry() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GradesEntryScreen(schoolClass: widget.schoolClass),
      ),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('درجات القسم'),
        centerTitle: true,
        backgroundColor: colors.headerGradientMid,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<GradeSession>>(
        future: _sessionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading();
          }
          if (snapshot.hasError) {
            return _buildError(snapshot.error.toString());
          }
          final sessions = snapshot.data ?? [];
          if (sessions.isEmpty) return _buildEmpty();
          return _buildList(sessions);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToEntry,
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('تقييم جديد',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildLoading() {
    final colors = context.colors;
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CircularProgressIndicator(color: Colors.green.shade600),
        const SizedBox(height: 16),
        Text('جاري التحميل...', style: TextStyle(color: colors.textSecondary)),
      ]),
    );
  }

  Widget _buildError(String error) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text('خطأ: $error',
              textAlign: TextAlign.center, style: TextStyle(color: colors.textPrimary)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
          ),
        ]),
      ),
    );
  }

  Widget _buildEmpty() {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                context.isDark ? const Color(0xFF1B3A1E) : Colors.green.shade50,
                context.isDark ? const Color(0xFF1B3A1E) : Colors.green.shade100,
              ]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.grade_outlined, size: 64, color: Color(0xFF4CAF50)),
          ),
          const SizedBox(height: 20),
          Text('لا توجد درجات بعد',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary)),
          const SizedBox(height: 8),
          Text('اضغط زر + لإضافة أول تقييم',
              style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        ]),
      ),
    );
  }

  Widget _buildList(List<GradeSession> sessions) {
    return RefreshIndicator(
      onRefresh: () async => _load(),
      color: Colors.green.shade600,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sessions.length,
        itemBuilder: (context, index) => _buildSessionCard(sessions[index], index),
      ),
    );
  }

  Widget _buildSessionCard(GradeSession s, int index) {
    final colors = context.colors;
    final pct = s.maxScore > 0 ? s.avg / s.maxScore : 0.0;
    final MaterialColor gradeColor = pct >= 0.75
        ? Colors.green
        : pct >= 0.5
            ? Colors.orange
            : Colors.red;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 250 + (index * 40)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, 15 * (1 - value)),
        child: Opacity(opacity: value, child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.cardBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(context.isDark ? 0.3 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.isDark
                      ? gradeColor.shade900.withOpacity(0.4)
                      : gradeColor.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.assignment_outlined,
                    color: gradeColor.shade400, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.assessment,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: colors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(ApiService.formatDateArabic(s.date),
                      style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: context.isDark
                      ? gradeColor.shade900.withOpacity(0.4)
                      : gradeColor.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(children: [
                  Text(s.avg.toStringAsFixed(2),
                      style: TextStyle(
                          color: gradeColor.shade400,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  Text('من ${s.maxScore.toInt()}',
                      style: TextStyle(color: gradeColor.shade400, fontSize: 10)),
                ]),
              ),
            ]),
            const SizedBox(height: 12),
            Divider(height: 1, color: colors.divider),
            const SizedBox(height: 12),
            Row(children: [
              _buildChip(Icons.people_outline, '${s.count} تلميذ', colors),
              const SizedBox(width: 8),
              _buildChip(Icons.scale_outlined, 'معامل ${s.coeff}', colors),
              const SizedBox(width: 8),
              if (s.note != null && s.note!.isNotEmpty)
                Expanded(
                  child: Text(s.note!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.textTertiary, fontSize: 11)),
                ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String text, AppColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.inputFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: colors.textTertiary),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 11, color: colors.textSecondary)),
      ]),
    );
  }
}