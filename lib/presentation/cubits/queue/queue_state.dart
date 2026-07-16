import 'package:equatable/equatable.dart';
import '../../../domain/entities/counter_entity.dart';
import '../../../domain/entities/queue_info.dart';

enum QueueInfoStatus { initial, loading, loaded, error }

class QueueInfoState extends Equatable {
  final QueueInfoStatus status;
  final List<CounterEntity> counters;
  final Map<String, QueueInfo> queueInfo;
  final int estimatePerPerson;

  const QueueInfoState({
    this.status = QueueInfoStatus.initial,
    this.counters = const [],
    this.queueInfo = const {},
    this.estimatePerPerson = 5,
  });

  QueueInfoState copyWith({
    QueueInfoStatus? status,
    List<CounterEntity>? counters,
    Map<String, QueueInfo>? queueInfo,
    int? estimatePerPerson,
  }) {
    return QueueInfoState(
      status: status ?? this.status,
      counters: counters ?? this.counters,
      queueInfo: queueInfo ?? this.queueInfo,
      estimatePerPerson: estimatePerPerson ?? this.estimatePerPerson,
    );
  }

  @override
  List<Object?> get props => [status, counters, queueInfo, estimatePerPerson];
}
