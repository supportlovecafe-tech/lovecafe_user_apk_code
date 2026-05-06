class LoyaltyTransaction {
  final String id;
  final String userId;
  final double? amount;
  final int points;
  final String type; // 'EARN' or 'REDEEM'
  final String? orderId;
  final DateTime createdAt;

  LoyaltyTransaction({
    required this.id,
    required this.userId,
    this.amount,
    required this.points,
    required this.type,
    this.orderId,
    required this.createdAt,
  });

  factory LoyaltyTransaction.fromMap(Map<String, dynamic> map) {
    return LoyaltyTransaction(
      id: map['id'],
      userId: map['user_id'],
      amount: (map['amount'] as num?)?.toDouble(),
      points: map['points'] as int,
      type: map['type'],
      orderId: map['order_id'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'points': points,
      'type': type,
      'order_id': orderId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
