import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api.dart';
import '../theme/app_theme.dart';
import 'messaging_screen.dart';

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

  // ═══════════════════════════════════════════
  // Quick actions
  // ═══════════════════════════════════════════
  Future<void> _makeCall(String? phone) async {
    if (phone == null || phone.trim().isEmpty) return _showNoPhone();
    try {
      await launchUrl(Uri.parse('tel:${phone.trim()}'));
    } catch (_) {
      _showError();
    }
  }

  Future<void> _openWhatsApp(String? phone) async {
    if (phone == null || phone.trim().isEmpty) return _showNoPhone();
    final clean = phone.replaceAll(RegExp(r'[^\d]'), '');
    final withCC = clean.startsWith('0') ? '213${clean.substring(1)}' : clean;
    try {
      await launchUrl(Uri.parse('https://wa.me/$withCC'),
          mode: LaunchMode.externalApplication);
    } catch (_) {
      _showError();
    }
  }

  Future<void> _sendSMS(String? phone) async {
    if (phone == null || phone.trim().isEmpty) return _showNoPhone();
    try {
      await launchUrl(Uri.parse('sms:${phone.trim()}'));
    } catch (_) {
      _showError();
    }
  }

  void _showNoPhone() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Row(children: [
        Icon(Icons.phone_disabled, color: Colors.white),
        SizedBox(width: 8),
        Text('لا يوجد رقم هاتف للولي'),
      ]),
      backgroundColor: Colors.orange.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showError() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('تعذّر فتح التطبيق'),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _goToMessaging() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessagingScreen(student: widget.student),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // Build
  // ═══════════════════════════════════════════
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
            Text('جاري التحميل...',
                style: TextStyle(color: colors.textSecondary)),
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
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 60, color: Colors.red.shade400),
                  const SizedBox(height: 16),
                  Text(error,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.textSecondary)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _loadAll,
                    icon: const Icon(Icons.refresh),
                    label: const Text('إعادة المحاولة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ]),
          ),
        ),
      ),
    ]);
  }

  Widget _buildContent(StudentHistory history) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverAppBar(
          expandedHeight: 180,
          pinned: true,
          backgroundColor: context.colors.headerGradientMid,
          foregroundColor: Colors.white,
          actions: [
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Material(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _goToMessaging,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.message_outlined, size: 18),
                        SizedBox(width: 6),
                        Text('مراسلة',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: EdgeInsets.zero,
            background: _buildCompactHeader(history),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 12),
            tabs: const [
              Tab(icon: Icon(Icons.event_available, size: 18), text: 'الحضور'),
              Tab(icon: Icon(Icons.grade_outlined, size: 18), text: 'الدرجات'),
              Tab(
                  icon: Icon(Icons.sticky_note_2_outlined, size: 18),
                  text: 'الملاحظات'),
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
  // Compact header with status
  // ═══════════════════════════════════════════
  Widget _buildCompactHeader(StudentHistory history) {
    final status = _computeStatus(history);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            context.colors.headerGradientMid,
            context.colors.headerGradientEnd,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 50, 16, 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: Colors.white, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: _buildAvatar(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          history.student.fullName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(children: [
                          const Icon(Icons.badge_outlined,
                              size: 11, color: Colors.white70),
                          const SizedBox(width: 3),
                          Text('رقم ${history.student.id}',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 11)),
                          if (widget.student.guardianPhone != null &&
                              widget.student.guardianPhone!
                                  .trim()
                                  .isNotEmpty) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.phone_iphone,
                                size: 11, color: Colors.white70),
                            const SizedBox(width: 3),
                            Text(widget.student.guardianPhone!,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 11)),
                          ],
                        ]),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: status.color,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(status.icon, size: 13, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(status.label,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final hasPhoto = widget.student.photoUrl != null &&
        widget.student.photoUrl!.trim().isNotEmpty;
    if (hasPhoto) {
      try {
        return Image.memory(
          base64Decode(widget.student.photoUrl!),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => _initialsAvatar(),
        );
      } catch (_) {
        return _initialsAvatar();
      }
    }
    return _initialsAvatar();
  }

  Widget _initialsAvatar() {
    final name = widget.student.fullName;
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(' ').length >= 2
            ? '${name.trim().split(' ')[0][0]}${name.trim().split(' ')[1][0]}'
            : name.trim()[0];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade700],
        ),
      ),
      child: Center(
        child: Text(initials,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20)),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // Status computation
  // ═══════════════════════════════════════════
  _StudentStatus _computeStatus(StudentHistory h) {
    if (h.total == 0) {
      return const _StudentStatus(
        label: 'جديد',
        icon: Icons.fiber_new,
        color: Color(0xFF9E9E9E),
      );
    }
    if (h.consecutiveAbsences >= 5) {
      return const _StudentStatus(
        label: 'خطر',
        icon: Icons.warning,
        color: Color(0xFFC62828),
      );
    }
    if (h.rate >= 90) {
      return const _StudentStatus(
        label: 'ممتاز',
        icon: Icons.star,
        color: Color(0xFF2E7D32),
      );
    }
    if (h.rate >= 75) {
      return const _StudentStatus(
        label: 'جيد',
        icon: Icons.check_circle,
        color: Color(0xFF43A047),
      );
    }
    if (h.rate >= 60) {
      return const _StudentStatus(
        label: 'متابعة',
        icon: Icons.info,
        color: Color(0xFFF9A825),
      );
    }
    return const _StudentStatus(
      label: 'تحذير',
      icon: Icons.warning_amber,
      color: Color(0xFFEF5350),
    );
  }

  // ═══════════════════════════════════════════
  // TAB 1: ATTENDANCE
  // ═══════════════════════════════════════════
  Widget _buildAttendanceTab(StudentHistory history) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ⭐ Feature 1: Smart Insights
        _buildSmartInsights(history),

        // ⭐ Feature 2: Weekly Trend
        _buildWeeklyTrend(history),

        // ⭐ Feature 3: Next Action
        _buildNextAction(history),

        // Quick Actions
        _buildQuickActions(),

        // Stats
        const SizedBox(height: 8),
        Row(children: [
          _buildStatCard('حضور', '${history.present}',
              Icons.check_circle, Colors.green),
          const SizedBox(width: 10),
          _buildStatCard('غياب', '${history.absent}',
              Icons.cancel, Colors.red),
          const SizedBox(width: 10),
          _buildStatCard('النسبة', '${history.rate}%',
              Icons.percent, Colors.blue),
        ]),
        const SizedBox(height: 20),

        // ⭐ Feature 4: Recent Activity
        _buildRecentActivity(history),
        const SizedBox(height: 20),

        _buildSectionTitle('سجل الحضور', '${history.records.length} يوم'),
        const SizedBox(height: 12),
        if (history.records.isEmpty)
          _buildEmptyBox('لا يوجد سجل بعد', Icons.event_busy)
        else
          ...history.records
              .take(15)
              .toList()
              .asMap()
              .entries
              .map((e) => _buildAttendanceTile(e.value, e.key)),
        const SizedBox(height: 40),
      ],
    );
  }

  // ─────────────────────────────────────────
  // ⭐ FEATURE 1: Smart Insights
  // ─────────────────────────────────────────
  Widget _buildSmartInsights(StudentHistory h) {
    final insights = _computeInsights(h);
    if (insights.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('تحليل ذكي', '${insights.length} ملاحظة'),
        const SizedBox(height: 12),
        ...insights.map((i) => _buildInsightRow(i)),
        const SizedBox(height: 20),
      ],
    );
  }

  List<_InsightData> _computeInsights(StudentHistory h) {
    final list = <_InsightData>[];

    if (h.total == 0) return list;

    // 1. Attendance status
    if (h.rate >= 90) {
      list.add(_InsightData(
        icon: Icons.verified,
        color: Colors.green,
        text: 'حضور ممتاز (${h.rate}%) — من الأكثر التزاماً',
      ));
    } else if (h.rate < 60) {
      list.add(_InsightData(
        icon: Icons.error_outline,
        color: Colors.red,
        text: 'حضور ضعيف (${h.rate}%) — يحتاج تدخل فوري',
      ));
    }

    // 2. Consecutive absences
    if (h.consecutiveAbsences >= 3) {
      list.add(_InsightData(
        icon: Icons.warning_amber,
        color: Colors.orange,
        text: 'غاب ${h.consecutiveAbsences} أيام متتالية — تواصل مع الولي',
      ));
    }

    // 3. Class comparison
    if (h.classAverageRate > 0) {
      final diff = h.rate - h.classAverageRate;
      if (diff >= 5) {
        list.add(_InsightData(
          icon: Icons.trending_up,
          color: Colors.green,
          text: 'فوق متوسط القسم بـ +$diff%',
        ));
      } else if (diff <= -5) {
        list.add(_InsightData(
          icon: Icons.trending_down,
          color: Colors.orange,
          text: 'تحت متوسط القسم بـ ${diff.abs()}%',
        ));
      }
    }

    // 4. Absences this month
    final monthAbsences = h.records
        .where((r) =>
            r.status == 'ABSENT' &&
            r.date.month == DateTime.now().month &&
            r.date.year == DateTime.now().year)
        .length;
    if (monthAbsences >= 3) {
      list.add(_InsightData(
        icon: Icons.event_busy,
        color: Colors.orange,
        text: '$monthAbsences غيابات هذا الشهر',
      ));
    }

    // 5. Perfect week detection
    final thisWeek = h.records.where((r) {
      final diff = DateTime.now().difference(r.date).inDays;
      return diff >= 0 && diff <= 7;
    }).toList();
    if (thisWeek.length >= 3 &&
        thisWeek.every((r) => r.status == 'PRESENT')) {
      list.add(_InsightData(
        icon: Icons.celebration,
        color: Colors.green,
        text: 'حضر كل حصص هذا الأسبوع ✨',
      ));
    }

    return list.take(4).toList();
  }

  Widget _buildInsightRow(_InsightData data) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: data.color.withOpacity(0.3),
          width: 1.2,
        ),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: context.isDark
                ? data.color.withOpacity(0.15)
                : data.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(data.icon, size: 16, color: data.color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            data.text,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary),
          ),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────
  // ⭐ FEATURE 2: Weekly Trend Chart
  // ─────────────────────────────────────────
  Widget _buildWeeklyTrend(StudentHistory h) {
    if (h.records.isEmpty) return const SizedBox.shrink();

    // Last 4 weeks
    final weeks = <int>[];
    for (int i = 3; i >= 0; i--) {
      final startDate = DateTime.now()
          .subtract(Duration(days: i * 7 + 6))
          .subtract(const Duration(hours: 1));
      final endDate = DateTime.now().subtract(Duration(days: i * 7));

      final weekRecords = h.records.where((r) {
        return r.date.isAfter(startDate) &&
            r.date.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();

      if (weekRecords.isEmpty) {
        weeks.add(0);
      } else {
        final present =
            weekRecords.where((r) => r.status == 'PRESENT').length;
        weeks.add((present / weekRecords.length * 100).round());
      }
    }

    if (weeks.every((w) => w == 0)) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('اتجاه آخر 4 أسابيع', Icons.show_chart),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
          decoration: BoxDecoration(
            color: context.colors.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.colors.cardBorder),
          ),
          child: SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: context.colors.divider,
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
                      getTitlesWidget: (v, m) => Text(
                        '${v.toInt()}%',
                        style: TextStyle(
                            color: context.colors.textTertiary,
                            fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (v, m) {
                        final i = v.toInt();
                        if (i < 0 || i > 3) return const SizedBox.shrink();
                        final labels = ['أسبوع 3', 'أسبوع 2', 'أسبوع 1', 'الآن'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(labels[i],
                              style: TextStyle(
                                  color: context.colors.textTertiary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.green.shade800,
                    tooltipRoundedRadius: 10,
                    getTooltipItem: (g, gi, rod, ri) => BarTooltipItem(
                      '${rod.toY.toInt()}%',
                      const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                barGroups: List.generate(4, (i) {
                  final rate = weeks[i];
                  final color = rate >= 80
                      ? Colors.green.shade500
                      : rate >= 60
                          ? Colors.orange.shade400
                          : rate > 0
                              ? Colors.red.shade400
                              : Colors.grey.shade400;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: rate.toDouble(),
                        color: color,
                        width: 28,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ─────────────────────────────────────────
  // ⭐ FEATURE 3: Next Action
  // ─────────────────────────────────────────
  Widget _buildNextAction(StudentHistory h) {
    final action = _computeAction(h);
    if (action == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('الإجراء المقترح', Icons.flash_on, Colors.amber),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [action.color.shade600, action.color.shade400],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: action.color.withOpacity(0.3),
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(action.icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(action.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(action.subtitle,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 12)),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (action.isCall) {
                      _makeCall(widget.student.guardianPhone);
                    } else if (action.isMessage) {
                      _goToMessaging();
                    }
                  },
                  icon: Icon(action.buttonIcon, size: 18),
                  label: Text(action.buttonLabel,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: action.color.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  _NextAction? _computeAction(StudentHistory h) {
    if (h.total == 0) return null;

    // High priority: consecutive absences
    if (h.consecutiveAbsences >= 5) {
      return _NextAction(
        icon: Icons.phone_in_talk,
        color: Colors.red,
        title: 'اتصال عاجل بالولي',
        subtitle: 'غاب ${h.consecutiveAbsences} أيام متتالية',
        buttonLabel: 'اتصل الآن',
        buttonIcon: Icons.call,
        isCall: true,
      );
    }

    if (h.consecutiveAbsences >= 3) {
      return _NextAction(
        icon: Icons.message_outlined,
        color: Colors.orange,
        title: 'راسل الولي',
        subtitle: 'غاب ${h.consecutiveAbsences} أيام متتالية',
        buttonLabel: 'افتح المراسلة',
        buttonIcon: Icons.send,
        isMessage: true,
      );
    }

    if (h.rate < 60 && h.total >= 5) {
      return _NextAction(
        icon: Icons.trending_down,
        color: Colors.orange,
        title: 'متابعة مطلوبة',
        subtitle: 'نسبة الحضور ${h.rate}% — أقل من المتوقع',
        buttonLabel: 'راسل الولي',
        buttonIcon: Icons.message,
        isMessage: true,
      );
    }

    if (h.rate >= 95 && h.total >= 10) {
      return _NextAction(
        icon: Icons.emoji_events,
        color: Colors.green,
        title: 'أحسنت! كافئه',
        subtitle: 'حضور ممتاز ${h.rate}% — أرسل رسالة تشجيع',
        buttonLabel: 'أرسل تهنئة',
        buttonIcon: Icons.send,
        isMessage: true,
      );
    }

    return null;
  }

  // ─────────────────────────────────────────
  // ⭐ FEATURE 4: Recent Activity Timeline
  // ─────────────────────────────────────────
  Widget _buildRecentActivity(StudentHistory h) {
    final events = <_ActivityEvent>[];

    // Attendance events
    for (final r in h.records.take(10)) {
      events.add(_ActivityEvent(
        date: r.date,
        icon: r.status == 'PRESENT'
            ? Icons.check_circle
            : Icons.cancel,
        color: r.status == 'PRESENT' ? Colors.green : Colors.red,
        title: r.status == 'PRESENT' ? 'حضر' : 'غاب',
        subtitle: r.period == 'MORNING' ? 'صباحاً' : 'مساءً',
      ));
    }

    // Sort by date descending
    events.sort((a, b) => b.date.compareTo(a.date));
    final recent = events.take(6).toList();

    if (recent.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('النشاط الأخير', Icons.history),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: context.colors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colors.cardBorder),
          ),
          child: Column(
            children:
                List.generate(recent.length, (i) {
              final e = recent[i];
              final isLast = i == recent.length - 1;
              return Column(children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.isDark
                            ? e.color.withOpacity(0.15)
                            : e.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:
                          Icon(e.icon, size: 16, color: e.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.title,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color:
                                      context.colors.textPrimary)),
                          const SizedBox(height: 2),
                          Text(e.subtitle,
                              style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      context.colors.textTertiary)),
                        ],
                      ),
                    ),
                    Text(_shortDateArabic(e.date),
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: context.colors.textSecondary)),
                  ]),
                ),
                if (!isLast)
                  Divider(
                      height: 1,
                      color: context.colors.divider,
                      indent: 14,
                      endIndent: 14),
              ]);
            }),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  String _shortDateArabic(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d).inDays;
    if (diff == 0) return 'اليوم';
    if (diff == 1) return 'أمس';
    if (diff < 7) return 'قبل $diff أيام';
    const months = ['جانفي','فيفري','مارس','أفريل','ماي','جوان','جويلية','أوت','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];
    return '${d.day} ${months[d.month - 1]}';
  }

  // ─────────────────────────────────────────
  // Quick Actions
  // ─────────────────────────────────────────
  Widget _buildQuickActions() {
    final phone = widget.student.guardianPhone;
    final hasPhone = phone != null && phone.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.flash_on, size: 16, color: Colors.amber.shade600),
            const SizedBox(width: 6),
            Text('تواصل سريع',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary)),
            if (!hasPhone) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('لا يوجد رقم',
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: _buildQuickAction(
                icon: Icons.call,
                label: 'اتصال',
                color: Colors.blue,
                enabled: hasPhone,
                onTap: () => _makeCall(phone),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickAction(
                icon: Icons.chat,
                label: 'واتساب',
                color: Colors.green,
                enabled: hasPhone,
                onTap: () => _openWhatsApp(phone),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickAction(
                icon: Icons.sms_outlined,
                label: 'SMS',
                color: Colors.purple,
                enabled: hasPhone,
                onTap: () => _sendSMS(phone),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required MaterialColor color,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: enabled
          ? (context.isDark
              ? color.shade900.withOpacity(0.3)
              : color.shade50)
          : context.colors.inputFill,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled
                  ? color.shade200
                  : context.colors.cardBorder,
            ),
          ),
          child: Column(children: [
            Icon(icon,
                size: 20,
                color:
                    enabled ? color.shade600 : context.colors.textTertiary),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: enabled
                        ? color.shade700
                        : context.colors.textTertiary)),
          ]),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // TAB 2: GRADES
  // ═══════════════════════════════════════════
  Widget _buildGradesTab() {
    final colors = context.colors;
    return FutureBuilder<StudentGrades>(
      future: _gradesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child:
                  CircularProgressIndicator(color: Colors.green.shade600));
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: Colors.red.shade400),
                    const SizedBox(height: 12),
                    Text('${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: colors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => setState(() {
                        _gradesFuture = ApiService.getStudentGrades(
                            widget.student.id);
                      }),
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

        final g = snapshot.data!;
        if (g.count == 0) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 60),
              _buildEmptyBox(
                  'لا توجد درجات بعد', Icons.grade_outlined),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildAverageCard(g.average),
            const SizedBox(height: 20),
            if (g.records.isNotEmpty) ...[
              _buildSectionTitle('تطور الدرجات', Icons.show_chart),
              const SizedBox(height: 12),
              _buildGradesChart(g.records),
              const SizedBox(height: 20),
            ],
            if (g.assessmentAverages.isNotEmpty) ...[
              _buildSectionTitle('حسب نوع التقييم',
                  '${g.assessmentAverages.length} نوع'),
              const SizedBox(height: 12),
              ...g.assessmentAverages
                  .map((a) => _buildAssessmentAvgTile(a)),
              const SizedBox(height: 20),
            ],
            _buildSectionTitle('كل النقاط', '${g.count} نقطة'),
            const SizedBox(height: 12),
            ...g.records
                .asMap()
                .entries
                .map((e) => _buildGradeTile(e.value, e.key)),
            const SizedBox(height: 40),
          ],
        );
      },
    );
  }

  Widget _buildGradesChart(List<StudentGrade> grades) {
    final colors = context.colors;
    final sorted = [...grades]..sort((a, b) => a.date.compareTo(b.date));
    final recent = sorted.length > 15
        ? sorted.sublist(sorted.length - 15)
        : sorted;
    if (recent.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.cardBorder),
      ),
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: 20,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 5,
              getDrawingHorizontalLine: (v) => FlLine(
                  color: colors.divider, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 5,
                  getTitlesWidget: (v, m) => Text(v.toInt().toString(),
                      style: TextStyle(
                          color: colors.textTertiary, fontSize: 10)),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval:
                      (recent.length / 4).ceilToDouble().clamp(1, 10),
                  getTitlesWidget: (v, m) {
                    final i = v.toInt();
                    if (i < 0 || i >= recent.length) {
                      return const SizedBox.shrink();
                    }
                    final d = recent[i].date;
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('${d.day}/${d.month}',
                          style: TextStyle(
                              color: colors.textTertiary,
                              fontSize: 9)),
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
                getTooltipItems: (s) => s
                    .map((sp) => LineTooltipItem(
                          sp.y.toStringAsFixed(1),
                          const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ))
                    .toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(recent.length,
                    (i) => FlSpot(i.toDouble(), recent[i].score)),
                isCurved: true,
                curveSmoothness: 0.3,
                color: Colors.green.shade600,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (s, p, b, i) => FlDotCirclePainter(
                      radius: 3.5,
                      color: Colors.green.shade600,
                      strokeWidth: 2,
                      strokeColor: Colors.white),
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
  // TAB 3: NOTES
  // ═══════════════════════════════════════════
  Widget _buildNotesTab() {
    final colors = context.colors;
    return FutureBuilder<StudentNotes>(
      future: _notesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child:
                  CircularProgressIndicator(color: Colors.green.shade600));
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: Colors.red.shade400),
                    const SizedBox(height: 12),
                    Text('${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: colors.textSecondary, fontSize: 13)),
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
              _buildEmptyBox('لا توجد ملاحظات بعد',
                  Icons.sticky_note_2_outlined),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [
              _buildStatCard('إيجابية', '${n.positive}',
                  Icons.star_outline, Colors.green),
              const SizedBox(width: 10),
              _buildStatCard('سلبية', '${n.negative}',
                  Icons.warning_amber_outlined, Colors.red),
              const SizedBox(width: 10),
              _buildStatCard('معلومات', '${n.info}',
                  Icons.info_outline, Colors.blue),
            ]),
            const SizedBox(height: 20),
            _buildSectionTitle('كل الملاحظات', '${n.total} ملاحظة'),
            const SizedBox(height: 12),
            ...n.notes
                .asMap()
                .entries
                .map((e) => _buildNoteTile(e.value, e.key)),
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
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: context.isDark
                          ? color.shade900.withOpacity(0.4)
                          : color.shade50,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child:
                        Icon(icon, color: color.shade400, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(note.title,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: colors.textPrimary)),
                  ),
                  Text(_shortDateArabic(note.date),
                      style: TextStyle(
                          fontSize: 10, color: colors.textTertiary)),
                ]),
                const SizedBox(height: 10),
                Text(note.content,
                    style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: colors.textSecondary)),
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
  // Helpers
  // ═══════════════════════════════════════════
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
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('المعدل العام',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(average.toStringAsFixed(2),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Text('/ 20',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16)),
                    ]),
              ]),
        ),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(
                color: Colors.white.withOpacity(0.3), width: 2),
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
    final color =
        pct >= 0.75 ? Colors.green : pct >= 0.5 ? Colors.orange : Colors.red;

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
            color: context.isDark
                ? color.shade900.withOpacity(0.4)
                : color.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child:
              Icon(Icons.assignment_outlined, color: color.shade400, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.assessment,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: colors.textPrimary)),
                const SizedBox(height: 2),
                Text('${a.count} نقطة',
                    style: TextStyle(
                        fontSize: 11, color: colors.textTertiary)),
              ]),
        ),
        Text(a.avg.toStringAsFixed(2),
            style: TextStyle(
                color: color.shade400,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        const SizedBox(width: 4),
        Text('/ 20',
            style: TextStyle(color: colors.textTertiary, fontSize: 12)),
      ]),
    );
  }

  Widget _buildGradeTile(StudentGrade g, int index) {
    final colors = context.colors;
    final pct = g.score / g.maxScore;
    final color =
        pct >= 0.75 ? Colors.green : pct >= 0.5 ? Colors.orange : Colors.red;

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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: context.isDark
                    ? color.shade900.withOpacity(0.4)
                    : color.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                    g.score.toStringAsFixed(g.score % 1 == 0 ? 0 : 1),
                    style: TextStyle(
                        color: color.shade400,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g.assessment,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: colors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(
                        '${ApiService.formatDateArabic(g.date)} • معامل ${g.coeff}',
                        style: TextStyle(
                            fontSize: 11, color: colors.textTertiary)),
                  ]),
            ),
            Text('/ ${g.maxScore.toInt()}',
                style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          ]),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, MaterialColor color) {
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
              color: context.isDark
                  ? color.shade900.withOpacity(0.4)
                  : color.shade50,
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
          Text(label,
              style: TextStyle(fontSize: 12, color: colors.textSecondary)),
        ]),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String? trailing,
      [Color? color]) {
    final colors = context.colors;
    final c = color ?? Colors.green.shade700;
    return Row(children: [
      Container(
        width: 4,
        height: 20,
        decoration: BoxDecoration(
            color: c, borderRadius: BorderRadius.circular(2)),
      ),
      const SizedBox(width: 10),
      Text(title,
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary)),
      const Spacer(),
      if (trailing != null)
        Text(trailing,
            style:
                TextStyle(color: colors.textTertiary, fontSize: 12)),
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
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary)),
      ]),
    );
  }

  Widget _buildAttendanceTile(AttendanceRecord record, int index) {
    final colors = context.colors;
    final isPresent = record.status == 'PRESENT';
    final isMorning = record.isMorning;
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
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: context.isDark
                    ? color.shade900.withOpacity(0.4)
                    : color.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(isPresent ? Icons.check : Icons.close,
                  color: color.shade400, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ApiService.formatDateArabic(record.date),
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: colors.textPrimary)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(
                        isMorning
                            ? Icons.wb_sunny_outlined
                            : Icons.nights_stay_outlined,
                        size: 12,
                        color: colors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(ApiService.periodName(record.period),
                          style: TextStyle(
                              fontSize: 11,
                              color: colors.textTertiary,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ]),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: context.isDark
                    ? color.shade900.withOpacity(0.4)
                    : color.shade50,
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

// ═══════════════════════════════════════════
// Helper classes
// ═══════════════════════════════════════════
class _StudentStatus {
  final String label;
  final IconData icon;
  final Color color;
  const _StudentStatus({
    required this.label,
    required this.icon,
    required this.color,
  });
}

class _InsightData {
  final IconData icon;
  final Color color;
  final String text;
  _InsightData({
    required this.icon,
    required this.color,
    required this.text,
  });
}

class _NextAction {
  final IconData icon;
  final MaterialColor color;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final IconData buttonIcon;
  final bool isCall;
  final bool isMessage;

  _NextAction({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.buttonIcon,
    this.isCall = false,
    this.isMessage = false,
  });
}

class _ActivityEvent {
  final DateTime date;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  _ActivityEvent({
    required this.date,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}