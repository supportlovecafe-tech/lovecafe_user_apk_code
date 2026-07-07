import '../../../core/models/food_item.dart';

enum OrderStatus { PENDING, PREPARING, READY, DELIVERED, CANCELLED }
enum PaymentStatus { PENDING, SUCCESS, FAILED }
enum PaymentMethod { DEMO_UPI, DEMO_CARD, DEMO_WALLET, PAY_ON_DELIVERY, PAY_LATER }

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
  final String? clientUuid;
  final bool isSyncing;

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
    this.clientUuid,
    this.isSyncing = false,
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
    int? pointsRedeemed,
    String? clientUuid,
    bool? isSyncing,
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
      clientUuid: clientUuid ?? this.clientUuid,
      isSyncing: isSyncing ?? this.isSyncing,
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
      'client_uuid': clientUuid,
      'is_syncing': isSyncing,
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
        final foodId = row['food_id']?.toString() ?? '';
        return OrderItem(
          itemId: row['item_id']?.toString() ?? '${foodId}_${DateTime.now().millisecondsSinceEpoch}',
          foodItem: FoodItem(
            id: foodId,
            name: row['food_name']?.toString() ?? '',
            description: row['food_description']?.toString() ?? '',
            imageUrl: row['food_image']?.toString() ?? '',
            price: (row['food_price'] as num?)?.toDouble() ?? 0,
            category: row['food_category']?.toString() ?? 'Classics',
          ),
          quantity: (row['quantity'] as num?)?.toInt() ?? 1,
          isDelivered: row['is_delivered'] == true,
          note: row['item_note']?.toString(),           // Feature 1: item note
          isCombo: row['is_combo'] == true,             // Feature 2: combo flag
          comboId: row['combo_id']?.toString(),         // Feature 2: combo id
          comboName: row['combo_name']?.toString(),     // Feature 2: combo name
          kdsStatus: row['kds_status']?.toString() ?? 'PENDING',
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
      clientUuid: map['client_uuid']?.toString(),
      isSyncing: map['is_syncing'] == true,
    );
  }
}

class OrderItem {
  final String itemId;
  final FoodItem foodItem;
  final int quantity;
  final bool isDelivered;
  final String? note;       // Feature 1: custom cooking/serving instruction
  final bool isCombo;       // Feature 2: true if this item is part of a combo
  final String? comboId;    // Feature 2: combo UUID
  final String? comboName;  // Feature 2: combo display name
  final String kdsStatus;   // PENDING, PREPARING, READY, DELIVERED

  OrderItem({
    required this.itemId,
    required this.foodItem,
    required this.quantity,
    this.isDelivered = false,
    this.note,
    this.isCombo = false,
    this.comboId,
    this.comboName,
    this.kdsStatus = 'PENDING',
  });

  Map<String, dynamic> toMap() {
    return {
      'item_id': itemId,
      'food_id': foodItem.id,
      'food_name': foodItem.name,
      'food_price': foodItem.price,
      'food_image': foodItem.imageUrl,
      'food_description': foodItem.description,
      'food_category': foodItem.category,
      'quantity': quantity,
      'is_delivered': isDelivered,
      'kds_status': kdsStatus,
      if (note != null && note!.isNotEmpty) 'item_note': note,   // Feature 1
      if (isCombo) 'is_combo': true,                             // Feature 2
      if (comboId != null) 'combo_id': comboId,                  // Feature 2
      if (comboName != null) 'combo_name': comboName,            // Feature 2
    };
  }
}
