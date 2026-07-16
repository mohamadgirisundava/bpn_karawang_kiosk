import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/realtime_service.dart';
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

      await _refreshQueueInfo();
      _setupRealtime();
    } catch (e) {
      emit(state.copyWith(status: QueueInfoStatus.error));
    }
  }

  Future<void> _refreshQueueInfo() async {
    if (state.counters.isEmpty) return;
    try {
      final ids = state.counters.map((c) => c.id).toList();
      final info = await _getQueueInfo.getAll(ids);
      emit(state.copyWith(queueInfo: info));
    } catch (_) {}
  }

  void _setupRealtime() {
    _realtimeSub?.cancel();
    _realtimeSub = RealtimeService.instance.onQueueUpdate.listen((_) {
      _refreshQueueInfo();
    });
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
