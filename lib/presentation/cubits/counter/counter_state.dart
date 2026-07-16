import 'package:equatable/equatable.dart';
import '../../../domain/entities/counter_entity.dart';
import '../../../domain/entities/queue_info.dart';

enum CounterStatus { initial, loading, loaded, error }

class CounterState extends Equatable {
  final CounterStatus status;
  final List<CounterEntity> counters;
  final Map<String, QueueInfo> queueInfo;
  final String errorMessage;

  const CounterState({
    this.status = CounterStatus.initial,
    this.counters = const [],
    this.queueInfo = const {},
    this.errorMessage = '',
  });

  CounterState copyWith({
    CounterStatus? status,
    List<CounterEntity>? counters,
    Map<String, QueueInfo>? queueInfo,
    String? errorMessage,
  }) {
    return CounterState(
      status: status ?? this.status,
      counters: counters ?? this.counters,
      queueInfo: queueInfo ?? this.queueInfo,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, counters, queueInfo, errorMessage];
}
