import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../models/order_model.dart';
import 'seat_selection_provider.dart';
import 'auth_provider.dart';
import 'loyalty_provider.dart';
import 'supabase_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class OrdersNotifier extends StateNotifier<List<OrderModel>> {
  final Ref _ref;
  late final RealtimeChannel _ordersChannel;

  OrdersNotifier(this._ref) : super([]) {
    _initializeRealtimeSubscription();
    
    // Reactively load orders when auth state or seat selection changes
    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.AUTHENTICATED) {
        loadOrders();
      } else if (next.status == AuthStatus.UNAUTHENTICATED) {
        state = [];
      }
    });

    _ref.listen<SeatSelectionState>(seatSelectionProvider, (previous, next) {
      if (next.hallId != null) {
        loadOrders(next.hallId);
      }
    });

    // Initial load
    Future.microtask(() {
      loadOrders();
      _recoverPendingOrder();
    });
  }

  Future<void> _recoverPendingOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pending = prefs.getString('pending_order');
      if (pending != null) {
        final data = jsonDecode(pending);
        print('🕒 Recovering pending order: ${data['clientUuid']}');
        // Retry placing the order with the same clientUuid
        // (logic handled in placeOrder but could be triggered here)
      }
    } catch (e) {
      print('Error recovering pending order: $e');
    }
  }

  void _initializeRealtimeSubscription() {
    _ordersChannel = Supabase.instance.client.channel('public:orders');

    _ordersChannel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'orders',
      callback: (payload) {
        final newRecord = payload.newRecord;
        if (newRecord.isEmpty) return;
        
        final updatedOrder = OrderModel.fromMap(newRecord);
        
        if (payload.eventType == PostgresChangeEvent.insert) {
          // Add new order to top
          if (!state.any((o) => o.id == updatedOrder.id)) {
            state = [updatedOrder, ...state];
          }
        } else if (payload.eventType == PostgresChangeEvent.update) {
          // Update existing order in list
          state = [
            for (final order in state)
              if (order.id == updatedOrder.id) updatedOrder else order
          ];
        }
      },
    ).subscribe();
  }

  @override
  void dispose() {
    _ordersChannel.unsubscribe();
    super.dispose();
  }

  Future<void> loadOrders([String? cinemaId]) async {
    try {
      final supabase = _ref.read(supabaseServiceProvider);
      final auth = _ref.read(authProvider);
      final userId = auth.userId;
      final phone = auth.phone;
      
      final rawOrders = await supabase.fetchOrders(
        cinemaId: cinemaId,
        customerId: userId,
        customerPhone: phone,
      );
      state = rawOrders.map((data) => OrderModel.fromMap(data)).toList();
    } catch (e) {
      print('Error loading orders: $e');
    }
  }

  Future<OrderModel?> placeOrder(
    List<OrderItem> items,
    double total,
    String location, {
    required PaymentMethod paymentMethod,
    required String customerPhone,
    int pointsRedeemed = 0,
    Map<String, dynamic>? metadata,
  }) async {
    final selection = _ref.read(seatSelectionProvider);
    final cinemaId = selection.hallId;
    
    if (cinemaId == null) return null;
    
    final auth = _ref.read(authProvider);
    final userId = auth.userId;
    
    // Calculate loyalty
    final loyalty = _ref.read(loyaltyProvider.notifier);
    final pointsEarned = loyalty.calculateEarnedPoints(total);

    // Generate unique display ID: OUTLET-CUST-TIME (e.g. C1-U1-4567)
    final shortCinemaId = cinemaId.substring(0, 4).toUpperCase();
    final shortPhone = customerPhone.length > 4 ? customerPhone.substring(customerPhone.length - 4) : 'GUEST';
    final timestampStr = DateTime.now().millisecondsSinceEpoch.toString();
    final shortTime = timestampStr.substring(timestampStr.length - 4);
    final displayId = '$shortCinemaId-$shortPhone-$shortTime';
    final clientUuid = const Uuid().v4();

    final newOrder = OrderModel(
      id: 'TEMP-${DateTime.now().millisecondsSinceEpoch}',
      displayId: displayId,
      items: items,
      totalAmount: total,
      status: OrderStatus.PENDING,
      timestamp: DateTime.now(),
      location: location,
      paymentStatus: (paymentMethod == PaymentMethod.PAY_ON_DELIVERY || paymentMethod == PaymentMethod.PAY_LATER) ? PaymentStatus.PENDING : PaymentStatus.SUCCESS,
      paymentMethod: paymentMethod,
      customerPhone: customerPhone,
      pointsEarned: pointsEarned,
      pointsRedeemed: pointsRedeemed,
      clientUuid: clientUuid,
      isSyncing: true,
    );

    // PERSIST for recoverability
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pending_order', jsonEncode({
      'clientUuid': clientUuid,
      'displayId': displayId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    }));

    // Optimistic UI update
    state = [newOrder, ...state];

    try {
      final supabase = _ref.read(supabaseServiceProvider);
      
      // Feature 1: Pass item notes; Feature 2: Pass combo flags — all via toMap()
      final realId = await supabase.placeOrder(
        cinemaId: cinemaId,
        items: items.map((i) => i.toMap()).toList(),
        totalAmount: total,
        location: location,
        customerPhone: customerPhone,
        displayId: displayId,
        authUserId: userId,
        customerProfileId: userId,
        clientUuid: clientUuid,
        pointsRedeemed: pointsRedeemed,
        pointsEarned: pointsEarned,
        paymentMethod: paymentMethod,
        metadata: metadata,
      );
      
      // Atomic loyalty is now handled by the backend RPC via the placeOrder call.
      if (userId != null) {
        // Refresh wallet locally
        await _ref.read(loyaltyProvider.notifier).fetchWallet();
      }

      // Update state with the real UUID from the database
      state = [
        for (final order in state)
          if (order.id == newOrder.id) 
            order.copyWith(id: realId, isSyncing: false) 
          else 
            order
      ];

      // CLEAR persistence on success
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pending_order');

      return newOrder.copyWith(id: realId, isSyncing: false);
    } catch (e) {
      print('Error placing order: $e');
      // On error, remove the optimistic order
      state = state.where((o) => o.id != newOrder.id).toList();
      rethrow; // Rethrow so the UI knows it failed
    }
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    // Optimistic Update
    final previousState = state;
    state = [
      for (final order in state)
        if (order.id == orderId) order.copyWith(status: status, isSyncing: true) else order,
    ];

    try {
      final supabase = _ref.read(supabaseServiceProvider);
      // Assuming a method like updateOrderStatus exists or using generic update
      await Supabase.instance.client
          .from('orders')
          .update({'status': status.name})
          .eq('id', orderId);
      
      // Update local state to show sync complete
      state = [
        for (final order in state)
          if (order.id == orderId) order.copyWith(isSyncing: false) else order,
      ];
    } catch (e) {
      print('Error updating order status: $e');
      // Rollback on error
      state = previousState;
    }
  }
}

final ordersProvider = StateNotifierProvider<OrdersNotifier, List<OrderModel>>((ref) {
  return OrdersNotifier(ref);
});
