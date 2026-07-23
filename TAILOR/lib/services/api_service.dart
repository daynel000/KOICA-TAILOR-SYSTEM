import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // XAMPP PHP backend running on localhost
  static const String baseUrl = 'http://localhost/tailor_connect';

  // ─── Login ───────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/login.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': username, 'password': password}),
        )
        .timeout(const Duration(milliseconds: 1500));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Login failed.');
    }
    return body;
  }

  // ─── Register ─────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> register({
    required String fullName,
    String? shopName,
    required String username,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    required String role, // 'customer' or 'tailor'
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/register.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'full_name':        fullName,
            'shop_name':        shopName,
            'username':         username,
            'email':            email,
            'phone':            phone,
            'password':         password,
            'confirm_password': confirmPassword,
            'role':             role,
          }),
        )
        .timeout(const Duration(seconds: 10));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 201 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Registration failed.');
    }
    return body;
  }
}
