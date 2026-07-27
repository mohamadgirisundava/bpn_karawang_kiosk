import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/error_message.dart';
import '../../../domain/usecases/create_print_job.dart';
import '../../../domain/usecases/create_queue.dart';
import '../../../domain/usecases/get_estimate_per_person.dart';
import '../../../domain/usecases/get_queue_info.dart';
import '../../../domain/usecases/watch_print_job_status.dart';
import 'ticket_state.dart';

/// Cubit untuk mengelola state halaman tiket (confirm → loading → success).
class TicketCubit extends Cubit<TicketState> {
  final CreateQueue _createQueue;
  final CreatePrintJob _createPrintJob;
  final GetQueueInfo _getQueueInfo;
  final GetEstimatePerPerson _getEstimatePerPerson;
  final WatchPrintJobStatus _watchPrintJobStatus;

  StreamSubscription<String>? _printJobSub;
  Timer? _printJobTimeout;

  // Kalau print-relay (helper Windows) nggak pernah merespons job ini
  // (mati/nggak jalan), jangan biarkan kiosk nunggu selamanya — kasih tau
  // user gagal setelah durasi ini, biarpun job-nya sendiri tetap
  // "pending" di server (bisa aja kecetak telat kalau relay nyala lagi).
  static const Duration _printTimeout = Duration(seconds: 12);

  TicketCubit({
    required CreateQueue createQueue,
    required CreatePrintJob createPrintJob,
    required GetQueueInfo getQueueInfo,
    required GetEstimatePerPerson getEstimatePerPerson,
    required WatchPrintJobStatus watchPrintJobStatus,
  }) : _createQueue = createQueue,
       _createPrintJob = createPrintJob,
       _getQueueInfo = getQueueInfo,
       _getEstimatePerPerson = getEstimatePerPerson,
       _watchPrintJobStatus = watchPrintJobStatus,
       super(const TicketState());

  /// Load info antrian untuk counter ini.
  Future<void> loadQueueInfo(String counterId) async {
    try {
      final info = await _getQueueInfo(counterId);
      final estimate = await _getEstimatePerPerson();
      emit(state.copyWith(queueInfo: info, estimatePerPerson: estimate));
    } catch (_) {
      // Pakai default
    }
  }

  /// Proses ambil nomor antrian. Sengaja TIDAK membuat job cetak — itu baru
  /// terjadi saat user menekan tombol "Cetak Tiket Antrian" (lihat
  /// [watchPrintJob]), supaya printer nggak langsung jalan begitu nomor
  /// antrian diambil.
  Future<void> takeTicket({
    required String counterId,
    required String counterCode,
  }) async {
    emit(state.copyWith(status: TicketStatus.loading));

    try {
      final ticket = await _createQueue(
        counterId: counterId,
        counterCode: counterCode,
      );

      emit(state.copyWith(status: TicketStatus.success, ticket: ticket));
    } catch (e) {
      emit(
        state.copyWith(
          status: TicketStatus.error,
          errorMessage: friendlyErrorMessage(e),
        ),
      );
    }
  }

  /// Buat job cetak lalu pantau statusnya (dipanggil saat user menekan
  /// tombol "Cetak Tiket Antrian"). UI mengikuti `state.printJobStatus`
  /// alih-alih animasi loading berdurasi tetap.
  Future<void> watchPrintJob({required String counterName}) async {
    final ticket = state.ticket;
    if (ticket == null) return;

    _printJobSub?.cancel();
    _printJobTimeout?.cancel();

    emit(state.copyWith(printJobStatus: PrintJobStatus.printing));

    final String printJobId;
    try {
      printJobId = await _createPrintJob(
        queueCode: ticket.queueCode,
        counterName: counterName,
        takenAt: ticket.takenAt ?? DateTime.now().toUtc().toIso8601String(),
      );
    } catch (_) {
      emit(state.copyWith(printJobStatus: PrintJobStatus.failed));
      return;
    }

    emit(state.copyWith(printJobId: printJobId));

    _printJobTimeout = Timer(_printTimeout, () {
      if (state.printJobStatus == PrintJobStatus.printing) {
        emit(state.copyWith(printJobStatus: PrintJobStatus.failed));
      }
    });

    _printJobSub = _watchPrintJobStatus(printJobId).listen((status) {
      if (status == 'printed') {
        _printJobTimeout?.cancel();
        emit(state.copyWith(printJobStatus: PrintJobStatus.printed));
        _printJobSub?.cancel();
      } else if (status == 'error') {
        _printJobTimeout?.cancel();
        emit(state.copyWith(printJobStatus: PrintJobStatus.failed));
        _printJobSub?.cancel();
      }
    });
  }

  @override
  Future<void> close() {
    _printJobSub?.cancel();
    _printJobTimeout?.cancel();
    return super.close();
  }
}
