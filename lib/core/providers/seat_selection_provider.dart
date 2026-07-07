import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'menu_provider.dart';
import 'auth_provider.dart';

class SeatSelectionState {
  final String? hallId;
  final String? hallName;
  final String? screenName;
  final String? seatLabel;
  final List<String>? allowedPaymentMethods;

  const SeatSelectionState({
    this.hallId,
    this.hallName,
    this.screenName,
    this.seatLabel,
    this.allowedPaymentMethods,
  });

  bool get isComplete =>
      hallId != null &&
      hallName != null &&
      screenName != null &&
      seatLabel != null &&
      seatLabel!.isNotEmpty;

  String get displayLabel {
    return '${hallName ?? 'Select hall'} • ${screenName ?? 'Select screen'} • ${seatLabel ?? 'Seat'}';
  }

  SeatSelectionState copyWith({
    String? hallId,
    String? hallName,
    String? screenName,
    String? seatLabel,
    List<String>? allowedPaymentMethods,
  }) {
    return SeatSelectionState(
      hallId: hallId ?? this.hallId,
      hallName: hallName ?? this.hallName,
      screenName: screenName ?? this.screenName,
      seatLabel: seatLabel ?? this.seatLabel,
      allowedPaymentMethods: allowedPaymentMethods ?? this.allowedPaymentMethods,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hallId': hallId,
      'hallName': hallName,
      'screenName': screenName,
      'seatLabel': seatLabel,
      'allowedPaymentMethods': allowedPaymentMethods,
    };
  }

  factory SeatSelectionState.fromMap(Map<String, dynamic> map) {
    return SeatSelectionState(
      hallId: map['hallId'],
      hallName: map['hallName'],
      screenName: map['screenName'],
      seatLabel: map['seatLabel'],
      allowedPaymentMethods: map['allowedPaymentMethods'] != null 
          ? List<String>.from(map['allowedPaymentMethods']) 
          : null,
    );
  }
}

class SeatSelectionNotifier extends StateNotifier<SeatSelectionState> {
  final Ref _ref;
  final String? _userId;
  String get _storageKey => 'ce_seat_selection_${_userId ?? 'guest'}';

  SeatSelectionNotifier(this._ref, this._userId) : super(const SeatSelectionState()) {
    _restoreSelection();
  }


  Future<void> _persistSelection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(state.toMap()));
  }

  Future<void> _restoreSelection() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageKey);
    if (saved != null) {
      try {
        var restoredState = SeatSelectionState.fromMap(jsonDecode(saved));
        if (restoredState.hallId != null) {
          try {
            final response = await Supabase.instance.client
                .from('cinemas')
                .select('allowed_payment_methods')
                .eq('id', restoredState.hallId!)
                .single();
            if (response['allowed_payment_methods'] != null) {
              final methods = List<String>.from(response['allowed_payment_methods']);
              restoredState = restoredState.copyWith(allowedPaymentMethods: methods);
            }
          } catch (e) {
            print('Error fetching updated payment methods on restore: $e');
          }
          state = restoredState;
          _ref.read(menuProvider.notifier).refreshMenu(state.hallId!);
        } else {
          state = restoredState;
        }
      } catch (e) {
        print('Error restoring seat selection: $e');
      }
    }
  }

  Future<void> updateSelection({
    required String hallId,
    required String hallName,
    required String screenName,
    required String seatLabel,
  }) async {
    List<String>? methods = ['DEMO_UPI', 'DEMO_CARD', 'PAY_ON_DELIVERY', 'PAY_LATER'];
    try {
      final response = await Supabase.instance.client
          .from('cinemas')
          .select('allowed_payment_methods')
          .eq('id', hallId)
          .single();
      if (response['allowed_payment_methods'] != null) {
        methods = List<String>.from(response['allowed_payment_methods']);
      }
    } catch (e) {
      print('Error fetching payment methods: $e');
    }

    state = SeatSelectionState(
      hallId: hallId,
      hallName: hallName,
      screenName: screenName,
      seatLabel: seatLabel,
      allowedPaymentMethods: methods,
    );
    _persistSelection();
    
    // Trigger menu refresh for the selected cinema (Tenant Identification)
    _ref.read(menuProvider.notifier).refreshMenu(hallId);
  }

  void clearSelection() async {
    state = const SeatSelectionState();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}


final seatSelectionProvider =
    StateNotifierProvider<SeatSelectionNotifier, SeatSelectionState>((ref) {
  final auth = ref.watch(authProvider);
  return SeatSelectionNotifier(ref, auth.userId);
});


