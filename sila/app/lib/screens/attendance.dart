import 'package:flutter/material.dart';
import '../services/api.dart';
import '../shared/widgets/student_avatar.dart';
import '../theme/app_theme.dart';

class AttendanceScreen extends StatefulWidget {
  final SchoolClass schoolClass;
  const AttendanceScreen({super.key, required this.schoolClass});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Student> _students = [];
  Map<int, String> _records = {};
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final students = await ApiService.getStudents(widget.schoolClass.id);
      final attendance = await ApiService.getAttendance(
        classId: widget.schoolClass.id,
        date: _selectedDate,
      );
      final records = <int, String>{};
      for (final entry in attendance) {
        if (entry.status != null) records[entry.studentId] = entry.status!;
      }
      setState(() {
        _students = students;
        _records = records;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _setStatus(int studentId, String status) {
    setState(() {
      if (_records[studentId] == status) {
        _records.remove(studentId);
      } else {
        _records[studentId] = status;
      }
    });
  }

  void _markAllPresent() {
    setState(() {
      for (final s in _students) {
        _records[s.id] = 'PRESENT';
      }
    });
    _showSnack('تم تعليم الكل كحاضر', isError: false);
  }

  Future<void> _save() async {
    final missing = _students.where((s) => !_records.containsKey(s.id)).length;
    if (missing > 0) {
      _showSnack('يجب تحديد حالة كل التلاميذ ($missing ناقص)', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final saved = await ApiService.saveAttendance(
        classId: widget.schoolClass.id,
        date: _selectedDate,
        records: _records,
      );
      _showSnack('تم حفظ حضور $saved تلميذ بنجاح', isError: false);
    } catch (e) {
      _showSnack('فشل الحفظ: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    // ✅ لا نُفرض ColorScheme - نستخدم ثيم التطبيق
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('ar'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadData();
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
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  int get _presentCount => _records.values.where((v) => v == 'PRESENT').length;
  int get _absentCount => _records.values.where((v) => v == 'ABSENT').length;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('تسجيل الحضور'),
        centerTitle: true,
        backgroundColor: colors.headerGradientMid,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(children: [
        _buildHeader(),
        Expanded(child: _buildBody()),
      ]),
      bottomNavigationBar:
          _students.isEmpty || _loading ? null : _buildBottomBar(),
    );
  }

  Widget _buildHeader() {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [colors.headerGradientMid, colors.headerGradientEnd],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(children: [
        Material(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _pickDate,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                const Icon(Icons.calendar_today,
                    color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    ApiService.formatDateArabic(_selectedDate),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, color: Colors.white),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(children: [
          _buildStatCard('الحاضرون', _presentCount, Icons.check_circle),
          const SizedBox(width: 10),
          _buildStatCard('الغائبون', _absentCount, Icons.cancel),
          const SizedBox(width: 10),
          _buildStatCard('المجموع', _students.length, Icons.people),
        ]),
      ]),
    );
  }

  Widget _buildStatCard(String label, int count, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 4),
          Text('$count',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _buildBody() {
    final colors = context.colors;
    if (_loading) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircularProgressIndicator(color: Colors.green.shade600),
          const SizedBox(height: 16),
          Text('جاري التحميل...',
              style: TextStyle(color: colors.textSecondary)),
        ]),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    size: 60, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text('خطأ: $_error',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.textPrimary)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ]),
        ),
      );
    }

    if (_students.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group_off, size: 72, color: colors.textTertiary),
                const SizedBox(height: 16),
                Text('لا يوجد تلاميذ في هذا القسم',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary)),
                const SizedBox(height: 8),
                Text('أضف تلاميذاً أولاً من شاشة القسم',
                    style:
                        TextStyle(color: colors.textSecondary, fontSize: 13)),
              ]),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: Colors.green.shade600,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _students.length,
        itemBuilder: (context, index) =>
            _buildStudentRow(_students[index], index),
      ),
    );
  }

  Widget _buildStudentRow(Student student, int index) {
    final colors = context.colors;
    final status = _records[student.id];
    final isPresent = status == 'PRESENT';
    final isAbsent = status == 'ABSENT';
    final isUnset = status == null;

    final borderColor = isPresent
        ? Colors.green.shade300
        : isAbsent
            ? Colors.red.shade300
            : colors.cardBorder;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 250 + (index * 30)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, 15 * (1 - value)),
        child: Opacity(opacity: value, child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: colors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(context.isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            StudentAvatar(
              studentId: student.id,
              fullName: student.fullName,
              photoBase64: student.photoUrl,
              size: 44,
              borderRadius: 12,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student.fullName,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: colors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(
                      isUnset ? 'لم يُحدَّد' : isPresent ? 'حاضر' : 'غائب',
                      style: TextStyle(
                        fontSize: 11,
                        color: isPresent
                            ? Colors.green.shade600
                            : isAbsent
                                ? Colors.red.shade600
                                : colors.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ]),
            ),
            _buildToggle(
              icon: Icons.check,
              label: 'حاضر',
              isActive: isPresent,
              isGreen: true,
              onTap: () => _setStatus(student.id, 'PRESENT'),
            ),
            const SizedBox(width: 6),
            _buildToggle(
              icon: Icons.close,
              label: 'غائب',
              isActive: isAbsent,
              isGreen: false,
              onTap: () => _setStatus(student.id, 'ABSENT'),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildToggle({
    required IconData icon,
    required String label,
    required bool isActive,
    required bool isGreen,
    required VoidCallback onTap,
  }) {
    final color = isGreen ? Colors.green : Colors.red;
    return Material(
      color: isActive
          ? color.shade600
          : (context.isDark
              ? color.shade900.withOpacity(0.3)
              : color.shade50),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon,
                size: 16,
                color: isActive ? Colors.white : color.shade400),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: isActive ? Colors.white : color.shade400,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ]),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDark ? 0.4 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _saving ? null : _markAllPresent,
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('الكل حاضر'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green.shade600,
                side: BorderSide(color: Colors.green.shade600, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save, size: 20),
              label: Text(_saving ? 'جاري الحفظ...' : 'حفظ الحضور',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}