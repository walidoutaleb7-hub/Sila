import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

// ═══════════════════════════════════════════
// نموذج المستخدم
// ═══════════════════════════════════════════
class AppUser {
  final String id;
  final String email;
  final String fullName;
  final String? schoolName;

  AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.schoolName,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['fullName'] as String,
        schoolName: json['schoolName'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'schoolName': schoolName,
      };
}

// ═══════════════════════════════════════════
// خدمة المصادقة
// ═══════════════════════════════════════════
class AuthService extends ChangeNotifier {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  String? _token;
  AppUser? _user;
  bool _initialized = false;

  String? get token => _token;
  AppUser? get user => _user;
  bool get isLoggedIn => _token != null && _user != null;
  bool get initialized => _initialized;

  /// يُستدعى في main()
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_tokenKey);
      final userJson = prefs.getString(_userKey);
      if (_token != null && userJson != null) {
        _user = AppUser.fromJson(jsonDecode(userJson));
      }
    } catch (_) {
      _token = null;
      _user = null;
    }
    _initialized = true;
    notifyListeners();
  }

  // ═══════════════════════════════════════════
  // إنشاء حساب
  // ═══════════════════════════════════════════
  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    String? schoolName,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'password': password,
        'fullName': fullName.trim(),
        'schoolName': (schoolName ?? '').trim().isEmpty ? null : schoolName!.trim(),
      }),
    ).timeout(const Duration(seconds: 60));

    final body = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 201 && body['success'] == true) {
      await _saveAuth(body['data']['token'], body['data']['user']);
      return;
    }

    throw Exception(
      body['error']?['message'] ?? 'فشل إنشاء الحساب',
    );
  }

  // ═══════════════════════════════════════════
  // تسجيل دخول
  // ═══════════════════════════════════════════
  Future<void> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'password': password,
      }),
    ).timeout(const Duration(seconds: 60));

    final body = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200 && body['success'] == true) {
      await _saveAuth(body['data']['token'], body['data']['user']);
      return;
    }

    throw Exception(
      body['error']?['message'] ?? 'البريد أو كلمة المرور غير صحيحة',
    );
  }

  // ═══════════════════════════════════════════
  // تسجيل خروج
  // ═══════════════════════════════════════════
  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    notifyListeners();
  }

  // ═══════════════════════════════════════════
  // تحديث المعلومات
  // ═══════════════════════════════════════════
  Future<void> updateProfile({
    String? fullName,
    String? schoolName,
  }) async {
    if (_token == null) return;

    final response = await http
        .put(
          Uri.parse('${AppConfig.apiBaseUrl}/api/auth/me'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
          },
          body: jsonEncode({
            if (fullName != null) 'fullName': fullName.trim(),
            if (schoolName != null)
              'schoolName': schoolName.trim().isEmpty ? null : schoolName.trim(),
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body['success'] == true) {
        _user = AppUser.fromJson(body['data']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, jsonEncode(body['data']));
        notifyListeners();
      }
    }
  }

  /// جلب معلوماتي من الخادم (للتحديث)
  Future<void> refreshMe() async {
    if (_token == null) return;
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/api/auth/me'),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body['success'] == true) {
          _user = AppUser.fromJson(body['data']);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_userKey, jsonEncode(body['data']));
          notifyListeners();
        }
      } else if (response.statusCode == 401) {
        await logout();
      }
    } catch (_) {}
  }

  // ═══════════════════════════════════════════
  // داخلي
  // ═══════════════════════════════════════════
  Future<void> _saveAuth(String token, Map<String, dynamic> userJson) async {
    _token = token;
    _user = AppUser.fromJson(userJson);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(userJson));
    notifyListeners();
  }
}

// نسخة عالمية واحدة
final authService = AuthService();