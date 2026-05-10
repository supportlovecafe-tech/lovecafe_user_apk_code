import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/combo_model.dart';
import 'supabase_provider.dart';
import 'auth_provider.dart';
import 'seat_selection_provider.dart';

class ComboState {
  final List<ComboMeal> items;
  final bool isLoading;
  final String? error;

  const ComboState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  ComboState copyWith({
    List<ComboMeal>? items,
    bool? isLoading,
    String? error,
  }) {
    return ComboState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ComboNotifier extends StateNotifier<ComboState> {
  final Ref _ref;

  ComboNotifier(this._ref) : super(const ComboState()) {
    // Clear combos on logout
    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.UNAUTHENTICATED) {
        state = const ComboState();
      }
    });
  }

  Future<void> loadCombos(String cinemaId) async {
    if (cinemaId.isEmpty) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final supabase = _ref.read(supabaseServiceProvider);
      final combos = await supabase.fetchCombos(cinemaId);
      state = state.copyWith(items: combos, isLoading: false);
    } catch (e) {
      print('ComboNotifier.loadCombos error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clear() {
    state = const ComboState();
  }
}

final comboProvider = StateNotifierProvider<ComboNotifier, ComboState>((ref) {
  final notifier = ComboNotifier(ref);

  // Auto-load when seat/outlet changes
  ref.listen<SeatSelectionState>(seatSelectionProvider, (previous, next) {
    if (next.hallId != null && next.hallId != previous?.hallId) {
      notifier.loadCombos(next.hallId!);
    }
  });

  return notifier;
});
