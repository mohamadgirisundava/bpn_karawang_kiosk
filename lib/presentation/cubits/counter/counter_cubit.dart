import 'dart:async';
import '../../../domain/entities/queue_entity.dart';
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

      refreshQueueInfo();
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

  /// Hitung ulang info antrian dari snapshot yang sudah ada di memori.
  ///
  /// Dulu di sini ada retry 3x berjeda 2 detik, karena query pertama sehabis
  /// cold-start sering gagal/timeout dan bikin layar nyangkut nampilin "0
  /// antrian" yang kelihatan valid. Sekarang nggak ada query sama sekali —
  /// nggak ada yang bisa gagal, jadi retry-nya ikut hilang. Kalau
  /// snapshot-nya sendiri belum datang, daftarnya memang masih kosong dan
  /// akan terisi begitu Firestore mengirimnya.
  void refreshQueueInfo() => _applyQueues(RealtimeService.instance.todayQueues);

  void _applyQueues(List<QueueEntity> todayQueues) {
    if (isClosed || state.counters.isEmpty) return;
    emit(
      state.copyWith(
        queueInfo: _getQueueInfo.getAll(
          todayQueues,
          state.counters.map((c) => c.id).toList(),
        ),
      ),
    );
  }

  void _setupRealtime() {
    _queueSub?.cancel();
    _counterSub?.cancel();

    _queueSub = RealtimeService.instance.onQueuesData.listen(_applyQueues);

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
