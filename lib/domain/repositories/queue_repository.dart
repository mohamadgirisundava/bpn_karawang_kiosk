import '../entities/queue_entity.dart';
import '../entities/queue_info.dart';

/// Abstract repository untuk operasi antrian.
abstract class QueueRepository {
  /// Buat tiket antrian baru.
  Future<QueueEntity> createQueue({
    required String counterId,
    required String counterCode,
  });

  /// Get info antrian (serving + waiting) untuk satu counter.
  Future<QueueInfo> getQueueInfo(String counterId);

  /// Get info antrian untuk semua counter sekaligus.
  Future<Map<String, QueueInfo>> getAllQueueInfo(List<String> counterIds);
}
