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
    final nextNumber = await datasource.getNextQueueNumber(counterId);
    final queueCode = '$counterCode${nextNumber.toString().padLeft(3, '0')}';

    final record = await datasource.createQueue(
      counterId: counterId,
      counterCode: counterCode,
      queueNumber: nextNumber,
      queueCode: queueCode,
    );

    return QueueModel.fromRecord(record);
  }

  @override
  Future<QueueInfo> getQueueInfo(String counterId) async {
    try {
      final serving = await datasource.getCurrentServing(counterId);
      final waiting = await datasource.getWaitingCount(counterId);

      return QueueInfo(
        currentServing: serving?.getStringValue('queue_code') ?? '-',
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
