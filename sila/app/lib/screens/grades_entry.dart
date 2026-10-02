import 'package:flutter/material.dart';
import '../services/api.dart';
import '../theme/app_theme.dart';

class GradesEntryScreen extends StatefulWidget {
  final SchoolClass schoolClass;
  final GradeSession? editSession; // null = إضافة، غير null = تعديل

  const GradesEntryScreen({
    super.key,
    required this.schoolClass,
    this.editSession,
  });

  @override
  State<GradesEntryScreen> createState() => _GradesEntryScreenState();
}

class _GradesEntryScreenState extends State<GradesEntryScreen> {
  static const _assessmentTypes = [
    'فرض',
    'اختبار',
    'مشاركة',
    'واجب منزلي',
    'تقييم شفهي',
  ];

  String _selectedAssessment = 'فرض';
  DateTime _selectedDate = DateTime.now();
  double _maxScore = 20;
  int _coeff = 1;
  final TextEditingController _noteController = TextEditingController();
  final Map<int, TextEditingController> _scoreControllers = {};

  List<Student> _students = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  bool get _isEditMode => widget.editSession != null;

  @override
  void initState() {
    super.initState();
    // إذا كنا في وضع التعديل، املأ القيم من الجلسة
    if (_isEditMode) {
      final s = widget.editSession!;
      _selectedAssessment = s.assessment;
      _selectedDate = s.date;
      _maxScore = s.maxScore;
      _coeff = s.coeff;
      _noteController.text = s.note ?? '';
    }
    _loadData();
  }

  @override
  void dispose() {
    _noteController.dispose();
    for (final c in _scoreControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final students = await ApiService.getStudents(widget.schoolClass.id);
      for (final s in students) {
        _scoreControllers[s.id] = TextEditingController();
      }

      // إذا كنا في وضع التعديل، املأ النقاط الحالية
      if (_isEditMode) {
        try {
          final session = await ApiService.getSessionGrades(
            classId: widget.schoolClass.id,
            assessment: widget.editSession!.assessment,
            date: widget.editSession!.date,
          );
          for (final r in session.records) {
            _scoreControllers[r.studentId]?.text =
                r.score.toStringAsFixed(r.score % 1 == 0 ? 0 : 2);
          }
        } catch (_) {
          // تجاهل — القائمة فارغة
        }
      }

      setState(() {
        _students = students;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: Colors.green.shade700,
            onPrimary: Colors.white,
            onSurface: context.isDark ? Colors.white : Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    final records = <int, double>{};
    for (final s in _students) {
      final text = _scoreControllers[s.id]?.text.trim() ?? '';
      if (text.isEmpty) {
        _showSnack('يجب إدخال نقطة لكل تلميذ', isError: true);
        return;
      }
      final val = double.tryParse(text);
      if (val == null || val < 0 || val > _maxScore) {
        _showSnack('نقطة غير صحيحة لـ ${s.fullName} (0 - ${_maxScore.toInt()})', isError: true);
        return;
      }
      records[s.id] = val;
    }

    setState(() => _saving = true);
    try {
      final saved = await ApiService.saveGrades(
        classId: widget.schoolClass.id,
        assessment: _selectedAssessment,
        maxScore: _maxScore,
        coeff: _coeff,
        date: _selectedDate,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        records: records,
      );
      if (!mounted) return;
      _showSnack(
        _isEditMode ? 'تم تحديث $saved نقطة' : 'تم حفظ $saved نقطة بنجاح',
        isError: false,
      );
      Navigator.pop(context, true);
    } catch (e) {
      _showSnack('فشل الحفظ: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(_isEditMode ? 'تعديل التقييم' : 'إدخال الدرجات'),
        centerTitle: true,
        backgroundColor: colors.headerGradientMid,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? _buildLoading()
          : _error != null
              ? _buildError()
              : _students.isEmpty
                  ? _buildEmpty()
                  : _buildBody(),
      bottomNavigationBar: _students.isEmpty || _loading ? null : _buildBottomBar(),
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

  Widget _buildError() {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text('خطأ: $_error', textAlign: TextAlign.center, style: TextStyle(color: colors.textPrimary)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
          ),
        ]),
      ),
    );
  }

  Widget _buildEmpty() {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.group_off, size: 72, color: colors.textTertiary),
          const SizedBox(height: 16),
          Text('لا يوجد تلاميذ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary)),
          const SizedBox(height: 8),
          Text('أضف تلاميذاً أولاً',
              style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        ]),
      ),
    );
  }

  Widget _buildBody() {
    final colors = context.colors;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSettingsCard(),
        const SizedBox(height: 20),
        Row(children: [
          Container(
            width: 4, height: 20,
            decoration: BoxDecoration(color: Colors.green.shade700, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 10),
          Text('النقاط (${_students.length} تلميذ)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary)),
        ]),
        const SizedBox(height: 12),
        ..._students.asMap().entries.map((entry) => _buildStudentRow(entry.value, entry.key)),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSettingsCard() {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder, width: 1),
      ),
      child: Column(children: [
        _buildFieldLabel('نوع التقييم', Icons.assignment_outlined),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _assessmentTypes.map((t) {
            final selected = _selectedAssessment == t;
            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: _isEditMode ? null : () => setState(() => _selectedAssessment = t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.green.shade600
                      : (context.isDark ? const Color(0xFF1B3A1E) : Colors.green.shade50),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? Colors.green.shade600 : colors.cardBorder,
                    width: 1,
                  ),
                ),
                child: Text(t,
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : (context.isDark ? const Color(0xFF81C784) : Colors.green.shade800),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    )),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        Divider(color: colors.divider),
        const SizedBox(height: 14),

        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: _isEditMode ? null : _pickDate,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              Icon(Icons.calendar_today_outlined,
                  size: 18, color: context.isDark ? const Color(0xFF81C784) : Colors.green.shade600),
              const SizedBox(width: 10),
              Text('التاريخ',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: colors.textPrimary)),
              const Spacer(),
              Text(ApiService.formatDateArabic(_selectedDate),
                  style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              const SizedBox(width: 6),
              if (!_isEditMode)
                Icon(Icons.arrow_forward_ios, size: 12, color: colors.textTertiary),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        Divider(color: colors.divider),
        const SizedBox(height: 8),

        Row(children: [
          Expanded(child: _buildNumberField('السقف', _maxScore, (v) => setState(() => _maxScore = v))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.scale_outlined,
                    size: 16,
                    color: context.isDark ? const Color(0xFF81C784) : Colors.green.shade600),
                const SizedBox(width: 6),
                Text('المعامل',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: colors.textPrimary)),
              ]),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.inputFill,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.cardBorder),
                ),
                child: Row(children: [
                  _buildStepBtn(Icons.remove, () {
                    if (_coeff > 1) setState(() => _coeff--);
                  }),
                  Expanded(
                    child: Center(
                      child: Text('$_coeff',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                    ),
                  ),
                  _buildStepBtn(Icons.add, () {
                    if (_coeff < 10) setState(() => _coeff++);
                  }),
                ]),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        Divider(color: colors.divider),
        const SizedBox(height: 8),

        TextField(
          controller: _noteController,
          maxLines: 2,
          style: TextStyle(color: colors.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'ملاحظة (اختياري)',
            hintStyle: TextStyle(color: colors.textTertiary, fontSize: 12),
            prefixIcon: Icon(Icons.notes_outlined,
                size: 18, color: context.isDark ? const Color(0xFF81C784) : Colors.green.shade600),
            filled: true,
            fillColor: colors.inputFill,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.cardBorder)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: context.isDark ? const Color(0xFF4CAF50) : Colors.green.shade300, width: 1.5)),
          ),
        ),
      ]),
    );
  }

  Widget _buildStepBtn(IconData icon, VoidCallback onTap) {
    final colors = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: colors.textSecondary),
      ),
    );
  }

  Widget _buildNumberField(String label, double value, Function(double) onChange) {
    final colors = context.colors;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.straighten_outlined,
            size: 16, color: context.isDark ? const Color(0xFF81C784) : Colors.green.shade600),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: colors.textPrimary)),
      ]),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colors.inputFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Row(children: [
          InkWell(
            onTap: value > 5 ? () => onChange(value - 5) : null,
            child: Icon(Icons.remove_circle_outline,
                size: 20, color: value > 5 ? colors.textSecondary : colors.textTertiary),
          ),
          Expanded(
            child: Center(
              child: Text('${value.toInt()}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary)),
            ),
          ),
          InkWell(
            onTap: value < 100 ? () => onChange(value + 5) : null,
            child: Icon(Icons.add_circle_outline,
                size: 20, color: value < 100 ? colors.textSecondary : colors.textTertiary),
          ),
        ]),
      ),
    ]);
  }

  Widget _buildFieldLabel(String label, IconData icon) {
    final colors = context.colors;
    return Row(children: [
      Icon(icon, size: 16, color: context.isDark ? const Color(0xFF81C784) : Colors.green.shade600),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: colors.textPrimary)),
    ]);
  }

  Widget _buildStudentRow(Student student, int index) {
    final colors = context.colors;
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
          border: Border.all(color: colors.cardBorder, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: context.isDark ? const Color(0xFF1B3A1E) : Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text('${index + 1}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: context.isDark ? const Color(0xFF81C784) : Colors.green.shade800)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(student.fullName,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: colors.textPrimary)),
            ),
            SizedBox(
              width: 70,
              child: TextField(
                controller: _scoreControllers[student.id],
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: '/${_maxScore.toInt()}',
                  hintStyle: TextStyle(color: colors.textTertiary, fontSize: 13, fontWeight: FontWeight.normal),
                  filled: true,
                  fillColor: colors.inputFill,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.cardBorder)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: context.isDark ? const Color(0xFF4CAF50) : Colors.green.shade300, width: 1.5)),
                ),
              ),
            ),
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
        child: ElevatedButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Icon(_isEditMode ? Icons.save_as : Icons.save, size: 20),
          label: Text(
            _saving
                ? (_isEditMode ? 'جاري التحديث...' : 'جاري الحفظ...')
                : (_isEditMode ? 'تحديث الدرجات' : 'حفظ الدرجات'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
          ),
        ),
      ),
    );
  }
}