import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'menu_provider.dart';

class SeatSelectionState {
  final String? hallId;
  final String? hallName;
  final String? screenName;
  final String? seatLabel;

  const SeatSelectionState({
    this.hallId,
    this.hallName,
    this.screenName,
    this.seatLabel,
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
  }) {
    return SeatSelectionState(
      hallId: hallId ?? this.hallId,
      hallName: hallName ?? this.hallName,
      screenName: screenName ?? this.screenName,
      seatLabel: seatLabel ?? this.seatLabel,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hallId': hallId,
      'hallName': hallName,
      'screenName': screenName,
      'seatLabel': seatLabel,
    };
  }

  factory SeatSelectionState.fromMap(Map<String, dynamic> map) {
    return SeatSelectionState(
      hallId: map['hallId'],
      hallName: map['hallName'],
      screenName: map['screenName'],
      seatLabel: map['seatLabel'],
    );
  }
}

class SeatSelectionNotifier extends StateNotifier<SeatSelectionState> {
  final Ref _ref;
  static const String _storageKey = 'ce_seat_selection';

  SeatSelectionNotifier(this._ref) : super(const SeatSelectionState()) {
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
        state = SeatSelectionState.fromMap(jsonDecode(saved));
        if (state.hallId != null) {
          _ref.read(menuProvider.notifier).refreshMenu(state.hallId!);
        }
      } catch (e) {
        print('Error restoring seat selection: $e');
      }
    }
  }

  void updateSelection({
    required String hallId,
    required String hallName,
    required String screenName,
    required String seatLabel,
  }) {
    state = SeatSelectionState(
      hallId: hallId,
      hallName: hallName,
      screenName: screenName,
      seatLabel: seatLabel,
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
  return SeatSelectionNotifier(ref);
});

