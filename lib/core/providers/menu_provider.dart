import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_item.dart';
import 'supabase_provider.dart';
import 'auth_provider.dart';


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
  }

  Future<void> refreshMenu(String cinemaId) async {
    print('🚨 MENU REFRESH TRIGGERED FOR CINEMA: $cinemaId');
    if (cinemaId.isEmpty) return;
    state = state.copyWith(isLoading: true, items: []);
    try {
      final supabase = _ref.read(supabaseServiceProvider);
      final items = await supabase.fetchMenu(cinemaId);
      state = state.copyWith(items: items);
    } catch (e) {
      print('Error fetching menu for $cinemaId: $e');
      state = state.copyWith(items: []);
    } finally {
      if (state.items.isEmpty) {
        // Fallback to mock data for demo purposes if DB is empty
        state = state.copyWith(
          items: [
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
            FoodItem(
              id: 'mock-3',
              name: 'Cool Blue Mojito',
              description: 'Refreshing summer drink',
              price: 180,
              imageUrl: 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?w=400',
              category: 'BEVERAGES',
            ),
          ],
        );
      }
      state = state.copyWith(isLoading: false);
    }
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
