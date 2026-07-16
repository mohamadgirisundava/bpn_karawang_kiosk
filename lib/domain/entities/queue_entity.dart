import 'package:equatable/equatable.dart';

/// Entity yang merepresentasikan satu record antrian.
class QueueEntity extends Equatable {
  final String id;
  final String counterId;
  final int queueNumber;
  final String queueCode;
  final String status;
  final String date;
  final String? takenAt;
  final String? calledAt;
  final String? completedAt;
  final String? calledBy;
  final String? deskNumber;

  const QueueEntity({
    required this.id,
    required this.counterId,
    required this.queueNumber,
    required this.queueCode,
    required this.status,
    required this.date,
    this.takenAt,
    this.calledAt,
    this.completedAt,
    this.calledBy,
    this.deskNumber,
  });

  @override
  List<Object?> get props => [id, counterId, queueNumber, queueCode, status];
}
