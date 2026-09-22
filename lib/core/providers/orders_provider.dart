import 'dart:async';
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
import '../services/auth_service.dart';

class OrdersNotifier extends StateNotifier<List<OrderModel>> {
  final Ref _ref;
  late final RealtimeChannel _ordersChannel;
  Timer? _pollingTimer;

  OrdersNotifier(this._ref) : super([]) {
    _initializeRealtimeSubscription();
    _startPolling();
    
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

  void _startPolling() {
    _pollingTimer?.cancel();
    // Poll every 5 seconds to guarantee customer app always has real-time accuracy even when WebSockets drop
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      loadOrders(null, true);
    });
  }

  Future<void> _recoverPendingOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pending = prefs.getString('pending_order');
      if (pending != null) {
        final data = jsonDecode(pending);
        print('🕒 Recovering pending order: ${data['clientUuid']}');
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
        try {
          final newRecord = payload.newRecord;
          if (newRecord.isEmpty) return;
          
          final updatedOrder = OrderModel.fromMap(newRecord);
          
          if (payload.eventType == PostgresChangeEvent.insert) {
            final existingIndex = state.indexWhere((o) =>
                o.id == updatedOrder.id ||
                (o.displayId.isNotEmpty && o.displayId == updatedOrder.displayId) ||
                (o.clientUuid != null && updatedOrder.clientUuid != null && o.clientUuid == updatedOrder.clientUuid));

            if (existingIndex != -1) {
              state = [
                for (int i = 0; i < state.length; i++)
                  if (i == existingIndex) updatedOrder else state[i]
              ];
            } else {
              state = [updatedOrder, ...state];
            }
          } else if (payload.eventType == PostgresChangeEvent.update) {
            final exists = state.any((o) =>
                o.id == updatedOrder.id ||
                (o.displayId.isNotEmpty && o.displayId == updatedOrder.displayId) ||
                (o.clientUuid != null && updatedOrder.clientUuid != null && o.clientUuid == updatedOrder.clientUuid));

            if (exists) {
              state = [
                for (final order in state)
                  if (order.id == updatedOrder.id ||
                      (order.displayId.isNotEmpty && order.displayId == updatedOrder.displayId) ||
                      (order.clientUuid != null && updatedOrder.clientUuid != null && order.clientUuid == updatedOrder.clientUuid))
                    updatedOrder
                  else
                    order
              ];
            } else {
              // Trigger fresh load to fetch full order list
              loadOrders(null, true);
            }
          }
        } catch (e) {
          print('Realtime orders callback parsing error: $e');
        }
      },
    ).subscribe();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _ordersChannel.unsubscribe();
    super.dispose();
  }

  Future<void> loadOrders([String? cinemaId, bool silent = false]) async {
    try {
      final supabase = _ref.read(supabaseServiceProvider);
      final auth = _ref.read(authProvider);
      final userId = auth.userId;
      final phone = auth.phone;
      
      final selection = _ref.read(seatSelectionProvider);
      final effectiveCinemaId = cinemaId ?? selection.hallId;

      final rawOrders = await supabase.fetchOrders(
        cinemaId: effectiveCinemaId,
        customerId: userId,
        customerPhone: phone,
      );
      final seenIds = <String>{};
      final seenDisplayIds = <String>{};
      final uniqueOrders = <OrderModel>[];

      for (final data in rawOrders) {
        final order = OrderModel.fromMap(data);
        if (seenIds.add(order.id) &&
            (order.displayId.isEmpty || seenDisplayIds.add(order.displayId))) {
          uniqueOrders.add(order);
        }
      }

      // Preserve any local optimistic/syncing orders that haven't persisted yet
      for (final localOrder in state) {
        if (localOrder.isSyncing || localOrder.id.startsWith('TEMP-')) {
          if (!uniqueOrders.any((o) =>
              (o.displayId.isNotEmpty && o.displayId == localOrder.displayId) ||
              (o.clientUuid != null && localOrder.clientUuid != null && o.clientUuid == localOrder.clientUuid))) {
            uniqueOrders.insert(0, localOrder);
          }
        }
      }

      state = uniqueOrders;
    } catch (e) {
      if (!silent) print('Error loading orders: $e');
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
        
        // Ensure the profile has the latest phone number from checkout
        try {
           final authSvc = _ref.read(authServiceProvider);
           final authState = _ref.read(authProvider);
           final names = authState.userName?.split(' ') ?? ['User', ''];
           final firstName = names.isNotEmpty ? names.first : 'User';
           final lastName = names.length > 1 ? names.skip(1).join(' ') : '';
           final data = {
             'id': userId,
             'user_id': userId,
             'phone': customerPhone,
             'first_name': firstName,
             'last_name': lastName.isEmpty ? 'User' : lastName,
             'password': 'OAUTH_LOGIN',
           };
           // We only attempt upsert if auth provider doesn't have a phone yet, or just do it silently
           await authSvc.client.from('customer_profiles').upsert(data, onConflict: 'id');
           
           // If they didn't have a phone in state, trigger an auth refresh
           if (_ref.read(authProvider).phone == null || _ref.read(authProvider).phone!.isEmpty) {
              _ref.read(authServiceProvider).client.auth.refreshSession();
           }
        } catch (e) {
           print('Silent profile upsert error: $e');
        }
      }

      // Update state with the real UUID from the database and prevent duplicates
      final deduplicated = <OrderModel>[];
      final seenIds = <String>{};
      final seenDisplayIds = <String>{};

      for (final order in state) {
        final resolvedOrder = (order.id == newOrder.id ||
                (order.displayId.isNotEmpty && order.displayId == displayId) ||
                (clientUuid.isNotEmpty && order.clientUuid == clientUuid))
            ? order.copyWith(id: realId, isSyncing: false)
            : order;

        if (seenIds.add(resolvedOrder.id) &&
            (resolvedOrder.displayId.isEmpty || seenDisplayIds.add(resolvedOrder.displayId))) {
          deduplicated.add(resolvedOrder);
        }
      }
      state = deduplicated;

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
