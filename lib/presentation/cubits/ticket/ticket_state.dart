import 'package:equatable/equatable.dart';
import '../../../domain/entities/queue_entity.dart';
import '../../../domain/entities/queue_info.dart';

enum TicketStatus { confirm, loading, success, error }

class TicketState extends Equatable {
  final TicketStatus status;
  final QueueEntity? ticket;
  final QueueInfo? queueInfo;
  final int estimatePerPerson;
  final String errorMessage;

  const TicketState({
    this.status = TicketStatus.confirm,
    this.ticket,
    this.queueInfo,
    this.estimatePerPerson = 5,
    this.errorMessage = '',
  });

  TicketState copyWith({
    TicketStatus? status,
    QueueEntity? ticket,
    QueueInfo? queueInfo,
    int? estimatePerPerson,
    String? errorMessage,
  }) {
    return TicketState(
      status: status ?? this.status,
      ticket: ticket ?? this.ticket,
      queueInfo: queueInfo ?? this.queueInfo,
      estimatePerPerson: estimatePerPerson ?? this.estimatePerPerson,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    ticket,
    queueInfo,
    estimatePerPerson,
    errorMessage,
  ];
}
