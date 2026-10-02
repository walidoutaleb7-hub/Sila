import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

// ═══════════════════════════════════════════
// نموذج القسم
// ═══════════════════════════════════════════
class SchoolClass {
  final int id;
  final String name;
  final String level;
  final int studentsCount;

  SchoolClass({
    required this.id,
    required this.name,
    required this.level,
    required this.studentsCount,
  });

  factory SchoolClass.fromJson(Map<String, dynamic> json) {
    return SchoolClass(
      id: json['id'] as int,
      name: json['name'] as String,
      level: json['level'] as String,
      studentsCount: (json['_count']?['students'] ?? 0) as int,
    );
  }
}

// ═══════════════════════════════════════════
// نموذج التلميذ
// ═══════════════════════════════════════════
class Student {
  final int id;
  final String fullName;
  final int classId;
  final String? status;

  Student({
    required this.id,
    required this.fullName,
    required this.classId,
    this.status,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as int,
      fullName: json['fullName'] as String,
      classId: json['classId'] as int,
      status: json['status'] as String?,
    );
  }
}

// ═══════════════════════════════════════════
// نموذج سجل الحضور
// ═══════════════════════════════════════════
class AttendanceEntry {
  final int studentId;
  final String fullName;
  final String? status;

  AttendanceEntry({
    required this.studentId,
    required this.fullName,
    this.status,
  });

  factory AttendanceEntry.fromJson(Map<String, dynamic> json) {
    return AttendanceEntry(
      studentId: json['studentId'] as int,
      fullName: json['fullName'] as String,
      status: json['status'] as String?,
    );
  }
}

// ═══════════════════════════════════════════
// نموذج سجل تلميذ
// ═══════════════════════════════════════════
class StudentHistory {
  final Student student;
  final int total;
  final int present;
  final int absent;
  final int rate;
  final List<AttendanceRecord> records;

  StudentHistory({
    required this.student,
    required this.total,
    required this.present,
    required this.absent,
    required this.rate,
    required this.records,
  });

  factory StudentHistory.fromJson(Map<String, dynamic> json) {
    final s = json['student'];
    final stats = json['stats'];
    final recs = json['records'] as List<dynamic>;

    return StudentHistory(
      student: Student(
        id: s['id'] as int,
        fullName: s['fullName'] as String,
        classId: s['classId'] as int,
      ),
      total: stats['total'] as int,
      present: stats['present'] as int,
      absent: stats['absent'] as int,
      rate: stats['rate'] as int,
      records: recs.map((e) => AttendanceRecord.fromJson(e)).toList(),
    );
  }
}

class AttendanceRecord {
  final DateTime date;
  final String status;

  AttendanceRecord({required this.date, required this.status});

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      date: DateTime.parse(json['date'] as String),
      status: json['status'] as String,
    );
  }
}

// ═══════════════════════════════════════════
// خدمة الاتصال بالخادم
// ═══════════════════════════════════════════
class ApiService {
  static const String _baseUrl = AppConfig.apiBaseUrl;

  // ─────────────────────────────────────────
  // الأقسام
  // ─────────────────────────────────────────
  static Future<List<SchoolClass>> getClasses() async {
    final response = await http
        .get(Uri.parse('$_baseUrl/api/classes'))
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body['success'] == true) {
        final List<dynamic> data = body['data'];
        return data.map((e) => SchoolClass.fromJson(e)).toList();
      }
    }
    throw Exception('فشل جلب الأقسام');
  }

  static Future<SchoolClass> createClass({
    required String name,
    required String level,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/classes'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'name': name, 'level': level}),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 201) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body['success'] == true) {
        return SchoolClass.fromJson({
          ...body['data'],
          '_count': {'students': 0},
        });
      }
    }
    throw Exception('فشل إنشاء القسم');
  }

  // ─────────────────────────────────────────
  // التلاميذ
  // ─────────────────────────────────────────
  static Future<List<Student>> getStudents(int classId) async {
    final response = await http
        .get(Uri.parse('$_baseUrl/api/classes/$classId/students'))
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body['success'] == true) {
        final List<dynamic> data = body['data'];
        return data.map((e) => Student.fromJson(e)).toList();
      }
    }
    throw Exception('فشل جلب التلاميذ');
  }

  static Future<Student> createStudent({
    required int classId,
    required String fullName,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/classes/$classId/students'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'fullName': fullName}),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 201) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body['success'] == true) {
        return Student.fromJson(body['data']);
      }
    }
    throw Exception('فشل إضافة التلميذ');
  }

  /// تعديل اسم تلميذ
  static Future<Student> updateStudent({
    required int studentId,
    required String fullName,
  }) async {
    final response = await http
        .put(
          Uri.parse('$_baseUrl/api/students/$studentId'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'fullName': fullName}),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body['success'] == true) {
        return Student.fromJson(body['data']);
      }
    }
    throw Exception('فشل تعديل التلميذ');
  }

  /// حذف تلميذ
  static Future<void> deleteStudent(int studentId) async {
    final response = await http
        .delete(Uri.parse('$_baseUrl/api/students/$studentId'))
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw Exception('فشل حذف التلميذ');
    }
  }

  /// جلب سجل حضور تلميذ
  static Future<StudentHistory> getStudentHistory(int studentId) async {
    final response = await http
        .get(Uri.parse('$_baseUrl/api/students/$studentId/attendance'))
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body['success'] == true) {
        return StudentHistory.fromJson(body['data']);
      }
    }
    throw Exception('فشل جلب سجل التلميذ');
  }

  // ─────────────────────────────────────────
  // الحضور
  // ─────────────────────────────────────────
  static Future<int> saveAttendance({
    required int classId,
    required DateTime date,
    required Map<int, String> records,
  }) async {
    final dateStr = _formatDate(date);
    final recordsList = records.entries
        .map((e) => {'studentId': e.key, 'status': e.value})
        .toList();

    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/attendance'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'classId': classId,
            'date': dateStr,
            'records': recordsList,
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body['success'] == true) {
        return body['data']['saved'] as int;
      }
    }
    throw Exception('فشل حفظ الحضور');
  }

  static Future<List<AttendanceEntry>> getAttendance({
    required int classId,
    required DateTime date,
  }) async {
    final dateStr = _formatDate(date);
    final response = await http
        .get(Uri.parse(
            '$_baseUrl/api/attendance?classId=$classId&date=$dateStr'))
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body['success'] == true) {
        final List<dynamic> students = body['data']['students'];
        return students.map((e) => AttendanceEntry.fromJson(e)).toList();
      }
    }
    throw Exception('فشل جلب سجل الحضور');
  }

  // ─────────────────────────────────────────
  // أدوات
  // ─────────────────────────────────────────
  static String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static String formatDateArabic(DateTime d) {
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
    return '${days[d.weekday - 1]}، ${d.day} ${months[d.month - 1]} ${d.year}';
  }
}