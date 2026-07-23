// ============================================================
// api/api_config.dart
//
// Central configuration for the Python backend connection.
//
// IMPORTANT FOR BOTH DASHBOARDS:
//   Both the Customer app (this project) and the Tailor dashboard
//   (other laptop) must point to the SAME Python server IP/domain.
//
// SETUP INSTRUCTIONS:
//   1. Find the IP address of the machine running the Python server
//      (run `ipconfig` on Windows or `ifconfig` on Mac/Linux)
//   2. Replace the baseUrl below with that IP address
//   3. Make sure both phones are on the same WiFi network
//      (or use ngrok for remote access during development)
// ============================================================

class ApiConfig {
  /// Base URL of the Python FastAPI backend server.
  /// Example local dev: 'http://192.168.1.100:8000'
  /// Example production: 'https://api.tailorconnect.ph'
  static const String baseUrl = 'http://192.168.1.100:8000';

  /// API version prefix (update if backend changes versions)
  static const String apiVersion = '/api/v1';

  /// Full API base path
  static String get apiBaseUrl => '$baseUrl$apiVersion';

  /// Default headers for JSON requests (no auth)
  static Map<String, String> get jsonHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// Headers for authenticated requests (includes Bearer token)
  static Map<String, String> authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// Request timeout duration
  static const Duration requestTimeout = Duration(milliseconds: 500);
}
