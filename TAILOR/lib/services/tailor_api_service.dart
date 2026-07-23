import 'dart:convert';
import 'package:http/http.dart' as http;
import '../session/tailor_session.dart';

/// API service for the Tailor Dashboard — connects to the Flask backend.
class TailorApiService {
  /// Base URL of the Flask backend.
  /// Use http://127.0.0.1:5000/api for web/Chrome.
  /// Use http://10.0.2.2:5000/api for Android emulator.
  static const String baseUrl = 'http://127.0.0.1:5000/api';

  int get _tailorId {
    if (!TailorSession.isLoggedIn()) throw Exception('Not logged in as tailor');
    return TailorSession.currentProfileId!;
  }

  // ─── AUTH ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
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
    final response = await http
        .get(Uri.parse('$baseUrl/dashboard/$_tailorId'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final body = json.decode(response.body) as Map<String, dynamic>;
      if (body['status'] == 'success') return body['data'];
    }
    throw Exception('Failed to load dashboard (status ${response.statusCode})');
  }

  // ─── ORDERS ───────────────────────────────────────────────────────────────

  Future<List<dynamic>> fetchOrders() async {
    final response = await http
        .get(Uri.parse('$baseUrl/orders/$_tailorId'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final body = json.decode(response.body) as Map<String, dynamic>;
      if (body['status'] == 'success') return body['data'];
    }
    throw Exception('Failed to load orders (status ${response.statusCode})');
  }

  Future<void> updateOrderStatus(int orderId, String status, int progress) async {
    final response = await http.put(
      Uri.parse('$baseUrl/orders/$orderId/status'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'status': status, 'progress_percent': progress}),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Failed to update order (status ${response.statusCode})');
    }
  }

  Future<void> createOrder(Map<String, dynamic> data) async {
    data['tailor_id'] = _tailorId;
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

  // ─── PROFILE ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> fetchProfile() async {
    final response = await http
        .get(Uri.parse('$baseUrl/profile/$_tailorId'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final body = json.decode(response.body) as Map<String, dynamic>;
      if (body['status'] == 'success') return body['data'];
    }
    throw Exception('Failed to load profile (status ${response.statusCode})');
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

  // ─── CHAT ─────────────────────────────────────────────────────────────────

  Future<List<dynamic>> fetchChatMessages(int orderId) async {
    final response = await http
        .get(Uri.parse('$baseUrl/chat/$orderId'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final body = json.decode(response.body) as Map<String, dynamic>;
      if (body['status'] == 'success') return body['data'];
    }
    throw Exception('Failed to load messages (status ${response.statusCode})');
  }

  Future<void> sendMessage(int orderId, int senderId, String text) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat/$orderId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'sender_id': senderId, 'message_text': text}),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to send message (status ${response.statusCode})');
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
      return [];
    } catch (_) {
      return [];
    }
  }
}

