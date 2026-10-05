import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'auth_service.dart';
import 'cache_service.dart';

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
  final int classAverageRate;
  final List<AttendanceRecord> records;

  StudentHistory({
    required this.student,
    required this.total,
    required this.present,
    required this.absent,
    required this.rate,
    required this.classAverageRate,
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
      classAverageRate: (json['classAverageRate'] ?? 0) as int,
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
// مخطط الجلوس
// ═══════════════════════════════════════════
class SeatingChart {
  final int id;
  final int classId;
  final int rows;
  final int cols;
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
// الإحصائيات المتقدمة
// ═══════════════════════════════════════════
class AdvancedStats {
  final String className;
  final String classLevel;
  final String period;
  final int totalStudents;
  final OverviewData overview;
  final List<DailyTrendPoint> dailyTrend;
  final List<int> weekdayRates;
  final List<StudentRank> topStudents;
  final List<StudentRank> worstStudents;
  final int atRiskCount;
  final List<AtRiskStudent> atRiskStudents;
  final List<Insight> insights;

  AdvancedStats({
    required this.className,
    required this.classLevel,
    required this.period,
    required this.totalStudents,
    required this.overview,
    required this.dailyTrend,
    required this.weekdayRates,
    required this.topStudents,
    required this.worstStudents,
    required this.atRiskCount,
    required this.atRiskStudents,
    required this.insights,
  });

  factory AdvancedStats.fromJson(Map<String, dynamic> json) => AdvancedStats(
        className: json['className'] as String,
        classLevel: json['classLevel'] as String,
        period: json['period'] as String,
        totalStudents: json['totalStudents'] as int,
        overview: OverviewData.fromJson(json['overview']),
        dailyTrend: (json['dailyTrend'] as List)
            .map((e) => DailyTrendPoint.fromJson(e))
            .toList(),
        weekdayRates: (json['weekdayRates'] as List)
            .map((e) => (e as num).toInt())
            .toList(),
        topStudents: (json['topStudents'] as List)
            .map((e) => StudentRank.fromJson(e))
            .toList(),
        worstStudents: (json['worstStudents'] as List)
            .map((e) => StudentRank.fromJson(e))
            .toList(),
        atRiskCount: json['atRiskCount'] as int,
        atRiskStudents: (json['atRiskStudents'] as List)
            .map((e) => AtRiskStudent.fromJson(e))
            .toList(),
        insights: (json['insights'] as List)
            .map((e) => Insight.fromJson(e))
            .toList(),
      );
}

class OverviewData {
  final int total, present, absent, rate, trend, prevRate;
  OverviewData({
    required this.total,
    required this.present,
    required this.absent,
    required this.rate,
    required this.trend,
    required this.prevRate,
  });
  factory OverviewData.fromJson(Map<String, dynamic> json) => OverviewData(
        total: json['total'] as int,
        present: json['present'] as int,
        absent: json['absent'] as int,
        rate: json['rate'] as int,
        trend: json['trend'] as int,
        prevRate: json['prevRate'] as int,
      );
}

class DailyTrendPoint {
  final String date;
  final int present, absent, rate;
  DailyTrendPoint({
    required this.date,
    required this.present,
    required this.absent,
    required this.rate,
  });
  factory DailyTrendPoint.fromJson(Map<String, dynamic> json) =>
      DailyTrendPoint(
        date: json['date'] as String,
        present: json['present'] as int,
        absent: json['absent'] as int,
        rate: json['rate'] as int,
      );
}

class AtRiskStudent {
  final int id;
  final String fullName;
  final int rate;
  AtRiskStudent({
    required this.id,
    required this.fullName,
    required this.rate,
  });
  factory AtRiskStudent.fromJson(Map<String, dynamic> json) => AtRiskStudent(
        id: json['id'] as int,
        fullName: json['fullName'] as String,
        rate: json['rate'] as int,
      );
}

class Insight {
  final String type;
  final String icon;
  final String message;
  Insight({
    required this.type,
    required this.icon,
    required this.message,
  });
  factory Insight.fromJson(Map<String, dynamic> json) => Insight(
        type: json['type'] as String,
        icon: json['icon'] as String,
        message: json['message'] as String,
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
// الخدمة (مع Cache)
// ═══════════════════════════════════════════
class ApiService {
  static const String _baseUrl = AppConfig.apiBaseUrl;
  static const Duration _timeout = Duration(seconds: 12);

  static Map<String, String> _headers({bool json = true}) {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    final token = authService.token;
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// GET مع cache fallback
  static Future<dynamic> _getCached({
    required String url,
    required String cacheKey,
  }) async {
    try {
      final response = await http
          .get(Uri.parse(url), headers: _headers(json: false))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body['success'] == true) {
          await CacheService.save(cacheKey, body['data']);
          return body['data'];
        }
        throw Exception(body['error']?['message'] ?? 'فشل');
      }
      throw Exception('فشل (${response.statusCode})');
    } catch (e) {
      final cached = CacheService.load(cacheKey);
      if (cached != null) return cached;
      rethrow;
    }
  }

  /// POST/PUT/DELETE (لا cache fallback — عملية كتابة)
  static Future<dynamic> _write({
    required String method,
    required String url,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse(url);
    late http.Response response;
    final headers = _headers();
    final encoded = body != null ? jsonEncode(body) : null;

    switch (method) {
      case 'POST':
        response =
            await http.post(uri, headers: headers, body: encoded).timeout(_timeout);
        break;
      case 'PUT':
        response =
            await http.put(uri, headers: headers, body: encoded).timeout(_timeout);
        break;
      case 'DELETE':
        response = await http.delete(uri, headers: headers).timeout(_timeout);
        break;
      default:
        throw Exception('method غير مدعوم');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded['success'] == true) return decoded['data'];
    }
    throw Exception(decoded['error']?['message'] ?? 'فشل العملية');
  }

  // ───────── الأقسام ─────────
  static Future<List<SchoolClass>> getClasses() async {
    final data = await _getCached(
      url: '$_baseUrl/api/classes',
      cacheKey: 'classes',
    );
    return (data as List).map((e) => SchoolClass.fromJson(e)).toList();
  }

  static Future<SchoolClass> createClass({
    required String name,
    required String level,
  }) async {
    final data = await _write(
      method: 'POST',
      url: '$_baseUrl/api/classes',
      body: {'name': name, 'level': level},
    );
    await CacheService.save('classes', null); // invalidate
    return SchoolClass.fromJson({...data, '_count': {'students': 0}});
  }

  // ───────── التلاميذ ─────────
  static Future<List<Student>> getStudents(int classId) async {
    final data = await _getCached(
      url: '$_baseUrl/api/classes/$classId/students',
      cacheKey: 'students_$classId',
    );
    return (data as List).map((e) => Student.fromJson(e)).toList();
  }

  static Future<Student> createStudent({
    required int classId,
    required String fullName,
    String? guardianName,
    String? guardianPhone,
  }) async {
    final data = await _write(
      method: 'POST',
      url: '$_baseUrl/api/classes/$classId/students',
      body: {
        'fullName': fullName,
        'guardianName': guardianName,
        'guardianPhone': guardianPhone,
      },
    );
    await CacheService.save('students_$classId', null);
    return Student.fromJson(data);
  }

  static Future<Student> updateStudent({
    required int studentId,
    required String fullName,
    String? guardianName,
    String? guardianPhone,
  }) async {
    final data = await _write(
      method: 'PUT',
      url: '$_baseUrl/api/students/$studentId',
      body: {
        'fullName': fullName,
        'guardianName': guardianName,
        'guardianPhone': guardianPhone,
      },
    );
    return Student.fromJson(data);
  }

  static Future<void> deleteStudent(int studentId) async {
    await _write(
      method: 'DELETE',
      url: '$_baseUrl/api/students/$studentId',
    );
  }

  static Future<Student> updateStudentPhoto({
    required int studentId,
    required String photoBase64,
  }) async {
    final data = await _write(
      method: 'PUT',
      url: '$_baseUrl/api/students/$studentId/photo',
      body: {'photoUrl': photoBase64},
    );
    return Student.fromJson(data);
  }

  static Future<Student> deleteStudentPhoto(int studentId) async {
    final data = await _write(
      method: 'DELETE',
      url: '$_baseUrl/api/students/$studentId/photo',
    );
    return Student.fromJson(data);
  }

  static Future<StudentHistory> getStudentHistory(int studentId) async {
    final data = await _getCached(
      url: '$_baseUrl/api/students/$studentId/attendance',
      cacheKey: 'student_history_$studentId',
    );
    return StudentHistory.fromJson(data);
  }

  static Future<ClassStats> getClassStats(int classId) async {
    final data = await _getCached(
      url: '$_baseUrl/api/classes/$classId/stats',
      cacheKey: 'class_stats_$classId',
    );
    return ClassStats.fromJson(data);
  }

  static Future<AdvancedStats> getAdvancedStats({
    required int classId,
    required String period,
  }) async {
    final data = await _getCached(
      url: '$_baseUrl/api/classes/$classId/advanced-stats?period=$period',
      cacheKey: 'advanced_stats_${classId}_$period',
    );
    return AdvancedStats.fromJson(data);
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
    final data = await _write(
      method: 'POST',
      url: '$_baseUrl/api/attendance',
      body: {
        'classId': classId,
        'date': dateStr,
        'period': period,
        'records': recordsList,
      },
    );
    return data['saved'] as int;
  }

  static Future<List<AttendanceEntry>> getAttendance({
    required int classId,
    required DateTime date,
    required String period,
  }) async {
    final dateStr = _formatDate(date);
    final data = await _getCached(
      url:
          '$_baseUrl/api/attendance?classId=$classId&date=$dateStr&period=$period',
      cacheKey: 'attendance_${classId}_${dateStr}_$period',
    );
    return (data['students'] as List)
        .map((e) => AttendanceEntry.fromJson(e))
        .toList();
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
    final data = await _write(
      method: 'POST',
      url: '$_baseUrl/api/grades',
      body: {
        'classId': classId,
        'assessment': assessment,
        'maxScore': maxScore,
        'coeff': coeff,
        'date': dateStr,
        'note': note,
        'records': recordsList,
      },
    );
    return data['saved'] as int;
  }

  static Future<List<GradeSession>> getClassGrades(int classId) async {
    final data = await _getCached(
      url: '$_baseUrl/api/classes/$classId/grades',
      cacheKey: 'class_grades_$classId',
    );
    return (data['sessions'] as List)
        .map((e) => GradeSession.fromJson(e))
        .toList();
  }

  static Future<StudentGrades> getStudentGrades(int studentId) async {
    final data = await _getCached(
      url: '$_baseUrl/api/students/$studentId/grades',
      cacheKey: 'student_grades_$studentId',
    );
    return StudentGrades.fromJson(data);
  }

  static Future<SessionGrades> getSessionGrades({
    required int classId,
    required String assessment,
    required DateTime date,
  }) async {
    final dateStr = _formatDate(date);
    final data = await _getCached(
      url:
          '$_baseUrl/api/grades/session?classId=$classId&assessment=${Uri.encodeComponent(assessment)}&date=$dateStr',
      cacheKey: 'session_${classId}_${assessment}_$dateStr',
    );
    return SessionGrades.fromJson(data);
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
    final data = await _write(
      method: 'POST',
      url: '$_baseUrl/api/notes',
      body: {
        'classId': classId,
        'studentId': studentId,
        'type': type,
        'title': title,
        'content': content,
        'date': _formatDate(date),
      },
    );
    return NoteItem.fromJson(data);
  }

  static Future<List<NoteItem>> getClassNotes(int classId) async {
    final data = await _getCached(
      url: '$_baseUrl/api/classes/$classId/notes',
      cacheKey: 'class_notes_$classId',
    );
    return (data['notes'] as List).map((e) => NoteItem.fromJson(e)).toList();
  }

  static Future<StudentNotes> getStudentNotes(int studentId) async {
    final data = await _getCached(
      url: '$_baseUrl/api/students/$studentId/notes',
      cacheKey: 'student_notes_$studentId',
    );
    return StudentNotes.fromJson(data);
  }

  static Future<void> deleteNote(int noteId) async {
    await _write(
      method: 'DELETE',
      url: '$_baseUrl/api/notes/$noteId',
    );
  }

  // ───────── الجدول ─────────
  static Future<List<ScheduleItem>> getSchedule() async {
    final data = await _getCached(
      url: '$_baseUrl/api/schedule',
      cacheKey: 'schedule',
    );
    return (data as List).map((e) => ScheduleItem.fromJson(e)).toList();
  }

  static Future<List<ScheduleItem>> getScheduleDay(int dayOfWeek) async {
    final data = await _getCached(
      url: '$_baseUrl/api/schedule/day/$dayOfWeek',
      cacheKey: 'schedule_day_$dayOfWeek',
    );
    return (data as List).map((e) => ScheduleItem.fromJson(e)).toList();
  }

  static Future<CurrentSchedule> getCurrentSchedule() async {
    final data = await _getCached(
      url: '$_baseUrl/api/schedule/current',
      cacheKey: 'schedule_current',
    );
    return CurrentSchedule.fromJson(data);
  }

  static Future<ScheduleItem> createSchedule({
    required int classId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    required String subject,
    String? room,
  }) async {
    final data = await _write(
      method: 'POST',
      url: '$_baseUrl/api/schedule',
      body: {
        'classId': classId,
        'dayOfWeek': dayOfWeek,
        'startTime': startTime,
        'endTime': endTime,
        'subject': subject,
        'room': room,
      },
    );
    await CacheService.save('schedule', null);
    return ScheduleItem.fromJson(data);
  }

  static Future<void> deleteSchedule(int scheduleId) async {
    await _write(
      method: 'DELETE',
      url: '$_baseUrl/api/schedule/$scheduleId',
    );
    await CacheService.save('schedule', null);
  }

  // ───────── مخطط الجلوس ─────────
  static Future<SeatingChart> getSeatingChart(int classId) async {
    final data = await _getCached(
      url: '$_baseUrl/api/classes/$classId/seating',
      cacheKey: 'seating_$classId',
    );
    return SeatingChart.fromJson(data);
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
    final data = await _write(
      method: 'PUT',
      url: '$_baseUrl/api/classes/$classId/seating',
      body: {
        'rows': rows,
        'cols': cols,
        'seats': seats,
        'delegate1': delegate1,
        'delegate2': delegate2,
        'delegate3': delegate3,
      },
    );
    return SeatingChart.fromJson(data);
  }

  static Future<void> deleteSeatingChart(int classId) async {
    await _write(
      method: 'DELETE',
      url: '$_baseUrl/api/classes/$classId/seating',
    );
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