import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_item.dart';
import '../models/order_model.dart';
import '../services/supabase_service.dart';
import 'auth_provider.dart';
import 'seat_selection_provider.dart';
import 'supabase_provider.dart';

/// Represents a single item in the "Order Again" recommendations list.
class ReorderSuggestion {
  final String foodId;
  final String name;
  final String imageUrl;
  final double price;
  final String category;
  final int orderCount;   // How many times this item was ordered

  const ReorderSuggestion({
    required this.foodId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.category,
    required this.orderCount,
  });

  FoodItem toFoodItem() {
    return FoodItem(
      id: foodId,
      name: name,
      description: '',
      imageUrl: imageUrl,
      price: price,
      category: category,
    );
  }
}

class ReorderState {
  final List<ReorderSuggestion> suggestions;
  final bool isLoading;

  const ReorderState({
    this.suggestions = const [],
    this.isLoading = false,
  });

  ReorderState copyWith({
    List<ReorderSuggestion>? suggestions,
    bool? isLoading,
  }) {
    return ReorderState(
      suggestions: suggestions ?? this.suggestions,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ReorderNotifier extends StateNotifier<ReorderState> {
  final Ref _ref;

  ReorderNotifier(this._ref) : super(const ReorderState()) {
    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.UNAUTHENTICATED) {
        state = const ReorderState();
      }
    });
  }

  Future<void> loadSuggestions(String cinemaId) async {
    final auth = _ref.read(authProvider);
    final userId = auth.userId;
    final phone = auth.phone;

    // Need at least one identifier to find orders
    if ((userId == null && phone == null) || cinemaId.isEmpty) return;

    state = state.copyWith(isLoading: true);

    try {
      final service = _ref.read(supabaseServiceProvider);
      final suggestions = await service.fetchReorderSuggestions(
        cinemaId: cinemaId,
        customerId: userId,
        customerPhone: phone,
      );
      state = state.copyWith(suggestions: suggestions, isLoading: false);
    } catch (e) {
      print('ReorderNotifier.loadSuggestions error: $e');
      state = state.copyWith(isLoading: false);
    }
  }
}

final reorderProvider = StateNotifierProvider<ReorderNotifier, ReorderState>((ref) {
  final notifier = ReorderNotifier(ref);

  ref.listen<SeatSelectionState>(seatSelectionProvider, (previous, next) {
    if (next.hallId != null) {
      notifier.loadSuggestions(next.hallId!);
    }
  });

  return notifier;
});
