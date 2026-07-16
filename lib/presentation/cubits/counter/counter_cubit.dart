import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/realtime_service.dart';
import '../../../domain/usecases/get_active_counters.dart';
import '../../../domain/usecases/get_queue_info.dart';
import 'counter_state.dart';

/// Cubit untuk mengelola daftar counter dan info antrian.
class CounterCubit extends Cubit<CounterState> {
  final GetActiveCounters _getActiveCounters;
  final GetQueueInfo _getQueueInfo;

  StreamSubscription<void>? _queueSub;
  StreamSubscription<void>? _counterSub;

  CounterCubit({
    required GetActiveCounters getActiveCounters,
    required GetQueueInfo getQueueInfo,
  }) : _getActiveCounters = getActiveCounters,
       _getQueueInfo = getQueueInfo,
       super(const CounterState());

  /// Load counters dan setup realtime.
  Future<void> loadCounters() async {
    emit(state.copyWith(status: CounterStatus.loading));

    try {
      final counters = await _getActiveCounters();

      emit(state.copyWith(status: CounterStatus.loaded, counters: counters));

      await refreshQueueInfo();
      _setupRealtime();
    } catch (e) {
      emit(
        state.copyWith(
          status: CounterStatus.error,
          errorMessage: 'Tidak dapat terhubung ke server.\n$e',
        ),
      );
    }
  }

  /// Refresh info antrian untuk semua counter.
  Future<void> refreshQueueInfo() async {
    if (state.counters.isEmpty) return;
    try {
      final ids = state.counters.map((c) => c.id).toList();
      final info = await _getQueueInfo.getAll(ids);
      emit(state.copyWith(queueInfo: info));
    } catch (_) {
      // Pakai data lama
    }
  }

  void _setupRealtime() {
    _queueSub?.cancel();
    _counterSub?.cancel();

    _queueSub = RealtimeService.instance.onQueueUpdate.listen((_) {
      refreshQueueInfo();
    });

    _counterSub = RealtimeService.instance.onCounterUpdate.listen((_) {
      loadCounters();
    });
  }

  @override
  Future<void> close() {
    _queueSub?.cancel();
    _counterSub?.cancel();
    return super.close();
  }
}
