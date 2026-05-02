import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../models/order_model.dart';
import 'seat_selection_provider.dart';
import 'auth_provider.dart';
import 'loyalty_provider.dart';
import 'supabase_provider.dart';

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
    Future.microtask(() => loadOrders());
  }

  void _initializeRealtimeSubscription() {
    _ordersChannel = Supabase.instance.client.channel('public:orders');

    _ordersChannel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'orders',
      callback: (payload) {
        print('Realtime change received: ${payload.eventType}');
        // Reload orders when any change occurs in the 'orders' table
        final hallId = _ref.read(seatSelectionProvider).hallId;
        loadOrders(hallId);
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

  Future<void> placeOrder(
    List<OrderItem> items,
    double total,
    String location, {
    required PaymentMethod paymentMethod,
    required String customerPhone,
    int pointsRedeemed = 0,
  }) async {
    final selection = _ref.read(seatSelectionProvider);
    final cinemaId = selection.hallId;
    
    if (cinemaId == null) return;
    
    final auth = _ref.read(authProvider);
    final userId = auth.userId;
    
    // Calculate loyalty
    final loyalty = _ref.read(loyaltyProvider.notifier);
    final pointsEarned = loyalty.calculateEarnedPoints(total);
    final redeemedValue = loyalty.calculateRedeemableValue(pointsRedeemed);

    // Generate unique display ID: OUTLET-CUST-TIME (e.g. C1-U1-4567)
    final shortCinemaId = cinemaId.substring(0, 4).toUpperCase();
    final shortPhone = customerPhone.length > 4 ? customerPhone.substring(customerPhone.length - 4) : 'GUEST';
    final timestampStr = DateTime.now().millisecondsSinceEpoch.toString();
    final shortTime = timestampStr.substring(timestampStr.length - 4);
    final displayId = '$shortCinemaId-$shortPhone-$shortTime';

    final newOrder = OrderModel(
      id: 'TEMP-${DateTime.now().millisecondsSinceEpoch}',
      displayId: displayId,
      items: items,
      totalAmount: total,
      status: OrderStatus.PENDING,
      timestamp: DateTime.now(),
      location: location,
      paymentStatus: PaymentStatus.SUCCESS,
      paymentMethod: paymentMethod,
      customerPhone: customerPhone,
      pointsEarned: pointsEarned,
      pointsRedeemed: pointsRedeemed,
    );

    // Optimistic UI update
    state = [newOrder, ...state];

    try {
      final supabase = _ref.read(supabaseServiceProvider);
      final realId = await supabase.placeOrder(
        cinemaId: cinemaId,
        items: items.map((i) => i.toMap()).toList(),
        totalAmount: total,
        location: location,
        customerPhone: customerPhone,
        displayId: displayId,
        authUserId: auth.isDemo ? null : userId,
        customerProfileId: auth.isDemo ? userId : null,
      );
      
      // Handle Loyalty Transaction atomically in DB
      if (userId != null) {
        await supabase.processLoyaltyOrder(
          userId: userId,
          orderId: realId,
          pointsRedeemed: pointsRedeemed,
          redeemedValue: redeemedValue,
          pointsEarned: pointsEarned,
        );
        // Refresh wallet
        await _ref.read(loyaltyProvider.notifier).fetchWallet();
      }

      // Update state with the real UUID from the database
      state = [
        for (final order in state)
          if (order.id == newOrder.id) order.copyWith(id: realId) else order
      ];
    } catch (e) {
      print('Error placing order: $e');
      // On error, remove the optimistic order
      state = state.where((o) => o.id != newOrder.id).toList();
    }
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    state = [
      for (final order in state)
        if (order.id == orderId) order.copyWith(status: status) else order,
    ];
  }
}

final ordersProvider = StateNotifierProvider<OrdersNotifier, List<OrderModel>>((ref) {
  return OrdersNotifier(ref);
});
