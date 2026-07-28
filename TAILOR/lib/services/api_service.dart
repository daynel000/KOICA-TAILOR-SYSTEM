import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Flask backend URL
  static const String baseUrl = 'http://192.168.254.48:5000/api';

  // ─── Login ───────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': username, 'password': password}),
        )
        .timeout(const Duration(seconds: 10));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || body['status'] != 'success') {
      throw Exception(body['message'] ?? 'Login failed.');
    }
    return body['data'];
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
          Uri.parse('$baseUrl/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'full_name': fullName,
            'shop_name': shopName ?? '',
            'email': email,
            'phone_number': phone,
            'password': password,
            'address': '',
            'is_tailor': role == 'tailor',
          }),
        )
        .timeout(const Duration(seconds: 10));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || body['status'] != 'success') {
      throw Exception(body['message'] ?? 'Registration failed.');
    }
    return body['data'];
  }

  // ─── Tailors Discovery ───────────────────────────────────────────────────
  static Future<List<dynamic>> fetchTailors() async {
    final response = await http
        .get(Uri.parse('$baseUrl/map/tailors'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['status'] == 'success') return body['data'];
    }
    return [];
  }

  // ─── Customer Orders ──────────────────────────────────────────────────────
  static Future<List<dynamic>> fetchCustomerOrders(int customerId) async {
    final response = await http
        .get(Uri.parse('$baseUrl/orders/customer/$customerId'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['status'] == 'success') return body['data'];
    }
    return [];
  }

  static Future<int> submitOrder({
    required int customerId,
    required int tailorId,
    required String clothingType,
    String? description,
    String? notes,
    String? dueDate,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/orders/customer_submit'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'customer_id': customerId,
            'tailor_id': tailorId,
            'clothing_type': clothingType,
            'description': description ?? '',
            'notes': notes ?? '',
            'due_date': dueDate,
          }),
        )
        .timeout(const Duration(seconds: 10));

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && body['status'] == 'success') {
      return body['order_id'];
    }
    throw Exception(body['message'] ?? 'Failed to submit order');
  }

  // ─── Chat Messages ────────────────────────────────────────────────────────
  static Future<List<dynamic>> fetchChatMessages(int orderId) async {
    final response = await http
        .get(Uri.parse('$baseUrl/chat/$orderId'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['status'] == 'success') return body['data'];
    }
    return [];
  }

  static Future<void> sendMessage({
    required int orderId,
    required int senderId,
    required String messageText,
  }) async {
    await http
        .post(
          Uri.parse('$baseUrl/chat/$orderId'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'sender_id': senderId,
            'message_text': messageText,
          }),
        )
        .timeout(const Duration(seconds: 10));
  }
}
