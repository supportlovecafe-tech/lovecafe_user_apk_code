import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'seat_selection_provider.dart';
import 'auth_provider.dart';
import '../models/food_item.dart';
import '../models/combo_model.dart';
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
  final bool isOffer;
  final String? offerId;

  CartItem({
    required this.foodItem,
    required this.quantity,
    this.note,
    this.isCombo = false,
    this.comboId,
    this.comboName,
    this.isOffer = false,
    this.offerId,
  });

  CartItem copyWith({int? quantity, String? note}) {
    return CartItem(
      foodItem: foodItem,
      quantity: quantity ?? this.quantity,
      note: note ?? this.note,
      isCombo: isCombo,
      comboId: comboId,
      comboName: comboName,
      isOffer: isOffer,
      offerId: offerId,
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
      'isOffer': isOffer,
      'offerId': offerId,
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
      isOffer: map['isOffer'] as bool? ?? false,
      offerId: map['offerId'],
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
        final cinemaId = _ref.read(seatSelectionProvider).hallId ?? 
                         (state.items.isNotEmpty ? state.items.first.foodItem.cinemaId : null);
        
        // Prepare items for API
        final apiItems = state.items.map((i) => {
            'id': i.isCombo ? i.comboId : i.foodItem.id,
            'name': i.isCombo ? i.comboName : i.foodItem.name,
            'quantity': i.quantity,
            'is_combo': i.isCombo,
            'offer_id': i.offerId,
        }).toList();

        final response = await supabaseService.validateOrder(apiItems, cinemaId);
        
        if (response.containsKey('breakdown')) {
            state = state.copyWith(
                breakdown: CartBreakdown.fromMap(response['breakdown']),
                isValidating: false,
            );
        }
    } catch (e) {
        print('Error fetching breakdown from API, using Supabase local fallback: $e');
        // ──────────────────────────────────────────────────────────────────
        // LOCAL OFFER-AWARE FALLBACK: mirrors the backend validate/route.ts
        // Fetches active offers from Supabase directly and applies correct
        // discount logic for BOGO, B2G1, UNLIMITED, FLAT, percentage deals.
        // ──────────────────────────────────────────────────────────────────
        try {
          final cinemaId = _ref.read(seatSelectionProvider).hallId ??
                           (state.items.isNotEmpty ? state.items.first.foodItem.cinemaId : null);

          // Fetch active offers with their mapped items
          List<Map<String, dynamic>> activeOffers = [];
          if (cinemaId != null) {
            final offersResp = await Supabase.instance.client
                .from('offers')
                .select('*, offer_items(food_item_id, custom_price)')
                .eq('cinema_id', cinemaId)
                .eq('is_active', true);
            activeOffers = List<Map<String, dynamic>>.from(offersResp);
          }

          double customPlatformPercent = 1.0;
          List<String> applicableCategories = ['ALL'];
          try {
            final feeResp = await Supabase.instance.client
                .from('global_settings')
                .select('value')
                .eq('key', 'platform_fees')
                .single();
            if (feeResp['value'] != null) {
              final val = Map<String, dynamic>.from(feeResp['value'] as Map);
              customPlatformPercent = (val['online_fee_percent'] as num?)?.toDouble() ?? 1.0;
              applicableCategories = List<String>.from(val['applicable_categories'] ?? ['ALL']);
            }
          } catch (feeErr) {
            print('Could not load global platform fee settings in fallback: $feeErr');
          }

          // Build a set of item IDs and custom prices for each offer
          final offerItemSets = <String, Set<String>>{};
          final offerItemPrices = <String, Map<String, double>>{};
          for (final offer in activeOffers) {
            final offerItemsList = offer['offer_items'] as List? ?? [];
            offerItemSets[offer['id'] as String] = offerItemsList
                .map((oi) => oi['food_item_id'].toString())
                .toSet();
            
            final priceMap = <String, double>{};
            for (final oi in offerItemsList) {
              if (oi['custom_price'] != null) {
                priceMap[oi['food_item_id'].toString()] = (oi['custom_price'] as num).toDouble();
              }
            }
            offerItemPrices[offer['id'] as String] = priceMap;
          }

          double grossSubtotal = 0;
          double totalDiscount = 0;
          double netTaxableSubtotal = 0;
          double netSubtotal = 0;
          double feeTaxableSubtotal = 0;

          for (final cartItem in state.items) {
            final price = cartItem.foodItem.price;
            final quantity = cartItem.quantity;
            final itemGross = price * quantity;
            grossSubtotal += itemGross;

            final itemId = cartItem.isCombo
                ? (cartItem.comboId ?? '')
                : cartItem.foodItem.id;

            // Find best applicable offer
            double bestDiscount = 0;
            for (final offer in activeOffers) {
              final mappedIds = offerItemSets[offer['id'] as String] ?? {};
              if (!mappedIds.contains(itemId)) continue;

              final category = offer['category'] as String? ?? '';
              
              // Only apply UNLIMITED offer if the item was explicitly added via this offer
              if (category == 'UNLIMITED' && cartItem.offerId != offer['id']) {
                continue;
              }

              double currentDiscount = 0;

              switch (category) {
                case 'BUY_1_GET_1':
                  // Every 2 items → 1 free (pay for 1, get 1 free)
                  final freeCount = (quantity ~/ 2) * 1;
                  currentDiscount = freeCount * price;
                  break;
                case 'BUY_1_GET_2':
                  // Every 3 items → 2 free
                  final freeCount = (quantity ~/ 3) * 2;
                  currentDiscount = freeCount * price;
                  break;
                case 'BUY_2_GET_1':
                  // Every 3 items → 1 free
                  final freeCount = (quantity ~/ 3) * 1;
                  currentDiscount = freeCount * price;
                  break;
                case 'UNLIMITED':
                  final customPrice = offerItemPrices[offer['id'] as String]?[itemId];
                  final promoPrice = customPrice ?? (offer['promo_price'] as num?)?.toDouble();
                  if (promoPrice != null && price > promoPrice) {
                    currentDiscount = (price - promoPrice) * quantity;
                  }
                  break;
                case 'FLAT_DISCOUNT':
                  final flatAmt = (offer['flat_discount_amount'] as num?)?.toDouble() ?? 0;
                  currentDiscount = flatAmt.clamp(0, itemGross);
                  break;
                case 'OFFER_OF_THE_DAY':
                case 'OFFER_OF_THE_WEEK':
                case 'OFFER_OF_THE_FESTIVAL':
                case 'OFFER_OF_THE_FILM':
                  final pct = (offer['discount_percentage'] as num?)?.toDouble() ?? 0;
                  final customPrice = offerItemPrices[offer['id'] as String]?[itemId];
                  final promoP = customPrice ?? (offer['promo_price'] as num?)?.toDouble();
                  final flatA = (offer['flat_discount_amount'] as num?)?.toDouble() ?? 0;
                  if (pct > 0) {
                    currentDiscount = itemGross * (pct / 100);
                  } else if (promoP != null && price > promoP) {
                    currentDiscount = (price - promoP) * quantity;
                  } else if (flatA > 0) {
                    currentDiscount = flatA.clamp(0, itemGross);
                  }
                  break;
              }

              if (currentDiscount > bestDiscount) {
                bestDiscount = currentDiscount;
              }
            }

            totalDiscount += bestDiscount;
            final itemNet = itemGross - bestDiscount;
            netSubtotal += itemNet;
            if (cartItem.foodItem.applyGst) {
              netTaxableSubtotal += itemNet;
            }

            final category = (cartItem.foodItem.category).toUpperCase();
            final isCombo = cartItem.isCombo;
            if (applicableCategories.contains('ALL') || (!isCombo && applicableCategories.contains(category))) {
              feeTaxableSubtotal += itemNet;
            }
          }

          final cgst = netTaxableSubtotal * 0.025;
          final sgst = netTaxableSubtotal * 0.025;
          final platformCharges = feeTaxableSubtotal * (customPlatformPercent / 100);
          state = state.copyWith(
            breakdown: CartBreakdown(
              subtotal: grossSubtotal,
              discount: totalDiscount,
              cgst: cgst,
              sgst: sgst,
              platformCharges: platformCharges,
              platformFeePercent: customPlatformPercent,
              total: netSubtotal + cgst + sgst + platformCharges,
            ),
            isValidating: false,
          );
        } catch (fallbackErr) {
          // Last-resort: plain arithmetic, no discounts
          print('Offer-aware fallback also failed: $fallbackErr — using plain subtotal');
          
          double customPlatformPercent = 1.0;
          List<String> applicableCategories = ['ALL'];
          try {
            final feeResp = await Supabase.instance.client
                .from('global_settings')
                .select('value')
                .eq('key', 'platform_fees')
                .single();
            if (feeResp['value'] != null) {
              final val = Map<String, dynamic>.from(feeResp['value'] as Map);
              customPlatformPercent = (val['online_fee_percent'] as num?)?.toDouble() ?? 1.0;
              applicableCategories = List<String>.from(val['applicable_categories'] ?? ['ALL']);
            }
          } catch (feeErr) {
            print('Could not load global platform fee settings in last-resort fallback: $feeErr');
          }

          final st = state.items.fold(0.0, (sum, item) => sum + (item.foodItem.price * item.quantity));
          final taxableSt = state.items.where((item) => item.foodItem.applyGst).fold(0.0, (sum, item) => sum + (item.foodItem.price * item.quantity));
          
          double feeTaxableSubtotal = 0;
          for (final cartItem in state.items) {
            final itemNet = cartItem.foodItem.price * cartItem.quantity;
            final category = (cartItem.foodItem.category).toUpperCase();
            final isCombo = cartItem.isCombo;
            if (applicableCategories.contains('ALL') || (!isCombo && applicableCategories.contains(category))) {
              feeTaxableSubtotal += itemNet;
            }
          }

          final cgst = taxableSt * 0.025;
          final sgst = taxableSt * 0.025;
          final platformCharges = feeTaxableSubtotal * (customPlatformPercent / 100);
          state = state.copyWith(
            breakdown: CartBreakdown(
              subtotal: st,
              cgst: cgst,
              sgst: sgst,
              platformCharges: platformCharges,
              platformFeePercent: customPlatformPercent,
              total: st + cgst + sgst + platformCharges,
            ),
            isValidating: false,
          );
        }
    }
  }

  void addItem(FoodItem item, {String? offerId}) {
    if (state.items.isNotEmpty && item.cinemaId != null) {
      final existingCinemaId = state.items.first.foodItem.cinemaId;
      if (existingCinemaId != null && existingCinemaId != item.cinemaId) {
        state = state.copyWith(items: []);
      }
    }

    final existingIndex =
        state.items.indexWhere((element) => element.foodItem.id == item.id && !element.isCombo && element.offerId == offerId);
    if (existingIndex != -1) {
      state = state.copyWith(items: [
        for (int i = 0; i < state.items.length; i++)
          if (i == existingIndex)
            state.items[i].copyWith(quantity: state.items[i].quantity + 1)
          else
            state.items[i]
      ]);
    } else {
      state = state.copyWith(items: [...state.items, CartItem(foodItem: item, quantity: 1, note: null, isOffer: offerId != null, offerId: offerId)]);
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
      applyGst: combo.applyGst,
    );

    final existingIndex = state.items.indexWhere(
      (element) => element.isCombo && element.comboId == combo.id,
    );

    if (existingIndex != -1) {
      state = state.copyWith(items: [
        for (int i = 0; i < state.items.length; i++)
          if (i == existingIndex)
            CartItem(
              foodItem: comboAsFood,
              quantity: state.items[i].quantity + 1,
              isCombo: true,
              comboId: combo.id,
              comboName: combo.name,
            )
          else
            state.items[i]
      ]);
    } else {
      state = state.copyWith(items: [
        ...state.items,
        CartItem(
          foodItem: comboAsFood,
          quantity: 1,
          isCombo: true,
          comboId: combo.id,
          comboName: combo.name,
        ),
      ]);
    }
    _saveCart();
    _fetchBreakdown();
  }

  void validateAndAddItem(FoodItem item, String? currentHallId, {String? offerId}) {
    addItem(item, offerId: offerId);
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
  double get discount => state.breakdown.discount;
  double get cgst => state.breakdown.cgst;
  double get sgst => state.breakdown.sgst;
  double get platformCharges => state.breakdown.platformCharges;
  double get platformFeePercent => state.breakdown.platformFeePercent;
  double get totalAmount => state.breakdown.total;

  void validateAvailability(List<FoodItem> freshMenu) {
    if (state.items.isEmpty) return;
    
    final List<CartItem> availableItems = [];
    bool changed = false;

    for (final item in state.items) {
      if (item.isCombo) {
         availableItems.add(item);
         continue;
      }

      final fresh = freshMenu.firstWhere((i) => i.id == item.foodItem.id, orElse: () => item.foodItem);
      if (fresh.isAvailable) {
        availableItems.add(item);
      } else {
        changed = true;
      }
    }

    if (changed) {
      state = state.copyWith(items: availableItems);
      _saveCart();
      _fetchBreakdown();
    }
  }

  void clearCart() {
    state = state.copyWith(items: []);
    _saveCart();
    _fetchBreakdown();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  final auth = ref.watch(authProvider);
  return CartNotifier(ref, auth.userId);
});
