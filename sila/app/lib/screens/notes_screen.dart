import 'package:flutter/material.dart';
import '../services/api.dart';
import '../theme/app_theme.dart';

class NotesScreen extends StatefulWidget {
  final SchoolClass schoolClass;
  const NotesScreen({super.key, required this.schoolClass});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  late Future<List<NoteItem>> _notesFuture;
  List<Student> _students = [];
  String _filterType = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _notesFuture = ApiService.getClassNotes(widget.schoolClass.id);
    });
    try {
      final students = await ApiService.getStudents(widget.schoolClass.id);
      if (mounted) setState(() => _students = students);
    } catch (_) {}
  }

  Future<void> _reload() async {
    setState(() {
      _notesFuture = ApiService.getClassNotes(widget.schoolClass.id);
    });
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

  // ═══════════════════════════════════════════
  // حوار إضافة ملاحظة
  // ═══════════════════════════════════════════
  Future<void> _showAddDialog() async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedType = 'JOURNAL';
    DateTime selectedDate = DateTime.now();
    int? selectedStudentId;

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      barrierDismissible: false,
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
                child: const Icon(Icons.note_add_outlined,
                    color: Color(0xFF4CAF50), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('ملاحظة جديدة',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: colors.textPrimary)),
              ),
            ]),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _dialogLabel('النوع', Icons.category_outlined),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _typeChip(context, setDialogState, selectedType,
                          'JOURNAL', 'مذكرة حصة', Icons.menu_book_outlined,
                          (t) {
                        setDialogState(() {
                          selectedType = t;
                          if (selectedType == 'JOURNAL') {
                            selectedStudentId = null;
                          }
                        });
                      }),
                      _typeChip(context, setDialogState, selectedType,
                          'POSITIVE', 'إيجابي', Icons.star_outline, (t) {
                        setDialogState(() => selectedType = t);
                      }),
                      _typeChip(context, setDialogState, selectedType,
                          'NEGATIVE', 'سلبي', Icons.warning_amber_outlined,
                          (t) {
                        setDialogState(() => selectedType = t);
                      }),
                      _typeChip(context, setDialogState, selectedType, 'INFO',
                          'معلومة', Icons.info_outline, (t) {
                        setDialogState(() => selectedType = t);
                      }),
                    ],
                  ),

                  if (selectedType != 'JOURNAL') ...[
                    const SizedBox(height: 16),
                    _dialogLabel('التلميذ', Icons.person_outline),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: colors.inputFill,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.cardBorder),
                      ),
                      child: DropdownButton<int?>(
                        value: selectedStudentId,
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        hint: Text('اختر تلميذاً',
                            style: TextStyle(
                                color: colors.textTertiary, fontSize: 13)),
                        dropdownColor: colors.cardBg,
                        style: TextStyle(
                            color: colors.textPrimary, fontSize: 14),
                        items: _students
                            .map((s) => DropdownMenuItem<int?>(
                                  value: s.id,
                                  child: Text(s.fullName),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setDialogState(() => selectedStudentId = v),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  _dialogLabel('العنوان', Icons.title_outlined),
                  const SizedBox(height: 8),
                  TextField(
                    controller: titleController,
                    maxLength: 200,
                    style:
                        TextStyle(color: colors.textPrimary, fontSize: 14),
                    decoration: _inputDecoration(
                      context,
                      hint: selectedType == 'JOURNAL'
                          ? 'مثال: رياضيات - المشتقات'
                          : 'مثال: تحسن ملحوظ',
                    ),
                  ),

                  const SizedBox(height: 4),
                  _dialogLabel('المحتوى', Icons.notes_outlined),
                  const SizedBox(height: 8),
                  TextField(
                    controller: contentController,
                    maxLines: 5,
                    maxLength: 2000,
                    style:
                        TextStyle(color: colors.textPrimary, fontSize: 14),
                    decoration: _inputDecoration(
                      context,
                      hint: selectedType == 'JOURNAL'
                          ? 'ماذا شُرح في الحصة؟'
                          : 'تفاصيل الملاحظة...',
                    ),
                  ),

                  const SizedBox(height: 4),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        locale: const Locale('ar', 'DZ'),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: colors.inputFill,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.cardBorder),
                      ),
                      child: Row(children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 16,
                            color: context.isDark
                                ? const Color(0xFF81C784)
                                : Colors.green.shade600),
                        const SizedBox(width: 10),
                        Text(ApiService.formatDateArabic(selectedDate),
                            style: TextStyle(
                                color: colors.textPrimary, fontSize: 13)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                style: TextButton.styleFrom(
                  foregroundColor: colors.textSecondary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                ),
                child: const Text('إلغاء'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  if (titleController.text.trim().isEmpty ||
                      contentController.text.trim().isEmpty) return;
                  if (selectedType != 'JOURNAL' &&
                      selectedStudentId == null) return;
                  Navigator.pop(context, {
                    'type': selectedType,
                    'title': titleController.text.trim(),
                    'content': contentController.text.trim(),
                    'date': selectedDate,
                    'studentId': selectedStudentId,
                  });
                },
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('حفظ',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  elevation: 0,
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
      await ApiService.createNote(
        classId: widget.schoolClass.id,
        studentId: result['studentId'],
        type: result['type'],
        title: result['title'],
        content: result['content'],
        date: result['date'],
      );
      _reload();
      _showSnack('تم حفظ الملاحظة', isError: false);
    } catch (e) {
      _showSnack('خطأ: $e', isError: true);
    }
  }

  // ✅ الدالة التي كانت مفقودة
  Widget _typeChip(
    BuildContext context,
    StateSetter setDialogState,
    String currentType,
    String type,
    String label,
    IconData icon,
    Function(String) onSelect,
  ) {
    final colors = context.colors;
    final selected = currentType == type;
    final color = _typeColor(type);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onSelect(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? color.shade600
              : (context.isDark
                  ? color.shade900.withOpacity(0.3)
                  : color.shade50),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color.shade600 : colors.cardBorder,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              size: 14,
              color: selected ? Colors.white : color.shade400),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.white : color.shade400)),
        ]),
      ),
    );
  }

  Widget _dialogLabel(String label, IconData icon) {
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

  InputDecoration _inputDecoration(BuildContext context,
      {required String hint}) {
    final colors = context.colors;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: colors.textTertiary, fontSize: 12),
      filled: true,
      fillColor: colors.inputFill,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
    );
  }

  Future<void> _confirmDelete(NoteItem note) async {
    final colors = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
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
          Text('حذف الملاحظة',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: colors.textPrimary)),
        ]),
        content: Text('هل أنت متأكد من حذف هذه الملاحظة؟',
            style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style:
                TextButton.styleFrom(foregroundColor: colors.textSecondary),
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
        await ApiService.deleteNote(note.id);
        _reload();
        _showSnack('تم حذف الملاحظة', isError: false);
      } catch (e) {
        _showSnack('خطأ: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('ملاحظات القسم'),
        centerTitle: true,
        backgroundColor: colors.headerGradientMid,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<NoteItem>>(
        future: _notesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.green.shade600),
                    const SizedBox(height: 16),
                    Text('جاري التحميل...',
                        style: TextStyle(color: colors.textSecondary)),
                  ]),
            );
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
                          style: TextStyle(color: colors.textSecondary)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _reload,
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

          final allNotes = snapshot.data ?? [];
          final notes = _filterType == 'ALL'
              ? allNotes
              : allNotes.where((n) => n.type == _filterType).toList();

          return Column(
            children: [
              _buildFilterRow(allNotes),
              Expanded(
                child: notes.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _reload,
                        color: Colors.green.shade600,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: notes.length,
                          itemBuilder: (context, index) =>
                              _buildNoteCard(notes[index], index),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('ملاحظة جديدة',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFilterRow(List<NoteItem> allNotes) {
    final colors = context.colors;
    int countOf(String type) => type == 'ALL'
        ? allNotes.length
        : allNotes.where((n) => n.type == type).length;

    final filters = [
      {'key': 'ALL', 'label': 'الكل', 'icon': Icons.apps},
      {'key': 'JOURNAL', 'label': 'مذكرات', 'icon': Icons.menu_book_outlined},
      {'key': 'POSITIVE', 'label': 'إيجابي', 'icon': Icons.star_outline},
      {
        'key': 'NEGATIVE',
        'label': 'سلبي',
        'icon': Icons.warning_amber_outlined
      },
      {'key': 'INFO', 'label': 'معلومات', 'icon': Icons.info_outline},
    ];

    return Container(
      color: colors.background,
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final f = filters[i];
            final key = f['key'] as String;
            final selected = _filterType == key;
            final color = key == 'ALL' ? Colors.green : _typeColor(key);
            final count = countOf(key);

            return InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => setState(() => _filterType = key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: selected
                      ? color.shade600
                      : (context.isDark ? colors.cardBg : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? color.shade600 : colors.cardBorder,
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(f['icon'] as IconData,
                      size: 14,
                      color: selected ? Colors.white : color.shade400),
                  const SizedBox(width: 6),
                  Text(f['label'] as String,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: selected
                              ? Colors.white
                              : colors.textPrimary)),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white.withOpacity(0.25)
                            : color.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('$count',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: selected
                                  ? Colors.white
                                  : color.shade700)),
                    ),
                  ],
                ]),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
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
            child: const Icon(Icons.sticky_note_2_outlined,
                size: 64, color: Color(0xFF4CAF50)),
          ),
          const SizedBox(height: 20),
          Text(
              _filterType == 'ALL'
                  ? 'لا توجد ملاحظات بعد'
                  : 'لا ملاحظات من هذا النوع',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary)),
          const SizedBox(height: 8),
          Text('اضغط زر + لإضافة أول ملاحظة',
              style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        ]),
      ),
    );
  }

  Widget _buildNoteCard(NoteItem note, int index) {
    final colors = context.colors;
    final color = _typeColor(note.type);
    final icon = _typeIcon(note.type);

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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.isDark
                      ? color.shade900.withOpacity(0.4)
                      : color.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color.shade400, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(note.title,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: colors.textPrimary)),
                    const SizedBox(height: 2),
                    Row(children: [
                      if (note.studentName != null) ...[
                        Icon(Icons.person_outline,
                            size: 11, color: colors.textTertiary),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(note.studentName!,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: color.shade400)),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Icon(Icons.calendar_today_outlined,
                          size: 10, color: colors.textTertiary),
                      const SizedBox(width: 3),
                      Text(ApiService.formatDateArabic(note.date),
                          style: TextStyle(
                              fontSize: 11, color: colors.textTertiary)),
                    ]),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    size: 18, color: colors.textTertiary),
                onPressed: () => _confirmDelete(note),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
            ]),
            const SizedBox(height: 10),
            Text(note.content,
                style: TextStyle(
                    fontSize: 13, height: 1.5, color: colors.textSecondary)),
          ]),
        ),
      ),
    );
  }

  MaterialColor _typeColor(String type) {
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

  IconData _typeIcon(String type) {
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
}