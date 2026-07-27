import '../repositories/queue_repository.dart';

/// Use case untuk membuat job pencetakan tiket fisik.
class CreatePrintJob {
  final QueueRepository repository;

  const CreatePrintJob(this.repository);

  Future<String> call({
    required String queueCode,
    required String counterName,
    required String takenAt,
  }) {
    return repository.createPrintJob(
      queueCode: queueCode,
      counterName: counterName,
      takenAt: takenAt,
    );
  }
}
