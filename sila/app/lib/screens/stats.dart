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
  String _period = 'month';
  late Future<AdvancedStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _statsFuture = ApiService.getAdvancedStats(
        classId: widget.schoolClass.id,
        period: _period,
      );
    });
  }

  void _changePeriod(String p) {
    if (_period == p) return;
    setState(() => _period = p);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('الإحصائيات'),
        centerTitle: true,
        backgroundColor: colors.headerGradientMid,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPeriodSelector(),
          Expanded(
            child: FutureBuilder<AdvancedStats>(
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
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // اختيار الفترة
  // ═══════════════════════════════════════════
  Widget _buildPeriodSelector() {
    final colors = context.colors;
    final periods = [
      {'key': 'week', 'label': 'الأسبوع'},
      {'key': 'month', 'label': 'الشهر'},
      {'key': 'term', 'label': 'الفصل'},
      {'key': 'all', 'label': 'الكل'},
    ];

    return Container(
      color: colors.background,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: context.isDark
              ? const Color(0xFF1A2027)
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: periods.map((p) {
            final isActive = _period == p['key'];
            return Expanded(
              child: Material(
                color:
                    isActive ? Colors.green.shade600 : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _changePeriod(p['key']!),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      p['label']!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isActive
                            ? Colors.white
                            : colors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CircularProgressIndicator(color: Colors.green.shade600),
        const SizedBox(height: 16),
        Text('جاري التحميل...',
            style: TextStyle(color: context.colors.textSecondary)),
      ]),
    );
  }

  Widget _buildError(String error) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text('خطأ: $error',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textPrimary)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white),
              ),
            ]),
      ),
    );
  }

  Widget _buildContent(AdvancedStats stats) {
    return RefreshIndicator(
      onRefresh: () async => _load(),
      color: Colors.green.shade600,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMainCard(stats),
          const SizedBox(height: 16),
          _buildKpiRow(stats),
          const SizedBox(height: 20),
          if (stats.insights.isNotEmpty) ...[
            _buildInsights(stats.insights),
            const SizedBox(height: 20),
          ],
          if (stats.dailyTrend.any((d) => d.present + d.absent > 0)) ...[
            _buildSectionTitle(
                'اتجاه الحضور اليومي', Icons.show_chart),
            const SizedBox(height: 12),
            _buildDailyTrendChart(stats.dailyTrend),
            const SizedBox(height: 20),
          ],
          if (stats.weekdayRates.any((r) => r > 0)) ...[
            _buildSectionTitle('حسب أيام الأسبوع', Icons.calendar_month),
            const SizedBox(height: 12),
            _buildWeekdayChart(stats.weekdayRates),
            const SizedBox(height: 20),
          ],
          if (stats.topStudents.isNotEmpty) ...[
            _buildSectionTitle('الأكثر التزاماً', Icons.star, Colors.amber),
            const SizedBox(height: 12),
            _buildRankList(stats.topStudents, isTop: true),
            const SizedBox(height: 20),
          ],
          if (stats.worstStudents.isNotEmpty) ...[
            _buildSectionTitle(
                'يحتاجون متابعة', Icons.warning_amber, Colors.red),
            const SizedBox(height: 12),
            _buildRankList(stats.worstStudents, isTop: false),
            const SizedBox(height: 20),
          ],
          if (stats.atRiskStudents.isNotEmpty) ...[
            _buildSectionTitle(
                'في خطر (أقل من 60%)', Icons.error_outline, Colors.red),
            const SizedBox(height: 12),
            _buildAtRiskList(stats.atRiskStudents),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // البطاقة الكبرى
  // ═══════════════════════════════════════════
  Widget _buildMainCard(AdvancedStats stats) {
    final rate = stats.overview.rate;
    final trend = stats.overview.trend;
    final hasData = stats.overview.total > 0;

    final color = rate >= 75
        ? Colors.green
        : rate >= 50
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: hasData
              ? [color.shade700, color.shade500]
              : [Colors.grey.shade600, Colors.grey.shade400],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: (hasData ? color : Colors.grey).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stats.className,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    '${stats.classLevel} • ${stats.totalStudents} تلميذ',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withOpacity(0.3), width: 2),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$rate%',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                    const Text('نسبة الحضور',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 9)),
                  ],
                ),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Container(
              height: 1, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 16),
          Row(children: [
            _buildMainStat('السجلات', '${stats.overview.total}',
                Icons.event_note),
            _buildMainDivider(),
            _buildMainStat('حضور', '${stats.overview.present}',
                Icons.check_circle),
            _buildMainDivider(),
            _buildMainStat('غياب', '${stats.overview.absent}',
                Icons.cancel),
          ]),
          if (hasData && stats.overview.prevRate > 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Icon(
                  trend > 0
                      ? Icons.trending_up
                      : trend < 0
                          ? Icons.trending_down
                          : Icons.trending_flat,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    trend > 0
                        ? 'تحسّن بنسبة +$trend% مقارنة بالفترة السابقة'
                        : trend < 0
                            ? 'انخفاض بنسبة $trend% مقارنة بالفترة السابقة'
                            : 'لا تغيير ملحوظ مقارنة بالفترة السابقة',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMainStat(String label, String value, IconData icon) {
    return Expanded(
      child: Column(children: [
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 20),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.8), fontSize: 11)),
      ]),
    );
  }

  Widget _buildMainDivider() {
    return Container(
        width: 1, height: 40, color: Colors.white.withOpacity(0.15));
  }

  // ═══════════════════════════════════════════
  // صف KPI
  // ═══════════════════════════════════════════
  Widget _buildKpiRow(AdvancedStats stats) {
    return Row(children: [
      Expanded(
        child: _buildKpiCard(
          icon: Icons.check_circle,
          label: 'حضور',
          value: '${stats.overview.present}',
          color: Colors.green,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _buildKpiCard(
          icon: Icons.cancel,
          label: 'غياب',
          value: '${stats.overview.absent}',
          color: Colors.red,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _buildKpiCard(
          icon: Icons.warning_amber,
          label: 'في خطر',
          value: '${stats.atRiskCount}',
          color: Colors.orange,
        ),
      ),
    ]);
  }

  Widget _buildKpiCard({
    required IconData icon,
    required String label,
    required String value,
    required MaterialColor color,
  }) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.isDark
                ? color.shade900.withOpacity(0.4)
                : color.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color.shade600, size: 18),
        ),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary)),
        const SizedBox(height: 2),
        Text(label,
            style:
                TextStyle(fontSize: 11, color: colors.textSecondary)),
      ]),
    );
  }

  // ═══════════════════════════════════════════
  // Insights
  // ═══════════════════════════════════════════
  Widget _buildInsights(List<Insight> insights) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('ملاحظات ذكية', Icons.lightbulb_outline,
            Colors.amber),
        const SizedBox(height: 12),
        ...insights.map((insight) => _buildInsightCard(insight)),
      ],
    );
  }

  Widget _buildInsightCard(Insight insight) {
    final colors = context.colors;
    MaterialColor color;
    IconData icon;

    switch (insight.type) {
      case 'positive':
        color = Colors.green;
        icon = Icons.trending_up;
        break;
      case 'negative':
        color = Colors.red;
        icon = Icons.trending_down;
        break;
      case 'warning':
        color = Colors.orange;
        icon = Icons.warning_amber;
        break;
      default:
        color = Colors.blue;
        icon = Icons.info_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
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
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.isDark
                ? color.shade900.withOpacity(0.4)
                : color.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color.shade600, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            insight.message,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary),
          ),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════
  // رسم الاتجاه اليومي (Line Chart)
  // ═══════════════════════════════════════════
  Widget _buildDailyTrendChart(List<DailyTrendPoint> data) {
    final colors = context.colors;
    final activeData =
        data.where((d) => d.present + d.absent > 0).toList();
    if (activeData.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.cardBorder),
      ),
      child: SizedBox(
        height: 220,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: 100,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 25,
              getDrawingHorizontalLine: (value) => FlLine(
                color: colors.divider,
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  interval: 25,
                  getTitlesWidget: (value, meta) => Text(
                    '${value.toInt()}%',
                    style: TextStyle(
                        color: colors.textTertiary, fontSize: 10),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 5,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= data.length) {
                      return const SizedBox.shrink();
                    }
                    if (idx % 5 != 0) return const SizedBox.shrink();
                    final d = data[idx].date;
                    final parts = d.split('-');
                    if (parts.length < 3) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '${parts[2]}/${parts[1]}',
                        style: TextStyle(
                            color: colors.textTertiary, fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => Colors.green.shade800,
                tooltipRoundedRadius: 10,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    return LineTooltipItem(
                      '${spot.y.toInt()}%',
                      const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    );
                  }).toList();
                },
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(
                  data.length,
                  (i) => FlSpot(i.toDouble(), data[i].rate.toDouble()),
                ),
                isCurved: true,
                curveSmoothness: 0.35,
                color: Colors.green.shade600,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) {
                    if (spot.y == 0) return FlDotCirclePainter(
                      radius: 0,
                      color: Colors.transparent,
                      strokeWidth: 0,
                      strokeColor: Colors.transparent,
                    );
                    return FlDotCirclePainter(
                      radius: 3,
                      color: Colors.green.shade600,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.withOpacity(0.3),
                      Colors.green.withOpacity(0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // رسم أيام الأسبوع (Bar Chart)
  // ═══════════════════════════════════════════
  Widget _buildWeekdayChart(List<int> rates) {
    final colors = context.colors;
    const dayLabels = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
    final maxRate =
        rates.isEmpty ? 0 : rates.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.cardBorder),
      ),
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: 100,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 25,
              getDrawingHorizontalLine: (value) => FlLine(
                color: colors.divider,
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  interval: 25,
                  getTitlesWidget: (value, meta) => Text(
                    '${value.toInt()}%',
                    style: TextStyle(
                        color: colors.textTertiary, fontSize: 10),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= 7) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        dayLabels[idx],
                        style: TextStyle(
                            color: colors.textTertiary, fontSize: 9),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => Colors.green.shade800,
                tooltipRoundedRadius: 10,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${rod.toY.toInt()}%',
                    const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  );
                },
              ),
            ),
            barGroups: List.generate(7, (i) {
              final rate = rates.length > i ? rates[i] : 0;
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: rate.toDouble(),
                    color: rate == maxRate && maxRate > 0
                        ? Colors.green.shade600
                        : (rate > 0 ? Colors.green.shade300 : Colors.grey.shade300),
                    width: 20,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(6),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // قائمة ترتيب
  // ═══════════════════════════════════════════
  Widget _buildRankList(List<StudentRank> list, {required bool isTop}) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        children: List.generate(list.length, (i) {
          final s = list[i];
          final isLast = i == list.length - 1;
          return Column(children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(children: [
                Container(
                  width: 30,
                  height: 30,
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
                Expanded(
                  child: Text(s.fullName,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: colors.textPrimary)),
                ),
                Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${s.rate}%',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isTop
                                  ? Colors.green.shade600
                                  : Colors.red.shade600)),
                      Text('${s.present} حضور • ${s.absent} غياب',
                          style: TextStyle(
                              fontSize: 10, color: colors.textTertiary)),
                    ]),
              ]),
            ),
            if (!isLast)
              Divider(
                  height: 1,
                  color: colors.divider,
                  indent: 14,
                  endIndent: 14),
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
  // قائمة الطلاب في خطر
  // ═══════════════════════════════════════════
  Widget _buildAtRiskList(List<AtRiskStudent> list) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200, width: 1.5),
      ),
      child: Column(
        children: List.generate(list.length, (i) {
          final s = list[i];
          final isLast = i == list.length - 1;
          return Column(children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.isDark
                        ? const Color(0xFF3A1A1A)
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.warning_amber,
                      color: Color(0xFFEF5350), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(s.fullName,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: colors.textPrimary)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${s.rate}%',
                      style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
              ]),
            ),
            if (!isLast)
              Divider(
                  height: 1,
                  color: colors.divider,
                  indent: 14,
                  endIndent: 14),
          ]);
        }),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // عنوان قسم
  // ═══════════════════════════════════════════
  Widget _buildSectionTitle(String title, IconData icon,
      [Color? color]) {
    final colors = context.colors;
    final c = color ?? Colors.green.shade700;
    return Row(children: [
      Container(
        width: 4,
        height: 20,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 10),
      Icon(icon, size: 18, color: c),
      const SizedBox(width: 6),
      Text(title,
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary)),
    ]);
  }
}