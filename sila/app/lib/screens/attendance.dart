import 'package:flutter/material.dart';
import '../services/api.dart';

class AttendanceScreen extends StatefulWidget {
  final SchoolClass schoolClass;

  const AttendanceScreen({super.key, required this.schoolClass});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Student> _students = [];
  Map<int, String> _records = {}; // studentId → PRESENT/ABSENT
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
      // 1. جلب التلاميذ
      final students = await ApiService.getStudents(widget.schoolClass.id);

      // 2. جلب سجل الحضور الحالي (إن وُجد)
      final attendance = await ApiService.getAttendance(
        classId: widget.schoolClass.id,
        date: _selectedDate,
      );

      // 3. دمج البيانات
      final records = <int, String>{};
      for (final entry in attendance) {
        if (entry.status != null) {
          records[entry.studentId] = entry.status!;
        }
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

  void _toggleStatus(int studentId) {
    setState(() {
      final current = _records[studentId];
      if (current == 'PRESENT') {
        _records[studentId] = 'ABSENT';
      } else {
        _records[studentId] = 'PRESENT';
      }
    });
  }

  void _markAllPresent() {
    setState(() {
      for (final student in _students) {
        _records[student.id] = 'PRESENT';
      }
    });
    _showSnack('تم تعليم الكل كحاضر', isError: false);
  }

  Future<void> _save() async {
    // تحقق: كل التلاميذ لهم حالة
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
      setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('ar'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green.shade700,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadData();
    }
  }

  void _showSnack(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
            ),
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

  int get _presentCount =>
      _records.values.where((v) => v == 'PRESENT').length;
  int get _absentCount =>
      _records.values.where((v) => v == 'ABSENT').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('تسجيل الحضور'),
        centerTitle: true,
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ═══════ شريط التاريخ + الإحصائيات ═══════
          _buildHeader(),

          // ═══════ المحتوى ═══════
          Expanded(child: _buildBody()),
        ],
      ),
      bottomNavigationBar: _students.isEmpty || _loading
          ? null
          : _buildBottomBar(),
    );
  }

  // ─────────────────────────────────────────
  // الرأس: التاريخ + العداد
  // ─────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Colors.green.shade800, Colors.green.shade600],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // اختيار التاريخ
          Material(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _pickDate,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _formatDateArabic(_selectedDate),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down,
                        color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // الإحصائيات
          Row(
            children: [
              _buildStatCard(
                label: 'الحاضرون',
                count: _presentCount,
                icon: Icons.check_circle,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              _buildStatCard(
                label: 'الغائبون',
                count: _absentCount,
                icon: Icons.cancel,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              _buildStatCard(
                label: 'المجموع',
                count: _students.length,
                icon: Icons.people,
                color: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // المحتوى الرئيسي
  // ─────────────────────────────────────────
  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.green.shade700),
            const SizedBox(height: 16),
            Text(
              'جاري التحميل...',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
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
              Text('خطأ: $_error', textAlign: TextAlign.center),
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
            ],
          ),
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
              Icon(Icons.group_off,
                  size: 72, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'لا يوجد تلاميذ في هذا القسم',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF37474F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'أضف تلاميذاً أولاً من شاشة القسم',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: Colors.green.shade700,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _students.length,
        itemBuilder: (context, index) {
          final student = _students[index];
          return _buildStudentRow(student, index);
        },
      ),
    );
  }

  Widget _buildStudentRow(Student student, int index) {
    final status = _records[student.id];
    final isPresent = status == 'PRESENT';
    final isAbsent = status == 'ABSENT';
    final isUnset = status == null;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 250 + (index * 30)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 15 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPresent
                ? Colors.green.shade300
                : isAbsent
                    ? Colors.red.shade300
                    : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // الاسم
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF263238),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isUnset
                          ? 'لم يُحدَّد'
                          : isPresent
                              ? 'حاضر'
                              : 'غائب',
                      style: TextStyle(
                        fontSize: 12,
                        color: isPresent
                            ? Colors.green.shade700
                            : isAbsent
                                ? Colors.red.shade700
                                : Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // أزرار التبديل
              _buildToggleButton(
                icon: Icons.check,
                label: 'حاضر',
                isActive: isPresent,
                color: Colors.green,
                onTap: () => _setStatus(student.id, 'PRESENT'),
              ),
              const SizedBox(width: 8),
              _buildToggleButton(
                icon: Icons.close,
                label: 'غائب',
                isActive: isAbsent,
                color: Colors.red,
                onTap: () => _setStatus(student.id, 'ABSENT'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required MaterialColor color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isActive ? color.shade600 : color.shade50,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive ? Colors.white : color.shade700,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : color.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  // ─────────────────────────────────────────
  // الشريط السفلي: الأزرار
  // ─────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // زر الكل حاضر
            Expanded(
              flex: 1,
              child: OutlinedButton.icon(
                onPressed: _saving ? null : _markAllPresent,
                icon: const Icon(Icons.done_all, size: 18),
                label: const Text('الكل حاضر'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green.shade700,
                  side: BorderSide(color: Colors.green.shade700, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // زر الحفظ
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save, size: 20),
                label: Text(
                  _saving ? 'جاري الحفظ...' : 'حفظ الحضور',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // تنسيق التاريخ بالعربية
  // ─────────────────────────────────────────
  String _formatDateArabic(DateTime d) {
    const days = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد'
    ];
    const months = [
      'جانفي',
      'فيفري',
      'مارس',
      'أفريل',
      'ماي',
      'جوان',
      'جويلية',
      'أوت',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];
    final dayName = days[d.weekday - 1];
    final monthName = months[d.month - 1];
    return '$dayName، ${d.day} $monthName ${d.year}';
  }
}