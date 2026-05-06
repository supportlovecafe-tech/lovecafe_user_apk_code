import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/food_item.dart';
import '../models/cinema_hall.dart';

class SupabaseService {
  SupabaseClient get _client => Supabase.instance.client;

  // --- Cinemas (Tenants) ---
  
  Future<List<CinemaHall>> fetchCinemas() async {
    final response = await _client
        .from('cinemas')
        .select('*, screens(*)');
    
    return (response as List).map((data) => CinemaHall.fromMap(data)).toList();
  }

  // --- Menu (Food Items) ---

  Future<List<FoodItem>> fetchMenu(String cinemaId) async {
    if (cinemaId.isEmpty) return [];
    
    try {
      print('Fetching menu for cinemaId: $cinemaId');
      final response = await _client
          .from('food_items')
          .select('*')
          .eq('cinema_id', cinemaId);
      
      if (response == null) {
        print('fetchMenu: Response is null');
        return [];
      }
      
      final List data = response as List;
      print('fetchMenu SUCCESS: Found ${data.length} items for cinema $cinemaId');
      if (data.isNotEmpty) {
        print('First item sample: ${data.first}');
      }
      
      return data.map((item) => FoodItem.fromMap(item)).toList();
    } catch (e) {
      print('SupabaseService.fetchMenu error: $e');
      return [];
    }
  }

  // --- Orders ---

  Future<String> placeOrder({
    required String cinemaId,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required String location,
    required String customerPhone,
    required String displayId,
    String? authUserId,
    String? customerProfileId,
  }) async {
    final orderData = {
      'cinema_id': cinemaId,
      'display_id': displayId, // Correctly using the passed client-side ID
      'items': items,
      'total_amount': totalAmount,
      'location': location,
      'customer_phone': customerPhone,
      'status': 'PENDING',
      'payment_status': 'PAID',
      'payment_method': 'DEMO_UPI',
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'is_demo_order': true,
    };

    // If it's a real Auth user, use customer_id
    if (authUserId != null && !authUserId.startsWith('TEMP')) {
      orderData['customer_id'] = authUserId;
    }
    
    // If it's a Demo user (from customer_profiles)
    if (customerProfileId != null && customerProfileId.length > 20) {
      orderData['customer_profile_id'] = customerProfileId;
    }

    try {
      final response = await _client.from('orders').insert(orderData).select('id').single();
      return response['id'].toString();
    } catch (e) {
      print('SupabaseService.placeOrder error: $e');
      rethrow;
    }
  }

  Future<void> processLoyaltyOrder({
    required String userId,
    required String orderId,
    required int pointsRedeemed,
    required int pointsEarned,
  }) async {
    try {
      await _client.rpc('process_loyalty_order', params: {
        'p_user_id': userId,
        'p_order_id': orderId,
        'p_points_redeemed': pointsRedeemed,
        'p_points_earned': pointsEarned,
      });
    } catch (e) {
      print('SupabaseService.processLoyaltyOrder error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchOrders({String? cinemaId, String? customerId, String? customerPhone}) async {
    var query = _client.from('orders').select('*');
    
    if (cinemaId != null) {
      query = query.eq('cinema_id', cinemaId);
    }
    
    if (customerId != null && customerPhone != null) {
      query = query.or('customer_id.eq.$customerId,customer_phone.eq.$customerPhone');
    } else if (customerId != null) {
      query = query.eq('customer_id', customerId);
    } else if (customerPhone != null) {
      query = query.eq('customer_phone', customerPhone);
    }

    final response = await query.order('timestamp', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> fetchCinePointsHistory(String userId) async {
    try {
      final response = await _client
          .from('loyalty_transactions')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('SupabaseService.fetchCinePointsHistory error: $e');
      return [];
    }
  }

  // --- Real-time Subscription ---
  
  RealtimeChannel subscribeToOrders(String cinemaId, void Function(Map<String, dynamic>) onChange) {
    return _client
        .channel('orders-sync')
        .onPostgresChanges(
          event: PostgresChangeEvent.all, // Listen to updates for tracking!
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'cinema_id',
            value: cinemaId,
          ),
          callback: (payload) {
            if (payload.newRecord.isNotEmpty) {
              onChange(payload.newRecord);
            }
          },
        )
        .subscribe();
  }
}

final supabaseService = SupabaseService();
