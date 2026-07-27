import '../../domain/entities/queue_entity.dart';
import '../../domain/entities/queue_info.dart';
import '../../domain/repositories/queue_repository.dart';
import '../datasources/queue_remote_datasource.dart';
import '../models/queue_model.dart';

/// Implementasi QueueRepository.
class QueueRepositoryImpl implements QueueRepository {
  final QueueRemoteDatasource datasource;

  const QueueRepositoryImpl(this.datasource);

  @override
  Future<QueueEntity> createQueue({
    required String counterId,
    required String counterCode,
  }) async {
    final doc = await datasource.createQueue(
      counterId: counterId,
      counterCode: counterCode,
    );

    return QueueModel.fromDoc(doc);
  }

  @override
  Future<String> createPrintJob({
    required String queueCode,
    required String counterName,
    required String takenAt,
  }) {
    return datasource.createPrintJob(
      queueCode: queueCode,
      counterName: counterName,
      takenAt: takenAt,
    );
  }

  @override
  Stream<String> watchPrintJobStatus(String printJobId) {
    return datasource.watchPrintJobStatus(printJobId);
  }

  @override
  Future<QueueInfo> getQueueInfo(String counterId) async {
    try {
      final serving = await datasource.getCurrentServing(counterId);
      final waiting = await datasource.getWaitingCount(counterId);

      return QueueInfo(
        currentServing: serving?.data()?['queue_code'] as String? ?? '-',
        waitingCount: waiting,
      );
    } catch (_) {
      return const QueueInfo(currentServing: '-', waitingCount: 0);
    }
  }

  @override
  Future<Map<String, QueueInfo>> getAllQueueInfo(
    List<String> counterIds,
  ) async {
    final Map<String, QueueInfo> info = {};

    for (final id in counterIds) {
      info[id] = await getQueueInfo(id);
    }

    return info;
  }
}
