import 'package:equatable/equatable.dart';
import '../../../domain/entities/queue_entity.dart';
import '../../../domain/entities/queue_info.dart';

enum TicketStatus { confirm, loading, success, error }

/// Status job cetak tiket fisik (dokumen `print_jobs`, diproses oleh
/// print-relay terpisah). `idle` = belum mulai dipantau (belum tekan
/// tombol cetak); `printing` = nunggu hasil realtime dari Firestore;
/// `printed`/`failed` = hasil akhir.
enum PrintJobStatus { idle, printing, printed, failed }

class TicketState extends Equatable {
  final TicketStatus status;
  final QueueEntity? ticket;
  final QueueInfo? queueInfo;
  final int estimatePerPerson;
  final String errorMessage;
  final PrintJobStatus printJobStatus;
  final String? printJobId;

  const TicketState({
    this.status = TicketStatus.confirm,
    this.ticket,
    this.queueInfo,
    this.estimatePerPerson = 5,
    this.errorMessage = '',
    this.printJobStatus = PrintJobStatus.idle,
    this.printJobId,
  });

  TicketState copyWith({
    TicketStatus? status,
    QueueEntity? ticket,
    QueueInfo? queueInfo,
    int? estimatePerPerson,
    String? errorMessage,
    PrintJobStatus? printJobStatus,
    String? printJobId,
  }) {
    return TicketState(
      status: status ?? this.status,
      ticket: ticket ?? this.ticket,
      queueInfo: queueInfo ?? this.queueInfo,
      estimatePerPerson: estimatePerPerson ?? this.estimatePerPerson,
      errorMessage: errorMessage ?? this.errorMessage,
      printJobStatus: printJobStatus ?? this.printJobStatus,
      printJobId: printJobId ?? this.printJobId,
    );
  }

  @override
  List<Object?> get props => [
    status,
    ticket,
    queueInfo,
    estimatePerPerson,
    errorMessage,
    printJobStatus,
    printJobId,
  ];
}
