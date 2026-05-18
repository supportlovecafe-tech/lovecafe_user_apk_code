import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'seat_selection_provider.dart';

/// Riverpod future provider that fetches all active promotional campaigns
/// for the customer's currently selected cinema outlet.
final offersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final selection = ref.watch(seatSelectionProvider);
  if (selection.hallId == null) {
    return [];
  }

  try {
    final response = await Supabase.instance.client
        .from('offers')
        .select('*, offer_items(food_item_id)')
        .eq('cinema_id', selection.hallId!)
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    print('[offersProvider] Error fetching active offers: $e');
    return [];
  }
});
