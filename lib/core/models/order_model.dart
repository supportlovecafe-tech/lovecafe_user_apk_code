import '../../../core/models/food_item.dart';

enum OrderStatus { PENDING, PREPARING, READY, DELIVERED, CANCELLED }
enum PaymentStatus { PENDING, SUCCESS, FAILED }
enum PaymentMethod { DEMO_UPI, DEMO_CARD, DEMO_WALLET }

class OrderModel {
  final String id;
  final String displayId;
  final List<OrderItem> items;
  final double totalAmount;
  final OrderStatus status;
  final DateTime timestamp;
  final String location; // e.g. "Hall 1 • Screen 2 • F9"
  final PaymentStatus paymentStatus;
  final PaymentMethod paymentMethod;
  final String customerPhone;
  final int? pointsEarned;
  final int? pointsRedeemed;

  OrderModel({
    required this.id,
    required this.displayId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.timestamp,
    required this.location,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.customerPhone,
    this.pointsEarned,
    this.pointsRedeemed,
  });

  OrderModel copyWith({
    String? id,
    String? displayId,
    List<OrderItem>? items,
    double? totalAmount,
    OrderStatus? status,
    DateTime? timestamp,
    String? location,
    PaymentStatus? paymentStatus,
    PaymentMethod? paymentMethod,
    String? customerPhone,
    int? pointsEarned,
    int? pointsRedeemed,
  }) {
    return OrderModel(
      id: id ?? this.id,
      displayId: displayId ?? this.displayId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      location: location ?? this.location,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      customerPhone: customerPhone ?? this.customerPhone,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      pointsRedeemed: pointsRedeemed ?? this.pointsRedeemed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'display_id': displayId,
      'items': items.map((item) => item.toMap()).toList(),
      'total_amount': totalAmount,
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
      'location': location,
      'payment_status': paymentStatus.name,
      'payment_method': paymentMethod.name,
      'customer_phone': customerPhone,
      'points_earned': pointsEarned,
      'points_redeemed': pointsRedeemed,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    final rawItems = (map['items'] as List<dynamic>? ?? []);
    final dbId = map['id']?.toString() ?? '';
    final dbDisplayId = map['display_id']?.toString();
    
    return OrderModel(
      id: dbId,
      displayId: dbDisplayId ?? dbId.substring(0, dbId.length > 8 ? 8 : dbId.length),
      items: rawItems.map((item) {
        final row = item as Map<String, dynamic>;
        return OrderItem(
          foodItem: FoodItem(
            id: row['food_id']?.toString() ?? '',
            name: row['food_name']?.toString() ?? '',
            description: row['food_description']?.toString() ?? '',
            imageUrl: row['food_image']?.toString() ?? '',
            price: (row['food_price'] as num?)?.toDouble() ?? 0,
            category: row['food_category']?.toString() ?? 'Classics',
          ),
          quantity: (row['quantity'] as num?)?.toInt() ?? 1,
          isDelivered: row['is_delivered'] == true,
        );
      }).toList(),
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
      status: OrderStatus.values.firstWhere(
        (value) => value.name == map['status'],
        orElse: () => OrderStatus.PENDING,
      ),
      timestamp: DateTime.tryParse(map['timestamp']?.toString() ?? '') ?? DateTime.now(),
      location: map['location']?.toString() ?? 'Hall 1 • Screen 1 • A1',
      paymentStatus: PaymentStatus.values.firstWhere(
        (value) => value.name == map['payment_status'],
        orElse: () => PaymentStatus.PENDING,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (value) => value.name == map['payment_method'],
        orElse: () => PaymentMethod.DEMO_UPI,
      ),
      customerPhone: map['customer_phone']?.toString() ?? 'NA',
      pointsEarned: map['points_earned'] as int?,
      pointsRedeemed: map['points_redeemed'] as int?,
    );
  }
}

class OrderItem {
  final FoodItem foodItem;
  final int quantity;
  final bool isDelivered;

  OrderItem({required this.foodItem, required this.quantity, this.isDelivered = false});

  Map<String, dynamic> toMap() {
    return {
      'food_id': foodItem.id,
      'food_name': foodItem.name,
      'food_price': foodItem.price,
      'food_image': foodItem.imageUrl,
      'food_description': foodItem.description,
      'food_category': foodItem.category,
      'quantity': quantity,
      'is_delivered': isDelivered,
    };
  }
}
