import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/realtime_service.dart';
import '../../../core/utils/error_message.dart';
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
          errorMessage: friendlyErrorMessage(e),
        ),
      );
    }
  }

  /// Refresh info antrian untuk semua counter. Query pertama abis app
  /// cold-start kadang gagal/timeout gara-gara koneksi Firestore-nya
  /// belum "anget" (belum pernah ada request sebelumnya) — dulu ini
  /// diem-diem gagal dan nyangkut nampilin 0 antrian sampai ada trigger
  /// nggak sengaja dari tempat lain yang mancing refresh ulang. Sekarang
  /// retry sendiri beberapa kali dengan jeda, biar biasanya udah kebenerin
  /// sendiri sebelum sempat kelihatan user.
  Future<void> refreshQueueInfo() async {
    if (state.counters.isEmpty) return;
    final ids = state.counters.map((c) => c.id).toList();

    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final info = await _getQueueInfo.getAll(ids);
        if (isClosed) return;
        emit(state.copyWith(queueInfo: info));
        return;
      } catch (e) {
        debugPrint('CounterCubit: gagal ambil info antrian (percobaan $attempt): $e');
        if (attempt == maxAttempts) return; // Pakai data lama, nyerah.
        await Future<void>.delayed(const Duration(seconds: 2));
      }
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
