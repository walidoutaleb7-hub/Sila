import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api.dart';
import '../shared/widgets/student_avatar.dart';
import '../theme/app_theme.dart';

class SeatingChartScreen extends StatefulWidget {
  final SchoolClass schoolClass;
  const SeatingChartScreen({super.key, required this.schoolClass});

  @override
  State<SeatingChartScreen> createState() => _SeatingChartScreenState();
}

class _SeatingChartScreenState extends State<SeatingChartScreen> {
  SeatingChart? _chart;
  List<Student> _students = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  int _rows = 5;
  int _cols = 4;
  Map<String, int> _seats = {};
  int? _delegate1;
  int? _delegate2;
  int? _delegate3;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final students = await ApiService.getStudents(widget.schoolClass.id);
      final chart = await ApiService.getSeatingChart(widget.schoolClass.id);

      setState(() {
        _students = students;
        _chart = chart;
        _rows = chart.rows;
        _cols = chart.cols;
        _seats = Map<String, int>.from(chart.seats);
        _delegate1 = chart.delegate1;
        _delegate2 = chart.delegate2;
        _delegate3 = chart.delegate3;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ═══════════════════════════════════════════
  // حفظ المخطط
  // ═══════════════════════════════════════════
  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final saved = await ApiService.saveSeatingChart(
        classId: widget.schoolClass.id,
        rows: _rows,
        cols: _cols,
        seats: _seats,
        delegate1: _delegate1,
        delegate2: _delegate2,
        delegate3: _delegate3,
      );
      setState(() => _chart = saved);
      if (mounted) _showSnack('تم الحفظ', isError: false);
    } catch (e) {
      if (mounted) _showSnack('فشل الحفظ: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
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
      duration: const Duration(seconds: 2),
    ));
  }

  // ═══════════════════════════════════════════
  // قائمة التلاميذ المُوزَّعين وغير المُوزَّعين
  // ═══════════════════════════════════════════
  Set<int> get _assignedIds =>
      {..._seats.values, if (_delegate1 != null) _delegate1!, if (_delegate2 != null) _delegate2!, if (_delegate3 != null) _delegate3!};

  List<Student> get _unassignedStudents =>
      _students.where((s) => !_assignedIds.contains(s.id)).toList();

  Student? _findStudent(int? id) {
    if (id == null) return null;
    try {
      return _students.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  // ═══════════════════════════════════════════
  // اختيار تلميذ لكرسي
  // ═══════════════════════════════════════════
  Future<void> _selectStudentForSeat(String seatKey) async {
    final currentId = _seats[seatKey];

    if (currentId != null) {
      // الكرسي مملوء → خيارات
      final action = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: context.colors.cardBg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => _buildSeatActions(currentId, seatKey),
      );

      if (action == 'change') {
        await _showStudentPicker(seatKey);
      } else if (action == 'remove') {
        setState(() => _seats.remove(seatKey));
        _save();
      }
    } else {
      await _showStudentPicker(seatKey);
    }
  }

  Widget _buildSeatActions(int studentId, String seatKey) {
    final colors = context.colors;
    final student = _findStudent(studentId);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: colors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(children: [
                StudentAvatar(
                  studentId: studentId,
                  fullName: student?.fullName ?? '—',
                  photoBase64: student?.photoUrl,
                  size: 48,
                  borderRadius: 12,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    student?.fullName ?? '—',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: colors.textPrimary),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: colors.divider),
            ListTile(
              leading: Icon(Icons.swap_horiz,
                  color: Colors.blue.shade600),
              title: const Text('تبديل مع تلميذ آخر',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, 'change'),
            ),
            ListTile(
              leading: Icon(Icons.person_remove_outlined,
                  color: Colors.red.shade600),
              title: const Text('إزالة من الكرسي',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, 'remove'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // منتقي التلاميذ
  // ═══════════════════════════════════════════
  Future<void> _showStudentPicker(String seatKey) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _buildStudentPicker(),
    );

    if (selected != null) {
      // إزالة التلميذ من أي كرسي آخر
      final oldKey = _seats.entries
          .firstWhere((e) => e.value == selected, orElse: () => const MapEntry('', -1))
          .key;
      if (oldKey.isNotEmpty) _seats.remove(oldKey);
      // إزالة من الأدوار
      if (_delegate1 == selected) _delegate1 = null;
      if (_delegate2 == selected) _delegate2 = null;
      if (_delegate3 == selected) _delegate3 = null;

      setState(() => _seats[seatKey] = selected);
      _save();
    }
  }

  Widget _buildStudentPicker() {
    final colors = context.colors;
    final available = _unassignedStudents;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: colors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: context.isDark
                        ? const Color(0xFF1B3A1E)
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.person_search,
                      color: Colors.green.shade600, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('اختر تلميذاً',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: colors.textPrimary)),
                      Text(
                        available.isEmpty
                            ? 'كل التلاميذ مُوزَّعون'
                            : '${available.length} تلميذ متاح',
                        style: TextStyle(
                            fontSize: 12, color: colors.textTertiary),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
            Divider(height: 1, color: colors.divider),
            Expanded(
              child: available.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline,
                                size: 64, color: Colors.green.shade400),
                            const SizedBox(height: 16),
                            Text('كل التلاميذ مُوزَّعون',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary)),
                            const SizedBox(height: 8),
                            Text('أزل تلميذاً من كرسي آخر لتغييره',
                                style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: available.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: colors.divider),
                      itemBuilder: (context, i) {
                        final s = available[i];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          leading: StudentAvatar(
                            studentId: s.id,
                            fullName: s.fullName,
                            photoBase64: s.photoUrl,
                            size: 44,
                            borderRadius: 12,
                          ),
                          title: Text(s.fullName,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: colors.textPrimary)),
                          onTap: () => Navigator.pop(context, s.id),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════
  // اختيار الأدوار
  // ═══════════════════════════════════════════
  Future<void> _selectDelegate(int roleIndex) async {
    final currentId = roleIndex == 1
        ? _delegate1
        : roleIndex == 2
            ? _delegate2
            : _delegate3;

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.colors.cardBg,
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
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: context.colors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8),
                child: Text(
                  roleIndex == 1
                      ? 'منوب القسم'
                      : roleIndex == 2
                          ? 'النائب الأول'
                          : 'النائب الثاني',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: context.colors.textPrimary),
                ),
              ),
              const SizedBox(height: 8),
              Divider(height: 1, color: context.colors.divider),
              ListTile(
                leading: Icon(Icons.person_add,
                    color: Colors.green.shade600),
                title: const Text('اختيار / تغيير',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(context, 'change'),
              ),
              if (currentId != null)
                ListTile(
                  leading: Icon(Icons.person_remove_outlined,
                      color: Colors.red.shade600),
                  title: const Text('إزالة',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () => Navigator.pop(context, 'remove'),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (action == 'change') {
      final selected = await showModalBottomSheet<int>(
        context: context,
        isScrollControlled: true,
        backgroundColor: context.colors.cardBg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => _buildStudentPicker(),
      );
      if (selected != null) {
        // إزالة من الكراسي والأدوار الأخرى
        final oldKey = _seats.entries
            .firstWhere((e) => e.value == selected,
                orElse: () => const MapEntry('', -1))
            .key;
        if (oldKey.isNotEmpty) _seats.remove(oldKey);
        if (_delegate1 == selected) _delegate1 = null;
        if (_delegate2 == selected) _delegate2 = null;
        if (_delegate3 == selected) _delegate3 = null;

        setState(() {
          if (roleIndex == 1) _delegate1 = selected;
          if (roleIndex == 2) _delegate2 = selected;
          if (roleIndex == 3) _delegate3 = selected;
        });
        _save();
      }
    } else if (action == 'remove') {
      setState(() {
        if (roleIndex == 1) _delegate1 = null;
        if (roleIndex == 2) _delegate2 = null;
        if (roleIndex == 3) _delegate3 = null;
      });
      _save();
    }
  }

  // ═══════════════════════════════════════════
  // تعديل الأبعاد
  // ═══════════════════════════════════════════
  Future<void> _showResizeDialog() async {
    int newRows = _rows;
    int newCols = _cols;

    final confirmed = await showDialog<bool>(
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
                child: const Icon(Icons.grid_view,
                    color: Color(0xFF4CAF50), size: 22),
              ),
              const SizedBox(width: 12),
              const Text('حجم القسم',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 17)),
            ]),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSizeRow(
                    context,
                    'الصفوف',
                    newRows,
                    (v) => setDialogState(() => newRows = v)),
                const SizedBox(height: 16),
                _buildSizeRow(
                    context,
                    'الأعمدة',
                    newCols,
                    (v) => setDialogState(() => newCols = v)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.isDark
                        ? const Color(0xFF3A2A0A)
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    Icon(Icons.info_outline,
                        size: 14, color: Colors.orange.shade700),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'الصفوف أو الأعمدة المُزالة ستفقد التلاميذ المُعيَّنين فيها.',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade800),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                    foregroundColor: context.colors.textSecondary),
                child: const Text('إلغاء'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('تطبيق',
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

    if (confirmed == true) {
      setState(() {
        _rows = newRows;
        _cols = newCols;
        // إزالة الخانات خارج الحدود
        _seats.removeWhere((key, _) {
          final parts = key.split('-');
          final r = int.tryParse(parts[0]) ?? -1;
          final c = int.tryParse(parts[1]) ?? -1;
          return r < 0 || r >= _rows || c < 0 || c >= _cols;
        });
      });
      _save();
    }
  }

  Widget _buildSizeRow(BuildContext context, String label, int value,
      Function(int) onChange) {
    final colors = context.colors;
    return Row(children: [
      Expanded(
        child: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: colors.textPrimary)),
      ),
      Container(
        decoration: BoxDecoration(
          color: colors.inputFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: value > 1 ? () => onChange(value - 1) : null,
          ),
          SizedBox(
            width: 40,
            child: Center(
              child: Text('$value',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: value < 20 ? () => onChange(value + 1) : null,
          ),
        ]),
      ),
    ]);
  }

  // ═══════════════════════════════════════════
  // مسح المخطط
  // ═══════════════════════════════════════════
  Future<void> _confirmClear() async {
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
            child: const Icon(Icons.cleaning_services,
                color: Color(0xFFEF5350), size: 22),
          ),
          const SizedBox(width: 12),
          const Text('مسح المخطط',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 17)),
        ]),
        content: const Text(
          'سيتم إزالة كل التلاميذ من الكراسي والأدوار.\n'
          'البنية (الصفوف والأعمدة) ستبقى.',
          style: TextStyle(fontSize: 14, height: 1.5),
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
            label: const Text('مسح',
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
      setState(() {
        _seats.clear();
        _delegate1 = null;
        _delegate2 = null;
        _delegate3 = null;
      });
      _save();
    }
  }

  // ═══════════════════════════════════════════
  // الواجهة الرئيسية
  // ═══════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('مخطط الجلوس'),
        centerTitle: true,
        backgroundColor: colors.headerGradientMid,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            color: colors.cardBg,
            onSelected: (value) {
              if (value == 'resize') _showResizeDialog();
              if (value == 'clear') _confirmClear();
              if (value == 'refresh') _loadAll();
            },
            itemBuilder: (context) => [
              _popupItem('resize', Icons.grid_view, 'تعديل الحجم',
                  Colors.blue, colors),
              _popupItem('clear', Icons.cleaning_services, 'مسح المخطط',
                  Colors.orange, colors),
              _popupItem('refresh', Icons.refresh, 'تحديث',
                  Colors.green, colors),
            ],
          ),
        ],
      ),
      body: _loading
          ? _buildLoading()
          : _error != null
              ? _buildError()
              : _students.isEmpty
                  ? _buildNoStudents()
                  : _buildContent(),
      floatingActionButton: _loading || _students.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _saving ? null : _save,
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: Text(_saving ? 'جاري الحفظ...' : 'حفظ',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
    );
  }

  PopupMenuItem<String> _popupItem(
    String value,
    IconData icon,
    String label,
    MaterialColor color,
    AppColors colors,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(children: [
        Icon(icon, size: 18, color: color.shade600),
        const SizedBox(width: 12),
        Text(label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary)),
      ]),
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

  Widget _buildError() {
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
                  style: TextStyle(color: context.colors.textPrimary)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadAll,
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

  Widget _buildNoStudents() {
    final colors = context.colors;
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
              Text('أضف تلاميذاً أولاً لتوزيعهم',
                  style: TextStyle(
                      color: colors.textSecondary, fontSize: 14)),
            ]),
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildBoard(),
        const SizedBox(height: 20),
        _buildClassGrid(),
        const SizedBox(height: 24),
        _buildDelegates(),
        const SizedBox(height: 80),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // السبورة (في الأعلى)
  // ═══════════════════════════════════════════
  Widget _buildBoard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D3B14), Color(0xFF1B5E20)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chalkboard_outlined,
              color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          const Text('السبورة',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 2)),
          const SizedBox(width: 8),
          const Icon(Icons.chalkboard_outlined,
              color: Colors.white70, size: 18),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // الشبكة
  // ═══════════════════════════════════════════
  Widget _buildClassGrid() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.isDark
            ? const Color(0xFF1A2027)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: context.colors.cardBorder,
          width: 1,
        ),
      ),
      child: Column(
        children: List.generate(_rows, (r) {
          return Padding(
            padding: EdgeInsets.only(bottom: r < _rows - 1 ? 10 : 0),
            child: Row(
              children: List.generate(_cols, (c) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        left: c < _cols - 1 ? 6 : 0),
                    child: _buildSeat(r, c),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSeat(int row, int col) {
    final key = '$row-$col';
    final studentId = _seats[key];
    final student = _findStudent(studentId);
    final colors = context.colors;
    final isFilled = student != null;

    final borderColor = isFilled
        ? Colors.green.shade400
        : colors.textTertiary.withOpacity(0.4);

    return AspectRatio(
      aspectRatio: 0.85,
      child: Material(
        color: isFilled
            ? (context.isDark
                ? const Color(0xFF1B3A1E)
                : Colors.green.shade50)
            : colors.cardBg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _selectStudentForSeat(key),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: isFilled ? 1.5 : 1.2,
              ),
              boxShadow: isFilled
                  ? [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: isFilled
                ? _buildFilledSeat(student)
                : _buildEmptySeat(colors),
          ),
        ),
      ),
    );
  }

  Widget _buildFilledSeat(Student student) {
    final colors = context.colors;
    final firstName = student.fullName.trim().split(' ').first;
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StudentAvatar(
            studentId: student.id,
            fullName: student.fullName,
            photoBase64: student.photoUrl,
            size: 36,
            borderRadius: 10,
          ),
          const SizedBox(height: 4),
          Text(
            firstName,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: colors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySeat(AppColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_circle_outline,
            size: 24,
            color: colors.textTertiary.withOpacity(0.5),
          ),
          const SizedBox(height: 2),
          Text(
            'فارغ',
            style: TextStyle(
                fontSize: 10,
                color: colors.textTertiary.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // الأدوار
  // ═══════════════════════════════════════════
  Widget _buildDelegates() {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.green.shade700,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Icon(Icons.workspace_premium,
              size: 18, color: Colors.amber.shade700),
          const SizedBox(width: 6),
          Text('أدوار القسم',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary)),
        ]),
        const SizedBox(height: 12),
        _buildDelegateRow(1, 'منوب القسم', Icons.star,
            Colors.amber, _delegate1),
        const SizedBox(height: 10),
        _buildDelegateRow(
            2, 'النائب الأول', Icons.star_half, Colors.blue, _delegate2),
        const SizedBox(height: 10),
        _buildDelegateRow(3, 'النائب الثاني', Icons.star_outline,
            Colors.blue.shade300, _delegate3),
      ],
    );
  }

  Widget _buildDelegateRow(
    int roleIndex,
    String label,
    IconData icon,
    MaterialColor color,
    int? studentId,
  ) {
    final colors = context.colors;
    final student = _findStudent(studentId);
    final isEmpty = student == null;

    return Material(
      color: colors.cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _selectDelegate(roleIndex),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isEmpty
                  ? colors.cardBorder
                  : color.shade200,
              width: isEmpty ? 1 : 1.5,
            ),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: context.isDark
                    ? color.shade900.withOpacity(0.4)
                    : color.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color.shade600),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 11,
                          color: colors.textTertiary,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    student?.fullName ?? 'لم يُحدَّد',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isEmpty
                            ? colors.textTertiary
                            : colors.textPrimary),
                  ),
                ],
              ),
            ),
            if (student != null) ...[
              StudentAvatar(
                studentId: student.id,
                fullName: student.fullName,
                photoBase64: student.photoUrl,
                size: 34,
                borderRadius: 9,
              ),
              const SizedBox(width: 8),
            ],
            Icon(Icons.edit_outlined,
                size: 16, color: colors.textTertiary),
          ]),
        ),
      ),
    );
  }
}