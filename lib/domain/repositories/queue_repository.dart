import '../entities/queue_entity.dart';
import '../entities/queue_info.dart';

/// Abstract repository untuk operasi antrian.
abstract class QueueRepository {
  /// Buat tiket antrian baru.
  Future<QueueEntity> createQueue({
    required String counterId,
    required String counterCode,
  });

  /// Buat job pencetakan tiket fisik (dipanggil saat user menekan tombol
  /// "Cetak Tiket Antrian"), mengembalikan id job untuk dipantau.
  Future<String> createPrintJob({
    required String queueCode,
    required String counterName,
    required String takenAt,
  });

  /// Pantau status job cetak tiket fisik terkait satu tiket antrian.
  Stream<String> watchPrintJobStatus(String printJobId);

  /// Get info antrian (serving + waiting) untuk satu counter.
  Future<QueueInfo> getQueueInfo(String counterId);

  /// Get info antrian untuk semua counter sekaligus.
  Future<Map<String, QueueInfo>> getAllQueueInfo(List<String> counterIds);
}
