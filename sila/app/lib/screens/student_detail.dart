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
  // Quick Actions
  // ═══════════════════════════════════════════
  Future<void> _makeCall(String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      _showNoPhoneSnack();
      return;
    }
    final uri = Uri.parse('tel:${phone.trim()}');
    try {
      await launchUrl(uri);
    } catch (_) {
      _showErrorSnack();
    }
  }

  Future<void> _openWhatsApp(String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      _showNoPhoneSnack();
      return;
    }
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    final withCC = cleanPhone.startsWith('0')
        ? '213${cleanPhone.substring(1)}'
        : cleanPhone;
    final uri = Uri.parse('https://wa.me/$withCC');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      _showErrorSnack();
    }
  }

  Future<void> _sendSMS(String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      _showNoPhoneSnack();
      return;
    }
    final uri = Uri.parse('sms:${phone.trim()}');
    try {
      await launchUrl(uri);
    } catch (_) {
      _showErrorSnack();
    }
  }

  void _showNoPhoneSnack() {
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

  void _showErrorSnack() {
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
                  Text('تعذّر التحميل',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary)),
                  const SizedBox(height: 8),
                  Text(error,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: colors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _loadAll,
                    icon: const Icon(Icons.refresh),
                    label: const Text('إعادة المحاولة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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
          expandedHeight: 200,
          pinned: true,
          backgroundColor: colors.headerGradientMid,
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
                    padding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    colors.headerGradientMid,
                    colors.headerGradientEnd,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 60, 20, 20),
                  child: Row(
                    children: [
                      // الصورة
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                              color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(19),
                          child: _buildAvatar(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // الاسم + المعلومات
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              history.student.fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(children: [
                              const Icon(Icons.badge_outlined,
                                  size: 13, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text(
                                'رقم ${history.student.id}',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                            ]),
                            if (widget.student.guardianPhone != null &&
                                widget.student.guardianPhone!
                                    .trim()
                                    .isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(children: [
                                const Icon(Icons.phone_iphone,
                                    size: 13, color: Colors.white70),
                                const SizedBox(width: 4),
                                Text(
                                  widget.student.guardianPhone!,
                                  style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12),
                                ),
                              ]),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green.shade400, Colors.green.shade700],
        ),
      ),
      child: Center(
        child: Text(initials,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 32)),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // Tab 1: Attendance
  // ═══════════════════════════════════════════
  Widget _buildAttendanceTab(StudentHistory history) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildComparisonCard(history),
        const SizedBox(height: 14),
        _buildQuickActions(),
        const SizedBox(height: 14),
        Row(children: [
          _buildStatCard('حضور', '${history.present}',
              Icons.check_circle, Colors.green),
          const SizedBox(width: 10),
          _buildStatCard('غياب', '${history.absent}',
              Icons.cancel, Colors.red),
          const SizedBox(width: 10),
          _buildStatCard('المجموع', '${history.total}',
              Icons.event, Colors.blue),
        ]),
        const SizedBox(height: 20),
        _buildHeatmap(history.records),
        const SizedBox(height: 20),
        _buildSectionTitle('سجل الحضور', '${history.records.length} يوم'),
        const SizedBox(height: 12),
        if (history.records.isEmpty)
          _buildEmptyBox('لا يوجد سجل حضور بعد', Icons.event_busy)
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

  // ═══════════════════════════════════════════
  // Comparison with class average
  // ═══════════════════════════════════════════
  Widget _buildComparisonCard(StudentHistory h) {
    final colors = context.colors;
    final studentRate = h.rate;
    final classRate = h.classAverageRate;
    final diff = studentRate - classRate;
    final hasData = h.total > 0 && classRate > 0;

    final isAbove = diff >= 0;
    final statusColor = !hasData
        ? Colors.grey
        : isAbove
            ? Colors.green
            : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: !hasData
              ? [Colors.grey.shade600, Colors.grey.shade400]
              : [statusColor.shade700, statusColor.shade500],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.analytics_outlined,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasData
                      ? (isAbove
                          ? 'ممتاز! فوق المعدل'
                          : 'يحتاج تحسيناً')
                      : 'لا توجد بيانات كافية',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  hasData
                      ? (isAbove
                          ? 'متقدم بـ +$diff% عن متوسط القسم'
                          : 'متأخر بـ $diff% عن متوسط القسم')
                      : 'سجّل حضوراً لعرض المقارنة',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12),
                ),
              ],
            ),
          ),
          if (hasData)
            Icon(
              isAbove ? Icons.trending_up : Icons.trending_down,
              color: Colors.white,
              size: 28,
            ),
        ]),
        const SizedBox(height: 16),
        Container(height: 1, color: Colors.white.withOpacity(0.15)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: _buildComparisonValue(
                'التلميذ', '$studentRate%', Colors.white),
          ),
          Container(
              width: 1, height: 50, color: Colors.white.withOpacity(0.15)),
          Expanded(
            child: _buildComparisonValue(
                'متوسط القسم', '$classRate%', Colors.white70),
          ),
        ]),
      ]),
    );
  }

  Widget _buildComparisonValue(
      String label, String value, Color color) {
    return Column(children: [
      Text(value,
          style: TextStyle(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.1)),
      const SizedBox(height: 4),
      Text(label,
          style: TextStyle(
              color: Colors.white.withOpacity(0.7), fontSize: 11)),
    ]);
  }

  // ═══════════════════════════════════════════
  // Quick actions
  // ═══════════════════════════════════════════
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
            Icon(Icons.flash_on,
                size: 16, color: Colors.amber.shade600),
            const SizedBox(width: 6),
            Text('إجراءات سريعة',
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
              color: enabled ? color.shade200 : context.colors.cardBorder,
            ),
          ),
          child: Column(children: [
            Icon(icon,
                size: 20,
                color: enabled ? color.shade600 : context.colors.textTertiary),
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
  // Heatmap
  // ═══════════════════════════════════════════
  Widget _buildHeatmap(List<AttendanceRecord> records) {
    final colors = context.colors;
    final now = DateTime.now();
    final days = <DateTime>[];
    for (int i = 29; i >= 0; i--) {
      days.add(now.subtract(Duration(days: i)));
    }

    final Map<String, String> statusByDate = {};
    for (final r in records) {
      final key = '${r.date.year}-${r.date.month}-${r.date.day}';
      if (statusByDate[key] != 'ABSENT') {
        statusByDate[key] = r.status;
      }
    }

    int presentCount = 0;
    int absentCount = 0;
    for (final key in statusByDate.keys) {
      if (statusByDate[key] == 'PRESENT') presentCount++;
      if (statusByDate[key] == 'ABSENT') absentCount++;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.local_fire_department,
                size: 18, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            Text('خريطة آخر 30 يوم',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary)),
            const Spacer(),
            Text('$presentCount ✅ / $absentCount ❌',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colors.textSecondary)),
          ]),
          const SizedBox(height: 14),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: days.map((d) {
              final key = '${d.year}-${d.month}-${d.day}';
              final status = statusByDate[key];
              final color = status == 'PRESENT'
                  ? Colors.green.shade500
                  : status == 'ABSENT'
                      ? Colors.red.shade400
                      : colors.inputFill;
              return Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: status == null
                        ? colors.cardBorder
                        : Colors.transparent,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${d.day}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: status == null
                          ? colors.textTertiary
                          : Colors.white,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // Tab 2: Grades
  // ═══════════════════════════════════════════
  Widget _buildGradesTab() {
    final colors = context.colors;
    return FutureBuilder<StudentGrades>(
      future: _gradesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(
                  color: Colors.green.shade600));
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
                        _gradesFuture =
                            ApiService.getStudentGrades(widget.student.id);
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
              _buildSectionTitle(
                  'تطور الدرجات', Icons.show_chart),
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
            _buildSectionTitle(
                'كل النقاط', '${g.count} نقطة'),
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
    final sorted = [...grades]
      ..sort((a, b) => a.date.compareTo(b.date));
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
                  reservedSize: 30,
                  interval: 5,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: TextStyle(
                        color: colors.textTertiary, fontSize: 10),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval:
                      (recent.length / 4).ceilToDouble().clamp(1, 10),
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= recent.length) {
                      return const SizedBox.shrink();
                    }
                    final d = recent[idx].date;
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '${d.day}/${d.month}',
                        style: TextStyle(
                            color: colors.textTertiary, fontSize: 9),
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
                      spot.y.toStringAsFixed(1),
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
                  recent.length,
                  (i) => FlSpot(i.toDouble(), recent[i].score),
                ),
                isCurved: true,
                curveSmoothness: 0.3,
                color: Colors.green.shade600,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                    radius: 3.5,
                    color: Colors.green.shade600,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
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
  // Tab 3: Notes
  // ═══════════════════════════════════════════
  Widget _buildNotesTab() {
    final colors = context.colors;
    return FutureBuilder<StudentNotes>(
      future: _notesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(
                  color: Colors.green.shade600));
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
                        _notesFuture =
                            ApiService.getStudentNotes(widget.student.id);
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
            _buildSectionTitle(
                'كل الملاحظات', '${n.total} ملاحظة'),
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
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
            border:
                Border.all(color: Colors.white.withOpacity(0.3), width: 2),
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
    final color = pct >= 0.75
        ? Colors.green
        : pct >= 0.5
            ? Colors.orange
            : Colors.red;

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
          child: Icon(Icons.assignment_outlined,
              color: color.shade400, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.assessment,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: colors.textPrimary)),
            const SizedBox(height: 2),
            Text('${a.count} نقطة',
                style:
                    TextStyle(fontSize: 11, color: colors.textTertiary)),
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
    final color = pct >= 0.75
        ? Colors.green
        : pct >= 0.5
            ? Colors.orange
            : Colors.red;

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
                    g.score
                        .toStringAsFixed(g.score % 1 == 0 ? 0 : 1),
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
                            fontSize: 11,
                            color: colors.textTertiary)),
                  ]),
            ),
            Text('/ ${g.maxScore.toInt()}',
                style:
                    TextStyle(color: colors.textTertiary, fontSize: 12)),
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

  Widget _buildSectionTitle(String title, String? trailing) {
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