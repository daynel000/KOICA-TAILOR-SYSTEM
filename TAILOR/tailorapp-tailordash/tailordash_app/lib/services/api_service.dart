import 'dart:convert';
import 'package:http/http.dart' as http;
import '../session.dart';

class ApiService {
  // Base URL of the Flask backend running on your PC
  // Using 127.0.0.1 works for Chrome (web). For Android emulator use 10.0.2.2:5000
  static const String baseUrl = 'http://127.0.0.1:5000/api';

  int get _tailorId {
    if (!AppSession.isLoggedIn()) throw Exception('Not logged in');
    return AppSession.currentProfileId!; // Assuming profile_id is what we need for tailor_id
  }
  
  int get _userId {
    if (!AppSession.isLoggedIn()) throw Exception('Not logged in');
    return AppSession.currentTailorId!; // The user_id
  }

  // ─── AUTH ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    ).timeout(const Duration(seconds: 10));

    final body = json.decode(response.body);
    if (response.statusCode == 200 && body['status'] == 'success') {
      return body['data'];
    }
    throw Exception(body['message'] ?? 'Failed to login');
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    ).timeout(const Duration(seconds: 10));

    final body = json.decode(response.body);
    if (response.statusCode == 200 && body['status'] == 'success') {
      return body['data'];
    }
    throw Exception(body['message'] ?? 'Failed to register');
  }

  // ─── DASHBOARD ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> fetchDashboardData() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/dashboard/$_tailorId'))
          .timeout(const Duration(seconds: 10));


      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        if (body['status'] == 'success') {
          return body['data'];
        }
      }
      throw Exception('Server returned status ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to load dashboard: $e');
    }
  }

  // ─── ORDERS ───────────────────────────────────────────────────────────────

  Future<List<dynamic>> fetchOrders() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/orders/$_tailorId'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        if (body['status'] == 'success') {
          return body['data'];
        }
      }
      throw Exception('Server returned status ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to load orders: $e');
    }
  }

  Future<void> updateOrderStatus(
      int orderId, String status, int progress) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/orders/$orderId/status'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'status': status,
              'progress_percent': progress,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Server returned status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update order: $e');
    }
  }

  // ─── PROFILE ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> fetchProfile() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/profile/$_tailorId'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        if (body['status'] == 'success') {
          return body['data'];
        }
      }
      throw Exception('Server returned status ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to load profile: $e');
    }
  }

  // ─── MAP ──────────────────────────────────────────────────────────────────

  Future<List<dynamic>> fetchNearbyTailors() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/map/tailors'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        if (body['status'] == 'success') {
          return body['data'];
        }
      }
      throw Exception('Server returned status ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to load nearby tailors: $e');
    }
  }

  // ─── CHAT ─────────────────────────────────────────────────────────────────

  Future<List<dynamic>> fetchChatMessages(int orderId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/chat/$orderId'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        if (body['status'] == 'success') {
          return body['data'];
        }
      }
      throw Exception('Server returned status ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to load messages: $e');
    }
  }

  Future<void> sendMessage(int orderId, int senderId, String text) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/chat/$orderId'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'sender_id': senderId,
              'message_text': text,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Server returned status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // ─── ADDITIONS ────────────────────────────────────────────────────────────

  Future<void> createOrder(Map<String, dynamic> data) async {
    data['tailor_id'] = _tailorId; // Inject current tailor ID
    final response = await http.post(
      Uri.parse('$baseUrl/orders/create'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    ).timeout(const Duration(seconds: 10));

    final body = json.decode(response.body);
    if (response.statusCode != 200 || body['status'] != 'success') {
      throw Exception(body['message'] ?? 'Failed to create order');
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/profile/$_tailorId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    ).timeout(const Duration(seconds: 10));

    final body = json.decode(response.body);
    if (response.statusCode != 200 || body['status'] != 'success') {
      throw Exception(body['message'] ?? 'Failed to update profile');
    }
  }
}
