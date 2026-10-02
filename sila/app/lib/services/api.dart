import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

// نموذج القسم
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

// خدمة الاتصال بالخادم
class ApiService {
  static const String _baseUrl = AppConfig.apiBaseUrl;

  // جلب كل الأقسام
  static Future<List<SchoolClass>> getClasses() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/classes'),
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body['success'] == true) {
        final List<dynamic> data = body['data'];
        return data.map((e) => SchoolClass.fromJson(e)).toList();
      }
    }
    throw Exception('فشل جلب الأقسام');
  }

  // إنشاء قسم جديد
  static Future<SchoolClass> createClass({
    required String name,
    required String level,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/classes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'level': level}),
    ).timeout(const Duration(seconds: 60));

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
}
