import 'package:flutter/material.dart';
import '../services/api.dart';
import '../services/messaging_service.dart';
import '../theme/app_theme.dart';
import '../theme/preferences_controller.dart';

class MessagingScreen extends StatefulWidget {
  final Student student;
  const MessagingScreen({super.key, required this.student});

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  String _filterCategory = 'ALL';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('مراسلة الولي'),
        centerTitle: true,
        backgroundColor: colors.headerGradientMid,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildFilterRow(),
          Expanded(child: _buildTemplatesList()),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // رأس الصفحة: معلومات التلميذ والولي
  // ═══════════════════════════════════════════
  Widget _buildHeader() {
    final colors = context.colors;
    final hasPhone = widget.student.guardianPhone?.trim().isNotEmpty ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        border: Border(
          bottom: BorderSide(color: colors.cardBorder, width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.green.shade400,
                  Colors.green.shade700,
                ]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  _initials(widget.student.fullName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.student.fullName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (widget.student.guardianName != null &&
                      widget.student.guardianName!.trim().isNotEmpty)
                    Text(
                      'الولي: ${widget.student.guardianName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: hasPhone
                  ? (context.isDark
                      ? const Color(0xFF1B3A1E)
                      : Colors.green.shade50)
                  : (context.isDark
                      ? const Color(0xFF3A2A0A)
                      : Colors.orange.shade50),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Icon(
                hasPhone ? Icons.phone_iphone : Icons.warning_amber_rounded,
                size: 18,
                color: hasPhone
                    ? (context.isDark
                        ? const Color(0xFF81C784)
                        : Colors.green.shade700)
                    : Colors.orange.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasPhone
                      ? MessagingService.formatPhone(
                          widget.student.guardianPhone!)
                      : 'لا يوجد رقم هاتف مسجّل',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: hasPhone
                        ? (context.isDark
                            ? const Color(0xFF81C784)
                            : Colors.green.shade700)
                        : Colors.orange.shade800,
                  ),
                ),
              ),
              if (hasPhone)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () =>
                        MessagingService.callPhone(widget.student.guardianPhone!),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.call,
                        size: 18,
                        color: context.isDark
                            ? const Color(0xFF81C784)
                            : Colors.green.shade700,
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // فلاتر الفئات
  // ═══════════════════════════════════════════
  Widget _buildFilterRow() {
    final colors = context.colors;
    final categories = [
      {'key': 'ALL', 'label': 'الكل', 'icon': Icons.apps},
      {'key': 'ABSENCE', 'label': 'الغياب', 'icon': Icons.event_busy},
      {'key': 'PRAISE', 'label': 'ثناء', 'icon': Icons.star_outline},
      {'key': 'WARNING', 'label': 'تنبيه', 'icon': Icons.warning_amber_outlined},
      {'key': 'MEETING', 'label': 'مواعيد', 'icon': Icons.event},
      {'key': 'GENERAL', 'label': 'عام', 'icon': Icons.info_outline},
    ];

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: colors.background,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = categories[i];
          final key = cat['key'] as String;
          final selected = _filterCategory == key;
          final color = _categoryColor(key);

          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => setState(() => _filterCategory = key),
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    cat['icon'] as IconData,
                    size: 14,
                    color: selected ? Colors.white : color.shade400,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat['label'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: selected ? Colors.white : colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════
  // قائمة الرسائل
  // ═══════════════════════════════════════════
  Widget _buildTemplatesList() {
    final templates = _filterCategory == 'ALL'
        ? kMessageTemplates
        : kMessageTemplates
            .where((t) => t.category == _filterCategory)
            .toList();

    if (templates.isEmpty) {
      return Center(
        child: Text(
          'لا رسائل في هذه الفئة',
          style: TextStyle(color: context.colors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: templates.length,
      itemBuilder: (context, i) => _buildTemplateCard(templates[i], i),
    );
  }

  Widget _buildTemplateCard(MessageTemplate template, int index) {
    final colors = context.colors;
    final color = _categoryColor(template.category);

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
          border: Border(
            right: BorderSide(color: color.shade400, width: 4),
            top: BorderSide(color: colors.cardBorder),
            bottom: BorderSide(color: colors.cardBorder),
            left: BorderSide(color: colors.cardBorder),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _previewAndSend(template),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.isDark
                            ? color.shade900.withOpacity(0.4)
                            : color.shade50,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        _categoryIcon(template.category),
                        color: color.shade400,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        template.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.send_outlined,
                      size: 16,
                      color: colors.textTertiary,
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    _preview(template),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _preview(MessageTemplate t) {
    return t.render(
      studentName: widget.student.fullName,
      teacherName: preferencesController.teacherName.isEmpty
          ? null
          : preferencesController.teacherName,
      schoolName: preferencesController.schoolName.isEmpty
          ? null
          : preferencesController.schoolName,
    );
  }

  // ═══════════════════════════════════════════
  // معاينة + إرسال
  // ═══════════════════════════════════════════
  Future<void> _previewAndSend(MessageTemplate template) async {
    final phone = widget.student.guardianPhone?.trim() ?? '';
    if (phone.isEmpty) {
      _showNoPhoneDialog();
      return;
    }

    final textController = TextEditingController(text: _preview(template));

    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _buildPreviewSheet(template, textController),
      ),
    );

    if (action == 'whatsapp') {
      final ok = await MessagingService.sendWhatsApp(
        phone: phone,
        message: textController.text,
      );
      if (!ok && mounted) _showError('تأكد من تثبيت تطبيق واتساب');
    } else if (action == 'sms') {
      await MessagingService.sendSMS(
        phone: phone,
        message: textController.text,
      );
    }
  }

  Widget _buildPreviewSheet(
    MessageTemplate template,
    TextEditingController textController,
  ) {
    final colors = context.colors;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // مقبض
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: colors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // العنوان
            Row(children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: context.isDark
                      ? const Color(0xFF1B3A1E)
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.send_rounded,
                    color: Color(0xFF4CAF50), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  template.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 14),

            // النص القابل للتعديل
            Container(
              constraints: const BoxConstraints(maxHeight: 250),
              child: TextField(
                controller: textController,
                maxLines: null,
                minLines: 4,
                style: TextStyle(
                    color: colors.textPrimary, fontSize: 13, height: 1.5),
                decoration: InputDecoration(
                  hintText: 'عدّل الرسالة إن أردت...',
                  hintStyle:
                      TextStyle(color: colors.textTertiary, fontSize: 12),
                  filled: true,
                  fillColor: colors.inputFill,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: context.isDark
                            ? const Color(0xFF4CAF50)
                            : Colors.green.shade300,
                        width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // أزرار الإرسال
            Row(children: [
              Expanded(
                child: _buildSendButton(
                  icon: Icons.chat_bubble_outline,
                  label: 'SMS',
                  color: Colors.blue,
                  onTap: () => Navigator.pop(context, 'sms'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _buildSendButton(
                  icon: Icons.chat,
                  label: 'واتساب',
                  color: Colors.green,
                  filled: true,
                  onTap: () => Navigator.pop(context, 'whatsapp'),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'إلغاء',
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButton({
    required IconData icon,
    required String label,
    required MaterialColor color,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    return filled
        ? ElevatedButton.icon(
            onPressed: onTap,
            icon: Icon(icon, size: 18),
            label: Text(label,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: color.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          )
        : OutlinedButton.icon(
            onPressed: onTap,
            icon: Icon(icon, size: 18),
            label: Text(label,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: color.shade600,
              side: BorderSide(color: color.shade600, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
  }

  void _showNoPhoneDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.isDark
                  ? const Color(0xFF3A2A0A)
                  : const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.phone_disabled,
                color: Color(0xFFFFB300), size: 22),
          ),
          const SizedBox(width: 12),
          const Text('رقم مفقود',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 17)),
        ]),
        content: const Text(
          'لا يوجد رقم هاتف لهذا التلميذ. '
          'أضف رقم الولي من تعديل بيانات التلميذ.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
    ));
  }

  String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return parts[0][0];
  }

  MaterialColor _categoryColor(String category) {
    switch (category) {
      case 'ABSENCE': return Colors.red;
      case 'PRAISE': return Colors.green;
      case 'WARNING': return Colors.orange;
      case 'MEETING': return Colors.blue;
      case 'GENERAL': default: return Colors.teal;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'ABSENCE': return Icons.event_busy;
      case 'PRAISE': return Icons.star_outline;
      case 'WARNING': return Icons.warning_amber_outlined;
      case 'MEETING': return Icons.event;
      case 'GENERAL': default: return Icons.info_outline;
    }
  }
}