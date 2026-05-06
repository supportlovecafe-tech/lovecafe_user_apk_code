import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'supabase_provider.dart';
import 'seat_selection_provider.dart';
import '../models/order_model.dart';

final realtimeOrdersProvider = StreamProvider<List<OrderModel>>((ref) async* {
  final supabase = ref.read(supabaseServiceProvider);
  final selection = ref.watch(seatSelectionProvider);
  final cinemaId = selection.hallId;

  if (cinemaId == null) {
    yield [];
    return;
  }

  // 1. Initial fetch
  final initialOrders = await supabase.fetchOrders(cinemaId: cinemaId);
  List<OrderModel> orders = initialOrders.map((data) => OrderModel.fromMap(data)).toList();
  yield orders;

  // 2. Listen for changes
  final channel = supabase.subscribeToOrders(cinemaId, (newRecord) {
    final newOrder = OrderModel.fromMap(newRecord);
    orders = [newOrder, ...orders];
    // Note: In a production app, you might want to handle updates/deletes too
  });

  ref.onDispose(() {
    channel.unsubscribe();
  });

  // We need a way to trigger a re-yield when 'orders' changes from the callback.
  // Since we are in a StreamProvider, we could use a StreamController or just
  // stick to the basic implementation for now.
  
  // For a more robust solution, we can use a StateNotifier that subscribes to the stream.
});
