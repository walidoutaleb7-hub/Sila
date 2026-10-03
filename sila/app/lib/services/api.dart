import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'auth_service.dart';

// ═══════════════════════════════════════════
// نماذج أساسية
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

  factory SchoolClass.fromJson(Map<String, dynamic> json) => SchoolClass(
        id: json['id'] as int,
        name: json['name'] as String,
        level: json['level'] as String,
        studentsCount: (json['_count']?['students'] ?? 0) as int,
      );
}

class Student {
  final int id;
  final String fullName;
  final int classId;
  final String? photoUrl;
  final String? guardianName;
  final String? guardianPhone;
  final int consecutiveAbsences;
  final String? status;

  Student({
    required this.id,
    required this.fullName,
    required this.classId,
    this.photoUrl,
    this.guardianName,
    this.guardianPhone,
    this.consecutiveAbsences = 0,
    this.status,
  });

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        id: json['id'] as int,
        fullName: json['fullName'] as String,
        classId: json['classId'] as int,
        photoUrl: json['photoUrl'] as String?,
        guardianName: json['guardianName'] as String?,
        guardianPhone: json['guardianPhone'] as String?,
        consecutiveAbsences: (json['consecutiveAbsences'] ?? 0) as int,
        status: json['status'] as String?,
      );

  bool get hasGuardianInfo =>
      (guardianName?.trim().isNotEmpty ?? false) ||
      (guardianPhone?.trim().isNotEmpty ?? false);

  bool get needsAlert => consecutiveAbsences >= 3;
}

class AttendanceEntry {
  final int studentId;
  final String fullName;
  final String? photoUrl;
  final String? guardianPhone;
  final String? status;

  AttendanceEntry({
    required this.studentId,
    required this.fullName,
    this.photoUrl,
    this.guardianPhone,
    this.status,
  });

  factory AttendanceEntry.fromJson(Map<String, dynamic> json) =>
      AttendanceEntry(
        studentId: json['studentId'] as int,
        fullName: json['fullName'] as String,
        photoUrl: json['photoUrl'] as String?,
        guardianPhone: json['guardianPhone'] as String?,
        status: json['status'] as String?,
      );
}

class AttendanceRecord {
  final DateTime date;
  final String period;
  final String status;

  AttendanceRecord({
    required this.date,
    required this.period,
    required this.status,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        date: DateTime.parse(json['date'] as String),
        period: json['period'] as String? ?? 'MORNING',
        status: json['status'] as String,
      );

  bool get isMorning => period == 'MORNING';
}

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

// ═══════════════════════════════════════════
// جدول الأسبوع
// ═══════════════════════════════════════════
class ScheduleItem {
  final int id;
  final int classId;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final String subject;
  final String? room;
  final ScheduleClassInfo? classInfo;

  ScheduleItem({
    required this.id,
    required this.classId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.subject,
    this.room,
    this.classInfo,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) => ScheduleItem(
        id: json['id'] as int,
        classId: json['classId'] as int,
        dayOfWeek: json['dayOfWeek'] as int,
        startTime: json['startTime'] as String,
        endTime: json['endTime'] as String,
        subject: json['subject'] as String,
        room: json['room'] as String?,
        classInfo: json['class'] != null
            ? ScheduleClassInfo.fromJson(json['class'])
            : null,
      );

  String get className => classInfo?.name ?? '—';
  String get classLevel => classInfo?.level ?? '';
}

class ScheduleClassInfo {
  final int id;
  final String name;
  final String level;

  ScheduleClassInfo({
    required this.id,
    required this.name,
    required this.level,
  });

  factory ScheduleClassInfo.fromJson(Map<String, dynamic> json) =>
      ScheduleClassInfo(
        id: json['id'] as int,
        name: json['name'] as String,
        level: json['level'] as String,
      );
}

class CurrentSchedule {
  final ScheduleItem? current;
  final ScheduleItem? next;

  CurrentSchedule({this.current, this.next});

  factory CurrentSchedule.fromJson(Map<String, dynamic> json) =>
      CurrentSchedule(
        current: json['current'] != null
            ? ScheduleItem.fromJson(json['current'])
            : null,
        next: json['next'] != null ? ScheduleItem.fromJson(json['next']) : null,
      );
}

// ═══════════════════════════════════════════
// مخطط الجلوس (طاولة = مقعدان)
// ═══════════════════════════════════════════
class SeatingChart {
  final int id;
  final int classId;
  final int rows;
  final int cols;
  // "r-c" → [id1, id2] حيث null تعني مقعد فارغ
  final Map<String, List<int?>> seats;
  final int? delegate1;
  final int? delegate2;
  final int? delegate3;

  SeatingChart({
    required this.id,
    required this.classId,
    required this.rows,
    required this.cols,
    required this.seats,
    this.delegate1,
    this.delegate2,
    this.delegate3,
  });

  factory SeatingChart.fromJson(Map<String, dynamic> json) {
    final seatsRaw = json['seats'];
    final seats = <String, List<int?>>{};
    if (seatsRaw is Map) {
      for (final entry in seatsRaw.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        final list = <int?>[null, null];
        if (value is List) {
          for (int i = 0; i < 2 && i < value.length; i++) {
            final v = value[i];
            if (v is num && v > 0) list[i] = v.toInt();
          }
        } else if (value is num && value > 0) {
          list[0] = value.toInt();
        }
        seats[key] = list;
      }
    }
    return SeatingChart(
      id: json['id'] as int,
      classId: json['classId'] as int,
      rows: json['rows'] as int,
      cols: json['cols'] as int,
      seats: seats,
      delegate1: json['delegate1'] as int?,
      delegate2: json['delegate2'] as int?,
      delegate3: json['delegate3'] as int?,
    );
  }
}

// ═══════════════════════════════════════════
// الإحصائيات
// ═══════════════════════════════════════════
class ClassStats {
  final String className;
  final String classLevel;
  final int totalStudents;
  final OverallStats overall;
  final TodayStats today;
  final List<DayStat> last7Days;
  final List<StudentRank> topStudents;
  final List<StudentRank> worstStudents;

  ClassStats({
    required this.className,
    required this.classLevel,
    required this.totalStudents,
    required this.overall,
    required this.today,
    required this.last7Days,
    required this.topStudents,
    required this.worstStudents,
  });

  factory ClassStats.fromJson(Map<String, dynamic> json) => ClassStats(
        className: json['className'] as String,
        classLevel: json['classLevel'] as String,
        totalStudents: json['totalStudents'] as int,
        overall: OverallStats.fromJson(json['overall']),
        today: TodayStats.fromJson(json['today']),
        last7Days:
            (json['last7Days'] as List).map((e) => DayStat.fromJson(e)).toList(),
        topStudents: (json['topStudents'] as List)
            .map((e) => StudentRank.fromJson(e))
            .toList(),
        worstStudents: (json['worstStudents'] as List)
            .map((e) => StudentRank.fromJson(e))
            .toList(),
      );
}

class OverallStats {
  final int total, present, absent, rate;
  OverallStats({
    required this.total,
    required this.present,
    required this.absent,
    required this.rate,
  });
  factory OverallStats.fromJson(Map<String, dynamic> json) => OverallStats(
        total: json['total'] as int,
        present: json['present'] as int,
        absent: json['absent'] as int,
        rate: json['rate'] as int,
      );
}

class TodayStats {
  final int present, absent;
  TodayStats({required this.present, required this.absent});
  factory TodayStats.fromJson(Map<String, dynamic> json) => TodayStats(
        present: json['present'] as int,
        absent: json['absent'] as int,
      );
}

class DayStat {
  final String date;
  final int present, absent;
  DayStat({required this.date, required this.present, required this.absent});
  factory DayStat.fromJson(Map<String, dynamic> json) => DayStat(
        date: json['date'] as String,
        present: json['present'] as int,
        absent: json['absent'] as int,
      );
}

class StudentRank {
  final int id;
  final String fullName;
  final int present, absent, total, rate;
  StudentRank({
    required this.id,
    required this.fullName,
    required this.present,
    required this.absent,
    required this.total,
    required this.rate,
  });
  factory StudentRank.fromJson(Map<String, dynamic> json) => StudentRank(
        id: json['id'] as int,
        fullName: json['fullName'] as String,
        present: json['present'] as int,
        absent: json['absent'] as int,
        total: json['total'] as int,
        rate: json['rate'] as int,
      );
}

// ═══════════════════════════════════════════
// الدرجات
// ═══════════════════════════════════════════
class GradeSession {
  final String assessment;
  final DateTime date;
  final double maxScore;
  final int coeff;
  final String? note;
  final int count;
  final double avg;

  GradeSession({
    required this.assessment,
    required this.date,
    required this.maxScore,
    required this.coeff,
    this.note,
    required this.count,
    required this.avg,
  });

  factory GradeSession.fromJson(Map<String, dynamic> json) => GradeSession(
        assessment: json['assessment'] as String,
        date: DateTime.parse(json['date'] as String),
        maxScore: (json['maxScore'] as num).toDouble(),
        coeff: json['coeff'] as int,
        note: json['note'] as String?,
        count: json['count'] as int,
        avg: (json['avg'] as num).toDouble(),
      );
}

class StudentGrade {
  final int id;
  final String assessment;
  final double score;
  final double maxScore;
  final int coeff;
  final DateTime date;
  final String? note;

  StudentGrade({
    required this.id,
    required this.assessment,
    required this.score,
    required this.maxScore,
    required this.coeff,
    required this.date,
    this.note,
  });

  factory StudentGrade.fromJson(Map<String, dynamic> json) => StudentGrade(
        id: json['id'] as int,
        assessment: json['assessment'] as String,
        score: (json['score'] as num).toDouble(),
        maxScore: (json['maxScore'] as num).toDouble(),
        coeff: json['coeff'] as int,
        date: DateTime.parse(json['date'] as String),
        note: json['note'] as String?,
      );
}

class AssessmentAverage {
  final String assessment;
  final double avg;
  final int count;
  AssessmentAverage({
    required this.assessment,
    required this.avg,
    required this.count,
  });
  factory AssessmentAverage.fromJson(Map<String, dynamic> json) =>
      AssessmentAverage(
        assessment: json['assessment'] as String,
        avg: (json['avg'] as num).toDouble(),
        count: json['count'] as int,
      );
}

class StudentGrades {
  final Student student;
  final double average;
  final int count;
  final List<AssessmentAverage> assessmentAverages;
  final List<StudentGrade> records;

  StudentGrades({
    required this.student,
    required this.average,
    required this.count,
    required this.assessmentAverages,
    required this.records,
  });

  factory StudentGrades.fromJson(Map<String, dynamic> json) {
    final s = json['student'];
    return StudentGrades(
      student: Student(
        id: s['id'] as int,
        fullName: s['fullName'] as String,
        classId: s['classId'] as int,
      ),
      average: (json['average'] as num).toDouble(),
      count: json['count'] as int,
      assessmentAverages: (json['assessmentAverages'] as List)
          .map((e) => AssessmentAverage.fromJson(e))
          .toList(),
      records:
          (json['records'] as List).map((e) => StudentGrade.fromJson(e)).toList(),
    );
  }
}

class StudentFullReport {
  final Student student;
  final int attendanceTotal;
  final int attendancePresent;
  final int attendanceAbsent;
  final int attendanceRate;
  final double? gradesAverage;

  StudentFullReport({
    required this.student,
    required this.attendanceTotal,
    required this.attendancePresent,
    required this.attendanceAbsent,
    required this.attendanceRate,
    required this.gradesAverage,
  });
}

class SessionGrades {
  final String assessment;
  final DateTime date;
  final double maxScore;
  final int coeff;
  final String? note;
  final List<SessionRecord> records;

  SessionGrades({
    required this.assessment,
    required this.date,
    required this.maxScore,
    required this.coeff,
    this.note,
    required this.records,
  });

  factory SessionGrades.fromJson(Map<String, dynamic> json) => SessionGrades(
        assessment: json['assessment'] as String,
        date: DateTime.parse(json['date'] as String),
        maxScore: (json['maxScore'] as num).toDouble(),
        coeff: json['coeff'] as int,
        note: json['note'] as String?,
        records:
            (json['records'] as List).map((e) => SessionRecord.fromJson(e)).toList(),
      );
}

class SessionRecord {
  final int studentId;
  final String fullName;
  final double score;
  final double maxScore;
  final int coeff;
  final String? note;

  SessionRecord({
    required this.studentId,
    required this.fullName,
    required this.score,
    required this.maxScore,
    required this.coeff,
    this.note,
  });

  factory SessionRecord.fromJson(Map<String, dynamic> json) => SessionRecord(
        studentId: json['studentId'] as int,
        fullName: json['fullName'] as String,
        score: (json['score'] as num).toDouble(),
        maxScore: (json['maxScore'] as num).toDouble(),
        coeff: json['coeff'] as int,
        note: json['note'] as String?,
      );
}

// ═══════════════════════════════════════════
// الملاحظات
// ═══════════════════════════════════════════
class NoteItem {
  final int id;
  final String type;
  final String title;
  final String content;
  final DateTime date;
  final int? studentId;
  final String? studentName;

  NoteItem({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.date,
    this.studentId,
    this.studentName,
  });

  factory NoteItem.fromJson(Map<String, dynamic> json) => NoteItem(
        id: json['id'] as int,
        type: json['type'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        date: DateTime.parse(json['date'] as String),
        studentId: json['studentId'] as int?,
        studentName: json['studentName'] as String?,
      );
}

class StudentNotes {
  final int positive;
  final int negative;
  final int info;
  final int total;
  final List<NoteItem> notes;

  StudentNotes({
    required this.positive,
    required this.negative,
    required this.info,
    required this.total,
    required this.notes,
  });

  factory StudentNotes.fromJson(Map<String, dynamic> json) {
    final s = json['stats'];
    return StudentNotes(
      positive: s['positive'] as int,
      negative: s['negative'] as int,
      info: s['info'] as int,
      total: s['total'] as int,
      notes: (json['notes'] as List).map((e) => NoteItem.fromJson(e)).toList(),
    );
  }
}

// ═══════════════════════════════════════════
// الخدمة
// ═══════════════════════════════════════════
class ApiService {
  static const String _baseUrl = AppConfig.apiBaseUrl;

  static Map<String, String> _headers({bool json = true}) {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    final token = authService.token;
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ───────── الأقسام ─────────
  static Future<List<SchoolClass>> getClasses() async {
    final response = await http
        .get(Uri.parse('$_baseUrl/api/classes'), headers: _headers(json: false))
        .timeout(const Duration(seconds: 60));
    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body['success'] == true) {
        return (body['data'] as List)
            .map((e) => SchoolClass.fromJson(e))
            .toList();
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
          headers: _headers(),
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

  // ───────── التلاميذ ─────────
  static Future<List<Student>> getStudents(int classId) async {
    final response = await http
        .get(Uri.parse('$_baseUrl/api/classes/$classId/students'),
            headers: _headers(json: false))
        .timeout(const Duration(seconds: 60));
    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body['success'] == true) {
        return (body['data'] as List).map((e) => Student.fromJson(e)).toList();
      }
    }
    throw Exception('فشل جلب التلاميذ');
  }

  static Future<Student> createStudent({
    required int classId,
    required String fullName,
    String? guardianName,
    String? guardianPhone,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/classes/$classId/students'),
          headers: _headers(),
          body: jsonEncode({
            'fullName': fullName,
            'guardianName': guardianName,
            'guardianPhone': guardianPhone,
          }),
        )
        .timeout(const Duration(seconds: 60));
    if (response.statusCode == 201) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body['success'] == true) return Student.fromJson(body['data']);
    }
    throw Exception('فشل إضافة التلميذ');
  }

  static Future<Student> updateStudent({
    required int studentId,
    required String fullName,
    String? guardianName,
    String? guardianPhone,
  }) async {
    final response = await http
        .put(
          Uri.parse('$_baseUrl/api/students/$studentId'),
          headers: _headers(),
          body: jsonEncode({
            'fullName': fullName,
            'guardianName': guardianName,
            'guardianPhone': guardianPhone,
          }),
        )
        .timeout(const Duration(seconds: 60));
    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body['success'] == true) return Student.fromJson(body['data']);
    }
    throw Exception('فشل تعديل التلميذ');
  }

  static Future<void> deleteStudent(int studentId) async {
    final response = await http
        .delete(Uri.parse('$_baseUrl/api/students/$studentId'),
            headers: _headers(json: false))
        .timeout(const Duration(seconds: 60));
    if (response.statusCode != 200) throw Exception('فشل حذف التلميذ');
  }

  static Future<Student> updateStudentPhoto({
    required int studentId,
    required String photoBase64,
  }) async {
    final response = await http
        .put(
          Uri.parse('$_baseUrl/api/students/$studentId/photo'),
          headers: _headers(),
          body: jsonEncode({'photoUrl': photoBase64}),
        )
        .timeout(const Duration(seconds: 120));
    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body['success'] == true) return Student.fromJson(body['data']);
    }
    throw Exception('فشل تحديث الصورة');
  }

  static Future<Student> deleteStudentPhoto(int studentId) async {
    final response = await http
        .delete(Uri.parse('$_baseUrl/api/students/$studentId/photo'),
            headers: _headers(json: false))
        .timeout(const Duration(seconds: 60));
    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body['success'] == true) return Student.fromJson(body['data']);
    }
    throw Exception('فشل حذف الصورة');
  }

  static Future<StudentHistory> getStudentHistory(int studentId) async {
    final response = await http
        .get(Uri.parse('$_baseUrl/api/students/$studentId/attendance'),
            headers: _headers(json: false))
        .timeout(const Duration(seconds: 60));
    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body['success'] == true) return StudentHistory.fromJson(body['data']);
    }
    throw Exception('فشل جلب سجل التلميذ');
  }

  static Future<ClassStats> getClassStats(int classId) async {
    final response = await http
        .get(Uri.parse('$_baseUrl/api/classes/$classId/stats'),
            headers: _headers(json: false))
        .timeout(const Duration(seconds: 60));
    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body['success'] == true) return ClassStats.fromJson(body['data']);
    }
    throw Exception('فشل جلب الإحصائيات');
  }

  static Future<List<StudentFullReport>> getFullClassReport(int classId) async {
    final students = await getStudents(classId);
    final result = <StudentFullReport>[];

    for (final student in students) {
      try {
        final history = await getStudentHistory(student.id);
        double? average;
        try {
          final grades = await getStudentGrades(student.id);
          average = grades.count > 0 ? grades.average : null;
        } catch (_) {
          average = null;
        }
        result.add(StudentFullReport(
          student: student,
          attendanceTotal: history.total,
          attendancePresent: history.present,
          attendanceAbsent: history.absent,
          attendanceRate: history.rate,
          gradesAverage: average,
        ));
      } catch (_) {
        result.add(StudentFullReport(
          student: student,
          attendanceTotal: 0,
          attendancePresent: 0,
          attendanceAbsent: 0,
          attendanceRate: 0,
          gradesAverage: null,
        ));
      }
    }
    return result;
  }

  // ───────── الحضور ─────────
  static Future<int> saveAttendance({
    required int classId,
    required DateTime date,
    required String period,
    required Map<int, String> records,
  }) async {
    final dateStr = _formatDate(date);
    final recordsList = records.entries
        .map((e) => {'studentId': e.key, 'status': e.value})
        .toList();
    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/attendance'),
          headers: _headers(),
          body: jsonEncode({
            'classId': classId,
            'date': dateStr,
            'period': period,
            'records': recordsList,
          }),
        )
        .timeout(const Duration(seconds: 60));
    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body['success'] == true) return body['data']['saved'] as int;
    }
    throw Exception('فشل حفظ الحضور');
  }

  static Future<List<AttendanceEntry>> getAttendance({
    required int classId,
    required DateTime date,
    required String period,
  }) async {
    final dateStr = _formatDate(date);
    final response = await http
        .get(
            Uri.parse(
                '$_baseUrl/api/attendance?classId=$classId&date=$dateStr&period=$period'),
            headers: _headers(json: false))
        .timeout(const Duration(seconds: 60));
    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body['success'] == true) {
        return (body['data']['students'] as List)
            .map((e) => AttendanceEntry.fromJson(e))
            .toList();
      }
    }
    throw Exception('فشل جلب سجل الحضور');
  }

  // ───────── الدرجات ─────────
  static Future<int> saveGrades({
    required int classId,
    required String assessment,
    required double maxScore,
    required int coeff,
    required DateTime date,
    String? note,
    required Map<int, double> records,
  }) async {
    final dateStr = _formatDate(date);
    final recordsList =
        records.entries.map((e) => {'studentId': e.key, 'score': e.value}).toList();
    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/grades'),
          headers: _headers(),
          body: jsonEncode({
            'classId': classId,
            'assessment': assessment,
            'maxScore': maxScore,
            'coeff': coeff,
            'date': dateStr,
            'note': note,
            'records': recordsList,
          }),
        )
        .timeout(const Duration(seconds: 60));
    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body['success'] == true) return body['data']['saved'] as int;
    }
    throw Exception('فشل حفظ الدرجات');
  }

  static Future<List<GradeSession>> getClassGrades(int classId) async {
    final response = await http
        .get(Uri.parse('$_baseUrl/api/classes/$classId/grades'),
            headers: _headers(json: false))
        .timeout(const Duration(seconds: 60));
    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body['success'] == true) {
        return (body['data']['sessions'] as List)
            .map((e) => GradeSession.fromJson(e))
            .toList();
      }
    }
    throw Exception('فشل جلب الدرجات');
  }

  static Future<StudentGrades> getStudentGrades(int studentId) async {
    final response = await http
        .get(Uri.parse('$_baseUrl/api/students/$studentId/grades'),
            headers: _headers(json: false))
        .timeout(const Duration(seconds: 60));
    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body['success'] == true) return StudentGrades.fromJson(body['data']);
    }
    throw Exception('فشل جلب درجات التلميذ');
  }

  static Future<SessionGrades> getSessionGrades({
    required int classId,
    required String assessment,
    required DateTime date,
  }) async {
    final dateStr = _formatDate(date);
    final uri = Uri.parse(
      '$_baseUrl/api/grades/session'
      '?classId=$classId'
      '&assessment=${Uri.encodeComponent(assessment)}'
      '&date=$dateStr',
    );
    final response = await http
        .get(uri, headers: _headers(json: false))
        .timeout(const Duration(seconds: 60));
    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body['success'] == true) return SessionGrades.fromJson(body['data']);
    }
    throw Exception('فشل جلب درجات الجلسة');
  }

  // ───────── الملاحظات ─────────
  static Future<NoteItem> createNote({
    required int classId,
    int? studentId,
    required String type,
    required String title,
    required String content,
    required DateTime date,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/notes'),
          headers: _headers(),
          body: jsonEncode({
            'classId': classId,
            'studentId': studentId,
            'type': type,
            'title': title,
            'content': content,
            'date': _formatDate(date),
          }),
        )
        .timeout(const Duration(seconds: 60));
    if (response.statusCode == 201) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body['success'] == true) return NoteItem.fromJson(body['data']);
    }
    throw Exception('فشل إنشاء الملاحظة');
  }

  static Future<List<NoteItem>> getClassNotes(int classId) async {
    final response = await http
        .get(Uri.parse('$_baseUrl/api/classes/$classId/notes'),
            headers: _headers(json: false))
        .timeout(const Duration(seconds: 60));
    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body['success'] == true) {
        return (body['data']['notes'] as List)
            .map((e) => NoteItem.fromJson(e))
            .toList();
      }
    }
    throw Exception('فشل جلب الملاحظات');
  }

  static Future<StudentNotes> getStudentNotes(int studentId) async {
    final response = await http
        .get(Uri.parse('$_baseUrl/api/students/$studentId/notes'),
            headers: _headers(json: false))
        .timeout(const Duration(seconds: 60));
    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body['success'] == true) return StudentNotes.fromJson(body['data']);
    }
    throw Exception('فشل جلب ملاحظات التلميذ');
  }

  static Future<void> deleteNote(int noteId) async {
    final response = await http
        .delete(Uri.parse('$_baseUrl/api/notes/$noteId'),
            headers: _headers(json: false))
        .timeout(const Duration(seconds: 60));
    if (response.statusCode != 200) throw Exception('فشل حذف الملاحظة');
  }

  // ───────── الجدول ─────────
  static Future<List<ScheduleItem>> getSchedule() async {
    final response = await http
        .get(Uri.parse('$_baseUrl/api/schedule'),
            headers: _headers(json: false))
        .timeout(const Duration(seconds: 60));
    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body['success'] == true) {
        return (body['data'] as List)
            .map((e) => ScheduleItem.fromJson(e))
            .toList();
      }
    }
    throw Exception('فشل جلب الجدول');
  }

  static Future<List<ScheduleItem>> getScheduleDay(int dayOfWeek) async {
    final response = await http
        .get(Uri.parse('$_baseUrl/api/schedule/day/$dayOfWeek'),
            headers: _headers(json: false))
        .timeout(const Duration(seconds: 60));
    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body['success'] == true) {
        return (body['data'] as List)
            .map((e) => ScheduleItem.fromJson(e))
            .toList();
      }
    }
    throw Exception('فشل جلب جدول اليوم');
  }

  static Future<CurrentSchedule> getCurrentSchedule() async {
    final response = await http
        .get(Uri.parse('$_baseUrl/api/schedule/current'),
            headers: _headers(json: false))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body['success'] == true) {
        return CurrentSchedule.fromJson(body['data']);
      }
    }
    throw Exception('فشل جلب الحصة الحالية');
  }

  static Future<ScheduleItem> createSchedule({
    required int classId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    required String subject,
    String? room,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/schedule'),
          headers: _headers(),
          body: jsonEncode({
            'classId': classId,
            'dayOfWeek': dayOfWeek,
            'startTime': startTime,
            'endTime': endTime,
            'subject': subject,
            'room': room,
          }),
        )
        .timeout(const Duration(seconds: 60));
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 201 && body['success'] == true) {
      return ScheduleItem.fromJson(body['data']);
    }
    throw Exception(body['error']?['message'] ?? 'فشل إضافة الحصة');
  }

  static Future<void> deleteSchedule(int scheduleId) async {
    final response = await http
        .delete(Uri.parse('$_baseUrl/api/schedule/$scheduleId'),
            headers: _headers(json: false))
        .timeout(const Duration(seconds: 60));
    if (response.statusCode != 200) throw Exception('فشل حذف الحصة');
  }

  // ───────── مخطط الجلوس ─────────
  static Future<SeatingChart> getSeatingChart(int classId) async {
    final response = await http
        .get(Uri.parse('$_baseUrl/api/classes/$classId/seating'),
            headers: _headers(json: false))
        .timeout(const Duration(seconds: 60));
    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body['success'] == true) return SeatingChart.fromJson(body['data']);
    }
    throw Exception('فشل جلب مخطط الجلوس');
  }

  static Future<SeatingChart> saveSeatingChart({
    required int classId,
    required int rows,
    required int cols,
    required Map<String, List<int?>> seats,
    int? delegate1,
    int? delegate2,
    int? delegate3,
  }) async {
    final response = await http
        .put(
          Uri.parse('$_baseUrl/api/classes/$classId/seating'),
          headers: _headers(),
          body: jsonEncode({
            'rows': rows,
            'cols': cols,
            'seats': seats,
            'delegate1': delegate1,
            'delegate2': delegate2,
            'delegate3': delegate3,
          }),
        )
        .timeout(const Duration(seconds: 60));
    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body['success'] == true) return SeatingChart.fromJson(body['data']);
    }
    throw Exception('فشل حفظ المخطط');
  }

  static Future<void> deleteSeatingChart(int classId) async {
    final response = await http
        .delete(Uri.parse('$_baseUrl/api/classes/$classId/seating'),
            headers: _headers(json: false))
        .timeout(const Duration(seconds: 60));
    if (response.statusCode != 200) throw Exception('فشل حذف المخطط');
  }

  // ───────── أدوات ─────────
  static String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static String formatDateArabic(DateTime d) {
    const days = ['الاثنين','الثلاثاء','الأربعاء','الخميس','الجمعة','السبت','الأحد'];
    const months = ['جانفي','فيفري','مارس','أفريل','ماي','جوان','جويلية','أوت','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];
    return '${days[d.weekday - 1]}، ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  static String formatShortDate(String dateStr) {
    final d = DateTime.parse(dateStr);
    const months = ['جانفي','فيفري','مارس','أفريل','ماي','جوان','جويلية','أوت','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];
    return '${d.day} ${months[d.month - 1]}';
  }

  static String dayName(int dayOfWeek) {
    const days = ['الاثنين','الثلاثاء','الأربعاء','الخميس','الجمعة','السبت','الأحد'];
    return days[(dayOfWeek - 1).clamp(0, 6)];
  }

  static String periodName(String period) {
    return period == 'MORNING' ? 'صباحاً' : 'مساءً';
  }
}