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
  final double chestInches;       // Chest circumference in inches
  final double waistInches;       // Waist circumference in inches
  final double hipsInches;        // Hips circumference in inches
  final double shouldersInches;   // Shoulder width in inches
  final double inseamInches;      // Inseam/leg length in inches
  final double confidenceScore;   // AI accuracy from 0.0 to 1.0 (e.g., 0.97 = 97%)
  final String postureFeedback;   // AI-generated posture analysis text
  final String recommendedSize;   // Recommended garment size (e.g., "M", "L", "XL")
  final String scannedAt;         // Timestamp when the scan was performed

  const ScanResultModel({
    required this.chestInches,
    required this.waistInches,
    required this.hipsInches,
    required this.shouldersInches,
    required this.inseamInches,
    required this.confidenceScore,
    required this.postureFeedback,
    required this.recommendedSize,
    required this.scannedAt,
  });

  /// Creates a ScanResultModel from the JSON response, supporting both Python and Express formats.
  factory ScanResultModel.fromJson(Map<String, dynamic> json) {
    return ScanResultModel(
      chestInches: ((json['chest_inches'] ?? json['chest'] ?? 34.0) as num).toDouble(),
      waistInches: ((json['waist_inches'] ?? json['waist'] ?? 27.0) as num).toDouble(),
      hipsInches: ((json['hips_inches'] ?? json['hips'] ?? 37.0) as num).toDouble(),
      shouldersInches: ((json['shoulders_inches'] ?? json['shoulders'] ?? 15.0) as num).toDouble(),
      inseamInches: ((json['inseam_inches'] ?? json['inseam'] ?? 29.0) as num).toDouble(),
      confidenceScore: ((json['confidence_score'] ?? json['confidence'] ?? 0.90) as num).toDouble(),
      postureFeedback: (json['posture_feedback'] ?? json['postureFeedback'] ?? 'Keep a straight posture.') as String,
      recommendedSize: (json['recommended_size'] ?? json['sizeCategory'] ?? 'M') as String,
      scannedAt: (json['scanned_at'] ?? json['timestamp'] ?? DateTime.now().toString()) as String,
    );
  }

  /// Converts scan result to JSON for saving via the Python backend.
  Map<String, dynamic> toJson() {
    return {
      'chest_inches': chestInches,
      'waist_inches': waistInches,
      'hips_inches': hipsInches,
      'shoulders_inches': shouldersInches,
      'inseam_inches': inseamInches,
      'confidence_score': confidenceScore,
      'posture_feedback': postureFeedback,
      'recommended_size': recommendedSize,
      'scanned_at': scannedAt,
    };
  }

  /// Returns a user-friendly percentage string of the confidence score.
  String get confidencePercent => '${(confidenceScore * 100).round()}%';
}
