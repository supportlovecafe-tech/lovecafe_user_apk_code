// Love Cafe Database Schema Definitions

class DatabaseTables {
  static const String cinemas = 'cinemas';
  static const String screens = 'screens';
  static const String foodItems = 'food_items';
  static const String customerProfiles = 'customer_profiles';
  static const String orders = 'orders';
  static const String orderMessages = 'order_messages';
}

// Map database column names for type safety
class OrderColumns {
  static const String id = 'id';
  static const String displayId = 'display_id';
  static const String cinemaId = 'cinema_id';
  static const String customerId = 'customer_id';
  static const String customerProfileId = 'customer_profile_id';
  static const String items = 'items';
  static const String totalAmount = 'total_amount';
  static const String status = 'status';
  static const String location = 'location';
  static const String paymentStatus = 'payment_status';
  static const String paymentMethod = 'payment_method';
  static const String customerPhone = 'customer_phone';
  static const String isDemoOrder = 'is_demo_order';
  static const String pointsEarned = 'points_earned';
  static const String pointsRedeemed = 'points_redeemed';
  static const String timestamp = 'timestamp';
}

class FoodItemColumns {
  static const String id = 'id';
  static const String cinemaId = 'cinema_id';
  static const String name = 'name';
  static const String description = 'description';
  static const String price = 'price';
  static const String imageUrl = 'image_url';
  static const String category = 'category';
  static const String isAvailable = 'is_available';
}
