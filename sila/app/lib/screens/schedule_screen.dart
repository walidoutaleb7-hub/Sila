import 'package:flutter/material.dart';
import '../services/api.dart';
import '../theme/app_theme.dart';

class ScheduleScreen extends StatefulWidget {
  final List<SchoolClass> classes;
  const ScheduleScreen({super.key, required this.classes});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<ScheduleItem>> _scheduleFuture;
  int _selectedDay = 1;

  @override
  void initState() {
    super.initState();
    // ابدأ باليوم الحالي
    final today = DateTime.now().weekday;
    _selectedDay = today;
    _tabController = TabController(
      length: 7,
      vsync: this,
      initialIndex: today - 1,
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() => _selectedDay = _tabController.index + 1);
    });
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _load() {
    setState(() {
      _scheduleFuture = ApiService.getSchedule();
    });
  }

  Future<void> _showAddDialog() async {
    if (widget.classes.isEmpty) {
      _showSnack('أضف قسماً أولاً', isError: true);
      return;
    }

    int? selectedClassId = widget.classes.first.id;
    final subjectController = TextEditingController();
    final roomController = TextEditingController();
    TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 9, minute: 0);

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final colors = context.colors;
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22)),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            title: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.isDark
                      ? const Color(0xFF1B3A1E)
                      : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_alarm,
                    color: Color(0xFF4CAF50), size: 22),
              ),
              const SizedBox(width: 12),
              const Text('حصة جديدة',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 17)),
            ]),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // اليوم
                  _dialogLabel(context, 'اليوم', Icons.today),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: colors.inputFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.cardBorder),
                    ),
                    child: DropdownButton<int>(
                      value: _selectedDay,
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      dropdownColor: colors.cardBg,
                      style: TextStyle(
                          color: colors.textPrimary, fontSize: 14),
                      items: List.generate(7, (i) {
                        return DropdownMenuItem(
                          value: i + 1,
                          child: Text(ApiService.dayName(i + 1)),
                        );
                      }),
                      onChanged: (v) =>
                          setDialogState(() => _selectedDay = v!),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // القسم
                  _dialogLabel(context, 'القسم', Icons.class_outlined),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: colors.inputFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.cardBorder),
                    ),
                    child: DropdownButton<int>(
                      value: selectedClassId,
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      dropdownColor: colors.cardBg,
                      style: TextStyle(
                          color: colors.textPrimary, fontSize: 14),
                      items: widget.classes
                          .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text('${c.name} (${c.level})'),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setDialogState(() => selectedClassId = v),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // المادة
                  _dialogLabel(context, 'المادة', Icons.menu_book_outlined),
                  const SizedBox(height: 8),
                  _buildTextField(
                    context,
                    controller: subjectController,
                    hint: 'مثال: رياضيات',
                  ),
                  const SizedBox(height: 14),

                  // الوقت
                  _dialogLabel(context, 'الوقت', Icons.access_time),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: _buildTimeButton(
                        context,
                        label: 'من',
                        time: startTime,
                        onTap: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: startTime,
                          );
                          if (t != null) setDialogState(() => startTime = t);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTimeButton(
                        context,
                        label: 'إلى',
                        time: endTime,
                        onTap: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: endTime,
                          );
                          if (t != null) setDialogState(() => endTime = t);
                        },
                      ),
                    ),
                  ]),
                  const SizedBox(height: 14),

                  // القاعة
                  _dialogLabel(context, 'القاعة (اختياري)', Icons.meeting_room_outlined),
                  const SizedBox(height: 8),
                  _buildTextField(
                    context,
                    controller: roomController,
                    hint: 'مثال: قاعة 5',
                  ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                    foregroundColor: colors.textSecondary),
                child: const Text('إلغاء'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  if (subjectController.text.trim().isEmpty) return;
                  Navigator.pop(context, {
                    'dayOfWeek': _selectedDay,
                    'classId': selectedClassId,
                    'subject': subjectController.text.trim(),
                    'startTime': _formatTime(startTime),
                    'endTime': _formatTime(endTime),
                    'room': roomController.text.trim(),
                  });
                },
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('إضافة',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (result == null) return;

    try {
      await ApiService.createSchedule(
        classId: result['classId'] as int,
        dayOfWeek: result['dayOfWeek'] as int,
        startTime: result['startTime'] as String,
        endTime: result['endTime'] as String,
        subject: result['subject'] as String,
        room: (result['room'] as String).isEmpty
            ? null
            : result['room'] as String,
      );
      _load();
      if (mounted) _showSnack('تم إضافة الحصة', isError: false);
    } catch (e) {
      if (mounted) _showSnack('$e', isError: true);
    }
  }

  String _formatTime(TimeOfDay t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Widget _dialogLabel(BuildContext context, String label, IconData icon) {
    final colors = context.colors;
    return Row(children: [
      Icon(icon,
          size: 14,
          color: context.isDark
              ? const Color(0xFF81C784)
              : Colors.green.shade600),
      const SizedBox(width: 6),
      Text(label,
          style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: colors.textPrimary)),
    ]);
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
  }) {
    final colors = context.colors;
    return TextField(
      controller: controller,
      style: TextStyle(color: colors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: colors.textTertiary, fontSize: 13),
        filled: true,
        fillColor: colors.inputFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors.cardBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: context.isDark
                    ? const Color(0xFF4CAF50)
                    : Colors.green.shade300,
                width: 1.5)),
      ),
    );
  }

  Widget _buildTimeButton(
    BuildContext context, {
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.inputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10, color: colors.textTertiary)),
            const SizedBox(height: 2),
            Row(children: [
              Icon(Icons.access_time,
                  size: 16,
                  color: context.isDark
                      ? const Color(0xFF81C784)
                      : Colors.green.shade600),
              const SizedBox(width: 6),
              Text(_formatTime(time),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: colors.textPrimary)),
            ]),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(ScheduleItem item) async {
    final colors = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.isDark
                  ? const Color(0xFF3A1A1A)
                  : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete_outline,
                color: Color(0xFFEF5350), size: 22),
          ),
          const SizedBox(width: 12),
          const Text('حذف الحصة',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 17)),
        ]),
        content: Text(
          'هل أنت متأكد من حذف حصة "${item.subject}"؟',
          style: TextStyle(color: colors.textSecondary, fontSize: 14),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
                foregroundColor: colors.textSecondary),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('حذف',
                style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.deleteSchedule(item.id);
        _load();
        if (mounted) _showSnack('تم حذف الحصة', isError: false);
      } catch (e) {
        if (mounted) _showSnack('$e', isError: true);
      }
    }
  }

  void _showSnack(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline : Icons.check_circle,
            color: Colors.white),
        const SizedBox(width: 8),
        Expanded(child: Text(message)),
      ]),
      backgroundColor:
          isError ? Colors.red.shade700 : Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('جدول الأسبوع'),
        centerTitle: true,
        backgroundColor: colors.headerGradientMid,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 12),
          tabs: List.generate(
            7,
            (i) => Tab(text: ApiService.dayName(i + 1)),
          ),
        ),
      ),
      body: FutureBuilder<List<ScheduleItem>>(
        future: _scheduleFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: Colors.green.shade600));
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 60, color: Colors.red.shade400),
                      const SizedBox(height: 16),
                      Text('${snapshot.error}',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: colors.textSecondary)),
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

          final all = snapshot.data ?? [];
          final dayItems =
              all.where((s) => s.dayOfWeek == _selectedDay).toList();

          if (dayItems.isEmpty) {
            return _buildEmpty(colors);
          }

          return RefreshIndicator(
            onRefresh: () async => _load(),
            color: Colors.green.shade600,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: dayItems.length,
              itemBuilder: (context, i) => _buildItemCard(dayItems[i], i),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('حصة جديدة',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmpty(AppColors colors) {
    return Center(
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
                child: const Icon(Icons.event_note,
                    size: 64, color: Color(0xFF4CAF50)),
              ),
              const SizedBox(height: 20),
              Text('لا يوجد حصص في هذا اليوم',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary)),
              const SizedBox(height: 8),
              Text('اضغط زر + لإضافة أول حصة',
                  style: TextStyle(
                      color: colors.textSecondary, fontSize: 14)),
            ]),
      ),
    );
  }

  Widget _buildItemCard(ScheduleItem item, int index) {
    final colors = context.colors;
    final now = DateTime.now();
    final isToday = now.weekday == item.dayOfWeek;
    final currentTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final isCurrent = isToday &&
        currentTime.compareTo(item.startTime) >= 0 &&
        currentTime.compareTo(item.endTime) < 0;
    final isPast = isToday && currentTime.compareTo(item.endTime) >= 0;

    final color = isCurrent
        ? Colors.green
        : isPast
            ? Colors.grey
            : Colors.blue;

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
          border: Border(
            right: BorderSide(color: color.shade400, width: 5),
            top: BorderSide(
                color: isCurrent ? color.shade200 : colors.cardBorder,
                width: isCurrent ? 1.5 : 1),
            bottom: BorderSide(
                color: isCurrent ? color.shade200 : colors.cardBorder,
                width: isCurrent ? 1.5 : 1),
            left: BorderSide(
                color: isCurrent ? color.shade200 : colors.cardBorder,
                width: isCurrent ? 1.5 : 1),
          ),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isCurrent) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.shade600,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_circle_fill,
                          size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text('الآن',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Row(children: [
                // الوقت
                Container(
                  width: 70,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: context.isDark
                        ? color.shade900.withOpacity(0.4)
                        : color.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(children: [
                    Text(item.startTime,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: color.shade600)),
                    Container(
                      width: 20,
                      height: 1,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: color.shade300,
                    ),
                    Text(item.endTime,
                        style: TextStyle(
                            fontSize: 11,
                            color: color.shade600,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
                const SizedBox(width: 14),
                // التفاصيل
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.subject,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: colors.textPrimary)),
                      const SizedBox(height: 6),
                      Row(children: [
                        Icon(Icons.class_,
                            size: 13, color: colors.textTertiary),
                        const SizedBox(width: 4),
                        Text(item.className,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colors.textSecondary)),
                        if (item.classLevel.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text('• ${item.classLevel}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: colors.textTertiary)),
                        ],
                      ]),
                      if (item.room != null &&
                          item.room!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(children: [
                          Icon(Icons.meeting_room_outlined,
                              size: 13, color: colors.textTertiary),
                          const SizedBox(width: 4),
                          Text(item.room!,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: colors.textTertiary)),
                        ]),
                      ],
                    ],
                  ),
                ),
                // زر الحذف
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      size: 18, color: colors.textTertiary),
                  onPressed: () => _confirmDelete(item),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}