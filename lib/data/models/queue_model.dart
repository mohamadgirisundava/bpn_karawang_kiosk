import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// Construct dari Firestore DocumentSnapshot.
  factory QueueModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return QueueModel(
      id: doc.id,
      counterId: data['counter'] as String? ?? '',
      queueNumber: data['queue_number'] as int? ?? 0,
      queueCode: data['queue_code'] as String? ?? '',
      status: data['status'] as String? ?? '',
      date: data['date'] as String? ?? '',
      takenAt: data['taken_at'] as String?,
      calledAt: data['called_at'] as String?,
      completedAt: data['completed_at'] as String?,
      calledBy: data['called_by'] as String?,
      deskNumber: data['desk_number'] as String?,
    );
  }
}
