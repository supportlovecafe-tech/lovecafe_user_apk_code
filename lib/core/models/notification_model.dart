class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final String type; // 'order_status', 'chat', 'promo'
  final String? orderId;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    this.orderId,
    this.isRead = false,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? timestamp,
    String? type,
    String? orderId,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      orderId: orderId ?? this.orderId,
      isRead: isRead ?? this.isRead,
    );
  }
}
