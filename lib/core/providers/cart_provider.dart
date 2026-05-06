import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food_item.dart';
import 'auth_provider.dart';
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

  Map<String, dynamic> toMap() {
    return {
      'foodItem': foodItem.toMap(),
      'quantity': quantity,
      'note': note,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      foodItem: FoodItem.fromMap(map['foodItem']),
      quantity: map['quantity'],
      note: map['note'],
    );
  }
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  final Ref _ref;
  final String? _userId;
  String get _storageKey => 'ce_cart_${_userId ?? 'guest'}';

  CartNotifier(this._ref, this._userId) : super([]) {
    _loadCart();
    
    // Multi-Outlet Protection: 
    _ref.listen<SeatSelectionState>(seatSelectionProvider, (previous, next) {
      if (previous?.hallId != next.hallId && next.hallId != null && state.isNotEmpty) {
        state = [];
        _saveCart();
      }
    });
  }

  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageKey);
    if (saved != null) {
      try {
        final List<dynamic> decoded = jsonDecode(saved);
        state = decoded.map((item) => CartItem.fromMap(item)).toList();
      } catch (e) {
        print('Error loading cart: $e');
      }
    }
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(state.map((e) => e.toMap()).toList()));
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
    _saveCart();
  }

  void validateAndAddItem(FoodItem item, String? currentHallId) {
    addItem(item);
  }

  void removeItem(String itemId) {
    state = state.where((element) => element.foodItem.id != itemId).toList();
    _saveCart();
  }

  void updateQuantity(String itemId, int delta) {
    final List<CartItem> newState = [];
    for (final item in state) {
      if (item.foodItem.id == itemId) {
        final newQty = item.quantity + delta;
        if (newQty > 0) {
          newState.add(item.copyWith(quantity: newQty));
        }
      } else {
        newState.add(item);
      }
    }
    state = newState;
    _saveCart();
  }

  void updateItemNote(String itemId, String? note) {
    state = [
      for (final item in state)
        if (item.foodItem.id == itemId) item.copyWith(note: note) else item
    ];
    _saveCart();
  }

  double get totalAmount {
    return state.fold(
        0, (sum, item) => sum + (item.foodItem.price * item.quantity));
  }

  void clearCart() {
    state = [];
    _saveCart();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  final auth = ref.watch(authProvider);
  return CartNotifier(ref, auth.userId);
});
