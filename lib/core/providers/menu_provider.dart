import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_item.dart';
import 'supabase_provider.dart';
import 'auth_provider.dart';
import '../services/cache_service.dart';
import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'cart_provider.dart';


class MenuState {
  final List<FoodItem> items;
  final bool isLoading;

  const MenuState({
    this.items = const [],
    this.isLoading = false,
  });

  MenuState copyWith({
    List<FoodItem>? items,
    bool? isLoading,
  }) {
    return MenuState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class MenuNotifier extends StateNotifier<MenuState> {
  final Ref _ref;

  MenuNotifier(this._ref) : super(const MenuState()) {
    // Session Protection: Clear menu on logout
    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.UNAUTHENTICATED && state.items.isNotEmpty) {
        state = const MenuState();
      }
    });
    _initializeRealtime();
  }

  RealtimeChannel? _menuChannel;

  void _initializeRealtime() {
    _menuChannel = Supabase.instance.client
        .channel('public:menu_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'food_items',
          callback: (payload) {
            final updated = FoodItem.fromMap(payload.newRecord);
            print('🔔 Realtime Menu Update: ${updated.name} (Available: ${updated.isAvailable})');
            _updateItemAvailability(updated.id, updated.isAvailable);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'combos',
          callback: (payload) {
            final updatedId = payload.newRecord['id'].toString();
            final isAvailable = payload.newRecord['is_available'] as bool;
            print('🔔 Realtime Combo Update: $updatedId (Available: $isAvailable)');
            _updateComboAvailability(updatedId, isAvailable);
          },
        )
        .subscribe();
  }

  void _updateItemAvailability(String id, bool isAvailable) {
    state = state.copyWith(items: [
      for (final item in state.items)
        if (item.id == id) item.copyWith(isAvailable: isAvailable) else item,
    ]);
    // Check cart
    _ref.read(cartProvider.notifier).validateAvailability(state.items);
  }

  void _updateComboAvailability(String comboId, bool isAvailable) {
    // Note: This logic assumes we might need to update state if we had a combos list
    // For now, primarily trigger cart validation
    _ref.read(cartProvider.notifier).validateAvailability(state.items);
  }

  @override
  void dispose() {
    if (_menuChannel != null) Supabase.instance.client.removeChannel(_menuChannel!);
    super.dispose();
  }

  Future<void> refreshMenu(String cinemaId) async {
    if (cinemaId.isEmpty) return;

    // 1. Try Loading from Cache first (Instant UI)
    final cachedData = await cacheService.getCachedMenu(cinemaId);
    if (cachedData != null) {
      final cachedItems = cachedData.map((item) => FoodItem.fromMap(item)).toList();
      state = state.copyWith(items: cachedItems, isLoading: false);
      print('📦 Menu loaded from CACHE for $cinemaId');
    } else {
      state = state.copyWith(isLoading: true);
    }

    // 2. Revalidate from Network in background
    try {
      final supabase = _ref.read(supabaseServiceProvider);
      final newItems = await supabase.fetchMenu(cinemaId);
      final List rawData = newItems.map((i) => i.toMap()).toList();

      // 3. Only update state if data actually changed to avoid flicker
      if (_hasDataChanged(cachedData, rawData)) {
        state = state.copyWith(items: newItems, isLoading: false);
        await cacheService.cacheMenu(cinemaId, rawData);
        print('🌐 Menu updated from NETWORK (via API) for $cinemaId');
      }
    } catch (e) {
      print('Error revalidating menu for $cinemaId: $e');
      if (state.items.isEmpty) {
        state = state.copyWith(items: _getMockData(), isLoading: false);
      }
    }
  }

  bool _hasDataChanged(dynamic cached, dynamic fresh) {
    if (cached == null) return true;
    return jsonEncode(cached) != jsonEncode(fresh);
  }

  List<FoodItem> _getMockData() {
    return [
      FoodItem(
        id: 'mock-1',
        name: 'Signature Popcorn',
        description: 'Classic buttered popcorn',
        price: 250,
        imageUrl: 'https://images.unsplash.com/photo-1572177191856-3cde618dee1f?w=400',
        category: 'POPCORN',
      ),
      FoodItem(
        id: 'mock-2',
        name: 'Gourmet Nachos',
        description: 'Loaded with cheese and jalapenos',
        price: 350,
        imageUrl: 'https://images.unsplash.com/photo-1513456852971-30c0b8199d4d?w=400',
        category: 'SNACKS',
      ),
    ];
  }

  Future<void> addItem(FoodItem item) async {
    state = state.copyWith(items: [...state.items, item]);
  }

  Future<void> updateItem(FoodItem item) async {
    state = state.copyWith(items: [
      for (final existing in state.items)
        if (existing.id == item.id) item else existing,
    ]);
  }

  Future<void> deleteItem(String id) async {
    state = state.copyWith(items: state.items.where((item) => item.id != id).toList());
  }

  Future<void> toggleAvailability(String id) async {
    state = state.copyWith(items: [
      for (final item in state.items)
        if (item.id == id)
          item.copyWith(isAvailable: !item.isAvailable)
        else
          item,
    ]);
  }
}

final menuProvider = StateNotifierProvider<MenuNotifier, MenuState>((ref) {
  return MenuNotifier(ref);
});
