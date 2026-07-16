import 'package:pocketbase/pocketbase.dart';
import '../../domain/entities/queue_entity.dart';

/// Model data untuk queue, meng-extend entity.
class QueueModel extends QueueEntity {
  const QueueModel({
    required super.id,
    required super.counterId,
    required super.queueNumber,
    required super.queueCode,
    required super.status,
    required super.date,
    super.takenAt,
    super.calledAt,
    super.completedAt,
    super.calledBy,
    super.deskNumber,
  });

  /// Construct dari PocketBase RecordModel.
  factory QueueModel.fromRecord(RecordModel record) {
    return QueueModel(
      id: record.id,
      counterId: record.getStringValue('counter'),
      queueNumber: record.getIntValue('queue_number'),
      queueCode: record.getStringValue('queue_code'),
      status: record.getStringValue('status'),
      date: record.getStringValue('date'),
      takenAt: record.getStringValue('taken_at'),
      calledAt: record.getStringValue('called_at'),
      completedAt: record.getStringValue('completed_at'),
      calledBy: record.getStringValue('called_by'),
      deskNumber: record.getStringValue('desk_number'),
    );
  }
}
