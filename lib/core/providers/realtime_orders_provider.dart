import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_provider.dart';
import 'seat_selection_provider.dart';
import '../models/order_model.dart';

final realtimeOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final supabase = ref.read(supabaseServiceProvider);
  final selection = ref.watch(seatSelectionProvider);
  final cinemaId = selection.hallId;

  if (cinemaId == null) {
    return Stream.value([]);
  }

  final controller = StreamController<List<OrderModel>>();
  List<OrderModel> orders = [];

  // 1. Initial Load
  supabase.fetchOrders(cinemaId: cinemaId).then((data) {
    orders = data.map((d) => OrderModel.fromMap(d)).toList();
    if (!controller.isClosed) controller.add(orders);
  });

  // 2. Realtime Listen
  final channel = Supabase.instance.client
      .channel('realtime-orders-swr')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'orders',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'cinema_id',
          value: cinemaId,
        ),
        callback: (payload) {
          final newRecord = payload.newRecord;
          if (newRecord.isEmpty) return;
          final updatedOrder = OrderModel.fromMap(newRecord);

          if (payload.eventType == PostgresChangeEvent.insert) {
            if (!orders.any((o) => o.id == updatedOrder.id)) {
              orders = [updatedOrder, ...orders];
            }
          } else if (payload.eventType == PostgresChangeEvent.update) {
            orders = [
              for (final order in orders)
                if (order.id == updatedOrder.id) updatedOrder else order
            ];
          }
          
          if (!controller.isClosed) controller.add(orders);
        },
      )
      .subscribe();

  ref.onDispose(() {
    channel.unsubscribe();
    controller.close();
  });

  return controller.stream;
});
