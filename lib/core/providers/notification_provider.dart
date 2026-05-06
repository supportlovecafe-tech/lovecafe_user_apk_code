import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import 'auth_provider.dart';

class NotificationNotifier extends StateNotifier<List<AppNotification>> {
  final Ref _ref;
  RealtimeChannel? _orderSubscription;
  RealtimeChannel? _chatSubscription;

  NotificationNotifier(this._ref) : super([]) {
    // Listen for auth changes to re-initialize subscriptions
    _ref.listen(authProvider, (previous, next) {
      if (next.userId != null && previous?.userId != next.userId) {
        _init(next.userId!);
      } else if (next.userId == null) {
        _cleanup();
        state = []; // Clear notification history on logout
      }
    });

    final initialUserId = _ref.read(authProvider).userId;
    if (initialUserId != null) {
      _init(initialUserId);
    }
  }

  void _init(String userId) {
    _cleanup();
    final supabase = Supabase.instance.client;

    // 1. Listen for Order Status Changes
    _orderSubscription = supabase
        .channel('public:orders:notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'customer_id',
            value: userId,
          ),
          callback: (payload) {
            final newStatus = payload.newRecord['status'];
            final oldStatus = payload.oldRecord['status'];
            if (newStatus != oldStatus) {
              _addNotification(
                title: 'Order Update',
                body: 'Your order status is now $newStatus',
                type: 'order_status',
                orderId: payload.newRecord['id'],
              );
            }
          },
        )
        .subscribe();

    // 2. Listen for New Messages (Chat)
    _chatSubscription = supabase
        .channel('public:order_messages:notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'order_messages',
          callback: (payload) {
            // We'll filter messages in memory for simplicity or add a more complex filter
            if (payload.newRecord['sender_role'] == 'OUTLET') {
              _addNotification(
                title: 'New Message from Outlet',
                body: payload.newRecord['content'],
                type: 'chat',
                orderId: payload.newRecord['order_id'],
              );
            }
          },
        )
        .subscribe();
  }

  void _cleanup() {
    _orderSubscription?.unsubscribe();
    _chatSubscription?.unsubscribe();
    _orderSubscription = null;
    _chatSubscription = null;
  }

  void _addNotification({
    required String title,
    required String body,
    required String type,
    String? orderId,
  }) {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
      type: type,
      orderId: orderId,
    );
    state = [notification, ...state];
  }

  void markAsRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: true) else n
    ];
  }

  void clearAll() {
    state = [];
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, List<AppNotification>>((ref) {
  return NotificationNotifier(ref);
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).where((n) => !n.isRead).length;
});

final hasNewChatMessagesProvider = Provider<bool>((ref) {
  return ref.watch(notificationProvider).any((n) => n.type == 'chat' && !n.isRead);
});
