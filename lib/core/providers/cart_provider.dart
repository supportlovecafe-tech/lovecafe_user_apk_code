import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_item.dart';
import 'seat_selection_provider.dart';

class CartItem {
  final FoodItem foodItem;
  final int quantity;
  final String? note;

  CartItem({required this.foodItem, required this.quantity, this.note});

  CartItem copyWith({int? quantity, String? note}) {
    return CartItem(
      foodItem: foodItem,
      quantity: quantity ?? this.quantity,
      note: note ?? this.note,
    );
  }
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  final Ref _ref;

  CartNotifier(this._ref) : super([]) {
    // Multi-Outlet Protection: 
    // Listen to seat selection. If hallId changes, clear cart to prevent mixed-outlet orders.
    _ref.listen<SeatSelectionState>(seatSelectionProvider, (previous, next) {
      if (previous?.hallId != next.hallId && next.hallId != null && state.isNotEmpty) {
        state = [];
      }
    });
  }

  void addItem(FoodItem item) {
    // Final safety check: if item is from a different cinema than what's in cart, clear cart
    if (state.isNotEmpty && item.cinemaId != null) {
      final existingCinemaId = state.first.foodItem.cinemaId;
      if (existingCinemaId != null && existingCinemaId != item.cinemaId) {
        state = [];
      }
    }

    final existingIndex =
        state.indexWhere((element) => element.foodItem.id == item.id);
    if (existingIndex != -1) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == existingIndex)
            state[i].copyWith(quantity: state[i].quantity + 1)
          else
            state[i]
      ];
    } else {
      state = [...state, CartItem(foodItem: item, quantity: 1, note: null)];
    }
  }

  void validateAndAddItem(FoodItem item, String? currentHallId) {
    // This is now redundant but kept for compatibility with UI code
    // The constructor listener handles the core logic
    addItem(item);
  }

  void removeItem(String itemId) {
    state = state.where((element) => element.foodItem.id != itemId).toList();
  }

  void updateQuantity(String itemId, int delta) {
    final List<CartItem> newState = [];
    for (final item in state) {
      if (item.foodItem.id == itemId) {
        final newQty = item.quantity + delta;
        if (newQty > 0) {
          newState.add(item.copyWith(quantity: newQty));
        }
        // If newQty <= 0, we don't add it to newState, effectively removing it
      } else {
        newState.add(item);
      }
    }
    state = newState;
  }

  void updateItemNote(String itemId, String? note) {
    state = [
      for (final item in state)
        if (item.foodItem.id == itemId) item.copyWith(note: note) else item
    ];
  }

  double get totalAmount {
    return state.fold(
        0, (sum, item) => sum + (item.foodItem.price * item.quantity));
  }

  void clearCart() {
    state = [];
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier(ref);
});
