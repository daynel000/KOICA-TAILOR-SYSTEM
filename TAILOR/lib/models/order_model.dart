// ============================================================
// models/order_model.dart
//
// Represents a Customer tailoring order/request.
//
// SHARED WITH TAILOR DASHBOARD:
//   The Tailor dashboard receives these same order fields when a
//   customer submits a new request via the Python backend.
//   Status updates from the Tailor dashboard update the same record
//   which this Customer app then reads to show progress.
//
// BACKEND API ENDPOINTS (Python):
//   GET  /api/orders                     → returns List<OrderModel> for logged-in customer
//   POST /api/orders                     → creates a new order, returns OrderModel
//   GET  /api/orders/{order_id}          → returns a single OrderModel
//   POST /api/orders/{order_id}/messages → sends a chat message, returns ChatMessage
// ============================================================

/// All possible statuses an order can have.
/// Both Customer and Tailor dashboards use these exact same string values.
enum OrderStatus {
  submitted,  // Customer created the order, waiting for tailor to accept
  accepted,   // Tailor accepted the order and confirmed measurements
  cutting,    // Tailor is currently cutting the fabric
  fitting,    // Garment is ready for intermediate fitting/try-on
  completed,  // Garment is finished and ready for pickup
}

/// Maps the backend string value to the OrderStatus enum.
OrderStatus orderStatusFromString(String value) {
  return OrderStatus.values.firstWhere(
    (e) => e.name == value,
    orElse: () => OrderStatus.submitted,
  );
}

class OrderModel {
  final String orderId;           // Unique order identifier (e.g., "order-001")
  final String tailorId;          // Foreign key linking to TailorModel.tailorId
  final String tailorShopName;    // Denormalized for display (avoids extra API call)
  final String garmentType;       // Type of garment (e.g., "Evening Gown")
  final OrderStatus status;       // Current stage in the production pipeline
  final String statusUpdatedDate; // Date when the status last changed
  final String estimatedCompletionDate; // Target delivery date
  final String customerNotes;     // Special instructions from the customer
  final double chestMeasurementInches;     // Chest circumference in inches
  final double waistMeasurementInches;     // Waist circumference in inches
  final double hipsMeasurementInches;      // Hips circumference in inches
  final double shouldersMeasurementInches; // Shoulder width in inches
  final double inseamMeasurementInches;    // Inseam/leg length in inches
  final String fabricMaterial;    // Selected fabric (e.g., "Premium Satin")
  final String? inspirationImageUrl; // Optional reference photo URL
  final List<ChatMessage> chatMessages; // Order-specific chat thread
  final String orderCreatedDate;  // Timestamp when order was first submitted

  const OrderModel({
    required this.orderId,
    required this.tailorId,
    required this.tailorShopName,
    required this.garmentType,
    required this.status,
    required this.statusUpdatedDate,
    required this.estimatedCompletionDate,
    required this.customerNotes,
    required this.chestMeasurementInches,
    required this.waistMeasurementInches,
    required this.hipsMeasurementInches,
    required this.shouldersMeasurementInches,
    required this.inseamMeasurementInches,
    required this.fabricMaterial,
    this.inspirationImageUrl,
    required this.chatMessages,
    required this.orderCreatedDate,
  });

  /// Creates an OrderModel from the Python backend JSON response.
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderId: json['order_id'] as String,
      tailorId: json['tailor_id'] as String,
      tailorShopName: json['tailor_shop_name'] as String,
      garmentType: json['garment_type'] as String,
      status: orderStatusFromString(json['status'] as String),
      statusUpdatedDate: json['status_updated_date'] as String,
      estimatedCompletionDate: json['estimated_completion_date'] as String,
      customerNotes: json['customer_notes'] as String? ?? '',
      chestMeasurementInches: (json['chest_measurement_inches'] as num).toDouble(),
      waistMeasurementInches: (json['waist_measurement_inches'] as num).toDouble(),
      hipsMeasurementInches: (json['hips_measurement_inches'] as num).toDouble(),
      shouldersMeasurementInches: (json['shoulders_measurement_inches'] as num).toDouble(),
      inseamMeasurementInches: (json['inseam_measurement_inches'] as num).toDouble(),
      fabricMaterial: json['fabric_material'] as String,
      inspirationImageUrl: json['inspiration_image_url'] as String?,
      chatMessages: (json['chat_messages'] as List)
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList(),
      orderCreatedDate: json['order_created_date'] as String,
    );
  }

  /// Converts an OrderModel to JSON for sending to the Python backend.
  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'tailor_id': tailorId,
      'tailor_shop_name': tailorShopName,
      'garment_type': garmentType,
      'status': status.name,
      'status_updated_date': statusUpdatedDate,
      'estimated_completion_date': estimatedCompletionDate,
      'customer_notes': customerNotes,
      'chest_measurement_inches': chestMeasurementInches,
      'waist_measurement_inches': waistMeasurementInches,
      'hips_measurement_inches': hipsMeasurementInches,
      'shoulders_measurement_inches': shouldersMeasurementInches,
      'inseam_measurement_inches': inseamMeasurementInches,
      'fabric_material': fabricMaterial,
      'inspiration_image_url': inspirationImageUrl,
      'chat_messages': chatMessages.map((m) => m.toJson()).toList(),
      'order_created_date': orderCreatedDate,
    };
  }

  /// Returns a number from 0–100 representing production completion.
  int get progressPercentage {
    switch (status) {
      case OrderStatus.submitted:  return 20;
      case OrderStatus.accepted:   return 40;
      case OrderStatus.cutting:    return 60;
      case OrderStatus.fitting:    return 80;
      case OrderStatus.completed:  return 100;
    }
  }

  bool get isCompleted => status == OrderStatus.completed;
}

/// A single message in an order's chat thread.
/// Sender must be either 'customer' or 'tailor' — matches backend convention.
class ChatMessage {
  final String messageId;   // Unique message ID
  final String senderRole;  // 'customer' or 'tailor' — used for bubble alignment
  final String messageText; // Content of the message
  final String sentAt;      // Formatted datetime string

  const ChatMessage({
    required this.messageId,
    required this.senderRole,
    required this.messageText,
    required this.sentAt,
  });

  bool get isSentByCustomer => senderRole == 'customer';
  bool get isSentByTailor => senderRole == 'tailor';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      messageId: json['message_id'] as String,
      senderRole: json['sender_role'] as String,
      messageText: json['message_text'] as String,
      sentAt: json['sent_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message_id': messageId,
      'sender_role': senderRole,
      'message_text': messageText,
      'sent_at': sentAt,
    };
  }
}
