import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'auth_provider.dart';
import 'supabase_provider.dart';
import '../models/loyalty_transaction.dart';

class LoyaltyState {
  final int availablePoints;
  final double rupeeValue;
  final int totalEarned;
  final int totalRedeemed;
  final List<LoyaltyTransaction> transactions;
  final bool isLoading;
  final bool isCinepointsEnabled;

  LoyaltyState({
    this.availablePoints = 0,
    this.rupeeValue = 0.0,
    this.totalEarned = 0,
    this.totalRedeemed = 0,
    this.transactions = const [],
    this.isLoading = false,
    this.isCinepointsEnabled = true,
  });

  LoyaltyState copyWith({
    int? availablePoints,
    double? rupeeValue,
    int? totalEarned,
    int? totalRedeemed,
    List<LoyaltyTransaction>? transactions,
    bool? isLoading,
    bool? isCinepointsEnabled,
  }) {
    return LoyaltyState(
      availablePoints: availablePoints ?? this.availablePoints,
      rupeeValue: rupeeValue ?? this.rupeeValue,
      totalEarned: totalEarned ?? this.totalEarned,
      totalRedeemed: totalRedeemed ?? this.totalRedeemed,
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      isCinepointsEnabled: isCinepointsEnabled ?? this.isCinepointsEnabled,
    );
  }
}

class LoyaltyNotifier extends StateNotifier<LoyaltyState> {
  final Ref _ref;
  static const double pointValue = 2.0;

  LoyaltyNotifier(this._ref) : super(LoyaltyState()) {
    // Initial fetch if user is logged in
    _init();
  }

  void _init() {
    fetchGlobalConfig();
    final auth = _ref.read(authProvider);
    if (auth.status == AuthStatus.AUTHENTICATED && auth.userId != null) {
      fetchWallet();
      fetchTransactions();
    }

    // Listen to auth changes
    _ref.listen<AuthState>(authProvider, (AuthState? previous, AuthState next) {
      if (next.status == AuthStatus.AUTHENTICATED && next.userId != null) {
        fetchWallet();
        fetchTransactions();
      } else if (next.status == AuthStatus.UNAUTHENTICATED) {
        state = LoyaltyState();
      }
    });
  }

  Future<void> fetchWallet() async {
    final userId = _ref.read(authProvider).userId;
    if (userId == null) return;

    state = state.copyWith(isLoading: true);
    
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('customer_profiles')
          .select('loyalty_points')
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        state = state.copyWith(
          availablePoints: response['loyalty_points'] as int? ?? 0,
          rupeeValue: (response['loyalty_points'] as int? ?? 0) * pointValue,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      print('Error fetching loyalty wallet: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> fetchGlobalConfig() async {
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('global_settings')
          .select('value')
          .eq('key', 'platform_fees')
          .maybeSingle();

      if (response != null && response['value'] != null) {
        final val = Map<String, dynamic>.from(response['value'] as Map);
        if (val.containsKey('enable_cinepoints')) {
          state = state.copyWith(isCinepointsEnabled: val['enable_cinepoints'] as bool);
        }
      }
    } catch (e) {
      print('Error fetching cinepoints config: $e');
    }
  }

  Future<void> fetchTransactions() async {
    final userId = _ref.read(authProvider).userId;
    if (userId == null) return;

    try {
      final supabase = _ref.read(supabaseServiceProvider);
      final response = await supabase.fetchCinePointsHistory(userId);

      final transactions = response
          .map((t) => LoyaltyTransaction.fromMap(t))
          .toList();
      state = state.copyWith(transactions: transactions);
    } catch (e) {
      print('Error fetching loyalty transactions: $e');
    }
  }

  int calculateEarnedPoints(double amount) {
    if (!state.isCinepointsEnabled || amount < 100) return 0;
    // Rule: 2 points for every 100 INR expense
    return ((amount / 100).floor()) * 2;
  }

  double calculateRedeemableValue(int points) {
    if (!state.isCinepointsEnabled) return 0.0;
    return points * pointValue;
  }
}

final loyaltyProvider = StateNotifierProvider<LoyaltyNotifier, LoyaltyState>((ref) {
  return LoyaltyNotifier(ref);
});
