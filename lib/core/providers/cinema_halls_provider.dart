import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cinema_hall.dart';
import 'supabase_provider.dart';

class CinemaHallsNotifier extends StateNotifier<List<CinemaHall>> {
  final Ref _ref;
  RealtimeChannel? _cinemasChannel;

  CinemaHallsNotifier(this._ref) : super([]) {
    refreshHalls();
    _subscribeRealtime();
  }

  void _subscribeRealtime() {
    try {
      _cinemasChannel = Supabase.instance.client
          .channel('public:cinemas_status_sync')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'cinemas',
            callback: (payload) {
              refreshHalls();
            },
          )
          .subscribe();
    } catch (e) {
      print('Failed to subscribe to cinema realtime updates: $e');
    }
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

  @override
  void dispose() {
    _cinemasChannel?.unsubscribe();
    super.dispose();
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

