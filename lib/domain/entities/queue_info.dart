import 'package:equatable/equatable.dart';

/// Value object untuk info antrian per counter.
class QueueInfo extends Equatable {
  final String currentServing;
  final int waitingCount;

  const QueueInfo({required this.currentServing, required this.waitingCount});

  @override
  List<Object?> get props => [currentServing, waitingCount];
}
