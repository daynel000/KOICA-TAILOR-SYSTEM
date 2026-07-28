// ============================================================
// models/scan_result_model.dart
//
// Represents the result from an AI Body Measurement Scan.
//
// SHARED WITH TAILOR DASHBOARD:
//   When a customer saves a scan result and then creates an order,
//   these measurement values are included in the OrderModel and
//   sent to the Python backend, which the Tailor dashboard reads.
//
// BACKEND API ENDPOINT (Python):
//   POST /api/scan → sends image + height + gender, returns ScanResultModel
// ============================================================

class ScanResultModel {
  final double bodyLength;          // 1. gitas on sa lawas
  final double shoulderWidth;       // 2. gilapdon sa Abaga
  final double chestWidth;          // 3. gilapdon sa dughan
  final double chestCircumference;  // 4. palibot sa dughan
  final double armLength;           // 5. gitas on sa bukton
  final double bicepCircumference;  // 6. palibot sa bukton (biceps)
  final double waistCircumference;  // 7. palibot sa hawak
  final double hipsCircumference;   // 8. palibot sa Hips
  final double confidenceScore;   // AI accuracy from 0.0 to 1.0 (e.g., 0.97 = 97%)
  final String postureFeedback;   // AI-generated posture analysis text
  final String recommendedSize;   // Recommended garment size (e.g., "M", "L", "XL")
  final String scannedAt;         // Timestamp when the scan was performed

  const ScanResultModel({
    required this.bodyLength,
    required this.shoulderWidth,
    required this.chestWidth,
    required this.chestCircumference,
    required this.armLength,
    required this.bicepCircumference,
    required this.waistCircumference,
    required this.hipsCircumference,
    required this.confidenceScore,
    required this.postureFeedback,
    required this.recommendedSize,
    required this.scannedAt,
  });

  /// Creates a ScanResultModel from the JSON response, supporting both Python and Express formats.
  factory ScanResultModel.fromJson(Map<String, dynamic> json) {
    return ScanResultModel(
      bodyLength: ((json['body_length'] ?? 28.0) as num).toDouble(),
      shoulderWidth: ((json['shoulder_width'] ?? 18.0) as num).toDouble(),
      chestWidth: ((json['chest_width'] ?? 20.0) as num).toDouble(),
      chestCircumference: ((json['chest_circumference'] ?? json['chest_inches'] ?? 40.0) as num).toDouble(),
      armLength: ((json['arm_length'] ?? 25.0) as num).toDouble(),
      bicepCircumference: ((json['bicep_circumference'] ?? 14.0) as num).toDouble(),
      waistCircumference: ((json['waist_circumference'] ?? json['waist_inches'] ?? 32.0) as num).toDouble(),
      hipsCircumference: ((json['hips_circumference'] ?? json['hips_inches'] ?? 38.0) as num).toDouble(),
      confidenceScore: ((json['confidence_score'] ?? json['confidence'] ?? 0.90) as num).toDouble(),
      postureFeedback: (json['posture_feedback'] ?? json['postureFeedback'] ?? 'Keep a straight posture.') as String,
      recommendedSize: (json['recommended_size'] ?? json['sizeCategory'] ?? 'M') as String,
      scannedAt: (json['scanned_at'] ?? json['timestamp'] ?? DateTime.now().toString()) as String,
    );
  }

  /// Converts scan result to JSON for saving via the Python backend.
  Map<String, dynamic> toJson() {
    return {
      'body_length': bodyLength,
      'shoulder_width': shoulderWidth,
      'chest_width': chestWidth,
      'chest_circumference': chestCircumference,
      'arm_length': armLength,
      'bicep_circumference': bicepCircumference,
      'waist_circumference': waistCircumference,
      'hips_circumference': hipsCircumference,
      'confidence_score': confidenceScore,
      'posture_feedback': postureFeedback,
      'recommended_size': recommendedSize,
      'scanned_at': scannedAt,
    };
  }

  /// Returns a user-friendly percentage string of the confidence score.
  String get confidencePercent => '${(confidenceScore * 100).round()}%';
}
