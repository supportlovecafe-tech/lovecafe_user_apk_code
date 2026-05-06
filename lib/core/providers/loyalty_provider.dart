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

  LoyaltyState({
    this.availablePoints = 0,
    this.rupeeValue = 0.0,
    this.totalEarned = 0,
    this.totalRedeemed = 0,
    this.transactions = const [],
    this.isLoading = false,
  });

  LoyaltyState copyWith({
    int? availablePoints,
    double? rupeeValue,
    int? totalEarned,
    int? totalRedeemed,
    List<LoyaltyTransaction>? transactions,
    bool? isLoading,
  }) {
    return LoyaltyState(
      availablePoints: availablePoints ?? this.availablePoints,
      rupeeValue: rupeeValue ?? this.rupeeValue,
      totalEarned: totalEarned ?? this.totalEarned,
      totalRedeemed: totalRedeemed ?? this.totalRedeemed,
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
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
          .from('loyalty_wallets')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        state = state.copyWith(
          availablePoints: response['total_points'] as int? ?? 0,
          rupeeValue: (response['total_points'] as int? ?? 0) * pointValue,
          totalEarned: response['total_earned'] as int? ?? 0,
          totalRedeemed: response['total_redeemed'] as int? ?? 0,
          isLoading: false,
        );
      } else {
        // Wallet might not exist yet
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      print('Error fetching loyalty wallet: $e');
      state = state.copyWith(isLoading: false);
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
    if (amount < 100) return 0;
    // Rule: 2 points for every 100 INR expense
    return ((amount / 100).floor()) * 2;
  }

  double calculateRedeemableValue(int points) {
    return points * pointValue;
  }
}

final loyaltyProvider = StateNotifierProvider<LoyaltyNotifier, LoyaltyState>((ref) {
  return LoyaltyNotifier(ref);
});
