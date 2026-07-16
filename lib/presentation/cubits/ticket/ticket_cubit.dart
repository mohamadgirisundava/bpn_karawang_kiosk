import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/create_queue.dart';
import '../../../domain/usecases/get_estimate_per_person.dart';
import '../../../domain/usecases/get_queue_info.dart';
import 'ticket_state.dart';

/// Cubit untuk mengelola state halaman tiket (confirm → loading → success).
class TicketCubit extends Cubit<TicketState> {
  final CreateQueue _createQueue;
  final GetQueueInfo _getQueueInfo;
  final GetEstimatePerPerson _getEstimatePerPerson;

  TicketCubit({
    required CreateQueue createQueue,
    required GetQueueInfo getQueueInfo,
    required GetEstimatePerPerson getEstimatePerPerson,
  }) : _createQueue = createQueue,
       _getQueueInfo = getQueueInfo,
       _getEstimatePerPerson = getEstimatePerPerson,
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

  /// Proses ambil nomor antrian.
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
        state.copyWith(status: TicketStatus.error, errorMessage: e.toString()),
      );
    }
  }
}
