import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'api.dart';

class ExportService {
  /// توليد ملف CSV ومشاركته
  /// يعيد عدد التلاميذ المُصدَّرين
  static Future<int> exportClassReport({
    required SchoolClass schoolClass,
    required List<StudentFullReport> reports,
  }) async {
    if (reports.isEmpty) {
      throw Exception('لا يوجد تلاميذ للتصدير');
    }

    // ─── 1. بناء محتوى CSV ───
    final buffer = StringBuffer();

    // BOM لـ Excel (يدعم العربية)
    buffer.write('\uFEFF');

    // رأس الجدول
    buffer.writeln('الترتيب,الاسم الكامل,الحضور,الغياب,المجموع,نسبة الحضور,المعدل');

    // بيانات التلاميذ
    for (int i = 0; i < reports.length; i++) {
      final r = reports[i];
      final avgText = r.gradesAverage != null
          ? r.gradesAverage!.toStringAsFixed(2)
          : '—';
      buffer.writeln(
        '${i + 1},'
        '${_escapeCsv(r.student.fullName)},'
        '${r.attendancePresent},'
        '${r.attendanceAbsent},'
        '${r.attendanceTotal},'
        '${r.attendanceRate}%,'
        '$avgText',
      );
    }

    // ─── 2. حفظ الملف ───
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .substring(0, 19);
    final safeName = schoolClass.name.replaceAll(RegExp(r'[^\w\u0600-\u06FF-]'), '_');
    final fileName = 'تقرير_${safeName}_$timestamp.csv';
    final file = File('${dir.path}/$fileName');

    await file.writeAsString(
      buffer.toString(),
      encoding: utf8,
    );

    // ─── 3. مشاركة ───
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'تقرير القسم ${schoolClass.name}',
      text: 'تقرير شامل لقسم ${schoolClass.name} '
          '(${schoolClass.level}) — ${reports.length} تلميذ',
    );

    return reports.length;
  }

  /// تلطيف الحقول التي تحتوي على فواصل
  static String _escapeCsv(String value) {
    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// توليد تقرير نصي بسيط (للواتساب المباشر بدون ملف)
  static String generateTextReport({
    required SchoolClass schoolClass,
    required List<StudentFullReport> reports,
  }) {
    if (reports.isEmpty) return 'لا يوجد تلاميذ.';

    final buffer = StringBuffer();
    buffer.writeln('📋 *تقرير قسم ${schoolClass.name}*');
    buffer.writeln('📚 المستوى: ${schoolClass.level}');
    buffer.writeln('👥 عدد التلاميذ: ${reports.length}');
    buffer.writeln('━━━━━━━━━━━━━━━━━━');

    // ترتيب حسب نسبة الحضور
    final sorted = [...reports]
      ..sort((a, b) => b.attendanceRate.compareTo(a.attendanceRate));

    for (int i = 0; i < sorted.length; i++) {
      final r = sorted[i];
      final emoji = r.attendanceRate >= 90
          ? '🟢'
          : r.attendanceRate >= 70
              ? '🟡'
              : '🔴';
      final avg = r.gradesAverage != null
          ? ' | معدل: ${r.gradesAverage!.toStringAsFixed(1)}'
          : '';
      buffer.writeln(
        '$emoji ${i + 1}. ${r.student.fullName} — '
        '${r.attendanceRate}%$avg',
      );
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━');
    buffer.writeln('🕐 ${_formatNow()}');
    return buffer.toString();
  }

  /// مشاركة تقرير نصي (واتساب، إلخ)
  static Future<void> shareTextReport({
    required SchoolClass schoolClass,
    required List<StudentFullReport> reports,
  }) async {
    final text = generateTextReport(
      schoolClass: schoolClass,
      reports: reports,
    );
    await Share.share(text, subject: 'تقرير قسم ${schoolClass.name}');
  }

  static String _formatNow() {
    final now = DateTime.now();
    final months = [
      'جانفي','فيفري','مارس','أفريل','ماي','جوان',
      'جويلية','أوت','سبتمبر','أكتوبر','نوفمبر','ديسمبر'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year} — '
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';
  }
}