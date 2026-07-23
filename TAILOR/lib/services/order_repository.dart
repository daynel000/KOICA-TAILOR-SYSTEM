import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order_model.dart';

/// Central repository for storing and synchronizing requests/orders
/// between the Customer app and Tailor dashboard.
class OrderRepository {
  static const String _storageKey = 'tailor_connect_orders_v1';

  static List<Map<String, dynamic>> _cachedOrders = [];
  static bool _initialized = false;

  /// Default initial orders for demo and offline persistence.
  static final List<Map<String, dynamic>> _defaultOrders = [
    {
      'order_id': 'ord_101',
      'customer_id': 'c1',
      'customer_name': 'Sarah Jenkins',
      'tailor_id': 't1',
      'tailor_shop_name': 'Silhouettes Couture',
      'garment_type': 'Custom Silk Dress',
      'clothing_type': 'Custom Silk Dress',
      'fabric_material': 'French Silk',
      'status': 'in_progress',
      'progress_percent': 65,
      'status_updated_date': 'Today',
      'estimated_completion_date': 'In 3 days',
      'customer_notes': 'A-line cut with back zipper, floor length.',
      'chest_measurement_inches': 36.5,
      'waist_measurement_inches': 28.0,
      'hips_measurement_inches': 38.0,
      'shoulders_measurement_inches': 15.0,
      'inseam_measurement_inches': 30.0,
      'chest': 36.5,
      'waist': 28.0,
      'hip': 38.0,
      'shoulder': 15.0,
      'inseam': 30.0,
      'inspiration_image_url': 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=500',
      'order_created_date': '3 days ago',
      'chat_messages': [],
    },
    {
      'order_id': 'ord_102',
      'customer_id': 'c2',
      'customer_name': 'Michael Tan',
      'tailor_id': 't1',
      'tailor_shop_name': 'Silhouettes Couture',
      'garment_type': '3-Piece Tuxedo Fit',
      'clothing_type': '3-Piece Tuxedo Fit',
      'fabric_material': 'Wool Blend',
      'status': 'new',
      'progress_percent': 20,
      'status_updated_date': 'Yesterday',
      'estimated_completion_date': 'In 7 days',
      'customer_notes': 'Satin lapels with double vent.',
      'chest_measurement_inches': 40.0,
      'waist_measurement_inches': 34.0,
      'hips_measurement_inches': 41.0,
      'shoulders_measurement_inches': 18.5,
      'inseam_measurement_inches': 32.0,
      'chest': 40.0,
      'waist': 34.0,
      'hip': 41.0,
      'shoulder': 18.5,
      'inseam': 32.0,
      'inspiration_image_url': 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=500',
      'order_created_date': 'Yesterday',
      'chat_messages': [],
    },
    {
      'order_id': 'ord_103',
      'customer_id': 'c3',
      'customer_name': 'Maria Santos',
      'tailor_id': 't2',
      'tailor_shop_name': 'Master Cutters PH',
      'garment_type': 'Evening Gown Alteration',
      'clothing_type': 'Evening Gown Alteration',
      'fabric_material': 'Premium Satin',
      'status': 'completed',
      'progress_percent': 100,
      'status_updated_date': '2 days ago',
      'estimated_completion_date': 'Completed',
      'customer_notes': 'Take in 1 inch at waist.',
      'chest_measurement_inches': 34.0,
      'waist_measurement_inches': 26.5,
      'hips_measurement_inches': 36.0,
      'shoulders_measurement_inches': 14.5,
      'inseam_measurement_inches': 29.0,
      'chest': 34.0,
      'waist': 26.5,
      'hip': 36.0,
      'shoulder': 14.5,
      'inseam': 29.0,
      'inspiration_image_url': 'https://images.unsplash.com/photo-1566174053879-31528523f8ae?w=500',
      'order_created_date': '1 week ago',
      'chat_messages': [],
    },
  ];

  /// Initialize and load saved orders from storage.
  static Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        _cachedOrders = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else {
        _cachedOrders = List<Map<String, dynamic>>.from(_defaultOrders);
        await _persist();
      }
    } catch (_) {
      _cachedOrders = List<Map<String, dynamic>>.from(_defaultOrders);
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

  /// Save a new order request created by a customer.
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

    final orderId = 'ord_${DateTime.now().millisecondsSinceEpoch}';
    final newOrderMap = <String, dynamic>{
      'order_id': orderId,
      'customer_id': 'c_current',
      'customer_name': customerName.isNotEmpty ? customerName : 'Customer',
      'tailor_id': tailorId.isNotEmpty ? tailorId : 't1',
      'tailor_shop_name': tailorShopName.isNotEmpty ? tailorShopName : 'Silhouettes Couture',
      'garment_type': garmentType.isNotEmpty ? garmentType : 'Custom Garment',
      'clothing_type': garmentType.isNotEmpty ? garmentType : 'Custom Garment',
      'fabric_material': fabricMaterial.isNotEmpty ? fabricMaterial : 'Custom Fabric',
      'status': 'submitted',
      'progress_percent': 20,
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
