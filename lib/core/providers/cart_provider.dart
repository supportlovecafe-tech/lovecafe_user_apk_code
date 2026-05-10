import 'seat_selection_provider.dart';
import '../models/cart_breakdown.dart';
import '../services/supabase_service.dart';

class CartItem {
  final FoodItem foodItem;
  final int quantity;
  final String? note;
  // Feature 2: combo tracking
  final bool isCombo;
  final String? comboId;
  final String? comboName;

  CartItem({
    required this.foodItem,
    required this.quantity,
    this.note,
    this.isCombo = false,
    this.comboId,
    this.comboName,
  });

  CartItem copyWith({int? quantity, String? note}) {
    return CartItem(
      foodItem: foodItem,
      quantity: quantity ?? this.quantity,
      note: note ?? this.note,
      isCombo: isCombo,
      comboId: comboId,
      comboName: comboName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'foodItem': foodItem.toMap(),
      'quantity': quantity,
      'note': note,
      'isCombo': isCombo,
      'comboId': comboId,
      'comboName': comboName,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      foodItem: FoodItem.fromMap(map['foodItem']),
      quantity: map['quantity'],
      note: map['note'],
      isCombo: map['isCombo'] as bool? ?? false,
      comboId: map['comboId'],
      comboName: map['comboName'],
    );
  }
}

class CartState {
  final List<CartItem> items;
  final CartBreakdown breakdown;
  final bool isValidating;

  CartState({
    required this.items,
    required this.breakdown,
    this.isValidating = false,
  });

  CartState copyWith({
    List<CartItem>? items,
    CartBreakdown? breakdown,
    bool? isValidating,
  }) {
    return CartState(
      items: items ?? this.items,
      breakdown: breakdown ?? this.breakdown,
      isValidating: isValidating ?? this.isValidating,
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  final Ref _ref;
  final String? _userId;
  String get _storageKey => 'ce_cart_${_userId ?? 'guest'}';

  CartNotifier(this._ref, this._userId) : super(CartState(items: [], breakdown: CartBreakdown())) {
    _loadCart();
    
    // Multi-Outlet Protection: 
    _ref.listen<SeatSelectionState>(seatSelectionProvider, (previous, next) {
      if (previous?.hallId != next.hallId && next.hallId != null && state.items.isNotEmpty) {
        state = state.copyWith(items: []);
        _saveCart();
        _fetchBreakdown();
      }
    });
  }

  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageKey);
    if (saved != null) {
      try {
        final List<dynamic> decoded = jsonDecode(saved);
        final items = decoded.map((item) => CartItem.fromMap(item)).toList();
        state = state.copyWith(items: items);
        _fetchBreakdown();
      } catch (e) {
        print('Error loading cart: $e');
      }
    }
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(state.items.map((e) => e.toMap()).toList()));
  }

  Future<void> _fetchBreakdown() async {
    if (state.items.isEmpty) {
        state = state.copyWith(breakdown: CartBreakdown(), isValidating: false);
        return;
    }

    state = state.copyWith(isValidating: true);
    try {
        final cinemaId = _ref.read(seatSelectionProvider).hallId;
        
        // Prepare items for API
        final apiItems = state.items.map((i) => {
            'id': i.isCombo ? i.comboId : i.foodItem.id,
            'name': i.isCombo ? i.comboName : i.foodItem.name,
            'quantity': i.quantity,
            'is_combo': i.isCombo
        }).toList();

        final response = await supabaseService.validateOrder(apiItems, cinemaId);
        
        if (response.containsKey('breakdown')) {
            state = state.copyWith(
                breakdown: CartBreakdown.fromMap(response['breakdown']),
                isValidating: false,
            );
        }
    } catch (e) {
        print('Error fetching breakdown: $e');
        // Local fallback if API fails
        final st = state.items.fold(0.0, (sum, item) => sum + (item.foodItem.price * item.quantity));
        state = state.copyWith(
            breakdown: CartBreakdown(
                subtotal: st,
                cgst: st * 0.025,
                sgst: st * 0.025,
                platformCharges: st * 0.01,
                total: st * 1.06,
            ),
            isValidating: false,
        );
    }
  }

  void addItem(FoodItem item) {
    if (state.items.isNotEmpty && item.cinemaId != null) {
      final existingCinemaId = state.items.first.foodItem.cinemaId;
      if (existingCinemaId != null && existingCinemaId != item.cinemaId) {
        state = state.copyWith(items: []);
      }
    }

    final existingIndex =
        state.items.indexWhere((element) => element.foodItem.id == item.id && !element.isCombo);
    if (existingIndex != -1) {
      state = state.copyWith(items: [
        for (int i = 0; i < state.items.length; i++)
          if (i == existingIndex)
            state.items[i].copyWith(quantity: state.items[i].quantity + 1)
          else
            state.items[i]
      ]);
    } else {
      state = state.copyWith(items: [...state.items, CartItem(foodItem: item, quantity: 1, note: null)]);
    }
    _saveCart();
    _fetchBreakdown();
  }

  /// Feature 2: Add a combo as a single cart entry.
  /// Each combo is treated as a distinct item (using comboId as unique key).
  void addCombo(ComboMeal combo) {
    // Build a synthetic FoodItem to represent the combo in cart
    final comboAsFood = FoodItem(
      id: 'combo-${combo.id}',
      cinemaId: combo.cinemaId,
      name: combo.name,
      description: combo.description,
      price: combo.price,
      imageUrl: combo.imageUrl,
      category: combo.category,
    );

    final existingIndex = state.indexWhere(
      (element) => element.isCombo && element.comboId == combo.id,
    );

    if (existingIndex != -1) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == existingIndex)
            CartItem(
              foodItem: comboAsFood,
              quantity: state[i].quantity + 1,
              isCombo: true,
              comboId: combo.id,
              comboName: combo.name,
            )
          else
            state[i]
      ];
    } else {
      state = [
        ...state,
        CartItem(
          foodItem: comboAsFood,
          quantity: 1,
          isCombo: true,
          comboId: combo.id,
          comboName: combo.name,
        ),
      ];
    }
    _saveCart();
  }

  void validateAndAddItem(FoodItem item, String? currentHallId) {
    addItem(item);
  }

  void removeItem(String itemId) {
    state = state.copyWith(items: state.items.where((element) => element.foodItem.id != itemId).toList());
    _saveCart();
    _fetchBreakdown();
  }

  void updateQuantity(String itemId, int delta) {
    final List<CartItem> newItems = [];
    for (final item in state.items) {
      if (item.foodItem.id == itemId) {
        final newQty = item.quantity + delta;
        if (newQty > 0) {
          newItems.add(item.copyWith(quantity: newQty));
        }
      } else {
        newItems.add(item);
      }
    }
    state = state.copyWith(items: newItems);
    _saveCart();
    _fetchBreakdown();
  }

  void updateItemNote(String itemId, String? note) {
    state = state.copyWith(items: [
      for (final item in state.items)
        if (item.foodItem.id == itemId) item.copyWith(note: note) else item
    ]);
    _saveCart();
  }

  double get subtotal => state.breakdown.subtotal;
  double get cgst => state.breakdown.cgst;
  double get sgst => state.breakdown.sgst;
  double get platformCharges => state.breakdown.platformCharges;
  double get totalAmount => state.breakdown.total;

  void validateAvailability(List<FoodItem> freshMenu) {
    if (state.isEmpty) return;
    
    final List<CartItem> availableItems = [];
    bool changed = false;

    for (final item in state) {
      if (item.isCombo) {
         // Combos might need separate validation if we have a combos list
         // For now keep them, or we could fetch availability via RPC
         availableItems.add(item);
         continue;
      }

      final fresh = freshMenu.firstWhere((i) => i.id == item.foodItem.id, orElse: () => item.foodItem);
      if (fresh.isAvailable) {
        availableItems.add(item);
      } else {
        changed = true;
        print('🚫 Item ${item.foodItem.name} became unavailable. Removing from cart.');
      }
    }

    if (changed) {
      state = availableItems;
      _saveCart();
    }
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
