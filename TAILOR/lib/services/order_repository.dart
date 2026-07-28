import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order_model.dart';
import 'api_service.dart';

/// Central repository for storing and synchronizing requests/orders
/// between the Customer app and Tailor dashboard.
class OrderRepository {
  static const String _storageKey = 'tailor_connect_orders_v1';

  static List<Map<String, dynamic>> _cachedOrders = [];
  static bool _initialized = false;

  /// Default initial orders — intentionally empty.
  /// Orders are loaded exclusively from the backend database.
  static final List<Map<String, dynamic>> _defaultOrders = [];

  /// Initialize and load saved orders from storage.
  static Future<void> init() async {
    if (_initialized) return;
    try {
      // Always start fresh — do not load from local cache.
      // Real orders come from the backend via AppProvider.loadInitialData().
      // Also clear any stale mock data that was persisted in previous versions.
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      _cachedOrders = [];
    } catch (_) {
      _cachedOrders = [];
    }
    _initialized = true;
  }

  /// Persist current cached orders to storage.
  static Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_cachedOrders));
    } catch (_) {}
  }

  /// Get all raw order maps.
  static Future<List<Map<String, dynamic>>> getAllOrdersRaw() async {
    await init();
    return List<Map<String, dynamic>>.from(_cachedOrders);
  }

  /// Get all OrderModels for the customer app.
  static Future<List<OrderModel>> getCustomerOrders() async {
    await init();
    return _cachedOrders.map((map) => _mapToOrderModel(map)).toList();
  }

  /// Get orders filtered for a specific tailor profile or shop name.
  static Future<List<Map<String, dynamic>>> getTailorOrdersRaw(int? profileId, String? shopName) async {
    await init();
    final tailorIdStr = profileId != null ? 't$profileId' : null;
    return _cachedOrders.where((o) {
      if (tailorIdStr != null && (o['tailor_id'] == tailorIdStr || o['tailor_id'] == profileId.toString())) {
        return true;
      }
      if (shopName != null && shopName.isNotEmpty && o['tailor_shop_name'].toString().toLowerCase().contains(shopName.toLowerCase())) {
        return true;
      }
      // If profile is default/1, return all orders that match tailor t1 or default
      return true;
    }).toList();
  }

  /// Save a new order request created by a customer and push to Flask API backend.
  static Future<OrderModel> addOrder({
    required String tailorId,
    required String tailorShopName,
    required String customerName,
    required String garmentType,
    required String fabricMaterial,
    required String customerNotes,
    required double chest,
    required double waist,
    required double hips,
    required double shoulders,
    required double inseam,
  }) async {
    await init();

    int numericTailorId = 1;
    final cleaned = tailorId.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isNotEmpty) {
      numericTailorId = int.tryParse(cleaned) ?? 1;
    }

    int dbOrderId = 0;
    try {
      dbOrderId = await ApiService.submitOrder(
        customerId: 1, // Default customer ID
        tailorId: numericTailorId,
        clothingType: garmentType,
        description: '$garmentType ($fabricMaterial)',
        notes: customerNotes,
      );
    } catch (_) {
      // Offline fallback
    }

    final orderId = dbOrderId > 0 ? dbOrderId.toString() : 'ord_${DateTime.now().millisecondsSinceEpoch}';
    final newOrderMap = <String, dynamic>{
      'order_id': orderId,
      'customer_id': '1',
      'customer_name': customerName.isNotEmpty ? customerName : 'Customer',
      'tailor_id': numericTailorId.toString(),
      'tailor_shop_name': tailorShopName.isNotEmpty ? tailorShopName : 'Silhouettes Couture',
      'garment_type': garmentType.isNotEmpty ? garmentType : 'Custom Garment',
      'clothing_type': garmentType.isNotEmpty ? garmentType : 'Custom Garment',
      'fabric_material': fabricMaterial.isNotEmpty ? fabricMaterial : 'Custom Fabric',
      'status': 'new',
      'progress_percent': 0,
      'status_updated_date': 'Just now',
      'estimated_completion_date': 'In 7 days',
      'customer_notes': customerNotes,
      'chest_measurement_inches': chest,
      'waist_measurement_inches': waist,
      'hips_measurement_inches': hips,
      'shoulders_measurement_inches': shoulders,
      'inseam_measurement_inches': inseam,
      'chest': chest,
      'waist': waist,
      'hip': hips,
      'shoulder': shoulders,
      'inseam': inseam,
      'inspiration_image_url': null,
      'order_created_date': 'Today',
      'chat_messages': [],
    };

    _cachedOrders.insert(0, newOrderMap);
    await _persist();

    return _mapToOrderModel(newOrderMap);
  }

  /// Update order status and progress from the Tailor Dashboard.
  static Future<void> updateOrderStatus(dynamic orderId, String newStatus, int progressPercent) async {
    await init();
    final idStr = orderId.toString();
    final index = _cachedOrders.indexWhere((o) => o['order_id'].toString() == idStr);

    if (index != -1) {
      _cachedOrders[index]['status'] = newStatus;
      _cachedOrders[index]['progress_percent'] = progressPercent;
      _cachedOrders[index]['status_updated_date'] = 'Just now';
      await _persist();
    }
  }

  /// Convert raw map into OrderModel safely.
  static OrderModel _mapToOrderModel(Map<String, dynamic> map) {
    String statusStr = map['status']?.toString() ?? 'submitted';
    if (statusStr == 'new') statusStr = 'submitted';
    if (statusStr == 'in_progress') statusStr = 'cutting';

    final statusEnum = orderStatusFromString(statusStr);

    return OrderModel(
      orderId: map['order_id']?.toString() ?? 'ord_0',
      tailorId: map['tailor_id']?.toString() ?? 't1',
      tailorShopName: map['tailor_shop_name']?.toString() ?? 'Tailor Shop',
      garmentType: map['garment_type']?.toString() ?? map['clothing_type']?.toString() ?? 'Custom Garment',
      status: statusEnum,
      statusUpdatedDate: map['status_updated_date']?.toString() ?? 'Recent',
      estimatedCompletionDate: map['estimated_completion_date']?.toString() ?? 'In 7 days',
      customerNotes: map['customer_notes']?.toString() ?? '',
      chestMeasurementInches: (map['chest_measurement_inches'] ?? map['chest'] as num?)?.toDouble() ?? 34.0,
      waistMeasurementInches: (map['waist_measurement_inches'] ?? map['waist'] as num?)?.toDouble() ?? 27.0,
      hipsMeasurementInches: (map['hips_measurement_inches'] ?? map['hip'] as num?)?.toDouble() ?? 37.0,
      shouldersMeasurementInches: (map['shoulders_measurement_inches'] ?? map['shoulder'] as num?)?.toDouble() ?? 14.5,
      inseamMeasurementInches: (map['inseam_measurement_inches'] ?? map['inseam'] as num?)?.toDouble() ?? 29.0,
      fabricMaterial: map['fabric_material']?.toString() ?? 'Custom Fabric',
      inspirationImageUrl: map['inspiration_image_url']?.toString(),
      chatMessages: (map['chat_messages'] as List?)
              ?.map((m) => ChatMessage.fromJson(Map<String, dynamic>.from(m as Map)))
              .toList() ??
          [],
      orderCreatedDate: map['order_created_date']?.toString() ?? 'Today',
    );
  }
}
