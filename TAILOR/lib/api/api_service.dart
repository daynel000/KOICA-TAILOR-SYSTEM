// ============================================================
// api/api_service.dart
//
// Central API service for all communication with the Python/FastAPI backend.
// All mock data has been removed. Every method makes a real HTTP call.
//
// SETUP:
//   Set the correct server IP/URL in api/api_config.dart before running.
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import '../models/tailor_model.dart';
import '../models/order_model.dart';
import '../models/scan_result_model.dart';
import '../models/customer_model.dart';

class ApiService {
  final http.Client _httpClient;

  ApiService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  // ----------------------------------------------------------
  // AUTH ENDPOINTS
  // ----------------------------------------------------------

  /// Logs in a customer. Returns customer data + auth token on success.
  /// POST /api/v1/auth/login
  Future<Map<String, dynamic>> loginCustomer({
    required String emailAddress,
    required String password,
  }) async {
    final response = await _httpClient
        .post(
          Uri.parse('${ApiConfig.apiBaseUrl}/auth/login'),
          headers: ApiConfig.jsonHeaders,
          body: jsonEncode({
            'email_address': emailAddress,
            'password': password,
          }),
        )
        .timeout(ApiConfig.requestTimeout);
    return _handleJsonResponse(response) as Map<String, dynamic>;
  }

  /// Registers a new customer account.
  /// POST /api/v1/auth/register
  Future<Map<String, dynamic>> registerCustomer({
    required String fullName,
    required String emailAddress,
    required String password,
    required String phoneNumber,
    required String cityLocation,
  }) async {
    final response = await _httpClient
        .post(
          Uri.parse('${ApiConfig.apiBaseUrl}/auth/register'),
          headers: ApiConfig.jsonHeaders,
          body: jsonEncode({
            'full_name': fullName,
            'email_address': emailAddress,
            'password': password,
            'phone_number': phoneNumber,
            'city_location': cityLocation,
          }),
        )
        .timeout(ApiConfig.requestTimeout);
    return _handleJsonResponse(response) as Map<String, dynamic>;
  }

  /// Fetches the profile of the currently logged-in customer.
  /// GET /api/v1/customer/me
  Future<CustomerModel> getCustomerProfile(String authToken) async {
    final response = await _httpClient
        .get(
          Uri.parse('${ApiConfig.apiBaseUrl}/customer/me'),
          headers: ApiConfig.authHeaders(authToken),
        )
        .timeout(ApiConfig.requestTimeout);
    return CustomerModel.fromJson(
      _handleJsonResponse(response) as Map<String, dynamic>,
    );
  }

  // ----------------------------------------------------------
  // TAILOR ENDPOINTS
  // ----------------------------------------------------------

  /// Fetches all available tailor shops.
  /// GET /api/v1/tailors
  Future<List<TailorModel>> getAllTailors() async {
    final response = await _httpClient
        .get(
          Uri.parse('${ApiConfig.apiBaseUrl}/tailors'),
          headers: ApiConfig.jsonHeaders,
        )
        .timeout(ApiConfig.requestTimeout);
    final List<dynamic> data =
        _handleJsonResponse(response) as List<dynamic>;
    return data.map((json) => TailorModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Fetches a single tailor by ID.
  /// GET /api/v1/tailors/{tailor_id}
  Future<TailorModel> getTailorById(String tailorId) async {
    final response = await _httpClient
        .get(
          Uri.parse('${ApiConfig.apiBaseUrl}/tailors/$tailorId'),
          headers: ApiConfig.jsonHeaders,
        )
        .timeout(ApiConfig.requestTimeout);
    return TailorModel.fromJson(
      _handleJsonResponse(response) as Map<String, dynamic>,
    );
  }

  // ----------------------------------------------------------
  // ORDER ENDPOINTS
  // ----------------------------------------------------------

  /// Fetches all orders for the logged-in customer.
  /// GET /api/v1/orders
  Future<List<OrderModel>> getCustomerOrders(String authToken) async {
    final response = await _httpClient
        .get(
          Uri.parse('${ApiConfig.apiBaseUrl}/orders'),
          headers: ApiConfig.authHeaders(authToken),
        )
        .timeout(ApiConfig.requestTimeout);
    final List<dynamic> data =
        _handleJsonResponse(response) as List<dynamic>;
    return data.map((json) => OrderModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Submits a new tailoring order.
  /// POST /api/v1/orders
  Future<OrderModel> createOrder({
    required String authToken,
    required Map<String, dynamic> orderData,
  }) async {
    final response = await _httpClient
        .post(
          Uri.parse('${ApiConfig.apiBaseUrl}/orders'),
          headers: ApiConfig.authHeaders(authToken),
          body: jsonEncode(orderData),
        )
        .timeout(ApiConfig.requestTimeout);
    return OrderModel.fromJson(
      _handleJsonResponse(response) as Map<String, dynamic>,
    );
  }

  /// Sends a chat message in an order thread.
  /// POST /api/v1/orders/{order_id}/messages
  Future<ChatMessage> sendChatMessage({
    required String authToken,
    required String orderId,
    required String messageText,
  }) async {
    final response = await _httpClient
        .post(
          Uri.parse('${ApiConfig.apiBaseUrl}/orders/$orderId/messages'),
          headers: ApiConfig.authHeaders(authToken),
          body: jsonEncode({'message_text': messageText}),
        )
        .timeout(ApiConfig.requestTimeout);
    return ChatMessage.fromJson(
      _handleJsonResponse(response) as Map<String, dynamic>,
    );
  }

  // ----------------------------------------------------------
  // AI SCAN ENDPOINT
  // ----------------------------------------------------------

  /// Sends an image to the Python backend for AI body measurement scanning.
  /// POST /api/v1/scan
  Future<ScanResultModel> runAIBodyScan({
    required String imageUrl,
    required String gender,
    required int heightCm,
  }) async {
    final response = await _httpClient
        .post(
          Uri.parse('${ApiConfig.apiBaseUrl}/scan'),
          headers: ApiConfig.jsonHeaders,
          body: jsonEncode({
            'image_url': imageUrl,
            'image': imageUrl, // Send base64 data to 'image' field for Express server compatibility
            'gender': gender,
            'height_cm': heightCm,
            'height': heightCm, // Send height value to 'height' field for Express server compatibility
          }),
        )
        .timeout(ApiConfig.requestTimeout);
    return ScanResultModel.fromJson(
      _handleJsonResponse(response) as Map<String, dynamic>,
    );
  }

  // ----------------------------------------------------------
  // PRIVATE HELPERS
  // ----------------------------------------------------------

  dynamic _handleJsonResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'API Error: ${response.statusCode} — ${response.body}',
      );
    }
  }
}

/// Custom exception for API errors.
class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
