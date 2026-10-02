import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../services/api.dart';
import '../theme/app_theme.dart';

class StatsScreen extends StatefulWidget {
  final SchoolClass schoolClass;
  const StatsScreen({super.key, required this.schoolClass});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late Future<ClassStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _statsFuture = ApiService.getClassStats(widget.schoolClass.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('إحصائيات القسم'),
        centerTitle: true,
        backgroundColor: colors.headerGradientMid,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<ClassStats>(
        future: _statsFuture,
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
            onPressed: _load,
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
    );
  }

  Widget _buildContent(ClassStats stats) {
    if (stats.overall.total == 0) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async => _load(),
      color: Colors.green.shade600,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMainCard(stats),
          const SizedBox(height: 20),
          _buildSectionTitle('آخر 7 أيام'),
          const SizedBox(height: 12),
          _buildWeekChart(stats),
          const SizedBox(height: 20),
          _buildSectionTitle('اليوم'),
          const SizedBox(height: 12),
          _buildTodayRow(stats),
          const SizedBox(height: 20),
          if (stats.topStudents.isNotEmpty) ...[
            _buildSectionTitle('الأكثر التزاماً'),
            const SizedBox(height: 12),
            _buildRankList(stats.topStudents, isTop: true),
            const SizedBox(height: 20),
          ],
          if (stats.worstStudents.isNotEmpty) ...[
            _buildSectionTitle('الأكثر غياباً'),
            const SizedBox(height: 12),
            _buildRankList(stats.worstStudents, isTop: false),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
            child: const Icon(Icons.bar_chart, size: 64, color: Color(0xFF4CAF50)),
          ),
          const SizedBox(height: 20),
          Text('لا توجد بيانات كافية',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary)),
          const SizedBox(height: 8),
          Text('ابدأ بتسجيل الحضور لعرض الإحصائيات',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // بطاقة الإحصائيات الكبرى
  // ═══════════════════════════════════════════
  Widget _buildMainCard(ClassStats stats) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [colors.headerGradientMid, colors.headerGradientEnd],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(stats.className,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('المستوى ${stats.classLevel} • ${stats.totalStudents} تلميذ',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.85), fontSize: 13)),
            ]),
          ),
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            ),
            child: Center(
              child: Text('${stats.overall.rate}%',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
        const SizedBox(height: 20),
        Container(height: 1, color: Colors.white.withOpacity(0.15)),
        const SizedBox(height: 16),
        Row(children: [
          _buildMainStat('إجمالي السجلات', '${stats.overall.total}', Icons.event_note),
          _buildDivider(),
          _buildMainStat('الحضور', '${stats.overall.present}', Icons.check_circle),
          _buildDivider(),
          _buildMainStat('الغياب', '${stats.overall.absent}', Icons.cancel),
        ]),
      ]),
    );
  }

  Widget _buildMainStat(String label, String value, IconData icon) {
    return Expanded(
      child: Column(children: [
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 20),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
      ]),
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 40, color: Colors.white.withOpacity(0.15));
  }

  // ═══════════════════════════════════════════
  // رسم بياني لآخر 7 أيام
  // ═══════════════════════════════════════════
  Widget _buildWeekChart(ClassStats stats) {
    final colors = context.colors;
    final maxVal = stats.last7Days
        .map((d) => d.present + d.absent)
        .fold<int>(0, (a, b) => a > b ? a : b);
    final maxY = (maxVal == 0 ? 5 : maxVal + 2).toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 20, 12),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => Colors.green.shade800,
                tooltipRoundedRadius: 10,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    rod.toY.toInt().toString(),
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: (maxY / 4).ceilToDouble(),
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: TextStyle(color: colors.textTertiary, fontSize: 10),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= stats.last7Days.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        ApiService.formatShortDate(stats.last7Days[idx].date),
                        style: TextStyle(color: colors.textTertiary, fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: (maxY / 4).ceilToDouble(),
              getDrawingHorizontalLine: (value) => FlLine(
                color: colors.divider,
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(stats.last7Days.length, (i) {
              final day = stats.last7Days[i];
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: day.present.toDouble(),
                    color: Colors.green.shade500,
                    width: 12,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(6),
                    ),
                  ),
                  BarChartRodData(
                    toY: day.absent.toDouble(),
                    color: Colors.red.shade400,
                    width: 12,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(6),
                    ),
                  ),
                ],
                barsSpace: 4,
              );
            }),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // إحصائيات اليوم
  // ═══════════════════════════════════════════
  Widget _buildTodayRow(ClassStats stats) {
    final hasToday = stats.today.present + stats.today.absent > 0;

    return Row(children: [
      Expanded(
        child: _buildTodayCard(
          label: 'حضور اليوم',
          value: '${stats.today.present}',
          icon: Icons.check_circle,
          color: Colors.green,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _buildTodayCard(
          label: 'غياب اليوم',
          value: '${stats.today.absent}',
          icon: Icons.cancel,
          color: Colors.red,
        ),
      ),
      if (!hasToday) ...[
        // ملاحظة بسيطة إذا لم يُسجَّل اليوم
      ],
    ]);
  }

  Widget _buildTodayCard({
    required String label,
    required String value,
    required IconData icon,
    required MaterialColor color,
  }) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder, width: 1),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: context.isDark ? color.shade900.withOpacity(0.4) : color.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color.shade400, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary)),
            Text(label,
                style: TextStyle(fontSize: 12, color: colors.textSecondary)),
          ]),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════
  // قائمة الترتيب
  // ═══════════════════════════════════════════
  Widget _buildRankList(List<StudentRank> list, {required bool isTop}) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder, width: 1),
      ),
      child: Column(
        children: List.generate(list.length, (i) {
          final s = list[i];
          final isLast = i == list.length - 1;
          return Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(children: [
                // الترتيب
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: _getRankColor(i, isTop),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 12),

                // الاسم
                Expanded(
                  child: Text(s.fullName,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: colors.textPrimary)),
                ),

                // الإحصائيات
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('${s.rate}%',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isTop
                              ? Colors.green.shade600
                              : Colors.red.shade600)),
                  Text('${s.present} حضور • ${s.absent} غياب',
                      style: TextStyle(fontSize: 10, color: colors.textTertiary)),
                ]),
              ]),
            ),
            if (!isLast)
              Divider(height: 1, color: colors.divider, indent: 14, endIndent: 14),
          ]);
        }),
      ),
    );
  }

  Color _getRankColor(int index, bool isTop) {
    if (index == 0) {
      return isTop ? const Color(0xFFFFB300) : const Color(0xFFC62828);
    } else if (index == 1) {
      return isTop ? const Color(0xFF9E9E9E) : const Color(0xFFE53935);
    } else if (index == 2) {
      return isTop ? const Color(0xFF8D6E63) : const Color(0xFFEF5350);
    }
    return isTop ? Colors.green.shade400 : Colors.red.shade300;
  }

  // ═══════════════════════════════════════════
  // عنوان قسم
  // ═══════════════════════════════════════════
  Widget _buildSectionTitle(String title) {
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
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary)),
    ]);
  }
}