import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cinema_hall.dart';
import 'supabase_provider.dart';

class CinemaHallsNotifier extends StateNotifier<List<CinemaHall>> {
  final Ref _ref;

  CinemaHallsNotifier(this._ref) : super([]) {
    refreshHalls();
  }

  Future<void> refreshHalls() async {
    try {
      final supabase = _ref.read(supabaseServiceProvider);
      final halls = await supabase.fetchCinemas();
      state = halls;
    } catch (e) {
      print('Error fetching halls: $e');
      state = [];
    }
  }

  Future<void> addHall(CinemaHall hall) async {
    state = [...state, hall];
  }

  Future<void> updateHall(CinemaHall hall) async {
    state = [
      for (final existing in state)
        if (existing.id == hall.id) hall else existing,
    ];
  }

  Future<void> deleteHall(String hallId) async {
    state = state.where((hall) => hall.id != hallId).toList();
  }
}

final cinemaHallsProvider =
    StateNotifierProvider<CinemaHallsNotifier, List<CinemaHall>>((ref) {
  return CinemaHallsNotifier(ref);
});

