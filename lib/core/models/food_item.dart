class FoodItem {
  final String id;
  final String? cinemaId; // Added for SaaS multi-tenancy
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final List<String> hallIds;
  final bool isAvailable;

  FoodItem({
    required this.id,
    this.cinemaId,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.hallIds = const [],
    this.isAvailable = true,
  });

  FoodItem copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? category,
    List<String>? hallIds,
    bool? isAvailable,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      hallIds: hallIds ?? this.hallIds,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'hallIds': hallIds,
      'isAvailable': isAvailable,
    };
  }

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id']?.toString() ?? '',
      cinemaId: map['cinema_id']?.toString(), // Map from database column
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      imageUrl: map['image_url']?.toString() ?? map['imageUrl']?.toString() ?? '', // Handle both snake and camel
      category: map['category']?.toString() ?? '',
      hallIds: (map['hall_ids'] as List<dynamic>? ?? map['hallIds'] as List<dynamic>? ?? [])
          .map((entry) => entry.toString())
          .toList(),
      isAvailable: map['is_available'] as bool? ?? map['isAvailable'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toDatabaseMap() {
    return {
      'name': name,
      'cinema_id': cinemaId,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'category': category,
      'is_available': isAvailable,
    };
  }
}
