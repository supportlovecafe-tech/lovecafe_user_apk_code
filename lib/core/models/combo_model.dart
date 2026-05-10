// Feature 2: Combo Meal Models
// Combos are outlet-specific bundles of existing food items at a fixed price.

class ComboMeal {
  final String id;
  final String cinemaId;
  final String name;
  final String description;
  final String imageUrl;
  final double price;           // Combo selling price
  final double? originalPrice;  // Sum of individual item prices (for savings display)
  final String category;        // Snacks Combo | Family Combo | Beverage Combo | Premium Combo
  final bool isAvailable;
  final List<ComboItem> items;  // Constituent items

  ComboMeal({
    required this.id,
    required this.cinemaId,
    required this.name,
    this.description = '',
    this.imageUrl = '',
    required this.price,
    this.originalPrice,
    this.category = 'Snacks Combo',
    this.isAvailable = true,
    this.items = const [],
  });

  /// Savings amount shown to customers (original - combo price)
  double get savings => (originalPrice ?? 0) - price;
  bool get hasSavings => savings > 0;

  /// Display-friendly savings string
  String get savingsLabel => hasSavings ? '₹${savings.toInt()} OFF' : '';

  factory ComboMeal.fromMap(Map<String, dynamic> map) {
    final rawItems = map['combo_items'] as List<dynamic>? ?? [];
    return ComboMeal(
      id: map['id']?.toString() ?? '',
      cinemaId: map['cinema_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      imageUrl: map['image_url']?.toString() ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      originalPrice: (map['original_price'] as num?)?.toDouble(),
      category: map['category']?.toString() ?? 'Snacks Combo',
      isAvailable: map['is_available'] as bool? ?? true,
      items: rawItems.map((i) => ComboItem.fromMap(i as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cinema_id': cinemaId,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'price': price,
      'original_price': originalPrice,
      'category': category,
      'is_available': isAvailable,
    };
  }
}

class ComboItem {
  final String id;
  final String comboId;
  final String foodItemId;
  final String foodItemName;
  final double foodItemPrice;
  final int quantity;

  const ComboItem({
    required this.id,
    required this.comboId,
    required this.foodItemId,
    required this.foodItemName,
    required this.foodItemPrice,
    required this.quantity,
  });

  factory ComboItem.fromMap(Map<String, dynamic> map) {
    return ComboItem(
      id: map['id']?.toString() ?? '',
      comboId: map['combo_id']?.toString() ?? '',
      foodItemId: map['food_item_id']?.toString() ?? '',
      foodItemName: map['food_item_name']?.toString() ?? '',
      foodItemPrice: (map['food_item_price'] as num?)?.toDouble() ?? 0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'combo_id': comboId,
      'food_item_id': foodItemId,
      'food_item_name': foodItemName,
      'food_item_price': foodItemPrice,
      'quantity': quantity,
    };
  }
}
