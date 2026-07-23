// ============================================================
// models/tailor_model.dart
//
// Represents a Tailor shop in the TailorConnect system.
//
// SHARED WITH TAILOR DASHBOARD:
//   The Tailor dashboard uses the SAME field names from this model
//   when it saves tailor data to MySQL via the Python backend.
//   Any changes here should be mirrored in the Tailor dashboard app.
//
// BACKEND API ENDPOINT (Python):
//   GET  /api/tailors        → returns List<TailorModel>
//   GET  /api/tailors/{id}   → returns a single TailorModel
// ============================================================

class TailorModel {
  final String tailorId;       // Unique tailor shop identifier (e.g., "jdc-tailoring")
  final String shopName;       // Display name of the tailor shop
  final double rating;         // Average star rating (0.0 to 5.0)
  final int reviewsCount;      // Total number of customer reviews
  final String location;       // Full address of the shop
  final List<String> specialties; // Services offered (e.g., "Wedding Gowns", "Barong Tagalog")
  final String priceRange;     // Price tier: "Budget", "Mid-range", or "Premium"
  final String distanceFromCustomer; // Formatted distance string (e.g., "1.2 km")
  final double latitude;       // GPS latitude for map display
  final double longitude;      // GPS longitude for map display
  final String avatarImageUrl; // Profile/shop photo URL
  final String workingHours;   // Operating hours string (e.g., "Mon–Sat, 8AM–6PM")
  final String about;          // Short bio/description of the shop
  final List<TailorReview> reviews; // List of customer reviews

  const TailorModel({
    required this.tailorId,
    required this.shopName,
    required this.rating,
    required this.reviewsCount,
    required this.location,
    required this.specialties,
    required this.priceRange,
    required this.distanceFromCustomer,
    required this.latitude,
    required this.longitude,
    required this.avatarImageUrl,
    required this.workingHours,
    required this.about,
    required this.reviews,
  });

  /// Creates a TailorModel from a JSON map (e.g., from Python backend API response).
  factory TailorModel.fromJson(Map<String, dynamic> json) {
    return TailorModel(
      tailorId: json['tailor_id'] as String,
      shopName: json['shop_name'] as String,
      rating: (json['rating'] as num).toDouble(),
      reviewsCount: json['reviews_count'] as int,
      location: json['location'] as String,
      specialties: List<String>.from(json['specialties'] as List),
      priceRange: json['price_range'] as String,
      distanceFromCustomer: json['distance_from_customer'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      avatarImageUrl: json['avatar_image_url'] as String,
      workingHours: json['working_hours'] as String,
      about: json['about'] as String,
      reviews: (json['reviews'] as List)
          .map((r) => TailorReview.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Converts a TailorModel to JSON for sending to the Python backend.
  Map<String, dynamic> toJson() {
    return {
      'tailor_id': tailorId,
      'shop_name': shopName,
      'rating': rating,
      'reviews_count': reviewsCount,
      'location': location,
      'specialties': specialties,
      'price_range': priceRange,
      'distance_from_customer': distanceFromCustomer,
      'latitude': latitude,
      'longitude': longitude,
      'avatar_image_url': avatarImageUrl,
      'working_hours': workingHours,
      'about': about,
      'reviews': reviews.map((r) => r.toJson()).toList(),
    };
  }
}

/// Represents a single customer review for a tailor shop.
class TailorReview {
  final String authorName;  // Reviewer's display name
  final int starRating;     // 1 to 5 stars
  final String reviewDate;  // Formatted date string
  final String reviewText;  // The review message

  const TailorReview({
    required this.authorName,
    required this.starRating,
    required this.reviewDate,
    required this.reviewText,
  });

  factory TailorReview.fromJson(Map<String, dynamic> json) {
    return TailorReview(
      authorName: json['author_name'] as String,
      starRating: json['star_rating'] as int,
      reviewDate: json['review_date'] as String,
      reviewText: json['review_text'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'author_name': authorName,
      'star_rating': starRating,
      'review_date': reviewDate,
      'review_text': reviewText,
    };
  }
}
