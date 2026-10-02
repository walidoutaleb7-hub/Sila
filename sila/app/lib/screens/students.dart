import 'package:flutter/material.dart';
import '../services/api.dart';
import 'attendance.dart';
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

  // ═══════════════════════════════════════════
  // حوار إضافة تلميذ
  // ═══════════════════════════════════════════
  Future<void> _showAddStudentDialog() async {
    final nameController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildStudentDialog(
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

  // ═══════════════════════════════════════════
  // حوار تعديل تلميذ
  // ═══════════════════════════════════════════
  Future<void> _showEditStudentDialog(Student student) async {
    final nameController = TextEditingController(text: student.fullName);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildStudentDialog(
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
        if (mounted) _showSnack('تم تعديل البيانات بنجاح', isError: false);
      } catch (e) {
        if (mounted) _showSnack('خطأ: $e', isError: true);
      }
    }
  }

  // ═══════════════════════════════════════════
  // حوار حذف تلميذ
  // ═══════════════════════════════════════════
  Future<void> _confirmDelete(Student student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: Color(0xFFC62828),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'حذف التلميذ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF263238),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'هل أنت متأكد من حذف التلميذ:',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAF9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                student.fullName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF263238),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 16, color: Colors.orange.shade700),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'سيتم حذف كل سجلات الحضور الخاصة به أيضاً.',
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
            ),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text(
              'حذف',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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

  // ═══════════════════════════════════════════
  // حوار موحد (إضافة/تعديل)
  // ═══════════════════════════════════════════
  Widget _buildStudentDialog({
    required String title,
    required IconData icon,
    required TextEditingController nameController,
  }) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF2E7D32), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Color(0xFF263238),
              ),
            ),
          ),
        ],
      ),
      content: TextField(
        controller: nameController,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: 'الاسم الكامل',
          hintText: 'مثال: أحمد بن علي',
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 13,
          ),
          labelStyle: const TextStyle(
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(
            Icons.badge_outlined,
            color: Colors.green.shade400,
            size: 20,
          ),
          filled: true,
          fillColor: const Color(0xFFF8FAF9),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Colors.green.shade100,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Colors.green.shade300,
              width: 1.5,
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey.shade600,
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 12),
          ),
          child: const Text('إلغاء'),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.check_rounded, size: 18),
          label: const Text(
            'حفظ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  void _showSnack(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle,
                color: Colors.white),
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

  void _goToAttendance() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AttendanceScreen(schoolClass: widget.schoolClass),
      ),
    );
  }

  void _goToStudentDetail(Student student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentDetailScreen(student: student),
      ),
    ).then((_) => _loadStudents());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // ═══════ AppBar ═══════
          SliverAppBar(
            expandedHeight: 150,
            pinned: true,
            backgroundColor: Colors.green.shade800,
            foregroundColor: Colors.white,
            centerTitle: true,
            title: Text(
              widget.schoolClass.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 17,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.zero,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Colors.green.shade800,
                      Colors.green.shade500,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -20,
                      left: -40,
                      child: Icon(
                        Icons.school,
                        size: 200,
                        color: Colors.white.withOpacity(0.07),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.workspace_premium_outlined,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'المستوى ${widget.schoolClass.level}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
                child: Material(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _goToAttendance,
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fact_check, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'الحضور',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ═══════ شريط البحث ═══════
          SliverToBoxAdapter(
            child: FutureBuilder<List<Student>>(
              future: _studentsFuture,
              builder: (context, snapshot) {
                final count = snapshot.data?.length ?? 0;
                if (count == 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    children: [
                      // عداد التلاميذ + زر البحث
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.people,
                                    size: 16, color: Colors.green.shade700),
                                const SizedBox(width: 6),
                                Text(
                                  '$count تلميذ',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // زر فتح/إغلاق البحث
                          Material(
                            color: _isSearching
                                ? Colors.green.shade50
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
                                child: Icon(
                                  _isSearching
                                      ? Icons.close
                                      : Icons.search,
                                  size: 22,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // خانة البحث (تظهر عند الضغط على أيقونة البحث)
                      if (_isSearching) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _searchController,
                          autofocus: true,
                          onChanged: (v) {
                            setState(() => _searchQuery = v.trim());
                          },
                          decoration: InputDecoration(
                            hintText: 'ابحث باسم التلميذ...',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.green.shade400,
                              size: 20,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear,
                                        size: 18,
                                        color: Colors.grey.shade500),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.green.shade100,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.green.shade300,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),

          // ═══════ قائمة التلاميذ ═══════
          FutureBuilder<List<Student>>(
            future: _studentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Colors.green.shade700,
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 16),
                        Text('جاري التحميل...',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 14)),
                      ],
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.wifi_off_rounded,
                                size: 56, color: Colors.red.shade400),
                          ),
                          const SizedBox(height: 20),
                          const Text('تعذّر الاتصال',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 13)),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _loadStudents,
                            icon: const Icon(Icons.refresh),
                            label: const Text('إعادة المحاولة'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final allStudents = snapshot.data ?? [];

              // تطبيق البحث
              final students = _searchQuery.isEmpty
                  ? allStudents
                  : allStudents
                      .where((s) => s.fullName
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()))
                      .toList();

              // حالة فارغة
              if (allStudents.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                Colors.green.shade50,
                                Colors.green.shade100,
                              ]),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.group_outlined,
                                size: 64, color: Colors.green.shade400),
                          ),
                          const SizedBox(height: 20),
                          const Text('لا يوجد تلاميذ بعد',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF37474F),
                              )),
                          const SizedBox(height: 8),
                          Text('اضغط زر + لإضافة أول تلميذ',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                );
              }

              // نتيجة البحث فارغة
              if (students.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text('لا نتائج لـ "$_searchQuery"',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              )),
                          const SizedBox(height: 8),
                          Text('جرّب كلمة أخرى',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _buildStudentCard(students[index], index),
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
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
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
              child: Row(
                children: [
                  // صورة رمزية
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.green.shade400,
                          Colors.green.shade700,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(student.fullName),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // الاسم والرقم
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF263238),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'رقم التلميذ: ${student.id}',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // قائمة الخيارات (تعديل / حذف)
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: Colors.grey.shade600,
                      size: 22,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined,
                                size: 18, color: Colors.green.shade700),
                            const SizedBox(width: 10),
                            const Text(
                              'تعديل',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline,
                                size: 18, color: Colors.red.shade700),
                            const SizedBox(width: 10),
                            Text(
                              'حذف',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}';
    }
    return parts[0][0];
  }
}