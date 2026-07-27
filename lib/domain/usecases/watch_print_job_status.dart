import '../repositories/queue_repository.dart';

/// Use case untuk memantau status job cetak tiket fisik.
class WatchPrintJobStatus {
  final QueueRepository repository;

  const WatchPrintJobStatus(this.repository);

  Stream<String> call(String printJobId) {
    return repository.watchPrintJobStatus(printJobId);
  }
}
