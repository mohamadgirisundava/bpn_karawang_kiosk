import 'dart:async';
import '../../../domain/entities/queue_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/realtime_service.dart';
import '../../../core/utils/error_message.dart';
import '../../../domain/usecases/get_active_counters.dart';
import '../../../domain/usecases/get_estimate_per_person.dart';
import '../../../domain/usecases/get_queue_info.dart';
import 'queue_state.dart';

/// Cubit untuk halaman info antrian (semua counter + serving + waiting).
class QueueInfoCubit extends Cubit<QueueInfoState> {
  final GetActiveCounters _getActiveCounters;
  final GetQueueInfo _getQueueInfo;
  final GetEstimatePerPerson _getEstimatePerPerson;

  StreamSubscription<void>? _realtimeSub;

  QueueInfoCubit({
    required GetActiveCounters getActiveCounters,
    required GetQueueInfo getQueueInfo,
    required GetEstimatePerPerson getEstimatePerPerson,
  }) : _getActiveCounters = getActiveCounters,
       _getQueueInfo = getQueueInfo,
       _getEstimatePerPerson = getEstimatePerPerson,
       super(const QueueInfoState());

  /// Load data counter, estimasi, dan info antrian.
  Future<void> loadData() async {
    emit(state.copyWith(status: QueueInfoStatus.loading));

    try {
      final counters = await _getActiveCounters();
      final estimate = await _getEstimatePerPerson();

      emit(
        state.copyWith(
          status: QueueInfoStatus.loaded,
          counters: counters,
          estimatePerPerson: estimate,
        ),
      );

      _refreshQueueInfo();
      _setupRealtime();
    } catch (e) {
      emit(
        state.copyWith(
          status: QueueInfoStatus.error,
          errorMessage: friendlyErrorMessage(e),
        ),
      );
    }
  }

  // Dulu di sini ada retry 3x, karena query pertama sehabis cold-start
  // sering gagal/timeout. Sekarang nggak ada query — cuma perhitungan dari
  // snapshot yang sudah di memori, jadi nggak ada yang bisa gagal.
  void _refreshQueueInfo() => _applyQueues(RealtimeService.instance.todayQueues);

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
    _realtimeSub?.cancel();
    _realtimeSub = RealtimeService.instance.onQueuesData.listen(_applyQueues);
    // Listen settings update untuk refresh estimate
    RealtimeService.instance.onSettingsUpdate.listen((_) {
      _refreshEstimate();
    });
  }

  Future<void> _refreshEstimate() async {
    try {
      final estimate = await _getEstimatePerPerson();
      emit(state.copyWith(estimatePerPerson: estimate));
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _realtimeSub?.cancel();
    return super.close();
  }
}
