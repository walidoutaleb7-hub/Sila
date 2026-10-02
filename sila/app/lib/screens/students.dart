import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api.dart';
import '../services/export_service.dart';
import '../shared/widgets/student_avatar.dart';
import '../theme/app_theme.dart';
import 'attendance.dart';
import 'grades_list.dart';
import 'notes_screen.dart';
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
  bool _exporting = false;

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
  // التصدير
  // ═══════════════════════════════════════════
  Future<void> _showExportOptions() async {
    final colors = context.colors;
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: colors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: colors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.ios_share,
                        color: context.isDark ? const Color(0xFF81C784) : Colors.green.shade700,
                        size: 22),
                    const SizedBox(width: 10),
                    Text('تصدير تقرير القسم',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: colors.textPrimary)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Divider(height: 1, color: colors.divider),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.isDark ? const Color(0xFF1B3A1E) : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.table_chart_outlined,
                      color: context.isDark ? const Color(0xFF81C784) : Colors.green.shade700,
                      size: 22),
                ),
                title: Text('ملف Excel / CSV',
                    style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary)),
                subtitle: Text('جدول كامل يفتح في Excel',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                trailing: Icon(Icons.arrow_forward_ios, size: 14, color: colors.textTertiary),
                onTap: () => Navigator.pop(context, 'csv'),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.isDark ? const Color(0xFF1B2A3A) : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.chat_outlined,
                      color: context.isDark ? const Color(0xFF64B5F6) : Colors.blue.shade700,
                      size: 22),
                ),
                title: Text('تقرير نصي (واتساب)',
                    style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary)),
                subtitle: Text('نص جاهز للإرسال في واتساب',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                trailing: Icon(Icons.arrow_forward_ios, size: 14, color: colors.textTertiary),
                onTap: () => Navigator.pop(context, 'text'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (choice == null) return;

    setState(() => _exporting = true);

    try {
      final reports = await ApiService.getFullClassReport(widget.schoolClass.id);
      if (reports.isEmpty) {
        if (mounted) _showSnack('لا يوجد تلاميذ للتصدير', isError: true);
        return;
      }

      if (choice == 'csv') {
        await ExportService.exportClassReport(
          schoolClass: widget.schoolClass,
          reports: reports,
        );
        if (mounted) _showSnack('تم تجهيز ${reports.length} تلميذ', isError: false);
      } else {
        await ExportService.shareTextReport(
          schoolClass: widget.schoolClass,
          reports: reports,
        );
      }
    } catch (e) {
      if (mounted) _showSnack('فشل التصدير: $e', isError: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  // ═══════════════════════════════════════════
  // إضافة تلميذ
  // ═══════════════════════════════════════════
  Future<void> _showAddStudentDialog() async {
    final nameController = TextEditingController();
    final guardianNameController = TextEditingController();
    final guardianPhoneController = TextEditingController();
    String? photoBase64;

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
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
                child: const Icon(Icons.person_add_alt_1_outlined,
                    color: Color(0xFF4CAF50), size: 22),
              ),
              const SizedBox(width: 12),
              Text('إضافة تلميذ',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: colors.textPrimary)),
            ]),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPhotoPicker(
                    context: context,
                    photoBase64: photoBase64,
                    fullName: nameController.text,
                    onPicked: (b64) => setDialogState(() => photoBase64 = b64),
                    onRemoved: () => setDialogState(() => photoBase64 = null),
                  ),
                  const SizedBox(height: 16),
                  _buildInput(context, nameController, 'الاسم الكامل',
                      'مثال: أحمد بن علي', Icons.badge_outlined,
                      onChanged: () => setDialogState(() {})),
                  const SizedBox(height: 12),
                  _buildInput(context, guardianNameController, 'اسم الولي (اختياري)',
                      'مثال: محمد بن علي', Icons.family_restroom,
                      onChanged: () => setDialogState(() {})),
                  const SizedBox(height: 12),
                  _buildInput(context, guardianPhoneController, 'رقم هاتف الولي (اختياري)',
                      'مثال: 0555123456', Icons.phone_iphone,
                      keyboardType: TextInputType.phone,
                      onChanged: () => setDialogState(() {})),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                style: TextButton.styleFrom(foregroundColor: colors.textSecondary),
                child: const Text('إلغاء'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  if (nameController.text.trim().isEmpty) return;
                  Navigator.pop(context, {
                    'fullName': nameController.text.trim(),
                    'guardianName': guardianNameController.text.trim(),
                    'guardianPhone': guardianPhoneController.text.trim(),
                    'photoBase64': photoBase64,
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
      final student = await ApiService.createStudent(
        classId: widget.schoolClass.id,
        fullName: result['fullName'] as String,
        guardianName: (result['guardianName'] as String).isEmpty
            ? null
            : result['guardianName'] as String,
        guardianPhone: (result['guardianPhone'] as String).isEmpty
            ? null
            : result['guardianPhone'] as String,
      );
      if (result['photoBase64'] != null) {
        await ApiService.updateStudentPhoto(
          studentId: student.id,
          photoBase64: result['photoBase64'] as String,
        );
      }
      _loadStudents();
      if (mounted) _showSnack('تم إضافة التلميذ بنجاح', isError: false);
    } catch (e) {
      if (mounted) _showSnack('خطأ: $e', isError: true);
    }
  }

  // ═══════════════════════════════════════════
  // تعديل تلميذ
  // ═══════════════════════════════════════════
  Future<void> _showEditStudentDialog(Student student) async {
    final nameController = TextEditingController(text: student.fullName);
    final guardianNameController =
        TextEditingController(text: student.guardianName ?? '');
    final guardianPhoneController =
        TextEditingController(text: student.guardianPhone ?? '');
    String? photoBase64 = student.photoUrl;
    bool photoChanged = false;

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
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
                child: const Icon(Icons.edit_outlined,
                    color: Color(0xFF4CAF50), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('تعديل البيانات',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: colors.textPrimary)),
              ),
            ]),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPhotoPicker(
                    context: context,
                    photoBase64: photoBase64,
                    fullName: nameController.text,
                    onPicked: (b64) => setDialogState(() {
                      photoBase64 = b64;
                      photoChanged = true;
                    }),
                    onRemoved: () => setDialogState(() {
                      photoBase64 = null;
                      photoChanged = true;
                    }),
                  ),
                  const SizedBox(height: 16),
                  _buildInput(context, nameController, 'الاسم الكامل',
                      'مثال: أحمد بن علي', Icons.badge_outlined,
                      onChanged: () => setDialogState(() {})),
                  const SizedBox(height: 12),
                  _buildInput(context, guardianNameController, 'اسم الولي',
                      'مثال: محمد بن علي', Icons.family_restroom,
                      onChanged: () => setDialogState(() {})),
                  const SizedBox(height: 12),
                  _buildInput(context, guardianPhoneController, 'رقم هاتف الولي',
                      'مثال: 0555123456', Icons.phone_iphone,
                      keyboardType: TextInputType.phone,
                      onChanged: () => setDialogState(() {})),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                style: TextButton.styleFrom(foregroundColor: colors.textSecondary),
                child: const Text('إلغاء'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  if (nameController.text.trim().isEmpty) return;
                  Navigator.pop(context, {
                    'fullName': nameController.text.trim(),
                    'guardianName': guardianNameController.text.trim(),
                    'guardianPhone': guardianPhoneController.text.trim(),
                    'photoBase64': photoBase64,
                    'photoChanged': photoChanged,
                  });
                },
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('حفظ',
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
      await ApiService.updateStudent(
        studentId: student.id,
        fullName: result['fullName'] as String,
        guardianName: (result['guardianName'] as String).isEmpty
            ? null
            : result['guardianName'] as String,
        guardianPhone: (result['guardianPhone'] as String).isEmpty
            ? null
            : result['guardianPhone'] as String,
      );
      if (result['photoChanged'] == true) {
        if (result['photoBase64'] == null) {
          await ApiService.deleteStudentPhoto(student.id);
        } else {
          await ApiService.updateStudentPhoto(
            studentId: student.id,
            photoBase64: result['photoBase64'] as String,
          );
        }
      }
      _loadStudents();
      if (mounted) _showSnack('تم حفظ التعديلات', isError: false);
    } catch (e) {
      if (mounted) _showSnack('خطأ: $e', isError: true);
    }
  }

  // ═══════════════════════════════════════════
  // حقل إدخال
  // ═══════════════════════════════════════════
  Widget _buildInput(
    BuildContext context,
    TextEditingController controller,
    String label,
    String hint,
    IconData icon, {
    TextInputType? keyboardType,
    VoidCallback? onChanged,
  }) {
    final colors = context.colors;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged == null ? null : (_) => onChanged(),
      style: TextStyle(color: colors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: colors.textTertiary, fontSize: 12),
        labelStyle: TextStyle(
          color: context.isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon,
            color: context.isDark ? const Color(0xFF81C784) : Colors.green.shade400,
            size: 20),
        filled: true,
        fillColor: colors.inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors.inputBorder, width: 1)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: context.isDark ? const Color(0xFF4CAF50) : Colors.green.shade300,
                width: 1.5)),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // منتقي الصورة
  // ═══════════════════════════════════════════
  Widget _buildPhotoPicker({
    required BuildContext context,
    required String? photoBase64,
    required String fullName,
    required Function(String?) onPicked,
    required VoidCallback onRemoved,
  }) {
    final colors = context.colors;
    final hasPhoto = photoBase64 != null && photoBase64.trim().isNotEmpty;

    return Column(children: [
      Stack(children: [
        Container(
          width: 90, height: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.cardBorder, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: hasPhoto
                ? Image.memory(
                    base64Decode(photoBase64),
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) => _photoPlaceholder(colors, fullName),
                  )
                : _photoPlaceholder(colors, fullName),
          ),
        ),
        Positioned(
          bottom: -4, right: -4,
          child: Material(
            color: Colors.green.shade600,
            shape: const CircleBorder(),
            elevation: 3,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _pickImage(onPicked),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
              ),
            ),
          ),
        ),
        if (hasPhoto)
          Positioned(
            top: -4, right: -4,
            child: Material(
              color: Colors.red.shade600,
              shape: const CircleBorder(),
              elevation: 3,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemoved,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.close, color: Colors.white, size: 14),
                ),
              ),
            ),
          ),
      ]),
      const SizedBox(height: 6),
      Text(hasPhoto ? 'تغيير الصورة' : 'إضافة صورة',
          style: TextStyle(
              fontSize: 11,
              color: colors.textTertiary,
              fontWeight: FontWeight.w500)),
    ]);
  }

  Widget _photoPlaceholder(AppColors colors, String fullName) {
    final initial = fullName.trim().isEmpty ? '?' : fullName.trim().split(' ').first[0];
    return Container(
      color: colors.inputFill,
      child: Center(
        child: Text(initial,
            style: TextStyle(
                color: colors.textTertiary,
                fontWeight: FontWeight.bold,
                fontSize: 32)),
      ),
    );
  }

  Future<void> _pickImage(Function(String?) onPicked) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 70,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      onPicked(base64Encode(bytes));
    } catch (e) {
      if (mounted) _showSnack('فشل اختيار الصورة: $e', isError: true);
    }
  }

  // ═══════════════════════════════════════════
  // حذف
  // ═══════════════════════════════════════════
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
            child: const Icon(Icons.delete_outline, color: Color(0xFFEF5350), size: 22),
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
              Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange.shade700),
              const SizedBox(width: 6),
              Expanded(
                child: Text('سيتم حذف كل السجلات (حضور، درجات، ملاحظات).',
                    style: TextStyle(color: Colors.orange.shade800, fontSize: 12)),
              ),
            ]),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: colors.textSecondary),
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

  void _goToGrades() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => GradesListScreen(schoolClass: widget.schoolClass)));
  }

  void _goToNotes() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => NotesScreen(schoolClass: widget.schoolClass)));
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
      body: Stack(
        children: [
          CustomScrollView(
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
                  _buildIconButton(
                    icon: Icons.ios_share,
                    onTap: _exporting ? null : _showExportOptions,
                  ),
                  _buildTextButton(
                    icon: Icons.sticky_note_2_outlined,
                    label: 'الملاحظات',
                    onTap: _goToNotes,
                  ),
                  _buildTextButton(
                    icon: Icons.grade_outlined,
                    label: 'الدرجات',
                    onTap: _goToGrades,
                  ),
                  _buildIconButton(
                    icon: Icons.insights,
                    onTap: _goToStats,
                  ),
                  _buildTextButton(
                    icon: Icons.fact_check,
                    label: 'الحضور',
                    onTap: _goToAttendance,
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
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                              child: const Icon(Icons.group_outlined, size: 64, color: Color(0xFF4CAF50)),
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

          if (_exporting)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colors.cardBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    CircularProgressIndicator(color: Colors.green.shade600),
                    const SizedBox(height: 16),
                    Text('جاري تجهيز التقرير...',
                        style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary)),
                  ]),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStudentDialog,
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('تلميذ جديد', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, required VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 8, bottom: 8),
      child: Material(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Icon(icon, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildTextButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 8, bottom: 8),
      child: Material(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 16),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCard(Student student, int index) {
    final colors = context.colors;
    final hasGuardianPhone = student.guardianPhone?.trim().isNotEmpty ?? false;

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
                StudentAvatar(
                  studentId: student.id,
                  fullName: student.fullName,
                  photoBase64: student.photoUrl,
                  size: 52,
                  borderRadius: 14,
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
                    Row(children: [
                      Icon(Icons.badge_outlined,
                          size: 12, color: colors.textTertiary),
                      const SizedBox(width: 3),
                      Text('${student.id}',
                          style: TextStyle(color: colors.textTertiary, fontSize: 11)),
                      if (hasGuardianPhone) ...[
                        const SizedBox(width: 10),
                        Icon(Icons.phone_iphone,
                            size: 12,
                            color: context.isDark
                                ? const Color(0xFF81C784)
                                : Colors.green.shade600),
                        const SizedBox(width: 3),
                        Text('ولي',
                            style: TextStyle(
                                color: context.isDark
                                    ? const Color(0xFF81C784)
                                    : Colors.green.shade600,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ],
                    ]),
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
}