// ============================================================
// models/customer_model.dart
//
// Represents the logged-in Customer user.
//
// BACKEND API ENDPOINTS (Python):
//   POST /api/auth/login    → returns CustomerModel (with auth token)
//   POST /api/auth/register → creates a new account, returns CustomerModel
//   GET  /api/customer/me   → returns the logged-in CustomerModel
// ============================================================

class CustomerModel {
  final String customerId;      // Unique customer identifier
  final String fullName;        // Customer's full display name
  final String emailAddress;    // Login email
  final String phoneNumber;     // Contact number
  final String cityLocation;    // Customer's general city/area (e.g., "Dumaguete City")
  final String avatarImageUrl;  // Profile photo URL
  final String accountTier;     // Membership tier: "standard" or "premium"
  final String memberSince;     // Date joined (formatted string)

  const CustomerModel({
    required this.customerId,
    required this.fullName,
    required this.emailAddress,
    required this.phoneNumber,
    required this.cityLocation,
    required this.avatarImageUrl,
    required this.accountTier,
    required this.memberSince,
  });

  bool get isPremium => accountTier == 'premium';

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      customerId: json['customer_id'] as String,
      fullName: json['full_name'] as String,
      emailAddress: json['email_address'] as String,
      phoneNumber: json['phone_number'] as String,
      cityLocation: json['city_location'] as String,
      avatarImageUrl: json['avatar_image_url'] as String,
      accountTier: json['account_tier'] as String? ?? 'standard',
      memberSince: json['member_since'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'full_name': fullName,
      'email_address': emailAddress,
      'phone_number': phoneNumber,
      'city_location': cityLocation,
      'avatar_image_url': avatarImageUrl,
      'account_tier': accountTier,
      'member_since': memberSince,
    };
  }
}
