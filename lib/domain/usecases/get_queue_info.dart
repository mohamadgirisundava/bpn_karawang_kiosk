import '../entities/queue_info.dart';
import '../repositories/queue_repository.dart';

/// Use case untuk mengambil info antrian semua counter.
class GetQueueInfo {
  final QueueRepository repository;

  const GetQueueInfo(this.repository);

  /// Get info untuk satu counter.
  Future<QueueInfo> call(String counterId) {
    return repository.getQueueInfo(counterId);
  }

  /// Get info untuk semua counter.
  Future<Map<String, QueueInfo>> getAll(List<String> counterIds) {
    return repository.getAllQueueInfo(counterIds);
  }
}
