import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';
import 'backend_config.dart';
import '../models/food_item.dart';
import '../models/cinema_hall.dart';
import '../models/combo_model.dart';
import '../providers/reorder_provider.dart';
import '../models/order_model.dart';

class SupabaseService {
  final _client = Supabase.instance.client;
  final _dio = Dio(BaseOptions(
    baseUrl: BackendConfig.backendApiUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

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
      final response = await _dio.get('/api/menu', queryParameters: {'cinemaId': cinemaId});
      final List data = response.data as List;
      return data.map((item) => FoodItem.fromMap(item)).toList();
    } catch (e) {
      print('Error fetching menu via API, falling back to Supabase: $e');
      final response = await _client
          .from('food_items')
          .select('*')
          .or('cinema_id.eq.$cinemaId,cinema_id.is.null')
          .eq('is_available', true);
      return (response as List).map((data) => FoodItem.fromMap(data)).toList();
    }
  }

  // --- Combos (Feature 2) ---

  Future<List<ComboMeal>> fetchCombos(String cinemaId) async {
    if (cinemaId.isEmpty) return [];
    try {
      final response = await _dio.get('/api/combos', queryParameters: {'cinemaId': cinemaId});
      final List data = response.data as List;
      return data.map((item) => ComboMeal.fromMap(item)).toList();
    } catch (e) {
      print('Error fetching combos via API, falling back to Supabase: $e');
      final response = await _client
          .from('combos')
          .select('*, combo_items(*)')
          .eq('cinema_id', cinemaId)
          .eq('is_available', true);
      return (response as List).map((data) => ComboMeal.fromMap(data)).toList();
    }
  }

  // --- Orders ---

  Future<Map<String, dynamic>> validateOrder(List<Map<String, dynamic>> items, String? cinemaId) async {
    try {
      final response = await _dio.post('/api/orders/validate', data: {
        'items': items,
        'cinema_id': cinemaId,
      });
      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('SupabaseService.validateOrder error: $e');
      rethrow;
    }
  }

  Future<String> placeOrder({
    required String cinemaId,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required String location,
    required String customerPhone,
    required String displayId,
    required PaymentMethod paymentMethod,
    int? pointsRedeemed,
    int? pointsEarned,
    String? authUserId,
    String? customerProfileId,
    String? clientUuid,
    Map<String, dynamic>? metadata,
  }) async {
    final orderData = {
      'cinema_id': cinemaId,
      'display_id': displayId,
      'items': items,
      'total_amount': totalAmount,
      'location': "APK, ${location.replaceAll(' • ', ', ')}",
      'customer_phone': customerPhone,
      'points_redeemed': pointsRedeemed ?? 0,
      'points_earned': pointsEarned ?? 0,
      'status': 'PENDING',
      'payment_status': 'PAID',
      'payment_method': paymentMethod.name,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'is_demo_order': true,
      'client_uuid': clientUuid,
      'metadata': metadata,
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
      print('Calling Next.js Backend API for secure order placement...');
      
      final token = _client.auth.currentSession?.accessToken;

      final response = await _dio.post(
        '/api/orders/create',
        data: orderData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'x-idempotency-key': clientUuid ?? DateTime.now().toIso8601String(),
          },
        ),
      );
      
      if (response.data['success'] == true) {
         print('API Order Success: ${response.data['id']}');
         return response.data['id'].toString();
      } else {
         throw Exception(response.data['error'] ?? 'Order failed via API');
      }
    } catch (e) {
      print('SupabaseService.placeOrder API ERROR: $e');
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
    // Build the base filter query first, THEN apply ordering
    var query = _client.from('orders').select('*');
    
    if (cinemaId != null) {
      query = query.eq('cinema_id', cinemaId);
    }
    
    if (customerId != null && !customerId.startsWith('TEMP')) {
      if (customerPhone != null) {
        query = query.or('customer_id.eq.$customerId,customer_phone.eq.$customerPhone');
      } else {
        query = query.eq('customer_id', customerId);
      }
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

  // --- Feature 3: Reorder Suggestions ---

  Future<List<ReorderSuggestion>> fetchReorderSuggestions({
    required String cinemaId,
    String? customerId,
    String? customerPhone,
  }) async {
    if (customerId == null && customerPhone == null) return [];
    try {
      final response = await _dio.get('/api/recommendations', queryParameters: {
        'cinemaId': cinemaId,
        'userId': customerId ?? 'GUEST',
        'phone': customerPhone ?? 'NA',
      });
      final List data = response.data as List;
      return data.map<ReorderSuggestion>((item) => ReorderSuggestion(
        foodId: item['food_id']?.toString() ?? '',
        name: item['food_name']?.toString() ?? '',
        imageUrl: item['food_image']?.toString() ?? '',
        price: (item['food_price'] as num?)?.toDouble() ?? 0,
        category: item['food_category']?.toString() ?? '',
        orderCount: item['count'] as int? ?? 1,
      )).toList();
    } catch (e) {
      print('Error fetching recommendations via API, falling back to Supabase: $e');
      // Fallback to existing direct query logic
      var query = _client
          .from('orders')
          .select('items, timestamp')
          .eq('cinema_id', cinemaId)
          .neq('status', 'CANCELLED');

      if (customerId != null && customerPhone != null) {
        query = query.or('customer_id.eq.$customerId,customer_phone.eq.$customerPhone');
      } else if (customerId != null) {
        query = query.eq('customer_id', customerId);
      } else if (customerPhone != null) {
        query = query.eq('customer_phone', customerPhone);
      }

      final response = await query
          .order('timestamp', ascending: false)
          .limit(30);
      final orders = List<Map<String, dynamic>>.from(response);

      // Aggregate items by food_id with frequency + recency weighting
      final Map<String, _ItemAggregate> aggregates = {};
      for (int orderIdx = 0; orderIdx < orders.length; orderIdx++) {
        final order = orders[orderIdx];
        final rawItems = order['items'] as List<dynamic>? ?? [];
        final recencyWeight = orders.length - orderIdx; // more recent = higher weight

        for (final rawItem in rawItems) {
          final item = rawItem as Map<String, dynamic>;
          final foodId = item['food_id']?.toString() ?? '';
          if (foodId.isEmpty || foodId.startsWith('mock-') || item['is_combo'] == true) continue;

          if (aggregates.containsKey(foodId)) {
            aggregates[foodId]!.count++;
            aggregates[foodId]!.score += recencyWeight;
          } else {
            aggregates[foodId] = _ItemAggregate(
              foodId: foodId,
              name: item['food_name']?.toString() ?? '',
              imageUrl: item['food_image']?.toString() ?? '',
              price: (item['food_price'] as num?)?.toDouble() ?? 0,
              category: item['food_category']?.toString() ?? '',
              count: 1,
              score: recencyWeight.toDouble(),
            );
          }
        }
      }

      // Sort by score (recency × frequency), take top 5
      final sorted = aggregates.values.toList()
        ..sort((a, b) => b.score.compareTo(a.score));

      return sorted.take(5).map<ReorderSuggestion>((agg) => ReorderSuggestion(
        foodId: agg.foodId,
        name: agg.name,
        imageUrl: agg.imageUrl,
        price: agg.price,
        category: agg.category,
        orderCount: agg.count,
      )).toList();
    } catch (e) {
      print('SupabaseService.fetchReorderSuggestions error: $e');
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

/// Internal aggregation helper
class _ItemAggregate {
  final String foodId;
  final String name;
  final String imageUrl;
  final double price;
  final String category;
  int count;
  double score;

  _ItemAggregate({
    required this.foodId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.category,
    required this.count,
    required this.score,
  });
}

final supabaseService = SupabaseService();
