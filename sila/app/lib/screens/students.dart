import 'package:flutter/material.dart';
import '../services/api.dart';
import '../theme/app_theme.dart';
import 'attendance.dart';
import 'stats.dart';
import 'student_detail.dart';

class StudentsScreen extends StatefulWidget {
  final SchoolClass schoolClass;
  const StudentsScreen({super.key, required this.schoolClass});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  late Future<List<Student>> _studentsFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadStudents() {
    setState(() {
      _studentsFuture = ApiService.getStudents(widget.schoolClass.id);
    });
  }

  Future<void> _showAddStudentDialog() async {
    final nameController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildDialog(
        title: 'إضافة تلميذ',
        icon: Icons.person_add_alt_1_outlined,
        nameController: nameController,
      ),
    );
    if (confirmed == true && nameController.text.trim().isNotEmpty) {
      try {
        await ApiService.createStudent(
          classId: widget.schoolClass.id,
          fullName: nameController.text.trim(),
        );
        _loadStudents();
        if (mounted) _showSnack('تم إضافة التلميذ بنجاح', isError: false);
      } catch (e) {
        if (mounted) _showSnack('خطأ: $e', isError: true);
      }
    }
  }

  Future<void> _showEditStudentDialog(Student student) async {
    final nameController = TextEditingController(text: student.fullName);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildDialog(
        title: 'تعديل بيانات التلميذ',
        icon: Icons.edit_outlined,
        nameController: nameController,
      ),
    );
    if (confirmed == true &&
        nameController.text.trim().isNotEmpty &&
        nameController.text.trim() != student.fullName) {
      try {
        await ApiService.updateStudent(
          studentId: student.id,
          fullName: nameController.text.trim(),
        );
        _loadStudents();
        if (mounted) _showSnack('تم تعديل البيانات', isError: false);
      } catch (e) {
        if (mounted) _showSnack('خطأ: $e', isError: true);
      }
    }
  }

  Future<void> _confirmDelete(Student student) async {
    final colors = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.isDark ? const Color(0xFF3A1A1A) : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete_outline,
                color: Color(0xFFEF5350), size: 22),
          ),
          const SizedBox(width: 12),
          Text('حذف التلميذ',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: colors.textPrimary)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هل أنت متأكد من حذف التلميذ:',
                style: TextStyle(color: colors.textSecondary, fontSize: 14)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colors.inputFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.cardBorder),
              ),
              child: Text(student.fullName,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: colors.textPrimary)),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Icon(Icons.warning_amber_rounded,
                  size: 16, color: Colors.orange.shade700),
              const SizedBox(width: 6),
              Expanded(
                child: Text('سيتم حذف كل سجلات الحضور الخاصة به أيضاً.',
                    style: TextStyle(color: Colors.orange.shade800, fontSize: 12)),
              ),
            ]),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: colors.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('حذف',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ApiService.deleteStudent(student.id);
        _loadStudents();
        if (mounted) _showSnack('تم حذف التلميذ', isError: false);
      } catch (e) {
        if (mounted) _showSnack('خطأ: $e', isError: true);
      }
    }
  }

  Widget _buildDialog({
    required String title,
    required IconData icon,
    required TextEditingController nameController,
  }) {
    final colors = context.colors;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      title: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: context.isDark ? const Color(0xFF1B3A1E) : const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF4CAF50), size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: colors.textPrimary)),
        ),
      ]),
      content: TextField(
        controller: nameController,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        style: TextStyle(color: colors.textPrimary),
        decoration: InputDecoration(
          labelText: 'الاسم الكامل',
          hintText: 'مثال: أحمد بن علي',
          hintStyle: TextStyle(color: colors.textTertiary, fontSize: 13),
          labelStyle: TextStyle(
            color: context.isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(Icons.badge_outlined,
              color: context.isDark ? const Color(0xFF81C784) : Colors.green.shade400,
              size: 20),
          filled: true,
          fillColor: colors.inputFill,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.inputBorder, width: 1)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                  color: context.isDark ? const Color(0xFF4CAF50) : Colors.green.shade300,
                  width: 1.5)),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(
            foregroundColor: colors.textSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text('إلغاء'),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.check_rounded, size: 18),
          label: const Text('حفظ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  void _showSnack(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline : Icons.check_circle, color: Colors.white),
        const SizedBox(width: 8),
        Expanded(child: Text(message)),
      ]),
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _goToAttendance() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => AttendanceScreen(schoolClass: widget.schoolClass)));
  }

  void _goToStats() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => StatsScreen(schoolClass: widget.schoolClass)));
  }

  void _goToStudentDetail(Student student) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => StudentDetailScreen(student: student)))
        .then((_) => _loadStudents());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 150,
            pinned: true,
            backgroundColor: colors.headerGradientMid,
            foregroundColor: Colors.white,
            centerTitle: true,
            title: Text(widget.schoolClass.name,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 17)),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.zero,
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
                    top: -20, left: -40,
                    child: Icon(Icons.school, size: 200,
                        color: Colors.white.withOpacity(0.07)),
                  ),
                  Positioned(
                    bottom: 20, left: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.workspace_premium_outlined,
                            size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text('المستوى ${widget.schoolClass.level}',
                            style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
            actions: [
              // زر الإحصائيات
              Padding(
                padding: const EdgeInsets.only(left: 6, top: 8, bottom: 8),
                child: Material(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _goToStats,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Icon(Icons.insights, size: 20),
                    ),
                  ),
                ),
              ),
              // زر الحضور
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
                child: Material(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _goToAttendance,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.fact_check, size: 18),
                        SizedBox(width: 6),
                        Text('الحضور',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ]),
                    ),
                  ),
                ),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: FutureBuilder<List<Student>>(
              future: _studentsFuture,
              builder: (context, snapshot) {
                final count = snapshot.data?.length ?? 0;
                if (count == 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: context.isDark ? const Color(0xFF1B3A1E) : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(children: [
                          Icon(Icons.people, size: 16,
                              color: context.isDark ? const Color(0xFF81C784) : Colors.green.shade700),
                          const SizedBox(width: 6),
                          Text('$count تلميذ',
                              style: TextStyle(
                                  color: context.isDark ? const Color(0xFF81C784) : Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                        ]),
                      ),
                      const Spacer(),
                      Material(
                        color: _isSearching
                            ? (context.isDark ? const Color(0xFF1B3A1E) : Colors.green.shade50)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() {
                              _isSearching = !_isSearching;
                              if (!_isSearching) {
                                _searchController.clear();
                                _searchQuery = '';
                              }
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Icon(_isSearching ? Icons.close : Icons.search,
                                size: 22,
                                color: context.isDark ? const Color(0xFF81C784) : Colors.green.shade700),
                          ),
                        ),
                      ),
                    ]),
                    if (_isSearching) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchController,
                        autofocus: true,
                        onChanged: (v) => setState(() => _searchQuery = v.trim()),
                        style: TextStyle(color: colors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'ابحث باسم التلميذ...',
                          hintStyle: TextStyle(color: colors.textTertiary, fontSize: 13),
                          prefixIcon: Icon(Icons.search,
                              color: context.isDark ? const Color(0xFF81C784) : Colors.green.shade400,
                              size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, size: 18, color: colors.textTertiary),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  })
                              : null,
                          filled: true,
                          fillColor: colors.cardBg,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: colors.cardBorder, width: 1)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                  color: context.isDark ? const Color(0xFF4CAF50) : Colors.green.shade300,
                                  width: 1.5)),
                        ),
                      ),
                    ],
                  ]),
                );
              },
            ),
          ),

          FutureBuilder<List<Student>>(
            future: _studentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      CircularProgressIndicator(color: Colors.green.shade600, strokeWidth: 3),
                      const SizedBox(height: 16),
                      Text('جاري التحميل...',
                          style: TextStyle(color: colors.textSecondary, fontSize: 14)),
                    ]),
                  ),
                );
              }

              if (snapshot.hasError) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: context.isDark ? const Color(0xFF3A1A1A) : Colors.red.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.wifi_off_rounded, size: 56, color: Colors.red.shade400),
                        ),
                        const SizedBox(height: 20),
                        Text('تعذّر الاتصال',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary)),
                        const SizedBox(height: 8),
                        Text('${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _loadStudents,
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة المحاولة'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ]),
                    ),
                  ),
                );
              }

              final allStudents = snapshot.data ?? [];
              final students = _searchQuery.isEmpty
                  ? allStudents
                  : allStudents
                      .where((s) => s.fullName.toLowerCase().contains(_searchQuery.toLowerCase()))
                      .toList();

              if (allStudents.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
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
                          child: const Icon(Icons.group_outlined,
                              size: 64, color: Color(0xFF4CAF50)),
                        ),
                        const SizedBox(height: 20),
                        Text('لا يوجد تلاميذ بعد',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary)),
                        const SizedBox(height: 8),
                        Text('اضغط زر + لإضافة أول تلميذ',
                            style: TextStyle(color: colors.textSecondary, fontSize: 14)),
                      ]),
                    ),
                  ),
                );
              }

              if (students.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.search_off, size: 64, color: colors.textTertiary),
                        const SizedBox(height: 16),
                        Text('لا نتائج لـ "$_searchQuery"',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary)),
                        const SizedBox(height: 8),
                        Text('جرّب كلمة أخرى',
                            style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                      ]),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildStudentCard(students[index], index),
                    childCount: students.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStudentDialog,
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('تلميذ جديد',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStudentCard(Student student, int index) {
    final colors = context.colors;
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, 20 * (1 - value)),
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _goToStudentDetail(student),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.green.shade400, Colors.green.shade700],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(_getInitials(student.fullName),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(student.fullName,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: colors.textPrimary)),
                    const SizedBox(height: 4),
                    Text('رقم التلميذ: ${student.id}',
                        style: TextStyle(color: colors.textTertiary, fontSize: 12)),
                  ]),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: colors.textSecondary, size: 22),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  color: colors.cardBg,
                  elevation: 4,
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditStudentDialog(student);
                    } else if (value == 'delete') {
                      _confirmDelete(student);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF4CAF50)),
                        const SizedBox(width: 10),
                        Text('تعديل',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary)),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF5350)),
                        const SizedBox(width: 10),
                        const Text('حذف',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFEF5350))),
                      ]),
                    ),
                  ],
                ),
                Icon(Icons.arrow_forward_ios, size: 14, color: colors.textTertiary),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return parts[0][0];
  }
}